import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ChecklistPage extends StatefulWidget {
  final String tabunganId;

  const ChecklistPage({
    required this.tabunganId,
    Key? key,
  }) : super(key: key);

  @override
  State<ChecklistPage> createState() => _ChecklistPageState();
}

class _ChecklistPageState extends State<ChecklistPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Future<Map<String, dynamic>> _tabunganData;

  // Helper method to parse dates that could be either Timestamp or String
  DateTime _parseDate(dynamic date) {
    if (date is Timestamp) {
      return date.toDate();
    } else if (date is String) {
      return DateTime.parse(date);
    }
    throw Exception('Invalid date format');
  }

  @override
  void initState() {
    super.initState();
    _tabunganData = _fetchTabunganData();
  }

  Future<Map<String, dynamic>> _fetchTabunganData() async {
    final doc = await _firestore
        .collection('target_tabungan')
        .doc(widget.tabunganId)
        .get();
    if (!doc.exists) {
      throw Exception('Document not found');
    }
    return doc.data() as Map<String, dynamic>;
  }

  Future<void> _handleChecklistTap(DocumentSnapshot doc) async {
    final now = DateTime.now();
    final tgl = _parseDate(doc['tanggalMenabung']);
    final isPastOrToday = tgl.isBefore(now) ||
        (tgl.year == now.year && tgl.month == now.month && tgl.day == now.day);
    final isChecked = doc['status'] ?? false;

    if (!isChecked && isPastOrToday) {
      final tabunganData = await _tabunganData;
      final mulai = _parseDate(tabunganData['mulaiMenabung']);
      final selesai = _parseDate(tabunganData['selesaiMenabung']);
      final target = (tabunganData['target'] as num).toInt();
      final totalHari = selesai.difference(mulai).inDays + 1;
      final nominalPerHari = ((target / totalHari).ceil()).toInt();

      await _firestore
          .collection('target_tabungan')
          .doc(widget.tabunganId)
          .collection('checklist')
          .doc(doc.id)
          .update({'status': true});

      final checklistSnapshot = await _firestore
          .collection('target_tabungan')
          .doc(widget.tabunganId)
          .collection('checklist')
          .where('status', isEqualTo: true)
          .get();

      int jumlahBenar = checklistSnapshot.docs.length;
      int totalBaru = jumlahBenar * nominalPerHari;

      await _firestore
          .collection('target_tabungan')
          .doc(widget.tabunganId)
          .update({'targetTerkumpul': totalBaru});

      setState(() {
        _tabunganData = _fetchTabunganData();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Checklist Tabungan',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 131, 120, 201),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _tabunganData,
        builder: (context, tabunganSnapshot) {
          if (tabunganSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (tabunganSnapshot.hasError) {
            return Center(child: Text('Error: ${tabunganSnapshot.error}'));
          }
          if (!tabunganSnapshot.hasData) {
            return const Center(child: Text('Data tidak ditemukan'));
          }

          final tabunganData = tabunganSnapshot.data!;
          final mulai = _parseDate(tabunganData['mulaiMenabung']);
          final selesai = _parseDate(tabunganData['selesaiMenabung']);
          final target = (tabunganData['target'] as num).toInt();
          final totalHari = selesai.difference(mulai).inDays + 1;
          final nominalPerHari = ((target / totalHari).ceil()).toInt();

          return StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('target_tabungan')
                .doc(widget.tabunganId)
                .collection('checklist')
                .orderBy('tanggalMenabung')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;
              final now = DateTime.now();

              if (docs.isEmpty) {
                return const Center(
                  child: Text('Belum ada checklist untuk tabungan ini'),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final tanggal = _parseDate(doc['tanggalMenabung']);
                  final status = doc['status'] ?? false;
                  final nominal =
                      (doc['nominal'] as num?)?.toInt() ?? nominalPerHari;
                  final isPastOrToday = tanggal.isBefore(now) ||
                      (tanggal.year == now.year &&
                          tanggal.month == now.month &&
                          tanggal.day == now.day);

                  return Container(
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: status
                              ? const Color.fromARGB(255, 131, 120, 201)
                                  .withOpacity(0.2)
                              : Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          status
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: status
                              ? const Color.fromARGB(255, 131, 120, 201)
                              : Colors.grey[600],
                        ),
                      ),
                      title: Text(
                        DateFormat('EEEE, dd MMMM yyyy', 'id_ID')
                            .format(tanggal),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      subtitle: Text(
                        'Rp${NumberFormat('#,###').format(nominal)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      trailing: status
                          ? const Icon(Icons.lock, color: Colors.grey)
                          : isPastOrToday
                              ? IconButton(
                                  icon: const Icon(Icons.check,
                                      color:
                                          Color.fromARGB(255, 131, 120, 201)),
                                  onPressed: () => _handleChecklistTap(doc),
                                )
                              : const Icon(Icons.lock_outline,
                                  color: Colors.grey),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
