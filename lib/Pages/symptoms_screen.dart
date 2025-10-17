import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SymptomsScreen extends StatefulWidget {
  const SymptomsScreen({Key? key}) : super(key: key);

  @override
  _SymptomsScreenState createState() => _SymptomsScreenState();
}

class _SymptomsScreenState extends State<SymptomsScreen> {
  final String _apiUrl = "http://127.0.0.1:5000";
  List<String> _symptoms = [];
  bool _isLoading = true;
  String? _selectedSymptom;
  String _predictedCondition = "";

  @override
  void initState() {
    super.initState();
    _fetchSymptoms();
  }

  Future<void> _fetchSymptoms() async {
    try {
      final response = await http.get(Uri.parse('$_apiUrl/symptoms'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _symptoms = List<String>.from(data['symptoms']);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load symptoms');
      }
    } catch (e) {
      print('Error fetching symptoms: $e');
      setState(() {
        _isLoading = false;
        _symptoms = ['Error loading symptoms'];
      });
    }
  }

  Future<void> _predictCondition() async {
    if (_selectedSymptom == null) {
      setState(() {
        _predictedCondition = "Please select a symptom.";
      });
      return;
    }

    setState(() {
      _predictedCondition = "Predicting...";
    });

    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/predict'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'symptoms': [_selectedSymptom],
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _predictedCondition = "Predicted Condition: ${data['condition']}\nConfidence: ${(data['confidence'] * 100).toStringAsFixed(2)}%";
        });
      } else {
        throw Exception('Failed to get prediction');
      }
    } catch (e) {
      print('Error predicting condition: $e');
      setState(() {
        _predictedCondition = "Error during prediction.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Symptom Predictor'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              "Select a symptom:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : DropdownButton<String>(
              value: _selectedSymptom,
              hint: const Text("Choose a symptom..."),
              isExpanded: true,
              items: _symptoms.map((String symptom) {
                return DropdownMenuItem<String>(
                  value: symptom,
                  child: Text(symptom),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedSymptom = newValue;
                  _predictedCondition = ""; // Reset prediction on new selection
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _predictCondition,
              child: const Text("Predict"),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _predictedCondition.isEmpty ? "Prediction will appear here." : _predictedCondition,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
