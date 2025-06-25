import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PemasukanAddPage extends StatefulWidget {
  final DocumentReference userReportDocRef;

  const PemasukanAddPage({Key? key, required this.userReportDocRef})
      : super(key: key);

  @override
  _PemasukanAddPageState createState() => _PemasukanAddPageState();
}

class _PemasukanAddPageState extends State<PemasukanAddPage> {
  final _formKey = GlobalKey<FormState>();
  final _nominalController = TextEditingController();
  final _keteranganController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _selectedKategori;
  bool _isLoading = false;

  static const List<String> _kategoriList = [
    'Gaji & Upah',
    'Pendapatan Pasif',
    'Hibah dan Donasi',
    'Pemasukan Investasi',
    'Pemasukan Tidak Terduga',
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
      final nominal =
          int.parse(_nominalController.text.replaceAll(RegExp(r'[^0-9]'), ''));

      await FirebaseFirestore.instance
          .collection('reports')
          .doc(widget.userReportDocRef.id)
          .collection('pemasukan')
          .add({
        'tanggal': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'timestamp': _selectedDate,
        'nominal': nominal,
        'kategori': _selectedKategori!,
        'keterangan': _keteranganController.text,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pemasukan berhasil disimpan')),
      );
      Navigator.pop(context);
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Tambah Pemasukan',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
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
    return _buildSection(
      title: 'Tanggal',
      child: GestureDetector(
        onTap: _pickDate,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('dd MMMM yyyy').format(_selectedDate),
                style: const TextStyle(fontSize: 16),
              ),
              const Icon(Icons.calendar_today, color: Colors.blueAccent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNominalInput() {
    return _buildSection(
      title: 'Nominal',
      child: TextFormField(
        controller: _nominalController,
        keyboardType: TextInputType.number,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          prefixText: 'Rp ',
          hintText: 'Masukkan nominal',
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Masukkan nominal';
          final cleanValue = value.replaceAll(RegExp(r'[^0-9]'), '');
          if (cleanValue.isEmpty || int.tryParse(cleanValue) == null) {
            return 'Masukkan angka yang valid';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildKategoriDropdown() {
    return _buildSection(
      title: 'Kategori',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: DropdownButtonFormField<String>(
          value: _selectedKategori,
          isExpanded: true,
          style: const TextStyle(fontSize: 16),
          decoration: const InputDecoration(border: InputBorder.none),
          hint: const Text('Pilih kategori'),
          items: _kategoriList
              .map((kategori) => DropdownMenuItem(
                    value: kategori,
                    child: Text(
                      kategori,
                      style: const TextStyle(
                          fontSize: 16, color: Color.fromARGB(221, 30, 30, 30)),
                    ),
                  ))
              .toList(),
          onChanged: (value) => setState(() => _selectedKategori = value),
          validator: (value) => value == null ? 'Pilih kategori' : null,
          dropdownColor: const Color.fromARGB(255, 255, 255, 255),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildKeteranganInput() {
    return _buildSection(
      title: 'Keterangan (opsional)',
      child: TextFormField(
        controller: _keteranganController,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Masukkan keterangan',
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        maxLines: 2,
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
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
                'SIMPAN PEMASUKAN',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
