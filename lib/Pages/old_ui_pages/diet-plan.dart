import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// DietPlanHistoryPage displays a list of past symptom and diet logs.
class DietPlanHistoryPage extends StatefulWidget {
  const DietPlanHistoryPage({super.key});

  @override
  State<DietPlanHistoryPage> createState() => _DietPlanHistoryPageState();
}

class _DietPlanHistoryPageState extends State<DietPlanHistoryPage> {
  // List to store the history of diet plan entries.
  final List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  // Loads the history of logs from SharedPreferences.
  Future<void> _loadHistory() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? historyString = prefs.getString('dietPlanHistory');
    if (historyString != null) {
      final List<dynamic> decodedList = json.decode(historyString);
      setState(() {
        _history.clear();
        _history.addAll(decodedList.cast<Map<String, dynamic>>());
      });
    }
  }

  // Deletes an entry from the history and updates storage.
  Future<void> _deleteEntry(int index) async {
    setState(() {
      _history.removeAt(index);
    });
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String encodedList = json.encode(_history);
    await prefs.setString('dietPlanHistory', encodedList);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diet Plan History'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _history.isEmpty
            ? Center(
          child: Text(
            'No diet plans logged yet.',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        )
            : ListView.builder(
          itemCount: _history.length,
          itemBuilder: (context, index) {
            final entry = _history[index];
            final symptom = entry['symptom'] as String;
            final causes = entry['causes'] as String;
            final dietPlan = entry['dietPlan'] as String;

            return Dismissible(
              key: Key(entry['timestamp']),
              onDismissed: (direction) {
                _deleteEntry(index);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Entry deleted')),
                );
              },
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20.0),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              child: Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: ExpansionTile(
                  leading: const Icon(Icons.restaurant, color: Colors.orange),
                  title: Text(
                    'Symptom Log: $symptom',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(dietPlan,
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Causes: $causes',
                              style: const TextStyle(
                                  fontStyle: FontStyle.italic)),
                          const SizedBox(height: 8),
                          Text('Diet Plan: $dietPlan'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
