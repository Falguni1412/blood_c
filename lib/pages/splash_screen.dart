import 'package:flutter/material.dart';
import 'intro_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Wait for 3 seconds, then go to intro slides
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => IntroScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bloodtype, color: Color(0xFFAB0202), size: 130),
            const SizedBox(height: 20),
            Text(
              'BloodCare',
              style: TextStyle(
                color: Color(0xFF7C0707),
                fontSize: 36,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                fontFamily: 'Verdana',
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Connecting Donors & Receivers',
              style: TextStyle(
                color: Color(0xFF7C0707),
                fontSize: 16,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                fontFamily: 'Georgia',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
