import 'package:flutter/material.dart';

class NotificationPage extends StatefulWidget {
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  bool isReminderOn = true;
  int daysBefore = 3;
  TimeOfDay selectedTime = TimeOfDay(hour: 8, minute: 11);

  void _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Notifikasi')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Notifikasi Tagihan', style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(child: Text('Ingatkan tagihan yang akan datang atau terlewat')),
                Checkbox(
                  value: isReminderOn,
                  onChanged: (bool? value) {
                    setState(() {
                      isReminderOn = value ?? false;
                    });
                  },
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.remove),
                  onPressed: () {
                    setState(() {
                      if (daysBefore > 1) daysBefore--;
                    });
                  },
                ),
                Text('$daysBefore Hari', style: TextStyle(fontSize: 18)),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    setState(() {
                      daysBefore++;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
            Text('Pukul berapa untuk mengingatkan tagihan yang akan datang?'),
            SizedBox(height: 10),
            GestureDetector(
              onTap: () => _selectTime(context),
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(Icons.access_time),
                    Text('${selectedTime.format(context)}'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
