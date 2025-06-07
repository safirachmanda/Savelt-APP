import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:convert';


class ProfileBox extends StatelessWidget {
  final String uid;

  ProfileBox({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Text('User data tidak ditemukan');
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final displayName = userData['displayName'] ?? 'Tidak ada nama';
        final profileImage = userData['profileImage'] ?? '';

        ImageProvider? imageProvider;

        if (profileImage.isNotEmpty) {
          // Kalau profileImage berupa URL
          if (profileImage.startsWith('http')) {
            imageProvider = NetworkImage(profileImage);
          } else {
            // Jika profileImage base64, decode dulu
            try {
              final decodedBytes = base64Decode(profileImage);
              imageProvider = MemoryImage(decodedBytes);
            } catch (e) {
              imageProvider = AssetImage('assets/default_profile.png');
            }
          }
        } else {
          imageProvider = AssetImage('assets/default_profile.png');
        }

        return _buildRoundedBox(
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: imageProvider,
            ),
            title: Text(
              'Selamat Datang!',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(displayName),
          ),
        );
      },
    );
  }

  Widget _buildRoundedBox({required Widget child}) {
    return Container(
      margin: EdgeInsets.all(12),
      padding: EdgeInsets.all(8),
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
