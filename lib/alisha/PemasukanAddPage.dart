import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PemasukanAddPage extends StatefulWidget {
  @override
  _PemasukanAddPageState createState() => _PemasukanAddPageState();
}

class _PemasukanAddPageState extends State<PemasukanAddPage> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  final _nominalController = TextEditingController();
  String? _selectedKategori;
  final _keteranganController = TextEditingController();

  final List<String> _kategoriList = [
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
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate)
      setState(() {
        _selectedDate = picked;
      });
  }

  void _submitForm() {
    if (_formKey.currentState!.validate() && _selectedDate != null && _selectedKategori != null) {
      final pemasukanData = {
        'tanggal': DateFormat('yyyy-MM-dd').format(_selectedDate!),
        'nominal': _nominalController.text,
        'kategori': _selectedKategori!,
        'keterangan': _keteranganController.text,
      };

      // Untuk sementara tampilkan di console
      print('Data pemasukan: $pemasukanData');

      // Reset form
      _formKey.currentState!.reset();
      setState(() {
        _selectedDate = null;
        _selectedKategori = null;
      });
      _nominalController.clear();
      _keteranganController.clear();
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
      appBar: AppBar(title: Text('Tambah Pemasukan')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Input tanggal
              ListTile(
                title: Text(_selectedDate == null
                    ? 'Pilih Tanggal'
                    : 'Tanggal: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}'),
                trailing: Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              SizedBox(height: 10),

              // Input nominal
              TextFormField(
                controller: _nominalController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Nominal'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Masukkan nominal' : null,
              ),
              SizedBox(height: 10),

              // Dropdown kategori
              DropdownButtonFormField<String>(
                value: _selectedKategori,
                items: _kategoriList
                    .map((kategori) => DropdownMenuItem(
                          value: kategori,
                          child: Text(kategori),
                        ))
                    .toList(),
                decoration: InputDecoration(labelText: 'Kategori'),
                onChanged: (value) {
                  setState(() {
                    _selectedKategori = value;
                  });
                },
                validator: (value) =>
                    value == null ? 'Pilih kategori' : null,
              ),
              SizedBox(height: 10),

              // Input keterangan
              TextFormField(
                controller: _keteranganController,
                decoration: InputDecoration(labelText: 'Keterangan'),
                maxLines: 2,
              ),
              SizedBox(height: 20),

              // Tombol submit
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
