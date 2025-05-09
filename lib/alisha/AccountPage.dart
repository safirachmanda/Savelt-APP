import 'package:flutter/material.dart';
import 'ChangeAccountPage.dart';
import 'NotificationPage.dart';
import 'LanguagePage.dart';

class AccountPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Akun')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey[300], // Ganti dengan warna default jika tidak ada gambar
                  child: Icon(Icons.person, size: 30, color: Colors.white), // Menampilkan ikon default
                ),
                SizedBox(width: 10),
                Text(
                  'Safira Putri Jihan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 20),
            ListTile(
              title: Text('Ubah Akun'),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChangeAccountPage()),
              ),
            ),
            Divider(),
            ListTile(
              title: Text('Notifikasi'),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationPage()),
              ),
            ),
            Divider(),
            ListTile(
              title: Text('Bahasa'),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LanguagePage()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
