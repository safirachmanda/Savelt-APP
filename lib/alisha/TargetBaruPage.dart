import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'TargetPage.dart'; // Make sure this import points to your TargetPage file

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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isSaving = false; // Added loading state

  final List<Map<String, String>> frequencyOptions = [
    {'label': 'Harian', 'value': 'Harian'},
    {'label': 'Mingguan', 'value': 'Mingguan'},
    {'label': 'Bulanan', 'value': 'Bulanan'},
  ];

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now()),
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
    if (_isSaving) return; // Prevent multiple clicks
    
    setState(() {
      _isSaving = true;
    });

    final name = _nameController.text;
    final targetAmount = int.tryParse(_targetAmountController.text) ?? 0;
    final User? user = _auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda belum login')),
      );
      setState(() {
        _isSaving = false;
      });
      return;
    }

    if (name.isEmpty ||
        _startDate == null ||
        _endDate == null ||
        targetAmount < 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Isi semua data dan pastikan target minimal 500')),
      );
      setState(() {
        _isSaving = false;
      });
      return;
    }

    if (_startDate!.isAfter(_endDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Tanggal mulai harus sebelum tanggal selesai')),
      );
      setState(() {
        _isSaving = false;
      });
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

      while (checklistCount > 0) {
        nominalPerChecklist =
            _roundUpToNearest500((targetAmount / checklistCount).ceil());
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
          const SnackBar(
              content:
                  Text('Tidak bisa membagi target pas sesuai kelipatan 500')),
        );
        setState(() {
          _isSaving = false;
        });
        return;
      }

      final docRef =
          await FirebaseFirestore.instance.collection('target_tabungan').add({
        'nama': name,
        'target': targetAmount,
        'targetTerkumpul': 0,
        'mulaiMenabung': _startDate!.toIso8601String(),
        'selesaiMenabung': _endDate!.toIso8601String(),
        'frekuensi': _selectedFrequency,
        'dibuatPada': FieldValue.serverTimestamp(),
        'uid': user.uid,
      });

      // Save all checklist items
      final batch = FirebaseFirestore.instance.batch();
      final checklistCollection = docRef.collection('checklist');
      
      for (final date in finalDates) {
        final doc = checklistCollection.doc();
        batch.set(doc, {
          'tanggalMenabung': date.toIso8601String(),
          'nominal': nominalPerChecklist,
          'status': false,
          'uid': user.uid,
        });
      }
      
      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Target berhasil disimpan')),
      );

      // Navigate back to TargetPage and remove current page from stack
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => TargetPage()),
        (Route<dynamic> route) => false,
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: $e')),
      );
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Tambah Target Tabungan',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF6A5ACD),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildInputField(
                label: 'Nama Tabungan',
                hint: 'Contoh: Kamera',
                controller: _nameController,
              ),
              const SizedBox(height: 20),
              _buildInputField(
                label: 'Target Jumlah (minimal Rp500)',
                hint: 'Contoh: 2000000',
                controller: _targetAmountController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              _buildDateField(
                label: 'Tanggal Mulai',
                date: _startDate,
                onPressed: () => _selectDate(context, true),
              ),
              const SizedBox(height: 20),
              _buildDateField(
                label: 'Tanggal Selesai',
                date: _endDate,
                onPressed: () => _selectDate(context, false),
              ),
              const SizedBox(height: 20),
              _buildSection(
                title: 'Frekuensi Menabung',
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedFrequency,
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: Colors.black, fontSize: 16),
                    underline: const SizedBox(),
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
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveTargetToFirebase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6A5ACD),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'SIMPAN TARGET',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return _buildSection(
      title: label,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          hintText: hint,
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
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onPressed,
  }) {
    return _buildSection(
      title: label,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date == null
                    ? 'Pilih tanggal'
                    : DateFormat('dd/MM/yyyy').format(date),
                style: TextStyle(fontSize: 16),
              ),
              Icon(Icons.calendar_today, color: Color(0xFF6A5ACD)),
            ],
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
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        child,
      ],
    );
  }
}