// import tetap sama
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'TargetBaruPage.dart';
import 'HomePage.dart';
import 'BillsPage.dart';
import 'ReportsPage.dart';
import 'AccountPage.dart';

class TargetPage extends StatefulWidget {
  @override
  _TargetPageState createState() => _TargetPageState();
}

class _TargetPageState extends State<TargetPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _deleteTarget(String docId) {
    _firestore.collection('target_tabungan').doc(docId).delete();
  }

  Future<void> _handleChecklistTap({
    required String tabunganId,
    required DocumentSnapshot checklistDoc,
    required int nominalPerHari,
  }) async {
    final now = DateTime.now();
    final tgl = (checklistDoc['tanggal'] as Timestamp).toDate();
    final isToday = tgl.year == now.year && tgl.month == now.month && tgl.day == now.day;
    final isChecked = checklistDoc['status'] ?? false;

    if (!isChecked && isToday) {
      await _firestore
          .collection('target_tabungan')
          .doc(tabunganId)
          .collection('checklist')
          .doc(checklistDoc.id)
          .update({'status': true});

      final checklistSnapshot = await _firestore
          .collection('target_tabungan')
          .doc(tabunganId)
          .collection('checklist')
          .where('status', isEqualTo: true)
          .get();

      int jumlahBenar = checklistSnapshot.docs.length;
      int totalBaru = jumlahBenar * nominalPerHari;

      await _firestore.collection('target_tabungan').doc(tabunganId).update({
        'targetTerkumpul': totalBaru,
      });
    }
  }

  Future<void> _showAddChecklistDialog({
    required String docId,
    required DateTime mulai,
    required DateTime selesai,
  }) async {
    final checklistCollection =
        _firestore.collection('target_tabungan').doc(docId).collection('checklist');
    final existingChecklists = await checklistCollection.get();

    final existingDates = existingChecklists.docs
        .map((e) => (e['tanggal'] as Timestamp).toDate())
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet();

    final List<DateTime> allDates = [];
    for (int i = 0; i <= selesai.difference(mulai).inDays; i++) {
      final current = mulai.add(Duration(days: i));
      if (!existingDates.contains(DateTime(current.year, current.month, current.day))) {
        allDates.add(current);
      }
    }

    if (allDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Semua tanggal checklist sudah ditambahkan.')),
      );
      return;
    }

    final Map<DateTime, bool> selectedDates = {
      for (var d in allDates) d: false,
    };

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('Tambah Checklist'),
            content: Container(
              width: double.maxFinite,
              height: 300,
              child: ListView(
                children: selectedDates.entries.map((entry) {
                  return CheckboxListTile(
                    title: Text(DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(entry.key)),
                    value: entry.value,
                    onChanged: (val) {
                      setDialogState(() {
                        selectedDates[entry.key] = val ?? false;
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  for (var entry in selectedDates.entries) {
                    if (entry.value) {
                      await checklistCollection.add({
                        'tanggal': Timestamp.fromDate(entry.key),
                        'status': false,
                      });
                    }
                  }
                  Navigator.pop(context);
                },
                child: Text('Simpan'),
              ),
            ],
          );
        });
      },
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.blue,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      currentIndex: 3,
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
            break;
          case 1:
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => BillsPage()));
            break;
          case 2:
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ReportsPage()));
            break;
          case 4:
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AccountPage()));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Target Tabungan'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('target_tabungan').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Text('Terjadi kesalahan');
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id;
              final target = data['target'] ?? 0;
              final terkumpul = data['targetTerkumpul'] ?? 0;
              final nama = data['nama'] ?? 'Target';
              final mulai = DateTime.parse(data['mulaiMenabung']);
              final selesai = DateTime.parse(data['selesaiMenabung']);
              final jumlahHari = selesai.difference(mulai).inDays + 1;
              final nominalChecklist = (target / jumlahHari).ceil();

              return Card(
                margin: const EdgeInsets.all(8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color.fromARGB(255, 39, 167, 176), Colors.lightBlueAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ExpansionTile(
                    title: Text(nama,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    subtitle: Text(
                      'Terkumpul: Rp$terkumpul / Rp$target',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: StreamBuilder<QuerySnapshot>(
                          stream: _firestore
                              .collection('target_tabungan')
                              .doc(docId)
                              .collection('checklist')
                              .orderBy('tanggal')
                              .snapshots(),
                          builder: (context, tabunganSnapshot) {
                            if (tabunganSnapshot.hasError) return Text('Error');
                            if (tabunganSnapshot.connectionState == ConnectionState.waiting) {
                              return CircularProgressIndicator();
                            }

                            final checklistDocs = tabunganSnapshot.data!.docs;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mulai Menabung: ${DateFormat('dd MMM yyyy', 'id_ID').format(mulai)}',
                                  style: TextStyle(color: Colors.white),
                                ),
                                Text(
                                  'Selesai Menabung: ${DateFormat('dd MMM yyyy', 'id_ID').format(selesai)}',
                                  style: TextStyle(color: Colors.white),
                                ),
                                Text(
                                  'Target: Rp$target',
                                  style: TextStyle(color: Colors.white),
                                ),
                                SizedBox(height: 10),
                                ...checklistDocs.map((doc) {
                                  final tgl = (doc['tanggal'] as Timestamp).toDate();
                                  final status = doc['status'] ?? false;

                                  return CheckboxListTile(
                                    title: Text(
                                      DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(tgl),
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                    value: status,
                                    onChanged: (val) async {
                                      await _handleChecklistTap(
                                        tabunganId: docId,
                                        checklistDoc: doc,
                                        nominalPerHari: nominalChecklist,
                                      );
                                    },
                                    controlAffinity: ListTileControlAffinity.leading,
                                    activeColor: Colors.white,
                                    checkColor: Colors.blue,
                                  );
                                }).toList(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () => _deleteTarget(docId),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Hapus Tabungan'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => _showAddChecklistDialog(
                                        docId: docId,
                                        mulai: mulai,
                                        selesai: selesai,
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Tambah Checklist'),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => TargetBaruPage()));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
