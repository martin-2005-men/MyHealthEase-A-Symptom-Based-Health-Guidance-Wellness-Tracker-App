import 'package:flutter/material.dart';
import 'package:healthease_app/Pages/dashboard.dart';
import 'package:healthease_app/Pages/home.dart';
import 'package:healthease_app/Pages/profile.dart';
import 'package:healthease_app/Pages/symptoms.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;

  late List<Widget> pages;

  @override
  void initState() {
    super.initState();
    pages = [
      HomeTab(
        onNavigate: (index) {
          setState(() => selectedIndex = index);
        },
      ),
      SymptomCheckerPage(),
      Dashboard(),
      Profile(),
    ];
  }

  void onTap(int index) => setState(() => selectedIndex = index);

  Widget _buildAnimatedIcon(IconData iconData, int index) {
    return AnimatedScale(
      scale: selectedIndex == index ? 1.2 : 1.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: Icon(iconData),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // The background is now a solid white color.
      appBar: AppBar(
        title: const Text(
          "MyHealthEase",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: const Color(0xFF6F7EFC).withOpacity(0.8),
        elevation: 4.0,
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      body: pages[selectedIndex],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(bottom: 24.0, left: 16.0, right: 16.0),
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: onTap,
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF4A4A94),
          unselectedItemColor: Colors.grey.shade500,
          items: [
            BottomNavigationBarItem(
              icon: _buildAnimatedIcon(Icons.home, 0),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: _buildAnimatedIcon(Icons.medical_services, 1),
              label: "Symptoms",
            ),
            BottomNavigationBarItem(
              icon: _buildAnimatedIcon(Icons.dashboard, 2),
              label: "Dashboard",
            ),
            BottomNavigationBarItem(
              icon: _buildAnimatedIcon(Icons.person, 3),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }
}
