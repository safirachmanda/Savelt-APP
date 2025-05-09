import 'package:flutter/material.dart';
import 'HomePage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'TargetBaruPage.dart';
import 'HomePage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TargetPage(),
    );
  }
}

class TargetPage extends StatefulWidget {
  @override
  _TargetPageState createState() => _TargetPageState();
}

class _TargetPageState extends State<TargetPage> {
  List<Map<String, dynamic>> tabunganList = [
    {
      'name': 'Liburan',
      'total': 700000,
      'target': 2000000,
      'missed': 300000,
      'startDate': '01/02/2025',
      'endDate': '21/06/2025',
      'frequency': 'Weekly',
      'expanded': false,
      'notification': true,
    }
  ];

  void _toggleExpand(int index) {
    setState(() {
      tabunganList[index]['expanded'] = !tabunganList[index]['expanded'];
    });
  }

  void _toggleNotification(int index) {
    setState(() {
      tabunganList[index]['notification'] = !tabunganList[index]['notification'];
    });
  }

  void _showDeleteConfirmation(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Konfirmasi'),
          content: const Text('Apakah Anda yakin ingin menghapus tabungan ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  tabunganList.removeAt(index);
                });
                Navigator.pop(context);
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  void _showAddSavingCalendar() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CalendarDatePicker(
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              onDateChanged: (date) {},
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tutup'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showSuccessDialog();
                  },
                  child: const Text('Berhasil Menabung'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: const Text('Selamat, Anda berhasil menabung!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Target Tabungan')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ...List.generate(tabunganList.length, (index) {
              var tabungan = tabunganList[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
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
                    title: Text(
                      tabungan['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    subtitle: Text(
                      'Total tabungan ${NumberFormat.currency(locale: "id", symbol: "Rp").format(tabungan['total'])}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    initiallyExpanded: tabungan['expanded'],
                    onExpansionChanged: (value) => _toggleExpand(index),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total Target: Rp${tabungan['target']}'),
                            Text('Total Missed: Rp${tabungan['missed']}'),
                            Text('Started: ${tabungan['startDate']}'),
                            Text('Due: ${tabungan['endDate']}'),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Notifikasi:'),
                                Row(
                                  children: [
                                    Text(tabungan['notification'] ? 'ON' : 'OFF',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: tabungan['notification'] ? Colors.green : Colors.red)),
                                    Switch(
                                      value: tabungan['notification'],
                                      onChanged: (val) => _toggleNotification(index),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ElevatedButton(
                                  onPressed: () => _showDeleteConfirmation(index),
                                  child: const Text('Delete Tabungan'),
                                ),
                                ElevatedButton(
                                  onPressed: _showAddSavingCalendar,
                                  child: const Text('Tambahkan Tabungan'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              );
            }),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TargetBaruPage()),
                );
              },
              child: const Text('+ Tambahkan Target Tabungan Baru'),
            )
          ],
        ),
      ),
    );
  }
}
