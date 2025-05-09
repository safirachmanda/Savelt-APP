import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const SaveltApp());
}

class SaveltApp extends StatelessWidget {
  const SaveltApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ReportScreen(),
    );
  }
}

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  double pemasukan = 900000;
  double pengeluaran = 600000;
  double sisaUang = 1000000;
  List<Map<String, dynamic>> transactions = [];  
  int selectedPeriod = 1;
  DateTime? selectedDate;


  void _showAddTransactionModal(BuildContext context, bool isIncome) {
    TextEditingController amountController = TextEditingController();
    String? selectedCategory;


    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isIncome ? "Tambah Pemasukan" : "Tambah Pengeluaran", style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(prefixText: "Rp ", hintText: "Masukkan nominal"),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                items: ["Makanan", "Belanja", "Tagihan", "Hiburan", "Transportasi"]
                    .map((category) => DropdownMenuItem(value: category, child: Text(category)))
                    .toList(),
                onChanged: (value) {
                  selectedCategory = value;
                },
                decoration: const InputDecoration(hintText: "Pilih kategori"),
              ),
              const SizedBox(height: 10),
              TextField(
                readOnly: true,
                decoration: InputDecoration(
                  hintText: selectedDate != null ? DateFormat('dd/MM/yyyy').format(selectedDate!) : "Pilih tanggal",
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  setState(() {
                    selectedDate = pickedDate;
                  });
                                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (amountController.text.isNotEmpty && selectedCategory != null && selectedDate != null) {
                    double amount = double.tryParse(amountController.text) ?? 0;
                    setState(() {
                      transactions.add({
                        "amount": amount,
                        "category": selectedCategory,
                        "date": selectedDate,
                        "isIncome": isIncome,
                      });
                      if (isIncome) {
                        pemasukan += amount;
                      } else {
                        pengeluaran += amount;
                      }
                      sisaUang = pemasukan - pengeluaran;
                    });
                    Navigator.pop(context);
                  }
                },
                child: const Text("Tambahkan"),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
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
    Padding(padding: EdgeInsets.symmetric(horizontal: 18), child: Text('This Week')),
    Padding(padding: EdgeInsets.symmetric(horizontal: 18), child: Text('This Month')),
    Padding(padding: EdgeInsets.symmetric(horizontal: 18), child: Text('This Year')),
  ],
),

            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('Sisa Uang', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Rp ${sisaUang.toInt()}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => _showAddTransactionModal(context, true),
                          child: _buildInfoCard('Pemasukan', 'Rp ${pemasukan.toInt()}', Colors.blueAccent),
                        ),
                        GestureDetector(
                          onTap: () => _showAddTransactionModal(context, false),
                          child: _buildInfoCard('Pengeluaran', 'Rp ${pengeluaran.toInt()}', Colors.redAccent),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildBarChart(),
            const SizedBox(height: 20),
            _buildPieChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          borderData: FlBorderData(show: false),
          barGroups: List.generate(7, (index) =>
            BarChartGroupData(x: index, barRods: [
              BarChartRodData(toY: (index + 1) * 100.0, color: Colors.blueAccent),
              BarChartRodData(toY: (index + 1) * 50.0, color: Colors.redAccent),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(value: 40, title: 'Makanan', color: Colors.lightBlueAccent),
            PieChartSectionData(value: 20, title: 'Belanja', color: Colors.blueAccent),
            PieChartSectionData(value: 15, title: 'Hiburan', color: Colors.indigo),
            PieChartSectionData(value: 10, title: 'Tabungan', color: Colors.deepPurple),
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
        // ignore: deprecated_member_use
        color: color.withOpacity(0.7),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.white)),
          Text(amount, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }
}