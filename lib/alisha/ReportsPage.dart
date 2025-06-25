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
import 'CategoryDetailPage.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  int _selectedIndex = 2;
  late User _currentUser;
  DateTime _selectedMonth = DateTime.now();

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
    _userReportDocRef =
        FirebaseFirestore.instance.collection('reports').doc(_currentUser.uid);

    // Initialize user document with UID if it doesn't exist
    _initializeUserDocument();
  }

  Future<void> _initializeUserDocument() async {
    await _userReportDocRef.set({
      'uid': _currentUser.uid,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, double>> _calculateMonthlyTotals() async {
    // Get first and last day of selected month
    DateTime firstDay = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    DateTime lastDay =
        DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);

    // Calculate total income for the month
    final pemasukanSnapshot = await _pemasukanCollection
        .where('timestamp', isGreaterThanOrEqualTo: firstDay)
        .where('timestamp', isLessThanOrEqualTo: lastDay)
        .get();

    double totalPemasukan = 0;
    for (var doc in pemasukanSnapshot.docs) {
      totalPemasukan +=
          (doc.data() as Map<String, dynamic>)['nominal']?.toDouble() ?? 0;
    }

    // Calculate total expenses for the month
    final pengeluaranSnapshot = await _pengeluaranCollection
        .where('timestamp', isGreaterThanOrEqualTo: firstDay)
        .where('timestamp', isLessThanOrEqualTo: lastDay)
        .get();

    double totalPengeluaran = 0;
    for (var doc in pengeluaranSnapshot.docs) {
      totalPengeluaran +=
          (doc.data() as Map<String, dynamic>)['nominal']?.toDouble() ?? 0;
    }

    // Calculate remaining money
    double sisaUang = totalPemasukan - totalPengeluaran;

    // Update the user's report document
    await _userReportDocRef.set({
      'uid': _currentUser.uid, // Ensure UID is always included
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

  Future<Map<String, Map<String, double>>> _getCategoryData() async {
    // Get first and last day of selected month
    DateTime firstDay = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    DateTime lastDay =
        DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);

    // Get income data by category
    final pemasukanSnapshot = await _pemasukanCollection
        .where('timestamp', isGreaterThanOrEqualTo: firstDay)
        .where('timestamp', isLessThanOrEqualTo: lastDay)
        .get();

    // Get expense data by category
    final pengeluaranSnapshot = await _pengeluaranCollection
        .where('timestamp', isGreaterThanOrEqualTo: firstDay)
        .where('timestamp', isLessThanOrEqualTo: lastDay)
        .get();

    // Initialize category data
    Map<String, Map<String, double>> categoryData = {
      'pemasukan': {},
      'pengeluaran': {},
    };

    // Process income data by category
    for (var doc in pemasukanSnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      String category = data['kategori'] ?? 'Lainnya';
      double nominal = (data['nominal'] as num).toDouble();
      categoryData['pemasukan']![category] =
          (categoryData['pemasukan']![category] ?? 0) + nominal;
    }

    // Process expense data by category
    for (var doc in pengeluaranSnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      String category = data['kategori'] ?? 'Lainnya';
      double nominal = (data['nominal'] as num).toDouble();
      categoryData['pengeluaran']![category] =
          (categoryData['pengeluaran']![category] ?? 0) + nominal;
    }

    return categoryData;
  }

  Future<List<QueryDocumentSnapshot>> _getCategoryHistory(
      String type, String category) async {
    // Get first and last day of selected month
    DateTime firstDay = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    DateTime lastDay =
        DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);

    CollectionReference collection =
        type == 'pemasukan' ? _pemasukanCollection : _pengeluaranCollection;

    final snapshot = await collection
        .where('timestamp', isGreaterThanOrEqualTo: firstDay)
        .where('timestamp', isLessThanOrEqualTo: lastDay)
        .where('kategori', isEqualTo: category)
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs;
  }

  Future<void> _selectMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null && picked != _selectedMonth) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month, 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Laporan Keuangan',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectMonth(context),
            tooltip: 'Pilih Bulan',
          ),
        ],
      ),
      body: FutureBuilder<Map<String, double>>(
        future: _calculateMonthlyTotals(),
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
                _buildMonthSelector(),
                const SizedBox(height: 10),
                _buildTotalCard(pemasukan, pengeluaran, sisaUang),
                const SizedBox(height: 20),
                FutureBuilder<Map<String, Map<String, double>>>(
                  future: _getMonthlyData(),
                  builder: (context, monthlySnapshot) {
                    if (monthlySnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (monthlySnapshot.hasError) {
                      return Center(
                          child: Text('Error: ${monthlySnapshot.error}'));
                    }

                    return _buildBarChart(monthlySnapshot.data ?? {});
                  },
                ),
                const SizedBox(height: 20),
                _buildPieChart(pemasukan, pengeluaran),
                const SizedBox(height: 20),
                FutureBuilder<Map<String, Map<String, double>>>(
                  future: _getCategoryData(),
                  builder: (context, categorySnapshot) {
                    if (categorySnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (categorySnapshot.hasError) {
                      return Center(
                          child: Text('Error: ${categorySnapshot.error}'));
                    }

                    return _buildCategoryLists(categorySnapshot.data ?? {});
                  },
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildMonthSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            setState(() {
              _selectedMonth =
                  DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
            });
          },
        ),
        Text(
          DateFormat('MMMM yyyy').format(_selectedMonth),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: _selectedMonth.isBefore(
                  DateTime(DateTime.now().year, DateTime.now().month, 1))
              ? () {
                  setState(() {
                    _selectedMonth = DateTime(
                        _selectedMonth.year, _selectedMonth.month + 1, 1);
                  });
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildTotalCard(
      double pemasukan, double pengeluaran, double sisaUang) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sisa Uang',
                style: TextStyle(fontWeight: FontWeight.bold)),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Rp ${NumberFormat('#,###').format(sisaUang)}',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                // For smaller screens, stack the cards vertically
                if (constraints.maxWidth < 400) {
                  return Column(
                    children: [
                      _buildInfoCard(
                        title: 'Pemasukan',
                        amount: 'Rp ${NumberFormat('#,###').format(pemasukan)}',
                        color: Colors.blueAccent,
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PemasukanAddPage(
                                userReportDocRef: _userReportDocRef,
                              ),
                            ),
                          );
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 10),
                      _buildInfoCard(
                        title: 'Pengeluaran',
                        amount:
                            'Rp ${NumberFormat('#,###').format(pengeluaran)}',
                        color: Colors.purpleAccent,
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PengeluaranAddPage(
                                userReportDocRef: _userReportDocRef,
                              ),
                            ),
                          );
                          setState(() {});
                        },
                      ),
                    ],
                  );
                }
                // For larger screens, keep the horizontal layout
                else {
                  return Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          title: 'Pemasukan',
                          amount:
                              'Rp ${NumberFormat('#,###').format(pemasukan)}',
                          color: Colors.blueAccent,
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PemasukanAddPage(
                                  userReportDocRef: _userReportDocRef,
                                ),
                              ),
                            );
                            setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildInfoCard(
                          title: 'Pengeluaran',
                          amount:
                              'Rp ${NumberFormat('#,###').format(pengeluaran)}',
                          color: Colors.purpleAccent,
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PengeluaranAddPage(
                                  userReportDocRef: _userReportDocRef,
                                ),
                              ),
                            );
                            setState(() {});
                          },
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
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
        gradient: LinearGradient(
          colors: [color.withOpacity(0.5), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  amount,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
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
    var sortedKeys = monthlyData.keys.toList()..sort((a, b) => a.compareTo(b));

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
                          value = monthlyData[sortedKeys[group.x.toInt()]]![
                                  'pemasukan'] ??
                              0;
                        } else {
                          title = 'Pengeluaran';
                          color = Colors.purple;
                          value = monthlyData[sortedKeys[group.x.toInt()]]![
                                  'pengeluaran'] ??
                              0;
                        }

                        return BarTooltipItem(
                          '$title\nRp ${NumberFormat('#,###').format(value)}',
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
                                months[value.toInt()].split(
                                    ' ')[0], // Show only month abbreviation
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
                            'Rp ${NumberFormat('#,###').format(value)}',
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

  Widget _buildCategoryLists(Map<String, Map<String, double>> categoryData) {
    // Prepare income data
    final incomeCategories = categoryData['pemasukan']?.entries.toList() ?? [];
    final expenseCategories =
        categoryData['pengeluaran']?.entries.toList() ?? [];

    return Column(
      children: [
        // Income Categories List
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text('Kategori Pemasukan',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                if (incomeCategories.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Text('Tidak ada data pemasukan'),
                  )
                else
                  Column(
                    children: incomeCategories.map((entry) {
                      return _buildCategoryItem(
                        category: entry.key,
                        amount: entry.value,
                        type: 'pemasukan',
                        color: Colors.blue,
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Expense Categories List
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text('Kategori Pengeluaran',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                if (expenseCategories.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Text('Tidak ada data pengeluaran'),
                  )
                else
                  Column(
                    children: expenseCategories.map((entry) {
                      return _buildCategoryItem(
                        category: entry.key,
                        amount: entry.value,
                        type: 'pengeluaran',
                        color: Colors.purple,
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryItem({
    required String category,
    required double amount,
    required String type,
    required Color color,
  }) {
    IconData icon;
    switch (category.toLowerCase()) {
      case 'makanan':
        icon = Icons.fastfood;
        break;
      case 'transportasi':
        icon = Icons.directions_car;
        break;
      case 'belanja':
        icon = Icons.shopping_cart;
        break;
      case 'hiburan':
        icon = Icons.movie;
        break;
      case 'pendidikan':
        icon = Icons.school;
        break;
      case 'kesehatan':
        icon = Icons.local_hospital;
        break;
      case 'gaji':
        icon = Icons.attach_money;
        break;
      case 'investasi':
        icon = Icons.trending_up;
        break;
      default:
        icon = Icons.category;
    }

    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryDetailPage(
              type: type,
              category: category,
              month: _selectedMonth,
            ),
          ),
        );
      },
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.2),
        radius: 20,
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        category,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        '${type == 'pemasukan' ? 'Pemasukan' : 'Pengeluaran'}',
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'Rp${NumberFormat('#,###').format(amount)}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
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
            Text(
                'Pemasukan vs Pengeluaran ${DateFormat('MMMM yyyy').format(_selectedMonth)}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
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
                  sectionsSpace: 0,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(Colors.blueAccent, 'Pemasukan'),
                const SizedBox(width: 20),
                _buildLegendItem(Colors.purpleAccent, 'Pengeluaran'),
              ],
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
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const HomeScreen()));
            break;
          case 1:
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => BillsPage()));
            break;
          case 2:
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
