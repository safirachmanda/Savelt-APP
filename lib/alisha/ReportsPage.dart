import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'PemasukanAddPage.dart';
import 'PengeluaranAddPage.dart';
import 'HomePage.dart';
import 'BillsPage.dart';
import 'TargetPage.dart';
import 'AccountPage.dart';

void main() {
  runApp(const SaveltApp());
}

class SaveltApp extends StatelessWidget {
  const SaveltApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ReportsPage(),
    );
  }
}

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  int selectedPeriod = 0;
  double pemasukan = 900000;
  double pengeluaran = 600000;
  double sisaUang = 1000000;
  int _selectedIndex = 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Report', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTotalCard(),
            const SizedBox(height: 20),
            _buildBarChart(),
            const SizedBox(height: 20),
            _buildPieChart(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildTotalCard() {
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
                        MaterialPageRoute(builder: (context) => PemasukanAddPage()),
                      );
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
                        MaterialPageRoute(builder: (context) => PengeluaranAddPage()),
                      );
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

  Widget _buildBarChart() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Pemasukan & Pengeluaran', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  titlesData: FlTitlesData(show: true),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    _buildBarGroup(0, 200, 50),
                    _buildBarGroup(1, 150, 30),
                    _buildBarGroup(2, 50, 20),
                    _buildBarGroup(3, 80, 50),
                    _buildBarGroup(4, 400, 200),
                    _buildBarGroup(5, 300, 150),
                    _buildBarGroup(6, 250, 180),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y1, double y2) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(toY: y1, color: Colors.blue, width: 15),
        BarChartRodData(toY: y2, color: Colors.purple, width: 15),
      ],
    );
  }

  Widget _buildPieChart() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Pemasukan', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(value: 40, title: 'Makanan 40%', color: Colors.lightBlueAccent),
                    PieChartSectionData(value: 20, title: 'Belanja 20%', color: Colors.blueAccent),
                    PieChartSectionData(value: 15, title: 'Pengobatan 15%', color: Colors.teal),
                    PieChartSectionData(value: 15, title: 'Hiburan 15%', color: Colors.indigo),
                    PieChartSectionData(value: 10, title: 'Tabungan 10%', color: Colors.deepPurple),
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
