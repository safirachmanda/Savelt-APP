import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ChangeAccountPage.dart';
import 'NotificationPage.dart';
import 'LanguagePage.dart';
import 'dart:convert';

import 'HomePage.dart'; // Tambahkan import yang sesuai
import 'BillsPage.dart';
import 'ReportsPage.dart';
import 'TargetPage.dart';

class AccountPage extends StatefulWidget {
  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  String displayName = '';
  String email = '';
  String profileImage = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final data = doc.data();
        if (data != null) {
          setState(() {
            displayName = data['displayName'] ?? '';
            email = data['email'] ?? '';
            profileImage = data['profileImage'] ?? '';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Pengaturan Akun'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: profileImage.isNotEmpty
                            ? MemoryImage(base64Decode(profileImage))
                            : null,
                        child: profileImage.isEmpty
                            ? Icon(Icons.person, size: 30, color: Colors.white)
                            : null,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          displayName,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
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
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.blue,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      currentIndex: 4, // Index untuk halaman ini (Profile)
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
            // Sudah di halaman Profile, tidak perlu aksi
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
