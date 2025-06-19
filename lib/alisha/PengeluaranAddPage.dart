import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PengeluaranAddPage extends StatefulWidget {
  final DocumentReference userReportDocRef;

  const PengeluaranAddPage({Key? key, required this.userReportDocRef}) : super(key: key);

  @override
  _PengeluaranAddPageState createState() => _PengeluaranAddPageState();
}

class _PengeluaranAddPageState extends State<PengeluaranAddPage> {
  final _formKey = GlobalKey<FormState>();
  final _nominalController = TextEditingController();
  final _keteranganController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _selectedKategori;
  bool _isLoading = false;

  static const List<String> _kategoriList = [
    'Makanan & Minuman',
    'Tempat Tinggal',
    'Transportasi',
    'Kesehatan',
    'Pendidikan',
    'Komunikasi & Internet',
    'Hiburan & Gaya Hidup',
    'Belanja Pribadi',
    'Keuangan & Tabungan',
    'Sosial & Keluarga',
    'Tagihan',
    'Lainnya',
  ];

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _calculateAndSaveCategoryAverages() async {
    try {
      // Get current date and calculate previous month range
      final now = DateTime.now();
      final firstDayOfPreviousMonth = DateTime(now.year, now.month - 1, 1);
      final lastDayOfPreviousMonth = DateTime(now.year, now.month, 0);
      
      // Format dates for query
      final startDate = DateFormat('yyyy-MM-dd').format(firstDayOfPreviousMonth);
      final endDate = DateFormat('yyyy-MM-dd').format(lastDayOfPreviousMonth);

      // Get expenses from previous month grouped by category
      final expensesQuery = await FirebaseFirestore.instance
          .collection('reports')
          .doc(widget.userReportDocRef.id)
          .collection('pengeluaran')
          .where('tanggal', isGreaterThanOrEqualTo: startDate)
          .where('tanggal', isLessThanOrEqualTo: endDate)
          .get();

      // Prepare data structure
      final Map<String, List<double>> categoryExpenses = {};
      for (var category in _kategoriList) {
        categoryExpenses[category] = [];
      }

      // Group expenses by category
      for (var expenseDoc in expensesQuery.docs) {
        final data = expenseDoc.data();
        final category = data['kategori'] as String?;
        final nominal = (data['nominal'] as num?)?.toDouble();
        
        if (category != null && nominal != null && categoryExpenses.containsKey(category)) {
          categoryExpenses[category]!.add(nominal);
        }
      }

      // Calculate averages and save to Firestore
      final batch = FirebaseFirestore.instance.batch();
      final budgetsCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userReportDocRef.id)
          .collection('budgets');

      // Get current month and year for budget period
      final currentMonth = DateFormat('MMMM yyyy').format(now);
      final previousMonth = DateFormat('MMMM yyyy').format(firstDayOfPreviousMonth);

      for (var category in _kategoriList) {
        final expenses = categoryExpenses[category]!;
        final total = expenses.isNotEmpty ? expenses.reduce((a, b) => a + b) : 0.0;
        final average = expenses.isNotEmpty ? total / expenses.length : 0.0;

        final budgetDocRef = budgetsCollection.doc(category);
        
        batch.set(budgetDocRef, {
          'kategori': category,
          'rata_rata': average,
          'total_pengeluaran': total,
          'jumlah_transaksi': expenses.length,
          'terakhir_diperbarui': FieldValue.serverTimestamp(),
          'detail_transaksi': expenses,
          'periode_bulan': currentMonth, // Current month for the budget
          'periode_referensi': previousMonth, // The month the data was taken from
          'tanggal_mulai_referensi': firstDayOfPreviousMonth,
          'tanggal_akhir_referensi': lastDayOfPreviousMonth,
        });
      }

      await batch.commit();

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghitung rata-rata: $e')),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedKategori == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kategori terlebih dahulu')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final nominal = int.parse(_nominalController.text.replaceAll(RegExp(r'[^0-9]'), ''));

      // Save new expense
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(widget.userReportDocRef.id)
          .collection('pengeluaran')
          .add({
            'tanggal': DateFormat('yyyy-MM-dd').format(_selectedDate),
            'timestamp': _selectedDate,
            'nominal': nominal,
            'kategori': _selectedKategori!,
            'keterangan': _keteranganController.text,
            'createdAt': FieldValue.serverTimestamp(),
          });

      // Recalculate averages for all categories based on previous month
      await _calculateAndSaveCategoryAverages();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengeluaran berhasil disimpan')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nominalController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Pengeluaran'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildDateInput(),
              const SizedBox(height: 20),
              _buildNominalInput(),
              const SizedBox(height: 20),
              _buildKategoriDropdown(),
              const SizedBox(height: 20),
              _buildKeteranganInput(),
              const SizedBox(height: 30),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateInput() {
    return InkWell(
      onTap: _pickDate,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Tanggal',
          border: OutlineInputBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(DateFormat('dd MMMM yyyy').format(_selectedDate)),
            const Icon(Icons.calendar_today, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildNominalInput() {
    return TextFormField(
      controller: _nominalController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Nominal',
        prefixText: 'Rp ',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Masukkan nominal';
        final cleanValue = value.replaceAll(RegExp(r'[^0-9]'), '');
        if (cleanValue.isEmpty || int.tryParse(cleanValue) == null) {
          return 'Masukkan angka yang valid';
        }
        return null;
      },
    );
  }

  Widget _buildKategoriDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedKategori,
      items: _kategoriList.map((kategori) => DropdownMenuItem(
        value: kategori,
        child: Text(kategori),
      )).toList(),
      decoration: const InputDecoration(
        labelText: 'Kategori',
        border: OutlineInputBorder(),
      ),
      onChanged: (value) => setState(() => _selectedKategori = value),
      validator: (value) => value == null ? 'Pilih kategori' : null,
    );
  }

  Widget _buildKeteranganInput() {
    return TextFormField(
      controller: _keteranganController,
      decoration: const InputDecoration(
        labelText: 'Keterangan (opsional)',
        border: OutlineInputBorder(),
      ),
      maxLines: 2,
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Simpan Pengeluaran',
                style: TextStyle(fontSize: 16),
              ),
      ),
    );
  }
}