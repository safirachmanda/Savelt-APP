import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'TargetPage.dart';
import 'BillsPage.dart';
import 'ReportsPage.dart';
import 'AccountPage.dart';
import 'package:Savelt/widget/profilebox.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/targettabungan': (context) => TargetPage(),
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  double totalIncome = 0.0;
  double totalExpense = 0.0;
  double totalSavings = 0.0;
  double reportIncome = 0.0;
  List<Map<String, dynamic>> reminders = [];
  List<Map<String, dynamic>> weeklyExpenses =
      List.generate(7, (index) => {'amount': 0.0});
  List<Map<String, dynamic>> budgets = [];
  List<Map<String, dynamic>> budgetComparisons = [];
  double totalBudget = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchFinancialData();
    _fetchReminders();
    _fetchWeeklyExpenses();
    _fetchBudgets();
    _fetchBudgetComparisons();
    _fetchReportIncome();
  }

  Future<void> _fetchFinancialData() async {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

    final startDate = DateFormat('yyyy-MM-dd').format(firstDayOfMonth);
    final endDate = DateFormat('yyyy-MM-dd').format(lastDayOfMonth);

    var incomeSnapshot = await _firestore
        .collection('reports')
        .doc(uid)
        .collection('pemasukkan')
        .where('tanggal', isGreaterThanOrEqualTo: startDate)
        .where('tanggal', isLessThanOrEqualTo: endDate)
        .get();

    double income = incomeSnapshot.docs.fold(0.0, (sum, doc) {
      return sum + (doc.data()['nominal'] as num).toDouble();
    });

    var expenseSnapshot = await _firestore
        .collection('reports')
        .doc(uid)
        .collection('pengeluaran')
        .where('tanggal', isGreaterThanOrEqualTo: startDate)
        .where('tanggal', isLessThanOrEqualTo: endDate)
        .get();

    double expense = expenseSnapshot.docs.fold(0.0, (sum, doc) {
      return sum + (doc.data()['nominal'] as num).toDouble();
    });

    setState(() {
      totalIncome = income;
      totalExpense = expense;
      totalSavings = income - expense;
    });
  }

  Future<void> _fetchReportIncome() async {
    try {
      DocumentSnapshot reportSnapshot =
          await _firestore.collection('reports').doc(uid).get();

      if (reportSnapshot.exists) {
        var data = reportSnapshot.data() as Map<String, dynamic>;
        if (data.containsKey('pemasukan')) {
          setState(() {
            reportIncome = (data['pemasukan'] as num).toDouble();
          });
        }
      }
    } catch (e) {
      print('Error fetching report income: $e');
    }
  }

  Future<void> _fetchReminders() async {
    // Debug: Initial log
    debugPrint('[Reminders] Starting to fetch reminders...');

    // Validation checks
    if (uid == null || uid.isEmpty) {
      debugPrint('[Reminders][ERROR] UID is null or empty');
      setState(() {
        reminders = [];
      });
      return;
    }

    if (_firestore == null) {
      debugPrint('[Reminders][ERROR] Firestore instance is not initialized');
      setState(() {
        reminders = [];
      });
      return;
    }

    try {
      // Date setup
      final now = DateTime.now();
      final nextWeek = now.add(const Duration(days: 7));

      debugPrint(
          '[Reminders] Date range: ${DateFormat('yyyy-MM-dd HH:mm').format(now)} to ${DateFormat('yyyy-MM-dd HH:mm').format(nextWeek)}');

      // Firestore query
      final QuerySnapshot billsSnapshot;
      try {
        billsSnapshot = await _firestore
            .collection('bills')
            .where('uid', isEqualTo: uid)
            .where('due_date', isGreaterThanOrEqualTo: now)
            .where('due_date', isLessThanOrEqualTo: nextWeek)
            .orderBy('due_date')
            .limit(3)
            .get();

        debugPrint(
            '[Reminders] Found ${billsSnapshot.docs.length} upcoming bills');
      } on FirebaseException catch (e) {
        debugPrint('[Reminders][FIREBASE ERROR] ${e.code}: ${e.message}');
        setState(() {
          reminders = [];
        });
        return;
      }

      // Process documents
      final List<Map<String, dynamic>> billReminders = [];

      for (final doc in billsSnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;

          // Validate required fields
          if (data['due_date'] == null) {
            debugPrint(
                '[Reminders][WARNING] Document ${doc.id} missing due_date');
            continue;
          }

          // Parse dates
          final Timestamp dueTimestamp = data['due_date'] as Timestamp;
          final dueDate = dueTimestamp.toDate();
          final daysLeft = dueDate.difference(now).inDays;

          // Format amount
          String amountString = '-Rp0';
          try {
            if (data['amount'] != null) {
              final amount = int.parse(data['amount'].toString());
              amountString = '-Rp${NumberFormat('#,###').format(amount)}';
            }
          } catch (e) {
            debugPrint(
                '[Reminders][WARNING] Invalid amount format in document ${doc.id}');
          }

          // Build reminder item
          billReminders.add({
            'title': data['title']?.toString() ?? 'Tagihan Tanpa Nama',
            'subtitle':
                'Jatuh Tempo: ${DateFormat('dd/MM/yyyy').format(dueDate)} (${daysLeft} hari lagi)',
            'amount': amountString,
            'color': daysLeft <= 3 ? Colors.red : Colors.orange,
            'document_id': doc.id, // Useful for future reference
          });
        } catch (e) {
          debugPrint('[Reminders][ERROR] Processing document ${doc.id}: $e');
        }
      }

      debugPrint(
          '[Reminders] Successfully processed ${billReminders.length} reminders');

      setState(() {
        reminders = billReminders;
      });
    } catch (e) {
      debugPrint('[Reminders][CRITICAL ERROR] $e');
      debugPrint(e.toString());
      setState(() {
        reminders = [];
      });
    }
  }

  Future<void> _fetchWeeklyExpenses() async {
    try {
      DateTime now = DateTime.now();
      DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));

      var expenseSnapshot = await _firestore
          .collection('reports')
          .doc(uid)
          .collection('pengeluaran')
          .where('tanggal',
              isGreaterThanOrEqualTo:
                  DateFormat('yyyy-MM-dd').format(startOfWeek))
          .where('tanggal',
              isLessThanOrEqualTo: DateFormat('yyyy-MM-dd').format(endOfWeek))
          .get();

      List<Map<String, dynamic>> expenses =
          List.generate(7, (index) => {'amount': 0.0});

      for (var doc in expenseSnapshot.docs) {
        var data = doc.data();
        DateTime expenseDate = DateFormat('yyyy-MM-dd').parse(data['tanggal']);
        int dayOfWeek = expenseDate.weekday - 1;

        double amount = (data['nominal'] as num).toDouble();
        expenses[dayOfWeek]['amount'] =
            (expenses[dayOfWeek]['amount'] as double) + amount;
      }

      setState(() {
        weeklyExpenses = expenses;
      });
    } catch (e) {
      print('Error fetching weekly expenses: $e');
      setState(() {
        weeklyExpenses = List.generate(7, (index) => {'amount': 0.0});
      });
    }
  }

  Future<void> _fetchBudgets() async {
    var budgetsSnapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('budgets')
        .get();

    List<Map<String, dynamic>> budgetList = [];
    double sumBudgets = 0.0;

    for (var doc in budgetsSnapshot.docs) {
      var data = doc.data();
      if ((data['rata_rata'] as num).toDouble() > 0.0) {
        sumBudgets += (data['rata_rata'] as num).toDouble();
        budgetList.add({
          'title': data['kategori'],
          'icon': _getCategoryIcon(data['kategori']),
          'budgetLimit': (data['rata_rata'] as num).toDouble(),
        });
      }
    }

    setState(() {
      budgets = budgetList;
      totalBudget = sumBudgets;
    });
  }

  Future<void> _fetchBudgetComparisons() async {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

    final startDate = DateFormat('yyyy-MM-dd').format(firstDayOfMonth);
    final endDate = DateFormat('yyyy-MM-dd').format(lastDayOfMonth);

    var expenseSnapshot = await _firestore
        .collection('reports')
        .doc(uid)
        .collection('pengeluaran')
        .where('tanggal', isGreaterThanOrEqualTo: startDate)
        .where('tanggal', isLessThanOrEqualTo: endDate)
        .get();

    var budgetsSnapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('budgets')
        .get();

    double totalMonthlyBudget = 0.0;
    for (var budgetDoc in budgetsSnapshot.docs) {
      var budgetData = budgetDoc.data();
      totalMonthlyBudget += (budgetData['rata_rata'] as num).toDouble();
    }

    Map<String, double> currentExpensesByCategory = {};
    for (var doc in expenseSnapshot.docs) {
      var data = doc.data();
      var category = data['kategori'] as String;
      var amount = (data['nominal'] as num).toDouble();
      currentExpensesByCategory[category] =
          (currentExpensesByCategory[category] ?? 0.0) + amount;
    }

    List<Map<String, dynamic>> comparisons = [];

    if (totalMonthlyBudget > 0.0) {
      double totalPercentage = (totalExpense / totalMonthlyBudget) * 100;
      comparisons.add({
        'category': 'Total Budget',
        'icon': Icons.assignment,
        'budget': totalMonthlyBudget,
        'spent': totalExpense,
        'percentage': totalPercentage,
        'status': _getBudgetStatus(totalExpense, totalMonthlyBudget),
        'statusColor': _getBudgetStatusColor(totalExpense, totalMonthlyBudget),
      });
    }

    for (var budgetDoc in budgetsSnapshot.docs) {
      var budgetData = budgetDoc.data();
      var category = budgetData['kategori'] as String;
      var monthlyBudget = (budgetData['rata_rata'] as num).toDouble();
      var currentSpending = currentExpensesByCategory[category] ?? 0.0;
      var percentage =
          monthlyBudget > 0.0 ? (currentSpending / monthlyBudget) * 100 : 0.0;

      comparisons.add({
        'category': category,
        'icon': _getCategoryIcon(category),
        'budget': monthlyBudget,
        'spent': currentSpending,
        'percentage': percentage,
        'status': _getBudgetStatus(currentSpending, monthlyBudget),
        'statusColor': _getBudgetStatusColor(currentSpending, monthlyBudget),
      });
    }

    setState(() {
      budgetComparisons = comparisons;
    });
  }

  String _getBudgetStatus(double spent, double budget) {
    if (budget == 0.0) return 'No Budget Set';
    if (spent > budget) return 'Melebihi Budget';
    if (spent > budget * 0.8) return 'Mendekati Limit';
    return 'Dalam Budget';
  }

  Color _getBudgetStatusColor(double spent, double budget) {
    if (budget == 0.0) return Colors.grey;
    if (spent > budget) return Colors.red;
    if (spent > budget * 0.8) return Colors.orange;
    return Colors.green;
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Makanan & Minuman':
        return Icons.restaurant;
      case 'Transportasi':
        return Icons.directions_car;
      case 'Belanja Pribadi':
        return Icons.shopping_bag;
      case 'Hiburan & Gaya Hidup':
        return Icons.movie;
      case 'Kesehatan':
        return Icons.medical_services;
      case 'Pendidikan':
        return Icons.school;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalValue = totalIncome + totalExpense + reportIncome;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Image.asset('assets/savelt.png', height: 40),
            const SizedBox(width: 5),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: "SAVE",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.lightBlue,
                      fontSize: 22,
                      fontFamily: 'Inter',
                    ),
                  ),
                  TextSpan(
                    text: "LT",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontSize: 22,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'Home':
                  Navigator.pushNamed(context, '/home');
                  break;
                case 'Tagihan':
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => BillsPage()));
                  break;
                case 'Laporan Keuangan':
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => ReportsPage()));
                  break;
                case 'Target Tabungan':
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => TargetPage()));
                  break;
                case 'Profile':
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => AccountPage()));
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Home', child: Text('Home')),
              const PopupMenuItem(value: 'Tagihan', child: Text('Tagihan')),
              const PopupMenuItem(
                  value: 'Laporan Keuangan', child: Text('Laporan Keuangan')),
              const PopupMenuItem(
                  value: 'Target Tabungan', child: Text('Target Tabungan')),
              const PopupMenuItem(value: 'Profile', child: Text('Profile')),
            ],
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ProfileBox(uid: uid),
            _buildReminderBox(),
            _buildSummaryBox(totalValue),
            _buildExpenseChart(),
            _buildBudgetComparisonBox(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildReminderBox() {
    return _buildRoundedBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Center(
            child: Text(
              'Pengingat Tagihan',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const SizedBox(height: 8),
          if (reminders.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Tidak ada tagihan yang jatuh tempo dalam 7 hari ke depan',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            )
          else
            Column(
              children: reminders
                  .map((reminder) => _buildReminderItem(
                        title: reminder['title'],
                        subtitle: reminder['subtitle'],
                        amount: reminder['amount'],
                        color: reminder['color'],
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildReminderItem({
    required String title,
    required String subtitle,
    required String amount,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    amount,
                    style: TextStyle(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryBox(double totalValue) {
    return _buildRoundedBox(
      child: Column(
        children: [
          const Center(
            child: Text(
              'Rangkuman',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const SizedBox(height: 20),
          FutureBuilder<DocumentSnapshot>(
            future: _firestore.collection('reports').doc(uid).get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(child: Text('Tidak ada data laporan'));
              }

              var reportData = snapshot.data!.data() as Map<String, dynamic>;
              double pengeluaran =
                  (reportData['pengeluaran'] as num?)?.toDouble() ?? 0.0;
              double sisaUang =
                  (reportData['sisaUang'] as num?)?.toDouble() ?? 0.0;
              double pemasukan =
                  (reportData['pemasukan'] as num?)?.toDouble() ?? 0.0;

              double total = pemasukan + pengeluaran + sisaUang;

              return Column(
                children: [
                  SizedBox(
                    height: 150,
                    child: Stack(
                      children: [
                        PieChart(
                          PieChartData(
                            sections: [
                              PieChartSectionData(
                                value: pemasukan,
                                color: Colors.green,
                                title:
                                    'Pemasukan\n${total > 0.0 ? (pemasukan / total * 100).toStringAsFixed(1) : 0}%',
                                titleStyle: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                                radius: 60,
                                titlePositionPercentageOffset: 0.55,
                              ),
                              PieChartSectionData(
                                value: pengeluaran,
                                color: Colors.red,
                                title:
                                    'Pengeluaran\n${total > 0.0 ? (pengeluaran / total * 100).toStringAsFixed(1) : 0}%',
                                titleStyle: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                                radius: 60,
                                titlePositionPercentageOffset: 0.55,
                              ),
                            ],
                            centerSpaceRadius: 27,
                            sectionsSpace: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: [
                      _buildSummaryText(
                          'Pemasukan',
                          '+Rp${NumberFormat('#,###').format(pemasukan.toInt())}',
                          Colors.green),
                      _buildSummaryText(
                          'Pengeluaran',
                          '-Rp${NumberFormat('#,###').format(pengeluaran.toInt())}',
                          Colors.red),
                      _buildSummaryText(
                          'Sisa Uang',
                          'Rp${NumberFormat('#,###').format(sisaUang.toInt())}',
                          Colors.blue),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryText(String title, String amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(amount, style: TextStyle(color: color, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildExpenseChart() {
    return _buildRoundedBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'Pengeluaran - 7 Hari',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = [
                          'Sen',
                          'Sel',
                          'Rab',
                          'Kam',
                          'Jum',
                          'Sab',
                          'Min'
                        ];
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(days[value.toInt()],
                              style: const TextStyle(fontSize: 12)),
                        );
                      },
                      reservedSize: 22,
                    ),
                  ),
                ),
                barGroups: List.generate(7, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY:
                            (weeklyExpenses[index]['amount'] as num).toDouble(),
                        color: Colors.red,
                        width: 50,
                        borderRadius: BorderRadius.circular(8),
                      )
                    ],
                  );
                }),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBudgetComparisonBox() {
    return _buildRoundedBox(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'Perbandingan Budget',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Periode: ${DateFormat('MMMM yyyy').format(DateTime.now())}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            if (budgetComparisons.isEmpty)
              const Center(
                  child: Text('Tidak ada data budget',
                      style: TextStyle(color: Colors.grey)))
            else
              Column(
                children: [
                  if (totalBudget > 0.0)
                    Column(
                      children: [
                        _buildBudgetComparisonItem(
                          category: 'Total Budget',
                          icon: Icons.assignment,
                          budget: totalBudget,
                          spent: totalExpense,
                          percentage: (totalExpense / totalBudget) * 100,
                          status: _getBudgetStatus(totalExpense, totalBudget),
                          statusColor:
                              _getBudgetStatusColor(totalExpense, totalBudget),
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        const Text(
                          'Per Kategori:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ...budgetComparisons
                      .where((item) => item['category'] != 'Total Budget')
                      .map((comparison) => Column(
                            children: [
                              _buildBudgetComparisonItem(
                                category: comparison['category'],
                                icon: comparison['icon'],
                                budget: comparison['budget'],
                                spent: comparison['spent'],
                                percentage: comparison['percentage'],
                                status: comparison['status'],
                                statusColor: comparison['statusColor'],
                              ),
                              if (comparison != budgetComparisons.last)
                                const SizedBox(height: 16),
                            ],
                          ))
                      .toList(),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetComparisonItem({
    required String category,
    required IconData icon,
    required double budget,
    required double spent,
    required double percentage,
    required String status,
    required Color statusColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue.shade900,
              radius: 20,
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    status,
                    style: TextStyle(color: statusColor, fontSize: 14),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Rp${NumberFormat('#,###').format(spent.toInt())} / Rp${NumberFormat('#,###').format(budget.toInt())}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pengeluaran',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  Text(
                    'Rp${NumberFormat('#,###').format(spent.toInt())}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Budget',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  Text(
                    'Rp${NumberFormat('#,###').format(budget.toInt())}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: Colors.grey[200],
          ),
          child: Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  double widthFactor =
                      percentage > 100.0 ? 1.0 : percentage / 100.0;
                  return FractionallySizedBox(
                    widthFactor: widthFactor,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: statusColor,
                      ),
                    ),
                  );
                },
              ),
              if (percentage > 100.0)
                Positioned(
                  right: 0,
                  child: Container(
                    width: 2,
                    height: 8,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '0%',
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
            Text(
              '100%',
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.blue,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
            break;
          case 1:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => BillsPage()),
            );
            break;
          case 2:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ReportsPage()),
            );
            break;
          case 3:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => TargetPage()),
            );
            break;
          case 4:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => AccountPage()),
            );
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

  Widget _buildRoundedBox({required Widget child}) {
    return Container(
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}
