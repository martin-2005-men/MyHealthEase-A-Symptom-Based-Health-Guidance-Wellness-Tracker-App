import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// ⚠️ This package must be added to your pubspec.yaml file to work ⚠️
import 'package:intl/intl.dart';

// DietPlanHistoryPage displays a list of past symptom and diet logs from Firestore.
class DietPlanHistoryPage extends StatefulWidget {
  const DietPlanHistoryPage({super.key});

  @override
  State<DietPlanHistoryPage> createState() => _DietPlanHistoryPageState();
}

class _DietPlanHistoryPageState extends State<DietPlanHistoryPage> {

  String get _currentUserId {
    // Fetches the UID of the currently signed-in user
    return FirebaseAuth.instance.currentUser?.uid ?? 'anonymous_user';
  }

  // Gets the reference to the user's diet-plan history collection
  CollectionReference get _dietPlanCollection {
    final userId = _currentUserId;
    return FirebaseFirestore.instance
        .collection('user_symptom_history')
        .doc(userId)
        .collection('records'); // Reads from the standardized 'records' collection
  }

  // Deletes an entry from Firestore.
  Future<void> _deleteEntry(String documentId) async {
    try {
      await _dietPlanCollection.doc(documentId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entry deleted from history'), duration: Duration(seconds: 2)),
        );
      }
    } catch (e) {
      debugPrint("Error deleting document: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete entry: $e')),
        );
      }
    }
  }

  // Helper function to split the routine string into a list of steps
  List<String> _splitDietRoutine(String routine) {
    // Splits by period, semicolon, or newline, preserving the separators if they
    // contain text. We will filter and trim.
    return routine
        .split(RegExp(r'\.|\;|\n'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  // Widget to display the routine items as a bulleted list
  Widget _buildDietRoutineList(List<String> routineItems) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detailed Routine:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.deepOrange,
          ),
        ),
        const SizedBox(height: 10),
        ...routineItems.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom, colorful bullet point
                const Icon(
                  Icons.lens_sharp, // A filled circle icon for a strong bullet
                  size: 8,
                  color: Colors.orange,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  // Widget to display the specialist in a uniform style
  Widget _buildSpecialistRow(String specialist) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: Row(
        children: [
          Icon(Icons.local_hospital, color: Colors.teal.shade700, size: 20),
          const SizedBox(width: 8),
          const Text(
            'Recommended Specialist: ',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.teal),
          ),
          Expanded(
            child: Text(
              specialist,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check for anonymous user and show a warning
    if (_currentUserId == 'anonymous_user') {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Diet Plan History'),
          backgroundColor: Colors.orange,
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: Text(
              '🔒 Please sign in to securely view your personalized diet plan history from Firestore.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.red),
            ),
          ),
        ),
      );
    }

    // Use StreamBuilder to listen for real-time changes in Firestore
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diet Plan History', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _dietPlanCollection.orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error loading history: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.orange));
          }

          final history = snapshot.data!.docs;

          if (history.isEmpty) {
            return Center(
              child: Text(
                '🥗 No diet plans logged yet.\nRun the Symptom Checker to save your first routine!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final document = history[index];
              final entry = document.data() as Map<String, dynamic>;

              // Fetch all necessary data fields
              final symptom = entry['symptomsInput'] as String? ?? 'Symptoms Not Found';
              final causes = entry['healthCondition'] as String? ?? 'Condition Not Found';
              final specialist = entry['doctorSpecialist'] as String? ?? 'Specialist N/A';
              final dietPlan = entry['dietRoutine'] as String? ?? 'No detailed routine provided.';

              // Convert the single routine string to a list
              final routineItems = _splitDietRoutine(dietPlan);

              // Extract timestamp and format the date
              final timestamp = entry['timestamp'] as Timestamp?;
              final formattedDate = timestamp != null
                  ? DateFormat('MMM dd, yyyy - hh:mm a').format(timestamp.toDate())
                  : 'Date Unavailable';

              return Dismissible(
                key: Key(document.id),
                direction: DismissDirection.endToStart, // Swipe right to left to dismiss
                onDismissed: (direction) {
                  _deleteEntry(document.id);
                },
                background: Container(
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20.0),
                  child: const Icon(Icons.delete_forever, color: Colors.white, size: 30),
                ),
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: BorderSide(color: Colors.orange.shade100, width: 1)),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                    leading: Icon(Icons.fitness_center, color: Colors.orange.shade700, size: 30),
                    title: Text(
                      causes, // Use the condition/cause as the main title
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.black87),
                    ),
                    subtitle: Text(
                      'Logged: $formattedDate',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20.0),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(15),
                            bottomRight: Radius.circular(15),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Symptoms Reported: $symptom',
                              style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.blueGrey),
                            ),

                            // Display the Specialist
                            _buildSpecialistRow(specialist),

                            const Divider(height: 20, thickness: 1, color: Colors.orangeAccent),
                            // Display the routine as a clean list
                            _buildDietRoutineList(routineItems),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
