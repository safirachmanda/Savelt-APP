import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'PengeluaranAddPage.dart';

void main() {
  runApp(const ReportsAddPage());
}

class ReportsAddPage extends StatelessWidget {
  const ReportsAddPage({super.key});


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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert))],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Toggle untuk memilih periode
            ToggleButtons(
              isSelected: [selectedPeriod == 0, selectedPeriod == 1, selectedPeriod == 2],
              onPressed: (index) {
                setState(() {
                  selectedPeriod = index;
                });
              },
              borderRadius: BorderRadius.circular(8),
              selectedColor: Colors.white,
              fillColor: Colors.blueAccent,
              children: const [
                Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('This Week')),
                Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('This Month')),
                Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('This Year')),
              ],
            ),
            const SizedBox(height: 20),

            // Kartu Sisa Uang, Pemasukan, Pengeluaran
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Sisa Uang', style: TextStyle(fontWeight: FontWeight.bold)),
                    const Text('Rp 1.000.000', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInfoCard('Pemasukan', 'Rp 900.000', Colors.blueAccent),
                        _buildInfoCard('Pengeluaran', 'Rp 600.000', Colors.purpleAccent),
                      ],
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Grafik Pemasukan & Pengeluaran
            const Text('Pemasukan & Pengeluaran', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  titlesData: FlTitlesData(show: false), // Menyembunyikan label sumbu
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
      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2, // Menandakan halaman "Report" aktif
        onTap: (index) {},
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: 'Finance'),
          BottomNavigationBarItem(icon: Icon(Icons.insert_chart), label: 'Report'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  // Widget untuk menampilkan kartu pemasukan & pengeluaran
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

  // Fungsi untuk membuat data grafik batang
  BarChartGroupData _buildBarGroup(int x, double y1, double y2) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(fromY: 0, toY: y1, color: Colors.blue, width: 15), // Fix error
        BarChartRodData(fromY: 0, toY: y2, color: Colors.purple, width: 15), // Fix error
      ],
    );
  }
}
