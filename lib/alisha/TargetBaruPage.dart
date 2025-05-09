import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'TargetPage.dart';

class TargetBaruPage extends StatefulWidget {
  @override
  _TargetBaruPageState createState() => _TargetBaruPageState();
}

class _TargetBaruPageState extends State<TargetBaruPage> {
  TextEditingController namaController = TextEditingController();
  TextEditingController targetController = TextEditingController();
  DateTime? mulaiMenabung;
  DateTime? targetTerkumpul;
  String? frekuensi;
  bool notifikasi = true;

  Future<void> _selectDate(BuildContext context, Function(DateTime) onDateSelected) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  void _showDiscardDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Konfirmasi"),
        content: Text("Apakah anda yakin menghapus perubahan yang anda buat?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Tetap di halaman ini
            child: Text("Tidak"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Tutup dialog
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => TargetPage()),
              ); // Pindah ke TargetTabunganPage()
            },
            child: Text("Ya"),
          ),
        ],
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Konfirmasi"),
        content: Text("Apakah anda yakin ingin keluar? Perubahan yang anda buat akan hilang."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Tetap di halaman ini
            child: Text("Tidak"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Tutup dialog
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => TargetPage()),
              ); // Pindah ke TargetTabunganPage()
            },
            child: Text("Ya"),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Buat Target Tabungan Baru"),
        leading:
        IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => _showExitDialog(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(controller: namaController, decoration: InputDecoration(labelText: "Nama Tabungan")),
            SizedBox(height: 10),
            Text(""),
            TextField(controller: targetController, decoration: InputDecoration(labelText: "Target Tabungan (Rp...)"), keyboardType: TextInputType.number),
            SizedBox(height: 10),
            Text(""),
            Text("Tanggal Mulai Menabung"),
            ListTile(
              title: Text(mulaiMenabung == null ? "Pilih Tanggal Mulai Menabung" : DateFormat('dd/MM/yyyy').format(mulaiMenabung!)),
              trailing: Icon(Icons.calendar_today),
              onTap: () => _selectDate(context, (date) => setState(() => mulaiMenabung = date)),
            ),
            Text(""),
            Text("Tanggal Target Tabungan Terkumpul"),
            ListTile(
              title: Text(targetTerkumpul == null ? "Pilih Tanggal Target Terkumpul" : DateFormat('dd/MM/yyyy').format(targetTerkumpul!)),
              trailing: Icon(Icons.calendar_today),
              onTap: () => _selectDate(context, (date) => setState(() => targetTerkumpul = date)),
            ),
            Text(""),
            Text("Frekuensi Menabung"),
            DropdownButton<String>(
              hint: Text("Pilih Frekuensi Menabung"),
              value: frekuensi,
              onChanged: (value) => setState(() => frekuensi = value),
              items: ["Harian", "Mingguan", "Bulanan"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("\nNotifikasi"),
                Switch(value: notifikasi, onChanged: (val) => setState(() => notifikasi = val)),
              ],
            ),
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () => _showDiscardDialog(context),
                  child: Text("Discard"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => TargetPage()),
                    ); // Pindah ke TargetTabunganPage()
                  },
                  child: Text("Save"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
