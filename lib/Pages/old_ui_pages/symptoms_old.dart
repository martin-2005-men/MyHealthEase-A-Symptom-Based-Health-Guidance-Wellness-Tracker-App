import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class Symptoms extends StatefulWidget {
  const Symptoms({super.key});

  @override
  State<Symptoms> createState() => _SymptomsState();
}

class _SymptomsState extends State<Symptoms> {
  final TextEditingController _symptomController = TextEditingController();
  Map<String, dynamic>? _predictionResult;
  List<dynamic> _nearbyDoctors = [];
  bool _isLoading = false;
  String _message = "";

  // Set this to true to use mock data for testing.
  // Set to false to use the real API server.
  final bool isDebugging = false;

  final String _serverUrl = "http://192.168.0.80:5000";

  Future<void> _analyzeSymptoms() async {
    final symptoms = _symptomController.text.trim();
    if (symptoms.isEmpty) {
      setState(() {
        _message = "Please enter at least one symptom.";
        _predictionResult = null;
        _nearbyDoctors = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _predictionResult = null;
      _nearbyDoctors = [];
      _message = "";
    });

    // --- DEBUGGING MODE LOGIC ---
    if (isDebugging) {
      // Simulate a network delay
      await Future.delayed(const Duration(seconds: 2));

      // Hard-coded mock data to simulate a successful API response
      final mockData = {
        "causes": ["Poor sanitation", "contaminated water or food"],
        "confidence": "98%",
        "condition": "Typhoid",
        "diet": {
          "avoid": ["spicy foods", "fatty foods", "raw vegetables"],
          "recommend": ["boiled rice", "yogurt", "bananas", "soft-cooked vegetables"]
        },
        "nearby_doctors": [
          {"name": "Dr. Sarah Chen", "phone": "555-123-4567"},
          {"name": "Dr. David Rodriguez", "phone": "555-987-6543"}
        ],
        "specialization": "Gastroenterologist"
      };

      setState(() {
        _predictionResult = mockData;
        final doctorsData = mockData['nearby_doctors'];
        if (doctorsData is List) {
          _nearbyDoctors = doctorsData;
        } else {
          _nearbyDoctors = [];
        }
        if (_nearbyDoctors.isEmpty) {
          _message = "No nearby doctors found for this specialization.";
        }
      });
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // --- ONLINE MODE (ORIGINAL LOGIC) ---
    final List<String> symptomList = symptoms.split(',').map((s) => s.trim()).toList();

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() {
          _message = "Location permissions are required to find nearby doctors.";
        });
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      final response = await http.post(
        Uri.parse('$_serverUrl/predict'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'symptoms': symptomList,
          'latitude': position.latitude,
          'longitude': position.longitude,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _predictionResult = data;
          final doctorsData = data['nearby_doctors'];
          if (doctorsData is List) {
            _nearbyDoctors = doctorsData;
          } else {
            _nearbyDoctors = [];
          }

          if (_nearbyDoctors.isEmpty) {
            _message = "No nearby doctors found for this specialization at lat: ${position.latitude.toStringAsFixed(4)}, lon: ${position.longitude.toStringAsFixed(4)}.";
          } else {
            _message = "";
          }
        });
      } else {
        setState(() {
          _message = "Error: Failed to get a prediction. Status code: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _message = "Error: Could not connect to the server. Please check your network and try again. Error: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          const Text(
            "Symptom Checker",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          const Text(
            "Enter your symptoms below to check which Condition / Health Problem you have",
            style: TextStyle(fontSize: 16, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _symptomController,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              hintText: "Enter your symptoms...",hintStyle: TextStyle(fontSize: 18),
              prefixIcon: const Icon(Icons.sick_outlined),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
            onPressed: _analyzeSymptoms,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Analyze Symptoms", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 24),
          if (_message.isNotEmpty)
            Text(
              _message,
              style: TextStyle(
                fontSize: 16,
                color: _message.startsWith('Error') || _message.startsWith('Location') ? Colors.red : Colors.green,
              ),
              textAlign: TextAlign.center,
            ),
          if (_predictionResult != null)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Analysis Result",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    _buildResultRow("Condition", _predictionResult!['condition']),
                    _buildResultRow("Confidence", _predictionResult!['confidence'].toString()),
                    _buildResultRow("Specialization", _predictionResult!['specialization']),
                    _buildListSection("Causes", _predictionResult!['causes']),
                    _buildListSection("Recommended Diet", _predictionResult!['diet']['recommend']),
                    _buildListSection("Avoid", _predictionResult!['diet']['avoid']),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          if (_nearbyDoctors.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Nearby Doctors",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Divider(),
                ..._nearbyDoctors.map((doctor) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      title: Text(doctor['name']),
                      subtitle: Text(doctor['phone']),
                      leading: const Icon(Icons.local_hospital, color: Colors.indigo),
                    ),
                  );
                }).toList(),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label:",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListSection(String title, List<dynamic> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Text(
              "- $item",
              style: const TextStyle(fontSize: 16),
            ),
          )).toList(),
        ],
      ),
    );
  }
}