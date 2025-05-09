import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'TargetPage.dart';

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
        '/TargetPage': (context) => TargetPage(),
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Image.asset('assets/savelt.png', height:40),
            const SizedBox(width: 5),
            Expanded(
              child: Text.rich(
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
                overflow: TextOverflow.ellipsis,
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
                  Navigator.pushNamed(context, '/tagihan');
                  break;
                case 'Laporan Keuangan':
                  Navigator.pushNamed(context, '/laporankeuangan');
                  break;
                case 'Target Tabungan':
                  Navigator.pushNamed(context, '/targettabungan');
                  break;
                case 'Profile':
                  Navigator.pushNamed(context, '/profile');
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Home', child: Text('Home')),
              const PopupMenuItem(value: 'Tagihan', child: Text('Tagihan')),
              const PopupMenuItem(value: 'Laporan Keuangan', child: Text('Laporan Keuangan')),
              const PopupMenuItem(value: 'Target Tabungan', child: Text('Target Tabungan')),
              const PopupMenuItem(value: 'Profile', child: Text('Profile')),
            ],
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileBox(),
            _buildReminderBox(),
            _buildSummaryBox(),
            _buildExpenseChart(),
            _buildBudgetsBox(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileBox() {
    return _buildRoundedBox(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage('https://upload.wikimedia.org/wikipedia/commons/thumb/a/a0/Pierre-Person.jpg/800px-Pierre-Person.jpg'),
        ),
        title: Text('Selamat Datang!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text('Safira Putri Jihan'),
      ),
    );
  }

  Widget _buildReminderBox() {
    return _buildRoundedBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Center(child: Text('Pengingat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
          const SizedBox(height: 8),
          _buildReminderItem(title: 'Bayar Kos!', subtitle: 'Due: 07/03/2025', amount: '-Rp700.000,00', color: Colors.red),
          _buildReminderItem(title: 'Tabungan Liburan', subtitle: 'Jangan Lupa menabung minggu ini!', amount: 'Rp100.000,00', color: Colors.blue),
        ],
      ),
    );
  }

  Widget _buildReminderItem({required String title, required String subtitle, required String amount, required Color color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(amount, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          Text(subtitle, style: const TextStyle(fontSize: 14, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildSummaryBox() {
    double pemasukan = 3;
    double pengeluaran = 2.5;
    double tabungan = 0.5;
    double totalValue = pemasukan + pengeluaran + tabungan;

    return _buildRoundedBox(
      child: Column(
        children: [
          const Center(child: Text('Rangkuman', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(value: pemasukan, color: Colors.green, title: '${(pemasukan / totalValue * 100).toStringAsFixed(1)}%', titleStyle: const TextStyle(fontSize: 10, color: Colors.black)),
                      PieChartSectionData(value: pengeluaran, color: Colors.red, title: '${(pengeluaran / totalValue * 100).toStringAsFixed(1)}%', titleStyle: const TextStyle(fontSize: 10, color: Colors.black)),
                      PieChartSectionData(value: tabungan, color: Colors.blue, title: '${(tabungan / totalValue * 100).toStringAsFixed(1)}%', titleStyle: const TextStyle(fontSize: 10, color: Colors.black)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    _buildSummaryText('Pemasukan', '+Rp3.000.000,00', Colors.green),
                    _buildSummaryText('Pengeluaran', '-Rp2.500.000,00', Colors.red),
                    _buildSummaryText('Tabungan', 'Rp500.000,00', Colors.blue),
                  ],
                ),
              ),
            ],
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
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
          const Center(child: Text('Pengeluaran - 7 Hari', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(days[value.toInt()], style: const TextStyle(fontSize: 12)),
                        );
                      },
                      reservedSize: 22,
                    ),
                  ),
                ),
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 50000, color: Colors.red, width: 50, borderRadius: BorderRadius.circular(8))]),
                  BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 75000, color: Colors.red, width: 50, borderRadius: BorderRadius.circular(8))]),
                  BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 30000, color: Colors.red, width: 50, borderRadius: BorderRadius.circular(8))]),
                  BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 20000, color: Colors.red, width: 50, borderRadius: BorderRadius.circular(8))]),
                  BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 55000, color: Colors.red, width: 50, borderRadius: BorderRadius.circular(8))]),
                  BarChartGroupData(x: 5, barRods: [BarChartRodData(toY: 100000, color: Colors.red, width: 50, borderRadius: BorderRadius.circular(8))]),
                  BarChartGroupData(x: 6, barRods: [BarChartRodData(toY: 40000, color: Colors.red, width: 50, borderRadius: BorderRadius.circular(8))]),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBudgetsBox() {
    return _buildRoundedBox(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: Text('Budgets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
            const SizedBox(height: 16),
            _buildBudgetItem(
              title: 'Makanan/Minuman',
              icon: Icons.restaurant,
              progress: 1.4,
              amountUsed: 700000,
              budgetLimit: 500000,
              progressColor: Colors.red,
            ),
            const SizedBox(height: 16),
            _buildBudgetItem(
              title: 'Semua Kategori (Maret)',
              icon: Icons.assignment,
              progress: 0.833,
              amountUsed: 2500000,
              budgetLimit: 3000000,
              progressColor: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetItem({
    required String title,
    required IconData icon,
    required double progress,
    required double amountUsed,
    required double budgetLimit,
    required Color progressColor,
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
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("01/03/2025", style: TextStyle(fontSize: 12)),
            Text("${(progress * 100).toStringAsFixed(1)}%", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: progressColor)),
            const Text("31/03/2025", style: TextStyle(fontSize: 12)),
          ],
        ),
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: LinearProgressIndicator(
                value: (progress > 1) ? 1 : progress,
                minHeight: 14,
                backgroundColor: progressColor.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation(progressColor),
              ),
            ),
            Positioned(
              left: 250.0,
              child: Container(
                width: 2,
                height: 18,
                color: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Rp0.00", style: TextStyle(fontSize: 12)),
            Text("Rp${amountUsed.toStringAsFixed(2)}", style: TextStyle(fontSize: 12, color: progressColor)),
            Text("Rp${budgetLimit.toStringAsFixed(2)}", style: const TextStyle(fontSize: 12)),
          ],
        ),
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