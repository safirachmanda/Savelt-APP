import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TargetBaruPage extends StatefulWidget {
  @override
  _TargetBaruPageState createState() => _TargetBaruPageState();
}

class _TargetBaruPageState extends State<TargetBaruPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _targetAmountController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedFrequency = 'Harian';

  final List<Map<String, String>> frequencyOptions = [
    {'label': 'Harian', 'value': 'Harian'},
    {'label': 'Mingguan', 'value': 'Mingguan'},
    {'label': 'Bulanan', 'value': 'Bulanan'},
  ];

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  int _roundUpToNearest500(int value) {
    return ((value + 499) ~/ 500) * 500;
  }

  Future<void> _saveTargetToFirebase() async {
    final name = _nameController.text;
    final targetAmount = int.tryParse(_targetAmountController.text) ?? 0;

    if (name.isEmpty || _startDate == null || _endDate == null || targetAmount < 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi semua data dan pastikan target minimal 500')),
      );
      return;
    }

    if (_startDate!.isAfter(_endDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tanggal mulai harus sebelum tanggal selesai')),
      );
      return;
    }

    try {
      List<DateTime> allDates = [];
      DateTime current = _startDate!;
      while (!current.isAfter(_endDate!)) {
        allDates.add(current);
        current = _selectedFrequency == 'Harian'
            ? current.add(const Duration(days: 1))
            : _selectedFrequency == 'Mingguan'
                ? current.add(const Duration(days: 7))
                : DateTime(current.year, current.month + 1, current.day);
      }

      int totalAvailable = allDates.length;

      bool valid = false;
      int checklistCount = totalAvailable;
      int nominalPerChecklist = 0;
      List<DateTime> finalDates = [];

      // Ulangi hingga nominal * checklistCount == target
      while (checklistCount > 0) {
        nominalPerChecklist = _roundUpToNearest500((targetAmount / checklistCount).ceil());
        int total = nominalPerChecklist * checklistCount;

        if (total == targetAmount) {
          valid = true;
          finalDates = allDates.take(checklistCount).toList();
          break;
        }
        checklistCount--;
      }

      if (!valid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak bisa membagi target pas sesuai kelipatan 500')),
        );
        return;
      }

      final docRef = await FirebaseFirestore.instance.collection('target_tabungan').add({
        'nama': name,
        'target': targetAmount,
        'targetTerkumpul': 0, // Sesuai permintaan: 0
        'mulaiMenabung': _startDate!.toIso8601String(),
        'selesaiMenabung': _endDate!.toIso8601String(),
        'frekuensi': _selectedFrequency,
        'dibuatPada': FieldValue.serverTimestamp(),
      });

      for (final date in finalDates) {
        await docRef.collection('checklist').add({
          'tanggalMenabung': date.toIso8601String(),
          'nominal': nominalPerChecklist,
          'status': false,
        });
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Target Tabungan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Text('Nama Tabungan'),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Contoh: Kamera',
                ),
              ),
              const SizedBox(height: 12),
              const Text('Target Jumlah (minimal Rp500)'),
              TextField(
                controller: _targetAmountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Contoh: 2000000',
                ),
              ),
              const SizedBox(height: 12),
              const Text('Tanggal Mulai'),
              Row(
                children: [
                  Text(_startDate == null
                      ? 'Belum dipilih'
                      : DateFormat('dd/MM/yyyy').format(_startDate!)),
                  TextButton(
                    onPressed: () => _selectDate(context, true),
                    child: const Text('Pilih'),
                  ),
                ],
              ),
              const Text('Tanggal Selesai'),
              Row(
                children: [
                  Text(_endDate == null
                      ? 'Belum dipilih'
                      : DateFormat('dd/MM/yyyy').format(_endDate!)),
                  TextButton(
                    onPressed: () => _selectDate(context, false),
                    child: const Text('Pilih'),
                  ),
                ],
              ),
              const Text('Frekuensi Menabung'),
              DropdownButton<String>(
                value: _selectedFrequency,
                isExpanded: true,
                items: frequencyOptions.map((f) {
                  return DropdownMenuItem<String>(
                    value: f['value'],
                    child: Text(f['label']!),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedFrequency = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveTargetToFirebase,
                child: const Text('Simpan Target'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
