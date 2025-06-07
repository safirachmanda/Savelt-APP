import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'CategorySelectionPage.dart';
import 'HomePage.dart';
import 'ReportsPage.dart';
import 'TargetPage.dart';
import 'AccountPage.dart';

class BillsPage extends StatefulWidget {
  @override
  _BillsPageState createState() => _BillsPageState();
}

class _BillsPageState extends State<BillsPage> {
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Tagihan Anda', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('bills')
                    .orderBy('created_at', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('Belum ada tagihan'));
                  }

                  return ListView(
                    children: snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final icon = IconData(
                        data['icon_code'],
                        fontFamily: data['icon_font_family'],
                      );

                      final dueDateTimestamp = data['due_date'] as Timestamp?;
                      final dueDate = dueDateTimestamp != null
                          ? _dateFormat.format(dueDateTimestamp.toDate())
                          : '-';

                      return _buildTargetCard(
                        context: context,
                        docId: doc.id,
                        icon: icon,
                        title: data['title'] ?? 'Tanpa Judul',
                        amount: 'Rp ${data['amount']}',
                        rawAmount: data['amount'].toString(),
                        description: data['description'] ?? '',
                        iconColor: Color(data['color']),
                        dueDate: dueDate,
                        frequency: data['frequency'] ?? '',
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CategorySelectionPage()),
                );
              },
              icon: Icon(Icons.add, color: Colors.white),
              label: Text('Tambahkan Tagihan Lain', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildTargetCard({
    required BuildContext context,
    required String docId,
    required IconData icon,
    required String title,
    required String amount,
    required String rawAmount,
    required String description,
    required Color iconColor,
    required String dueDate,
    required String frequency,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: iconColor.withOpacity(0.1),
              radius: 25,
              child: Icon(icon, color: iconColor, size: 28),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text(description, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  SizedBox(height: 4),
                  Text('Jatuh tempo: $dueDate', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                  Text('Frekuensi: $frequency', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amount,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        _showEditDialog(context, docId, rawAmount, description, dueDate, frequency);
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await FirebaseFirestore.instance.collection('bills').doc(docId).delete();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Tagihan berhasil dihapus')),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    String docId,
    String currentAmount,
    String currentDesc,
    String currentDueDate,
    String currentFrequency,
  ) {
    final TextEditingController amountController = TextEditingController(text: currentAmount);
    final TextEditingController descController = TextEditingController(text: currentDesc);

    List<String> frequencies = ['Harian', 'Mingguan', 'Bulanan', 'Tahunan'];
    String dropdownValue = frequencies.contains(currentFrequency) ? currentFrequency : frequencies[0];

    DateTime? selectedDate;
    if (currentDueDate.isNotEmpty && currentDueDate != '-') {
      try {
        selectedDate = _dateFormat.parse(currentDueDate);
      } catch (e) {
        selectedDate = null;
      }
    }

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Edit Tagihan'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  decoration: InputDecoration(labelText: 'Nominal'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(labelText: 'Deskripsi'),
                ),
                SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: dropdownValue,
                  decoration: InputDecoration(labelText: 'Frekuensi'),
                  items: frequencies.map((freq) {
                    return DropdownMenuItem(
                      value: freq,
                      child: Text(freq),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        dropdownValue = value;
                      });
                    }
                  },
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(selectedDate == null
                          ? 'Pilih tanggal jatuh tempo'
                          : 'Jatuh tempo: ${_dateFormat.format(selectedDate!)}'),
                    ),
                    TextButton(
                      child: Text('Pilih Tanggal'),
                      onPressed: () async {
                        DateTime now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? now,
                          firstDate: DateTime(now.year - 5),
                          lastDate: DateTime(now.year + 5),
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                    )
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Tanggal jatuh tempo harus dipilih')),
                  );
                  return;
                }

                await FirebaseFirestore.instance.collection('bills').doc(docId).update({
                  'amount': amountController.text,
                  'description': descController.text,
                  'frequency': dropdownValue,
                  'due_date': Timestamp.fromDate(selectedDate!),
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Tagihan berhasil diperbarui')),
                );
              },
              child: Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.blue,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      currentIndex: 1, // Index untuk halaman ini
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
            break;
          case 1:
            // Halaman saat ini
            break;
          case 2:
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ReportsPage()));
            break;
          case 3:
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => TargetPage()));
            break;
          case 4:
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AccountPage()));
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: 'Tagihan'),
        BottomNavigationBarItem(icon: Icon(Icons.insert_chart), label: 'Laporan'),
        BottomNavigationBarItem(icon: Icon(Icons.savings), label: 'Target'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
