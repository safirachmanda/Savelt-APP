import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CategoryDetailPage extends StatelessWidget {
  final String type; // 'pemasukan' or 'pengeluaran'
  final String category;
  final DateTime month;
  
  const CategoryDetailPage({
    super.key,
    required this.type,
    required this.category,
    required this.month,
  });

  // Method to get icon based on category
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'gaji & upah':
        return Icons.work;
      case 'pendapatan pasif':
        return Icons.trending_up;
      case 'hibah dan donasi':
        return Icons.card_giftcard;
      case 'pemasukan investasi':
        return Icons.monetization_on;
      case 'pemasukan tidak terduga':
        return Icons.celebration;
      case 'makanan & minuman':
        return Icons.restaurant;
      case 'tempat tinggal':
        return Icons.home;
      case 'transportasi':
        return Icons.directions_car;
      case 'kesehatan':
        return Icons.local_hospital;
      case 'pendidikan':
        return Icons.school;
      case 'komunikasi & internet':
        return Icons.wifi;
      case 'hiburan & gaya hidup':
        return Icons.movie;
      case 'belanja pribadi':
        return Icons.shopping_bag;
      case 'keuangan & tabungan':
        return Icons.account_balance;
      case 'sosial & keluarga':
        return Icons.people;
      case 'tagihan':
        return Icons.receipt;
      default:
        return Icons.category;
    }
  }

  Future<void> _deleteTransaction(BuildContext context, String docId) async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(user.uid)
          .collection(type)
          .doc(docId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaksi berhasil dihapus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus transaksi: $e')),
      );
    }
  }

  Future<void> _editTransaction(
    BuildContext context, 
    String docId, 
    Map<String, dynamic> currentData
  ) async {
    final nominalController = TextEditingController(
      text: currentData['nominal'].toString());
    final descriptionController = TextEditingController(
      text: currentData['keterangan'] ?? '');
    final categoryController = TextEditingController(
      text: currentData['kategori']);
    final date = (currentData['timestamp'] as Timestamp).toDate();

    DateTime selectedDate = date;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Transaksi'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nominalController,
                  decoration: const InputDecoration(
                    labelText: 'Nominal',
                    prefixText: 'Rp ',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Keterangan',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                  ),
                  readOnly: true,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Tanggal:'),
                    const SizedBox(width: 8),
                    Text(DateFormat('dd MMM yyyy').format(selectedDate)),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (pickedDate != null) {
                          selectedDate = pickedDate;
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final user = FirebaseAuth.instance.currentUser!;
                  await FirebaseFirestore.instance
                      .collection('reports')
                      .doc(user.uid)
                      .collection(type)
                      .doc(docId)
                      .update({
                    'nominal': double.parse(nominalController.text),
                    'keterangan': descriptionController.text,
                    'timestamp': Timestamp.fromDate(selectedDate),
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Transaksi berhasil diperbarui')),
                  );
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal memperbarui transaksi: $e')),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final collection = FirebaseFirestore.instance
        .collection('reports')
        .doc(user.uid)
        .collection(type);

    // Get first and last day of selected month
    DateTime firstDay = DateTime(month.year, month.month, 1);
    DateTime lastDay = DateTime(month.year, month.month + 1, 0);

    return Scaffold(
      appBar: AppBar(
        title: Text('Detail $category'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: collection
            .where('timestamp', isGreaterThanOrEqualTo: firstDay)
            .where('timestamp', isLessThanOrEqualTo: lastDay)
            .where('kategori', isEqualTo: category)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 60,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tidak ada transaksi $category',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    DateFormat('MMMM yyyy').format(month),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;
          double total = 0;
          for (var doc in docs) {
            total += (doc['nominal'] as num).toDouble();
          }

          return Column(
            children: [
              _buildSummaryCard(total, docs.length),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final nominal = (data['nominal'] as num).toDouble();
                    final timestamp = (data['timestamp'] as Timestamp).toDate();
                    final description = data['keterangan'] ?? '-';
                    final date = DateFormat('dd MMM yyyy').format(timestamp);
                    final time = DateFormat('HH:mm').format(timestamp);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: type == 'pemasukan'
                                    ? Colors.green[50]
                                    : Colors.red[50],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                _getCategoryIcon(category),
                                color: type == 'pemasukan'
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    description,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$date • $time',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Rp${NumberFormat('#,###').format(nominal)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: type == 'pemasukan'
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      DateFormat('EEEE', 'id_ID').format(timestamp),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    PopupMenuButton(
                                      icon: const Icon(Icons.more_vert, size: 16),
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Text('Edit'),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Hapus'),
                                        ),
                                      ],
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          _editTransaction(context, doc.id, data);
                                        } else if (value == 'delete') {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Hapus Transaksi'),
                                              content: const Text(
                                                  'Apakah Anda yakin ingin menghapus transaksi ini?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: const Text('Batal'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    _deleteTransaction(context, doc.id);
                                                    Navigator.pop(context);
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.red,
                                                  ),
                                                  child: const Text('Hapus'),
                                                ),
                                              ],
                                            ),
                                          );
                                        }
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
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(double total, int transactionCount) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: type == 'pemasukan' ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: type == 'pemasukan' ? Colors.green[100] : Colors.red[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getCategoryIcon(category),
              size: 30,
              color: type == 'pemasukan' ? Colors.green[800] : Colors.red[800],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rp${NumberFormat('#,###').format(total)}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: type == 'pemasukan' ? Colors.green[800] : Colors.red[800],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Total $type',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                '$transactionCount transaksi',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}