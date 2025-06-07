import 'package:flutter/material.dart';

class PengeluaranAddPage extends StatefulWidget {
  @override
  _PengeluaranAddPageState createState() => _PengeluaranAddPageState();
}

class _PengeluaranAddPageState extends State<PengeluaranAddPage> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  final TextEditingController _nominalController = TextEditingController();
  final TextEditingController _keteranganController = TextEditingController();
  String? _selectedKategori;

  final List<String> _kategoriList = [
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
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tambah Pengeluaran'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Tanggal
              Text('Tanggal'),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    hintText: 'Pilih tanggal',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _selectedDate == null
                        ? ''
                        : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Nominal
              TextFormField(
                controller: _nominalController,
                decoration: InputDecoration(
                  labelText: 'Nominal',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),

              // Dropdown Kategori
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(),
                ),
                value: _selectedKategori,
                items: _kategoriList.map((kategori) {
                  return DropdownMenuItem(
                    value: kategori,
                    child: Text(kategori),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedKategori = value;
                  });
                },
              ),
              SizedBox(height: 16),

              // Keterangan
              TextFormField(
                controller: _keteranganController,
                decoration: InputDecoration(
                  labelText: 'Keterangan',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              SizedBox(height: 24),

              // Tombol Simpan
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // Tambahkan aksi simpan di sini
                    print('Tanggal: $_selectedDate');
                    print('Nominal: ${_nominalController.text}');
                    print('Kategori: $_selectedKategori');
                    print('Keterangan: ${_keteranganController.text}');
                  }
                },
                child: Text('Simpan'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
