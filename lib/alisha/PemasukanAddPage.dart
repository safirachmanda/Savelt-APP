import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PemasukanAddPage extends StatefulWidget {
  final DocumentReference userReportDocRef;

  const PemasukanAddPage({Key? key, required this.userReportDocRef}) : super(key: key);

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
      final nominal = int.parse(_nominalController.text.replaceAll(RegExp(r'[^0-9]'), ''));

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
      appBar: AppBar(
        title: const Text('Tambah Pemasukan'),
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
                'Simpan Pemasukan',
                style: TextStyle(fontSize: 16),
              ),
      ),
    );
  }
}

