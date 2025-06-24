import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'BillsPage.dart'; // Import Firebase Auth

class BillSettingsPage extends StatefulWidget {
  final String categoryTitle;
  final IconData categoryIcon;

  BillSettingsPage({required this.categoryTitle, required this.categoryIcon});

  @override
  _BillSettingsPageState createState() => _BillSettingsPageState();
}

class _BillSettingsPageState extends State<BillSettingsPage> {
  DateTime? selectedDate;
  final TextEditingController _amountController = TextEditingController();
  String? selectedFrequency;
  final List<String> frequencies = ['Harian', 'Mingguan', 'Bulanan', 'Tahunan'];

  Future<void> _saveBillToFirestore() async {
    // Get current user
    User? user = FirebaseAuth.instance.currentUser;
    
    // Check if user is logged in
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Anda harus login terlebih dahulu')),
      );
      return;
    }

    // Validate form fields
    if (selectedDate == null || _amountController.text.isEmpty || selectedFrequency == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Semua kolom harus diisi')),
      );
      return;
    }

    try {
      // Save to Firestore with user ID
      await FirebaseFirestore.instance.collection('bills').add({
        'due_date': selectedDate,
        'amount': _amountController.text,
        'frequency': selectedFrequency,
        'title': widget.categoryTitle,
        'icon_code': widget.categoryIcon.codePoint,
        'icon_font_family': widget.categoryIcon.fontFamily,
        'description': 'Repeat $selectedFrequency sampai tanggal ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
        'color': Colors.blue.value,
        'created_at': FieldValue.serverTimestamp(),
        'uid': user.uid, // Add user ID to the document
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tagihan berhasil ditambahkan')),
      );

      Navigator.pushAndRemoveUntil(
  context,
  MaterialPageRoute(builder: (context) => BillsPage()),
  (route) => false, // Ini akan menghapus semua halaman sebelumnya
);
    } catch (e) {
      print('Error saving to Firestore: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan tagihan: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Atur ${widget.categoryTitle}'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    child: Icon(widget.categoryIcon, color: Colors.blue, size: 30),
                  ),
                  SizedBox(height: 8),
                  Text(widget.categoryTitle, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            SizedBox(height: 20),

            Text('Kapan tenggat waktu?', style: TextStyle(fontWeight: FontWeight.bold)),
            GestureDetector(
              onTap: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() {
                    selectedDate = picked;
                  });
                }
              },
              child: Container(
                padding: EdgeInsets.all(12),
                margin: EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      selectedDate == null
                          ? 'Pilih tanggal'
                          : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                    ),
                    Icon(Icons.calendar_today, color: Colors.blue),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            Text('Berapa besar nominalnya?', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: 'Rp ',
                hintText: 'Masukkan nominal',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            SizedBox(height: 20),

            Text('Berapa frekuensi pengulangannya?', style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButtonFormField<String>(
              value: selectedFrequency,
              hint: Text('Pilih opsi pengulangan'),
              items: frequencies.map((String frequency) {
                return DropdownMenuItem<String>(
                  value: frequency,
                  child: Text(frequency),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedFrequency = newValue;
                });
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            SizedBox(height: 20),

            GestureDetector(
              onTap: _saveBillToFirestore,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'TAMBAH TAGIHAN',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}