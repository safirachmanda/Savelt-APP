import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
      )
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
                _buildInfoCard('Pemasukan', 'Rp ${pemasukan.toInt()}', Colors.blueAccent),
                _buildInfoCard('Pengeluaran', 'Rp ${pengeluaran.toInt()}', Colors.purpleAccent),
              ],
            )
          ],
        ),
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

  Widget _buildInfoCard(String title, String amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(colors: [color.withOpacity(0.5), color]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white)),
          Text(amount, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
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
}