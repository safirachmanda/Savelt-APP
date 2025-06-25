import 'package:flutter/material.dart';
import 'BillSettingsPage.dart';
import 'BillsPage.dart'; // Impor halaman Targetspage agar bisa kembali ke sana

class CategorySelectionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pilih Kategori Tagihan',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => BillsPage()),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'Tentukan tagihan apa saja yang ingin anda atur',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3, // 3 kolom per baris
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  CategoryItem(icon: Icons.credit_card, title: 'Credit Card'),
                  CategoryItem(icon: Icons.electric_bolt, title: 'Electricity'),
                  CategoryItem(icon: Icons.public, title: 'Internet'),
                  CategoryItem(icon: Icons.home, title: 'Home Loan'),
                  CategoryItem(icon: Icons.shield, title: 'Insurance'),
                  CategoryItem(icon: Icons.water, title: 'Water'),
                  CategoryItem(icon: Icons.apartment, title: 'Property Tax'),
                  CategoryItem(
                      icon: Icons.health_and_safety, title: 'Health Insurance'),
                  CategoryItem(icon: Icons.movie, title: 'Entertainment'),
                  CategoryItem(icon: Icons.school, title: 'Education'),
                  CategoryItem(icon: Icons.directions_car, title: 'Car Loan'),
                  CategoryItem(icon: Icons.smartphone, title: 'Mobile'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget kategori tanpa perubahan warna saat dipencet
class CategoryItem extends StatelessWidget {
  final IconData icon;
  final String title;

  const CategoryItem({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BillSettingsPage(
              categoryTitle: title,
              categoryIcon: icon,
            ),
          ),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.blue.withOpacity(0.1),
            child: Icon(icon, color: Colors.blue, size: 30),
          ),
          SizedBox(height: 8),
          Text(title,
              textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
