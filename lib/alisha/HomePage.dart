import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'TargetPage.dart';
import 'BillsPage.dart'; 
import 'ReportsPage.dart';
import 'AccountPage.dart';
import 'package:savelt4/widget/profilebox.dart';
import 'package:firebase_auth/firebase_auth.dart'; 

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
        //'/tagihan': (context) => const TagihanPage(),
        //'/laporankeuangan': (context) => const LaporanKeuanganPage(),
        '/targettabungan': (context) => TargetPage(), // Tambahkan rute ini
        //'/profile': (context) => const ProfilePage(),
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
  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Image.asset('savelt.png', height: 40), // Ganti dengan path ikon dompet
            const SizedBox(width: 5),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: "SAVE",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.lightBlue, // Warna biru muda
                      fontSize: 22,
                      fontFamily: 'Inter',
                    ),
                  ),
                  TextSpan(
                    text: "LT",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                      color: Colors.black, // Warna hitam
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
            ProfileBox(uid: uid),
            _buildReminderBox(),
            _buildSummaryBox(),
            _buildExpenseChart(),
            _buildBudgetsBox(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }


  Widget _buildReminderBox() {
  return _buildRoundedBox(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center, // Pusatkan semua elemen secara horizontal
      children: [
        const Center( // Menengahkan teks
          child: Text(
            'Pengingat',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        const SizedBox(height: 8),
        _buildReminderItem(
          title: 'Bayar Kos!',
          subtitle: 'Due: 07/03/2025',
          amount: '-Rp700.000,00',
          color: Colors.red,
        ),
        _buildReminderItem(
          title: 'Tabungan Liburan',
          subtitle: 'Jangan Lupa menabung minggu ini!',
          amount: 'Rp100.000,00',
          color: Colors.blue,
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
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              amount,
              style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
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
        const Center(
          child: Text(
            'Rangkuman',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            SizedBox(
              width: 150,
              height: 150,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: pemasukan,
                      color: Colors.green,
                      title: '${(pemasukan / totalValue * 100).toStringAsFixed(1)}%',
                      titleStyle: const TextStyle(fontSize: 10, color: Colors.black),
                    ),
                    PieChartSectionData(
                      value: pengeluaran,
                      color: Colors.red,
                      title: '${(pengeluaran / totalValue * 100).toStringAsFixed(1)}%',
                      titleStyle: const TextStyle(fontSize: 10, color: Colors.black),
                    ),
                    PieChartSectionData(
                      value: tabungan,
                      color: Colors.blue,
                      title: '${(tabungan / totalValue * 100).toStringAsFixed(1)}%',
                      titleStyle: const TextStyle(fontSize: 10, color: Colors.black),
                    ),
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween, // Membuat nominal rata kanan
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
        const Center(
          child: Text(
            'Pengeluaran - 7 Hari',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180, // Tinggi grafik lebih besar agar proporsional
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
                BarChartGroupData(x: 0, barRods: [
                  BarChartRodData(toY: 50000, color: Colors.red, width: 50, borderRadius: BorderRadius.circular(8))
                ]),
                BarChartGroupData(x: 1, barRods: [
                  BarChartRodData(toY: 75000, color: Colors.red, width: 50, borderRadius: BorderRadius.circular(8))
                ]),
                BarChartGroupData(x: 2, barRods: [
                  BarChartRodData(toY: 30000, color: Colors.red, width: 50, borderRadius: BorderRadius.circular(8))
                ]),
                BarChartGroupData(x: 3, barRods: [
                  BarChartRodData(toY: 20000, color: Colors.red, width: 50, borderRadius: BorderRadius.circular(8))
                ]),
                BarChartGroupData(x: 4, barRods: [
                  BarChartRodData(toY: 55000, color: Colors.red, width: 50, borderRadius: BorderRadius.circular(8))
                ]),
                BarChartGroupData(x: 5, barRods: [
                  BarChartRodData(toY: 100000, color: Colors.red, width: 50, borderRadius: BorderRadius.circular(8))
                ]),
                BarChartGroupData(x: 6, barRods: [
                  BarChartRodData(toY: 40000, color: Colors.red, width: 50, borderRadius: BorderRadius.circular(8))
                ]),
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
          const Center(
            child: Text(
              'Budgets',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const SizedBox(height: 16),
          _buildBudgetItem(
            title: 'Makanan/Minuman',
            icon: Icons.restaurant,
            progress: 1.4, // 140%
            amountUsed: 700000,
            budgetLimit: 500000,
            progressColor: Colors.red,
          ),
          const SizedBox(height: 16),
          _buildBudgetItem(
            title: 'Semua Kategori (Maret)',
            icon: Icons.assignment,
            progress: 0.833, // 83.3%
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
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("01/03/2025", style: TextStyle(fontSize: 12)),
            Text(
              "${(progress * 100).toStringAsFixed(1)}%",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: progressColor),
            ),
            const Text("31/03/2025", style: TextStyle(fontSize: 12)),
          ],
        ),
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: LinearProgressIndicator(
                value: (progress > 1) ? 1 : progress, // Progress tetap bisa melebihi batas 100%
                minHeight: 14,
                backgroundColor: progressColor.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation(progressColor),
              ),
            ),
            Positioned(
              left: (250 * (budgetLimit / budgetLimit)).toDouble(), // Posisi tetap 100% budget
              child: Container(
                width: 2,
                height: 18,
                color: Colors.black, // Warna garis batas anggaran
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



  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.blue, // Ubah warna latar belakang menjadi biru
      selectedItemColor: Colors.white, // Ubah warna ikon yang dipilih agar kontras
      unselectedItemColor: Colors.white70, // Warna ikon yang tidak dipilih
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
            MaterialPageRoute(builder: (context) => BillsPage()), // Ganti dengan halaman Tagihan
          );
          break;
        case 2:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ReportsPage()), // Ganti dengan halaman Laporan
          );
          break;
        case 3:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => TargetPage()), // Menuju TargetTabunganPage
          );
          break;
        case 4:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AccountPage()), // Ganti dengan halaman Profile
          );
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
