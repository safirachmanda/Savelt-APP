import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'TargetBaruPage.dart';
import 'HomePage.dart';
import 'BillsPage.dart';
import 'ReportsPage.dart';
import 'AccountPage.dart';
import 'ChecklistPage.dart';

class TargetPage extends StatefulWidget {
  @override
  _TargetPageState createState() => _TargetPageState();
}

class _TargetPageState extends State<TargetPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _deleteTarget(String docId) async {
    await _firestore.collection('target_tabungan').doc(docId).delete();
  }

  Future<double> _calculateSavedAmount(String tabunganId) async {
    try {
      final querySnapshot = await _firestore
          .collection('target_tabungan')
          .doc(tabunganId)
          .collection('checklist')
          .where('status', isEqualTo: true)
          .get();

      double total = 0;
      for (final doc in querySnapshot.docs) {
        final nominal = doc.data()['nominal'] ?? 0;
        total += (nominal as num).toDouble();
      }
      return total;
    } catch (e) {
      print('Error calculating saved amount: $e');
      return 0;
    }
  }

  DateTime _parseDate(dynamic date) {
    if (date is Timestamp) {
      return date.toDate();
    } else if (date is String) {
      return DateTime.parse(date);
    }
    return DateTime.now();
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
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'Belum ada target tabungan\nTambahkan target baru dengan tombol +',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final docId = doc.id;
              final targetAmount = (data['target'] as num?)?.toDouble() ?? 0.0;
              final name = data['nama'] ?? 'Target Tanpa Nama';
              
              // Handle date parsing safely
              final startDate = _parseDate(data['mulaiMenabung']);
              final endDate = _parseDate(data['selesaiMenabung']);

              return FutureBuilder<double>(
                future: _calculateSavedAmount(docId),
                builder: (context, savedSnapshot) {
                  final savedAmount = savedSnapshot.hasData ? savedSnapshot.data! : 0.0;
                  final progress = targetAmount > 0 ? (savedAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

                  // Update saved amount in Firestore if different
                  if (savedSnapshot.hasData) {
                    final currentSaved = (data['targetTerkumpul'] as num?)?.toDouble() ?? 0.0;
                    if (currentSaved != savedAmount) {
                      _firestore.collection('target_tabungan').doc(docId).update({
                        'targetTerkumpul': savedAmount,
                      });
                    }
                  }

                  return Card(
                    margin: EdgeInsets.all(12),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF4CA1AF),
                            Color(0xFF2C3E50),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ExpansionTile(
                        title: Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.white24,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              minHeight: 6,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Rp${NumberFormat('#,###').format(savedAmount)} / Rp${NumberFormat('#,###').format(targetAmount)}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailRow(
                                  Icons.calendar_today,
                                  'Mulai: ${DateFormat('dd MMM yyyy').format(startDate)}',
                                ),
                                SizedBox(height: 8),
                                _buildDetailRow(
                                  Icons.event_available,
                                  'Target: ${DateFormat('dd MMM yyyy').format(endDate)}',
                                ),
                                SizedBox(height: 8),
                                _buildDetailRow(
                                  Icons.attach_money,
                                  'Target: Rp${NumberFormat('#,###').format(targetAmount)}',
                                ),
                                SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () => _deleteTarget(docId),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red[700],
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        'Hapus',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ChecklistPage(
                                              tabunganId: docId,
                                            ),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green[700],
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        'Lihat Checklist',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TargetBaruPage()),
          );
        },
        child: Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.white70),
        SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.blue,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      currentIndex: 3, // Target tab is active
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => HomeScreen()),
            );
            break;
          case 1:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => BillsPage()),
            );
            break;
          case 2:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => ReportsPage()),
            );
            break;
          case 4:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => AccountPage()),
            );
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