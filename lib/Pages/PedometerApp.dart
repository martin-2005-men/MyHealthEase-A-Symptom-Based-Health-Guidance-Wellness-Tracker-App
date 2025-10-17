import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'dart:async';

// --- Global Constants ---
const int _goalSteps = 10000;
const Color _gradientStart = Color(0xFF6A1B9A); // Deep Purple
const Color _gradientEnd = Color(0xFFE91E63);   // Pink

// Helper class for number formatting (Simplified for demo)
class NumberFormat {
  static NumberFormat decimalPattern() {
    return NumberFormat._();
  }

  NumberFormat._();

  String format(int number) {
    if (number < 0) return 'Error';
    // Simple comma separation logic
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }
}

// =========================================================================
// 1. Main Application Wrapper
// =========================================================================
class PedometerNavigationApp extends StatelessWidget {
  const PedometerNavigationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Step Tracker Navigation',
      theme: ThemeData(
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      // Set the initial screen to the HomePage
      home: const HomePage(),
    );
  }
}

// =========================================================================
// 2. The Home Page (The "Older Page" to return to)
// =========================================================================
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // Function to navigate to the Pedometer Screen
  void _navigateToPedometer(BuildContext context) {
    // Navigator.push places the PedometerScreen on top of the HomePage
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PedometerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Use a different gradient for visual separation
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF42A5F5), Color(0xFF1565C0)], // Blue Gradient
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Activity Hub',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 50),
              // Button to trigger navigation
              ElevatedButton.icon(
                onPressed: () => _navigateToPedometer(context),
                icon: const Icon(Icons.directions_run),
                label: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    'START STEP TRACKER',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  foregroundColor: const Color(0xFF1565C0),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 10,
                ),
              ),
              const SizedBox(height: 150),
            ],
          ),
        ),
      ),
    );
  }
}


// =========================================================================
// 3. The Pedometer Screen (Modified from your original PedometerApp)
// =========================================================================
class PedometerScreen extends StatefulWidget {
  const PedometerScreen({super.key});

  @override
  State<PedometerScreen> createState() => _PedometerScreenState();
}

class _PedometerScreenState extends State<PedometerScreen> {
  late Stream<StepCount> _stepCountStream;
  late Stream<PedestrianStatus> _pedestrianStatusStream;

  String _status = 'Initializing...';
  int _steps = 0;

  @override
  void initState() {
    super.initState();
    _initPedometer();
  }

  // Initializes the Pedometer stream listeners
  void _initPedometer() {
    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream.listen(_onStepCount, onError: _onStepCountError);

    _pedestrianStatusStream = Pedometer.pedestrianStatusStream;
    _pedestrianStatusStream.listen(_onPedestrianStatusChanged, onError: _onPedestrianStatusError);

    if (!mounted) return;
    setState(() {
      _status = 'Step Counter Ready';
    });
  }

  // Handler for new step count events
  void _onStepCount(StepCount event) {
    if (!mounted) return;
    setState(() {
      _steps = event.steps;
    });
  }

  // Handler for Pedestrian Status events
  void _onPedestrianStatusChanged(PedestrianStatus event) {
    if (!mounted) return;
    setState(() {
      _status = event.status;
    });
  }

  // Error handler for step count stream
  void _onStepCountError(error) {
    if (!mounted) return;
    setState(() {
      _steps = -1;
      _status = 'Step Count Error: $error';
    });
  }

  // Error handler for pedestrian status stream
  void _onPedestrianStatusError(error) {
    if (!mounted) return;
    setState(() {
      _status = 'Status Error: $error';
    });
  }

  // Calculates the progress towards the goal as a decimal (0.0 to 1.0)
  double _calculateProgress() {
    return _steps / _goalSteps;
  }

  // Builds the large, digital display for the step count
  Widget _buildStepCounter() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Total Steps',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 24,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 10),
        // Display the step count in a large, digital style font
        Text(
          _steps < 0 ? '---' : NumberFormat.decimalPattern().format(_steps),
          style: TextStyle(
            color: Colors.white,
            fontSize: 100,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: _gradientEnd.withOpacity(0.5),
                blurRadius: 15,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Builds the progress bar and goal text
  Widget _buildGoalProgress() {
    final double progress = _calculateProgress().clamp(0.0, 1.0);
    final String goalMessage = progress >= 1.0
        ? 'GOAL ACHIEVED! 🎉'
        : '${NumberFormat.decimalPattern().format((_goalSteps - _steps).clamp(0, _goalSteps))} steps left';

    return Column(
      children: [
        Text(
          goalMessage,
          style: TextStyle(
            color: progress >= 1.0 ? Colors.yellowAccent : Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.white30,
          valueColor: AlwaysStoppedAnimation<Color>(
            progress >= 1.0 ? Colors.yellowAccent : Colors.lightGreenAccent,
          ),
          minHeight: 10,
          borderRadius: BorderRadius.circular(5),
        ),
        const SizedBox(height: 5),
        Text(
          'Goal: ${NumberFormat.decimalPattern().format(_goalSteps)} Steps',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }

  // Builds the current status display (walking, stopped, or error)
  Widget _buildStatusIndicator() {
    final statusText = _status.toUpperCase();
    IconData icon = Icons.timer_off;
    Color color = Colors.redAccent;

    if (statusText.contains('WALKING')) {
      icon = Icons.directions_walk;
      color = Colors.lightGreenAccent;
    } else if (statusText.contains('STOPPED')) {
      icon = Icons.pause_circle_filled;
      color = Colors.orangeAccent;
    } else if (statusText.contains('READY')) {
      icon = Icons.check_circle;
      color = Colors.lightBlueAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Added AppBar for title and automatic back button functionality
      appBar: AppBar(
        title: const Text(
          'Step Tracker',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _gradientStart.withOpacity(0.8),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        // Modern Aesthetic: Gradient Background
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_gradientStart, _gradientEnd],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Main Step Counter Display
                _buildStepCounter(),

                // Current Status Indicator
                Center(child: _buildStatusIndicator()),

                // Goal Progress Bar
                _buildGoalProgress(),

                // Note to User
                const Padding(
                  padding: EdgeInsets.only(top: 20.0),
                  child: Text(
                    'Pedometer data resets daily or after device reboot.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
