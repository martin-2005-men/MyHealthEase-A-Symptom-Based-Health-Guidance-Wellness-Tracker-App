import 'package:flutter/material.dart';
import 'dart:async';

import 'package:healthease_app/Pages/SignUpPage.dart';
import 'package:healthease_app/Pages/login.dart';
 // navigate after splash

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
   // Navigate to Login after 3 seconds
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // blue theme background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Image.asset(
              "assets/imgs/logo.png",
              width: 300,
              height: 300,
            ),
            const SizedBox(height: 10),
            // Tagline
            const Text(
              "Your Personal Health Companion",
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontFamily: 'Poppins',

              ),
            ),
          ],
        ),
      ),
    );
  }
}
