import 'package:flutter/material.dart';
import 'splashscreen4.dart';
import 'splashscreen6.dart';

class SplashScreen5 extends StatelessWidget {
  const SplashScreen5({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Tombol Skip
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SplashScreen6()),
                  );
                },
                child: const Text(
                  "Skip",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Image.asset(
                'assets/bell.png',
                width: 200,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: ClipPath(
              clipper: WaveClipper(),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple, Colors.lightBlueAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Teks "INGATKAN TAGIHAN"
                    RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: '\nINGATKAN\n',
                            style: TextStyle(
                              fontSize: 45,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Inter',
                              color: Colors.white,
                              height: 1.0,
                            ),
                          ),
                          TextSpan(
                            text: 'TAGIHAN',
                            style: TextStyle(
                              fontSize: 45,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Inter',
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20), // Diturunkan sedikit
                    const Text(
                      'Ingatkan Tagihan agar tidak ada pembayaran yang terlewat',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    const SizedBox(height: 80), // Diturunkan lebih jauh
                    // Indikator halaman dan tombol navigasi sejajar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Tombol Kiri (←) ke SplashScreen4
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SplashScreen4()),
                            );
                          },
                          icon: const Icon(Icons.arrow_back,
                              color: Colors.white, size: 28),
                        ),
                        // Indikator halaman (5 lingkaran)
                        Row(
                          children: List.generate(5, (index) {
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: index == 4
                                    ? Colors.white
                                    : Colors.transparent,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                            );
                          }),
                        ),
                        // Tombol Kanan (→) ke SplashScreen6
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SplashScreen6()),
                            );
                          },
                          icon: const Icon(Icons.arrow_forward,
                              color: Colors.white, size: 28),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom Clipper untuk efek wave di bagian bawah
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height * 0.15);

    path.quadraticBezierTo(
        size.width / 4, size.height * 0.08, size.width / 2, size.height * 0.15);
    path.quadraticBezierTo(
        size.width * 3 / 4, size.height * 0.25, size.width, size.height * 0.15);

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
