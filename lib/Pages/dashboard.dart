import 'package:flutter/material.dart';
import 'package:healthease_app/Pages/PedometerApp.dart';
import 'package:healthease_app/Pages/diet-plan.dart';
import 'package:healthease_app/Pages/mood_tracker.dart';
import 'package:healthease_app/Pages/sleep_tracker.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  // Custom Card Widget for reusability and modern styling
  Widget _buildFeatureCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color startColor,
    required Color endColor,
    required Widget pageToNavigate,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: endColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        gradient: LinearGradient(
          colors: [startColor.withOpacity(0.9), endColor.withOpacity(0.9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => pageToNavigate));
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Icon(icon, size: 36, color: Colors.white),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.white70),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Define a modern, consistent color scheme
    const Color primaryColor = Color(0xFF4A148C); // Deep Purple
    const Color accentColor = Color(0xFF00BFA5); // Teal Accent

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Health Dashboard", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            // Modern Greeting Header
            Text(
              "Welcome Back!",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 4),
            const Text(
              "Your Health Overview",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black87),
            ),
            const SizedBox(height: 25),

            // Card 1: Sleep tracker (Indigo theme)
            _buildFeatureCard(
              context: context,
              icon: Icons.bedtime_rounded,
              title: "Sleep Quality",
              subtitle: "Track and improve your sleep status",
              startColor: const Color(0xFF3F51B5), // Indigo
              endColor: const Color(0xFF5C6BC0), // Lighter Indigo
              pageToNavigate: const SleepTrackerPage(),
            ),

            // Card 2: Steps tracker (Green theme)
            _buildFeatureCard(
              context: context,
              icon: Icons.directions_run_rounded,
              title: "Daily Steps",
              subtitle: "0 / 10,000 steps achieved today",
              startColor: const Color(0xFF4CAF50), // Green
              endColor: const Color(0xFF81C784), // Lighter Green
              pageToNavigate: const PedometerNavigationApp(),
            ),

            // Card 3: Diet Plan (Orange theme)
            _buildFeatureCard(
              context: context,
              icon: Icons.restaurant_menu_rounded,
              title: "Diet Plan",
              subtitle: "foods recommended for today",
              startColor: const Color(0xFFFF9800), // Orange
              endColor: const Color(0xFFFFB74D), // Lighter Orange
              pageToNavigate: const DietPlanHistoryPage(),
            ),

            // Card 4: Mood Tracker (Purple theme)
            _buildFeatureCard(
              context: context,
              icon: Icons.sentiment_satisfied_alt_rounded,
              title: "Mood Tracker",
              subtitle: "Log your mood: Happy, Angry, Sad, or Neutral",
              startColor: primaryColor, // Deep Purple
              endColor: primaryColor.withOpacity(0.7),
              pageToNavigate: const MoodTrackerPage(),
            ),

            const SizedBox(height: 30),

            // Health summary section (Refined)
            Text(
              "Recent Health Summary",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
            ),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1), // Light teal background
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: accentColor.withOpacity(0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.notes, color: accentColor, size: 24),
                        const SizedBox(width: 8),
                        Text("Latest Self-Report", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: accentColor)),
                      ],
                    ),
                    const Divider(height: 20, color: Colors.transparent),
                    const Text(
                      "📝 You reported: **Headache**, **Fatigue**",
                      style: TextStyle(fontSize: 15, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "💡 Suggestion: Stay hydrated and get at least 7 hours of sleep tonight.",
                      style: TextStyle(fontSize: 15, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20,),
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
      ),
    );
  }
}
