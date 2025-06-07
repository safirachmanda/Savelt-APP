import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChangeAccountPage extends StatefulWidget {
  @override
  _ChangeAccountPageState createState() => _ChangeAccountPageState();
}

class _ChangeAccountPageState extends State<ChangeAccountPage> {
  final user = FirebaseAuth.instance.currentUser!;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _base64Image;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Load data user dan foto profil (base64) dari Firestore
  Future<void> _loadUserData() async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      setState(() {
        _nameController.text = user.displayName ?? '';
        _emailController.text = user.email ?? '';
        _base64Image = userDoc.exists && userDoc.data()!.containsKey('profileImage') && (userDoc.get('profileImage') != '') 
            ? userDoc.get('profileImage') 
            : null;
      });
    } catch (e) {
      print('Error load user data: $e');
    }
  }

  // Fungsi untuk pilih gambar dari galeri
  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final base64Str = base64Encode(bytes);

        setState(() {
          _base64Image = base64Str;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih gambar')),
      );
    }
  }

  // Simpan perubahan ke Firebase Auth dan Firestore
  Future<void> _saveChanges() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Update displayName
      if (_nameController.text.trim() != user.displayName) {
        await user.updateDisplayName(_nameController.text.trim());
      }

      // Update email jika beda
      if (_emailController.text.trim() != user.email) {
        await user.updateEmail(_emailController.text.trim());
      }

      // Update password jika diisi
      if (_passwordController.text.trim().isNotEmpty) {
        await user.updatePassword(_passwordController.text.trim());
      }

      // Simpan ke Firestore, merge data
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'displayName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'profileImage': _base64Image ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data berhasil diperbarui!')),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Terjadi kesalahan')),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _passwordController.clear();  // Clear password field after update
      });
    }
  }

  // Sign out user
  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pop(context);
  }

  // Delete akun user (pastikan user sudah login ulang jika perlu)
  Future<void> _deleteAccount() async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
      await user.delete();
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Gagal hapus akun')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tampilkan avatar gambar jika ada base64, kalau tidak tampil icon default
    Widget profileImageWidget;
    if (_base64Image != null && _base64Image!.isNotEmpty) {
      try {
        profileImageWidget = CircleAvatar(
          radius: 50,
          backgroundImage: MemoryImage(base64Decode(_base64Image!)),
        );
      } catch (e) {
        profileImageWidget = const CircleAvatar(
          radius: 50,
          child: Icon(Icons.person, size: 50),
        );
      }
    } else {
      profileImageWidget = const CircleAvatar(
        radius: 50,
        child: Icon(Icons.person, size: 50),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Ubah Akun')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Bisa tap foto untuk ganti
            GestureDetector(
              onTap: _pickImage,
              child: profileImageWidget,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Display Name'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                  labelText: 'Password Baru (kosongkan jika tidak ingin ubah)'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveChanges,
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Simpan Perubahan'),
            ),
            SizedBox(height: 20),
            TextButton(
              onPressed: _signOut,
              child: Text('SIGN OUT', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: _deleteAccount,
              child: Text('DELETE ACCOUNT', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}
