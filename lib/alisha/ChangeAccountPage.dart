import 'package:flutter/material.dart';

class ChangeAccountPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ubah Akun')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('DISPLAY NAME', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Safira Putri Jihan'),
            SizedBox(height: 10),
            Text('EMAIL ADDRESS', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('safirajihan@gmail.com'),
            SizedBox(height: 10),
            Text('PASSWORD', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('***********'),
            SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  TextButton(
                      onPressed: () {},
                      child: Text('SIGN OUT', style: TextStyle(color: Colors.red))
                  ),
                  TextButton(
                      onPressed: () {},
                      child: Text('DELETE ACCOUNT', style: TextStyle(color: Colors.red))
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
