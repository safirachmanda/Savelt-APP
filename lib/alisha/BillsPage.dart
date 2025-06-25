import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Debugging variables
  bool _isLoading = true;
  String _debugMessage = '';
  List<String> _debugLogs = [];

  @override
  void initState() {
    super.initState();
    _addDebugLog('BillsPage initialized');
    _checkUserAuth();
  }

  void _checkUserAuth() {
    _addDebugLog('Checking user authentication');
    if (_auth.currentUser == null) {
      _addDebugLog('No user logged in', isError: true);
      setState(() {
        _isLoading = false;
        _debugMessage = 'No user authenticated';
      });
    } else {
      _addDebugLog('User authenticated: ${_auth.currentUser?.uid}');
    }
  }

  void _addDebugLog(String message, {bool isError = false}) {
    final timestamp = DateTime.now().toIso8601String();
    final logEntry = '$timestamp - ${isError ? 'ERROR' : 'DEBUG'}: $message';
    _debugLogs.add(logEntry);
    if (isError) {
      debugPrint('🔥 $logEntry');
    } else {
      debugPrint('ℹ️ $logEntry');
    }
  }

  Stream<QuerySnapshot> _getBillsStream() {
    _addDebugLog('Getting bills stream for user: ${_auth.currentUser?.uid}');
    try {
      return _firestore
          .collection('bills')
          .where('uid', isEqualTo: _auth.currentUser?.uid)
          .orderBy('created_at', descending: true)
          .snapshots();
    } catch (e) {
      _addDebugLog('Error getting bills stream: $e', isError: true);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title:
            Text('Tagihan Anda', style: TextStyle(fontWeight: FontWeight.bold)),
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
                stream: _getBillsStream(),
                builder: (context, snapshot) {
                  _addDebugLog(
                      'StreamBuilder state: ${snapshot.connectionState}');

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    _addDebugLog('Waiting for bills data');
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    _addDebugLog('Error in bills stream: ${snapshot.error}',
                        isError: true);
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Error loading bills'),
                          SizedBox(height: 10),
                          Text(
                            snapshot.error.toString(),
                            style: TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    _addDebugLog('No bills data available');
                    return Center(child: Text('Belum ada tagihan'));
                  }

                  _addDebugLog('Received ${snapshot.data!.docs.length} bills');
                  return ListView(
                    children: snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      _addDebugLog(
                          'Processing bill: ${doc.id} - ${data['title']}');

                      // Debug data validation
                      if (data['icon_code'] == null ||
                          data['icon_font_family'] == null) {
                        _addDebugLog('Missing icon data for bill ${doc.id}',
                            isError: true);
                      }

                      var icon = IconData(
                        data['icon_code'] ?? Icons.error.codePoint,
                        fontFamily: data['icon_font_family'] ?? 'MaterialIcons',
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
                        iconColor: Color(data['color'] ?? Colors.grey.value),
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
                  MaterialPageRoute(
                      builder: (context) => CategorySelectionPage()),
                );
              },
              icon: Icon(Icons.add, color: Colors.white),
              label: Text('Tambahkan Tagihan Lain',
                  style: TextStyle(color: Colors.white)),
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

  void _showDebugInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Debug Information'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'User UID: ${_auth.currentUser?.uid ?? 'Not authenticated'}'),
              SizedBox(height: 10),
              Text('Debug Logs:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 5),
              Container(
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(5),
                ),
                padding: EdgeInsets.all(8),
                child: ListView(
                  children: _debugLogs.reversed
                      .map((log) => Text(log,
                          style: TextStyle(
                            fontSize: 12,
                            color: log.contains('ERROR')
                                ? Colors.red
                                : Colors.black,
                          )))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _debugLogs.clear();
                _addDebugLog('Logs cleared');
              });
            },
            child: Text('Clear Logs'),
          ),
        ],
      ),
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
                  Text(title,
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text(description,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  SizedBox(height: 4),
                  Text('Jatuh tempo: $dueDate',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                  Text('Frekuensi: $frequency',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amount,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        _addDebugLog('Editing bill: $docId');
                        _showEditDialog(context, docId, rawAmount, description,
                            dueDate, frequency);
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        _addDebugLog('Attempting to delete bill: $docId');
                        try {
                          await _firestore
                              .collection('bills')
                              .doc(docId)
                              .delete();
                          _addDebugLog('Successfully deleted bill: $docId');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Tagihan berhasil dihapus')),
                          );
                        } catch (e) {
                          _addDebugLog('Error deleting bill: $e',
                              isError: true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Gagal menghapus tagihan')),
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
  }

  void _showEditDialog(
    BuildContext context,
    String docId,
    String currentAmount,
    String currentDesc,
    String currentDueDate,
    String currentFrequency,
  ) {
    final TextEditingController amountController =
        TextEditingController(text: currentAmount);
    final TextEditingController descController =
        TextEditingController(text: currentDesc);

    List<String> frequencies = ['Harian', 'Mingguan', 'Bulanan', 'Tahunan'];
    String dropdownValue = frequencies.contains(currentFrequency)
        ? currentFrequency
        : frequencies[0];

    DateTime? selectedDate;
    if (currentDueDate.isNotEmpty && currentDueDate != '-') {
      try {
        selectedDate = _dateFormat.parse(currentDueDate);
        _addDebugLog('Parsed due date: $selectedDate');
      } catch (e) {
        _addDebugLog('Error parsing due date: $e', isError: true);
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
                            _addDebugLog('Selected new due date: $picked');
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
              onPressed: () {
                _addDebugLog('Edit dialog cancelled');
                Navigator.pop(context);
              },
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedDate == null) {
                  _addDebugLog('No due date selected', isError: true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Tanggal jatuh tempo harus dipilih')),
                  );
                  return;
                }

                try {
                  _addDebugLog('Updating bill $docId with: '
                      'amount=${amountController.text}, '
                      'description=${descController.text}, '
                      'frequency=$dropdownValue, '
                      'due_date=$selectedDate');

                  await _firestore.collection('bills').doc(docId).update({
                    'amount': amountController.text,
                    'description': descController.text,
                    'frequency': dropdownValue,
                    'due_date': Timestamp.fromDate(selectedDate!),
                  });

                  _addDebugLog('Successfully updated bill $docId');
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Tagihan berhasil diperbarui')),
                  );
                } catch (e) {
                  _addDebugLog('Error updating bill: $e', isError: true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal memperbarui tagihan')),
                  );
                }
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
        _addDebugLog('Bottom nav bar tapped: $index');
        switch (index) {
          case 0:
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => HomeScreen()));
            break;
          case 1:
            // Halaman saat ini
            break;
          case 2:
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => ReportsPage()));
            break;
          case 3:
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => TargetPage()));
            break;
          case 4:
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => AccountPage()));
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
            icon: Icon(Icons.attach_money), label: 'Tagihan'),
        BottomNavigationBarItem(
            icon: Icon(Icons.insert_chart), label: 'Laporan'),
        BottomNavigationBarItem(icon: Icon(Icons.savings), label: 'Target'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
