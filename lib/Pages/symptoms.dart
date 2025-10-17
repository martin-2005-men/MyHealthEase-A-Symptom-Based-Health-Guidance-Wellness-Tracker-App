import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart'; // REQUIRED for Firestore
import 'package:firebase_auth/firebase_auth.dart'; // REQUIRED for user ID

// Re-added the required import for the map page component!
import 'specialist_finder_map.dart';

// ⚠️ IMPORTANT: Set your Flask server IP here (e.g., http://192.168.0.195:5000)
// For Android Emulator, use 'http://10.0.2.2:5000'
const String _serverUrl = "http://192.168.0.195:5000";

// ==========================================================
// FIX: LOCAL DEFINITION OF DietPlanHistoryPage
// ==========================================================
class DietPlanHistoryPage extends StatelessWidget {
  const DietPlanHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off, size: 80, color: Colors.teal.shade300),
            const SizedBox(height: 16),
            Text(
              "Diet Plan History Content Placeholder",
              style: TextStyle(fontSize: 18, color: Colors.teal.shade700, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "This stub allows the application to compile. The full history logic belongs in 'diet-plan.dart'.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
// ==========================================================
// END FIX
// ==========================================================

// --- DATA MODEL ---

class PredictionResult {
  final String healthCondition;
  final String doctorSpecialist;
  final String dietRecommendations;
  final String foodsToAvoid;
  final String dietRoutine;
  final double similarityScore;

  PredictionResult.fromJson(Map<String, dynamic> json)
      : healthCondition = json['health_condition'] ?? 'N/A',
        doctorSpecialist = json['doctor_specialist'] ?? 'General Practitioner',
        dietRecommendations = json['diet_recommendations'] ?? 'N/A',
        foodsToAvoid = json['foods_to_avoid'] ?? 'N/A',
        dietRoutine = json['diet_routine'] ?? 'N/A',
        similarityScore = json['similarity_score'] as double? ?? 0.0;

  // Helper to convert to map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'healthCondition': healthCondition,
      'doctorSpecialist': doctorSpecialist,
      'dietRecommendations': dietRecommendations,
      'foodsToAvoid': foodsToAvoid,
      'dietRoutine': dietRoutine,
      'similarityScore': similarityScore,
    };
  }
}

// ==========================================================
// SYMPTOM CHECKER PAGE (UI for Input and Prediction)
// ==========================================================

class SymptomCheckerPage extends StatefulWidget {
  const SymptomCheckerPage({super.key});

  @override
  State<SymptomCheckerPage> createState() => _SymptomCheckerPageState();
}

class _SymptomCheckerPageState extends State<SymptomCheckerPage> {
  final TextEditingController _symptomController = TextEditingController();
  PredictionResult? _topPrediction;
  bool _isLoading = false;
  String _message = "";
  bool _showDietRoutine = false;

  // --- FIRESTORE INTEGRATION ---

  String get _currentUserId {
    return FirebaseAuth.instance.currentUser?.uid ?? 'anonymous_user';
  }

  /// Saves the user's input and the prediction result to Firestore.
  Future<void> _savePredictionToFirestore(
      PredictionResult prediction, String symptomsInput) async {
    final userId = _currentUserId;
    if (userId == 'anonymous_user') {
      debugPrint("Warning: User is anonymous. Data not saved.");
      return;
    }

    try {
      final firestore = FirebaseFirestore.instance;

      // Standardized Collection Path: 'user_symptom_history/{userId}/records'
      final collectionRef = firestore
          .collection('user_symptom_history')
          .doc(userId)
          .collection('records');

      await collectionRef.add({
        'userId': userId,
        'symptomsInput': symptomsInput, // User's raw input
        'timestamp': FieldValue.serverTimestamp(),
        // Save the key fields required by the history page
        'healthCondition': prediction.healthCondition,
        'doctorSpecialist': prediction.doctorSpecialist,
        'dietRoutine': prediction.dietRoutine,
        'dietRecommendations': prediction.dietRecommendations,
        'foodsToAvoid': prediction.foodsToAvoid,
      });
      debugPrint("Symptom data saved successfully for user: $userId");
    } catch (e) {
      debugPrint("Error saving prediction to Firestore: $e");
    }
  }

  // --- ANALYZE SYMPTOMS ---

  Future<void> _analyzeSymptoms() async {
    final symptomsInput = _symptomController.text.trim();
    if (symptomsInput.isEmpty) {
      setState(() {
        _message = "Please enter symptoms.";
        _topPrediction = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _topPrediction = null;
      _message = "Analyzing symptoms...";
    });

    try {
      final requestBody = jsonEncode({'symptoms': symptomsInput});
      final uri = Uri.parse('$_serverUrl/predict');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List;

        if (results.isNotEmpty) {
          final topResult = PredictionResult.fromJson(results.first);

          // Save the successful prediction to Firestore
          await _savePredictionToFirestore(topResult, symptomsInput);

          setState(() {
            _topPrediction = topResult;
            _message = "Prediction complete: ${topResult.healthCondition} (Data saved)";
          });
        } else {
          setState(() {
            _message = "No matching conditions found in the dataset.";
          });
        }
      } else {
        final errorDetail = jsonDecode(response.body)['error'] ?? 'Unknown Server Error';
        setState(() {
          _message = "Error: Failed to get prediction. Detail: $errorDetail";
        });
      }
    } catch (e) {
      setState(() {
        _message = "Network Error: Could not connect to the server. Check IP/Server status. Error: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Function to navigate to the new map file (using a generic search term)
  void _findNearbySpecialist() {
    // Navigate using a generic label as requested by the user, so the map searches for general facilities.
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => const SpecialistFinderMap(
        predictedSpecialist: "General Healthcare Facility",
      ),
    ));
  }

  // --- UI building remains the same ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Symptom & Specialist Finder", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      body: Container(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [
            _buildSymptomInput(),
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
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _analyzeSymptoms,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.teal.shade700,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 5,
              ),
              child: const Text("Analyze Health Condition", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(child: CircularProgressIndicator(color: Colors.teal)),

            _buildMessage(),

            if (_topPrediction != null)
              _buildPredictionCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSymptomInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
      ),
      child: TextField(
        controller: _symptomController,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: "Enter symptoms (e.g., fever, cough, fatigue)...",
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
          prefixIcon: const Icon(Icons.sick_outlined, color: Colors.teal),
          contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        ),
        maxLines: 2,
      ),
    );
  }

  Widget _buildMessage() {
    if (_message.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: _message.startsWith('Error') ? Colors.red.shade100 : Colors.green.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(_message, style: TextStyle(color: _message.startsWith('Error') ? Colors.red.shade800 : Colors.green.shade800)),
    );
  }

  Widget _buildPredictionCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInfoRow(Icons.healing, "Condition", _topPrediction!.healthCondition),
            _buildInfoRow(Icons.local_hospital, "Specialist", _topPrediction!.doctorSpecialist),
            const Divider(height: 20),
            _buildInfoRow(Icons.restaurant, "Diet Advice", _topPrediction!.dietRecommendations),
            _buildInfoRow(Icons.block, "Foods to Avoid", _topPrediction!.foodsToAvoid),

            // Diet Routine Toggle Button
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _showDietRoutine = !_showDietRoutine;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade100,
                foregroundColor: Colors.teal.shade900,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 1,
              ),
              child: Text(_showDietRoutine ? "Hide Detailed Diet Routine" : "Show Detailed Diet Routine"),
            ),
            if (_showDietRoutine)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(_topPrediction!.dietRoutine, style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 14)),
              ),

            const SizedBox(height: 16),

            // DOCTOR RECOMMENDATION BUTTON - Triggers navigation to the map
            ElevatedButton.icon(
              onPressed: _findNearbySpecialist, // Re-added navigation function
              icon: const Icon(Icons.location_on, size: 24),
              label: const Text("Find Nearby Doctors/Hospitals", style: TextStyle(fontSize: 16)), // Updated label
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 5,
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.teal.shade800, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.teal)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 16, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================
// App Navigator (New Component to host both pages)
// ==========================================================

class HealthAppNavigator extends StatefulWidget {
  const HealthAppNavigator({super.key});

  @override
  State<HealthAppNavigator> createState() => _HealthAppNavigatorState();
}

class _HealthAppNavigatorState extends State<HealthAppNavigator> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const SymptomCheckerPage(),
    const DietPlanHistoryPage(), // The history page is now one of the main tabs
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services_outlined),
            label: 'Symptom Check',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Diet History',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.teal.shade700,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}

void main() {
  // ⚠️ Ensure Firebase is initialized in your actual application start
  // WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp();
  runApp(const MaterialApp(
    home: HealthAppNavigator(),
    debugShowCheckedModeBanner: false,
  ));
}
