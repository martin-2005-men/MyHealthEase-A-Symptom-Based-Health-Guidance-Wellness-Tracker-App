import 'dart:async'; // Required for Timer
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// This is the main StatefulWidget for the home page.
class HomeTab extends StatefulWidget {
  // Callback to switch tabs
  final Function(int) onNavigate;

  const HomeTab({
    super.key,
    required this.onNavigate,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

// This is the State class where your UI and logic reside.
class _HomeTabState extends State<HomeTab> {
  // User name state
  String userName = "User"; // Default placeholder

  // Motivational Quote State
  int _currentQuoteIndex = 0;
  Timer? _timer;

  // Define a modern color palette
  static const Color primaryColor = Color(0xFF4A148C); // Deep Purple
  static const Color accentColor = Color(0xFF00BFA5); // Teal Accent

  // List of 25 Motivational Health Quotes
  final List<String> _quotes = const [
    "The greatest wealth is health.",
    "Take care of your body. It’s the only place you have to live.",
    "An apple a day keeps the doctor away.",
    "Health is a state of body, wellness is a state of being.",
    "Your body hears everything your mind says.",
    "To enjoy the glow of good health, you must exercise.",
    "Every step forward counts, no matter how small.",
    "Eat healthily, sleep better, and exercise daily.",
    "The first wealth is health.",
    "Today's actions are tomorrow's results.",
    "Invest in your health; it is your best savings account.",
    "A healthy outside starts from the inside.",
    "Movement is a medicine for creating change.",
    "The journey of a thousand miles begins with a single step.",
    "Prioritize your peace and your health will follow.",
    "Take time to breathe. It refreshes your mind.",
    "Commit to being fit, and never quit.",
    "Wellness is a marathon, not a sprint.",
    "Water is the driving force of all nature.",
    "It’s not about having time, it's about making time for your health.",
    "Be stronger than your excuses.",
    "Sleep is the best meditation.",
    "Don't wait until you're sick to take care of yourself.",
    "The doctor of the future will give no medicine, but will interest his patients in the care of the human frame, in diet, and in the cause and prevention of disease.",
    "Self-care is not selfish. It is essential."
  ];

  @override
  void initState() {
    super.initState();
    getCurrentUserName();
    _startQuoteTimer(); // Start the timer when the widget is initialized
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  // Timer logic to change the quote every 10 seconds
  void _startQuoteTimer() {
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        setState(() {
          _currentQuoteIndex = (_currentQuoteIndex + 1) % _quotes.length;
        });
      }
    });
  }

  // LOGIC UNCHANGED: Fetches user name from Firestore
  Future<void> getCurrentUserName() async{
    final uid = FirebaseAuth.instance.currentUser!.uid;
    FirebaseFirestore.instance.collection("USER").doc(uid).get().then((snapshot){
      if(snapshot.exists) {
        setState(() {
          userName = (snapshot.data() as Map<String, dynamic>)['Name']?.toString() ?? 'User';
        });
      }
      else{
        print("USER DOES NOT EXISTS");
      }
    }).catchError((error){
      print("Error fetching user name:$error");
      setState(() {
        userName = 'Guest';
      });
    });
  }

  // Custom Widget for the main navigation buttons (Unchanged)
  Widget _buildNavCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required int tabIndex,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => widget.onNavigate(tabIndex),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 30, color: iconColor),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget for the rotating quote display (Unchanged)
  Widget _buildMotivationalQuoteCard() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.9), // Darker accent color
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Daily Inspiration ✨",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          // AnimatedSwitcher for smooth transition between quotes
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (Widget child, Animation<double> animation) {
              // Fade transition
              return FadeTransition(opacity: animation, child: child);
            },
            child: Text(
              _quotes[_currentQuoteIndex],
              key: ValueKey<int>(_currentQuoteIndex), // Key needed for AnimatedSwitcher
              style: const TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: ListView(
        padding: const EdgeInsets.only(top: 0, left: 20, right: 20, bottom: 40),
        children: [
          // Greeting Header Section
          Container(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hello, ${userName.split(' ').first} 👋",
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Welcome to MyHealthEase, your personal health companion!",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // --- Navigation Cards ---
          _buildNavCard(
            icon: Icons.medical_services_rounded,
            title: "Check Symptoms",
            subtitle: "Let us know how you're feeling today",
            iconColor: Colors.blue.shade600,
            tabIndex: 1,
          ),

          _buildNavCard(
            icon: Icons.bar_chart_rounded,
            title: "Health Dashboard",
            subtitle: "View your activity, sleep, and diet metrics",
            iconColor: accentColor,
            tabIndex: 2,
          ),

          _buildNavCard(
            icon: Icons.person_rounded,
            title: "Your Profile",
            subtitle: "View and update your personal details",
            iconColor: Colors.purple.shade600,
            tabIndex: 3,
          ),

          const SizedBox(height: 30),

          // --- Rotating Motivational Quote ---
          _buildMotivationalQuoteCard(),

          const SizedBox(height: 30), // Spacing before the disclaimer

          // --- Disclaimer Notice (New Addition) ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              "Disclaimer: This application is for informational and predictive purposes only. For any medical concerns or conditions, please consult a verified and qualified healthcare professional.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
