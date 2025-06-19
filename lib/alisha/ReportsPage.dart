import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'PemasukanAddPage.dart';
import 'PengeluaranAddPage.dart';
import 'HomePage.dart';
import 'BillsPage.dart';
import 'TargetPage.dart';
import 'AccountPage.dart';
import 'package:intl/intl.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  int selectedPeriod = 0;
  int _selectedIndex = 2;
  late User _currentUser;
  
  // Firestore references
  late CollectionReference _pemasukanCollection;
  late CollectionReference _pengeluaranCollection;
  late DocumentReference _userReportDocRef;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser!;
    _pemasukanCollection = FirebaseFirestore.instance
        .collection('reports')
        .doc(_currentUser.uid)
        .collection('pemasukan');
    _pengeluaranCollection = FirebaseFirestore.instance
        .collection('reports')
        .doc(_currentUser.uid)
        .collection('pengeluaran');
    _userReportDocRef = FirebaseFirestore.instance
        .collection('reports')
        .doc(_currentUser.uid);
  }

  Future<Map<String, double>> _calculateTotals() async {
    // Calculate total income
    final pemasukanSnapshot = await _pemasukanCollection.get();
    double totalPemasukan = 0;
    for (var doc in pemasukanSnapshot.docs) {
      totalPemasukan += (doc.data() as Map<String, dynamic>)['nominal']?.toDouble() ?? 0;
    }

    // Calculate total expenses
    final pengeluaranSnapshot = await _pengeluaranCollection.get();
    double totalPengeluaran = 0;
    for (var doc in pengeluaranSnapshot.docs) {
      totalPengeluaran += (doc.data() as Map<String, dynamic>)['nominal']?.toDouble() ?? 0;
    }

    // Calculate remaining money
    double sisaUang = totalPemasukan - totalPengeluaran;

    // Update the user's report document
    await _userReportDocRef.set({
      'pemasukan': totalPemasukan,
      'pengeluaran': totalPengeluaran,
      'sisaUang': sisaUang,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return {
      'pemasukan': totalPemasukan,
      'pengeluaran': totalPengeluaran,
      'sisaUang': sisaUang,
    };
  }

  Future<Map<String, Map<String, double>>> _getMonthlyData() async {
    // Get data for the last 12 months
    DateTime now = DateTime.now();
    DateTime oneYearAgo = DateTime(now.year - 1, now.month, now.day);

    // Get income data
    final pemasukanSnapshot = await _pemasukanCollection
        .where('timestamp', isGreaterThan: oneYearAgo)
        .get();

    // Get expense data
    final pengeluaranSnapshot = await _pengeluaranCollection
        .where('timestamp', isGreaterThan: oneYearAgo)
        .get();

    // Initialize monthly data
    Map<String, Map<String, double>> monthlyData = {};
    for (int i = 0; i < 12; i++) {
      DateTime month = DateTime(now.year, now.month - i, 1);
      String monthKey = DateFormat('yyyy-MM').format(month);
      monthlyData[monthKey] = {
        'pemasukan': 0,
        'pengeluaran': 0,
      };
    }

    // Process income data
    for (var doc in pemasukanSnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      DateTime? timestamp = (data['timestamp'] as Timestamp?)?.toDate();
      if (timestamp != null) {
        String monthKey = DateFormat('yyyy-MM').format(timestamp);
        double nominal = (data['nominal'] as num).toDouble();
        if (monthlyData.containsKey(monthKey)) {
          monthlyData[monthKey]!['pemasukan'] =
              (monthlyData[monthKey]!['pemasukan'] ?? 0) + nominal;
        }
      }
    }

    // Process expense data
    for (var doc in pengeluaranSnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      DateTime? timestamp = (data['timestamp'] as Timestamp?)?.toDate();
      if (timestamp != null) {
        String monthKey = DateFormat('yyyy-MM').format(timestamp);
        double nominal = (data['nominal'] as num).toDouble();
        if (monthlyData.containsKey(monthKey)) {
          monthlyData[monthKey]!['pengeluaran'] =
              (monthlyData[monthKey]!['pengeluaran'] ?? 0) + nominal;
        }
      }
    }

    return monthlyData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Report', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert))],
      ),
      body: FutureBuilder<Map<String, double>>(
        future: _calculateTotals(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          double pemasukan = snapshot.data?['pemasukan'] ?? 0;
          double pengeluaran = snapshot.data?['pengeluaran'] ?? 0;
          double sisaUang = snapshot.data?['sisaUang'] ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildTotalCard(pemasukan, pengeluaran, sisaUang),
                const SizedBox(height: 20),
                FutureBuilder<Map<String, Map<String, double>>>(
                  future: _getMonthlyData(),
                  builder: (context, monthlySnapshot) {
                    if (monthlySnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    if (monthlySnapshot.hasError) {
                      return Center(child: Text('Error: ${monthlySnapshot.error}'));
                    }
                    
                    return _buildBarChart(monthlySnapshot.data ?? {});
                  },
                ),
                const SizedBox(height: 20),
                _buildPieChart(pemasukan, pengeluaran),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildTotalCard(double pemasukan, double pengeluaran, double sisaUang) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sisa Uang', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Rp ${sisaUang.toInt()}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildInfoCard(
                    title: 'Pemasukan',
                    amount: 'Rp ${pemasukan.toInt()}',
                    color: Colors.blueAccent,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PemasukanAddPage(
                            userReportDocRef: _userReportDocRef,
                          ),
                        ),
                      ).then((_) => setState(() {}));
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildInfoCard(
                    title: 'Pengeluaran',
                    amount: 'Rp ${pengeluaran.toInt()}',
                    color: Colors.purpleAccent,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PengeluaranAddPage(
                            userReportDocRef: _userReportDocRef,
                          ),
                        ),
                      ).then((_) => setState(() {}));
                    },
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String amount,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(colors: [color.withOpacity(0.5), color]),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white)),
              Text(amount, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.white),
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(Map<String, Map<String, double>> monthlyData) {
    // Prepare data for the chart
    List<BarChartGroupData> barGroups = [];
    List<String> months = [];
    
    // Sort months in chronological order
    var sortedKeys = monthlyData.keys.toList()
      ..sort((a, b) => a.compareTo(b));
    
    // Create bar groups for each month
    for (int i = 0; i < sortedKeys.length; i++) {
      String monthKey = sortedKeys[i];
      var data = monthlyData[monthKey]!;
      
      // Format month for display (e.g., "Jun 2025")
      DateTime monthDate = DateFormat('yyyy-MM').parse(monthKey);
      String monthDisplay = DateFormat('MMM yyyy').format(monthDate);
      months.add(monthDisplay);
      
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: data['pemasukan'] ?? 0,
              color: Colors.blue,
              width: 10,
            ),
            BarChartRodData(
              toY: data['pengeluaran'] ?? 0,
              color: Colors.purple,
              width: 10,
            ),
          ],
        ),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Pemasukan & Pengeluaran (12 Bulan Terakhir)', 
              style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxYValue(monthlyData) * 1.2, // Add 20% padding
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: Colors.grey,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        String title;
                        Color color;
                        double value;
                        
                        if (rodIndex == 0) {
                          title = 'Pemasukan';
                          color = Colors.blue;
                          value = monthlyData[sortedKeys[group.x.toInt()]]!['pemasukan'] ?? 0;
                        } else {
                          title = 'Pengeluaran';
                          color = Colors.purple;
                          value = monthlyData[sortedKeys[group.x.toInt()]]!['pengeluaran'] ?? 0;
                        }
                        
                        return BarTooltipItem(
                          '$title\nRp ${value.toInt()}',
                          TextStyle(color: color, fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < months.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                months[value.toInt()].split(' ')[0], // Show only month abbreviation
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            'Rp ${value.toInt()}',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                        reservedSize: 40,
                      ),
                    ),
                  ),
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                  barGroups: barGroups,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(Colors.blue, 'Pemasukan'),
                const SizedBox(width: 20),
                _buildLegendItem(Colors.purple, 'Pengeluaran'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  double _getMaxYValue(Map<String, Map<String, double>> monthlyData) {
    double max = 0;
    monthlyData.forEach((key, value) {
      double total = (value['pemasukan'] ?? 0) + (value['pengeluaran'] ?? 0);
      if (total > max) max = total;
    });
    return max == 0 ? 1000000 : max; // Default to 1,000,000 if no data
  }

  Widget _buildPieChart(double pemasukan, double pengeluaran) {
    // Calculate percentages for the pie chart
    double total = pemasukan + pengeluaran;
    double pemasukanPercent = total > 0 ? (pemasukan / total) * 100 : 0;
    double pengeluaranPercent = total > 0 ? (pengeluaran / total) * 100 : 0;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Pemasukan vs Pengeluaran', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: pemasukanPercent,
                      title: '${pemasukanPercent.toStringAsFixed(1)}%',
                      color: Colors.blueAccent,
                      radius: 80,
                    ),
                    PieChartSectionData(
                      value: pengeluaranPercent,
                      title: '${pengeluaranPercent.toStringAsFixed(1)}%',
                      color: Colors.purpleAccent,
                      radius: 80,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.blue,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      onTap: (index) {
        if (index == _selectedIndex) return;
        setState(() => _selectedIndex = index);
        switch (index) {
          case 0:
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
            break;
          case 1:
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => BillsPage()));
            break;
          case 2:
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