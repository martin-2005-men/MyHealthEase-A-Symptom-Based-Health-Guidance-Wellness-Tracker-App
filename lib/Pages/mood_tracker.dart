import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MoodTrackerPage extends StatefulWidget {
  const MoodTrackerPage({super.key});

  @override
  State<MoodTrackerPage> createState() => _MoodTrackerPageState();
}

class _MoodTrackerPageState extends State<MoodTrackerPage> {
  // A map of moods with their corresponding emojis.
  final Map<String, String> _moods = {
    'Ecstatic': '😍',
    'Happy': '😊',
    'Neutral': '😐',
    'Sad': '😔',
    'Angry': '😠',
  };

  // State variable to store the currently selected mood.
  String? _selectedMood;
  // State variable to display the last saved mood.
  String _lastSavedMood = 'Not logged yet';

  @override
  void initState() {
    super.initState();
    _loadLastMood();
  }

  // Loads the last saved mood from SharedPreferences.
  Future<void> _loadLastMood() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? moodEntryString = prefs.getString('lastMoodEntry');
    if (moodEntryString != null) {
      final Map<String, dynamic> decodedMap = json.decode(moodEntryString);
      setState(() {
        _lastSavedMood = '${decodedMap['mood']}';
      });
    }
  }

  // Saves the mood to SharedPreferences and updates the UI.
  Future<void> _saveMoodEntry() async {
    if (_selectedMood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a mood to save.')),
      );
      return;
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final entry = {
      'mood': _selectedMood,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await prefs.setString('lastMoodEntry', json.encode(entry));

    setState(() {
      _lastSavedMood = _selectedMood!;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Your mood has been logged as $_selectedMood!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Mood Tracker',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE0C3FC), // A lighter purple at the top
              Color(0xFF8EC5FC), // A calming blue at the bottom
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'How are you feeling today?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                Expanded(
                  child: Center(
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 16.0,
                        mainAxisSpacing: 16.0,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: _moods.length,
                      itemBuilder: (context, index) {
                        final moodName = _moods.keys.elementAt(index);
                        final emoji = _moods[moodName]!;
                        final isSelected = _selectedMood == moodName;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedMood = moodName;
                            });
                          },
                          child: AnimatedScale(
                            scale: isSelected ? 1.1 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeIn,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.85),
                                borderRadius: BorderRadius.circular(20),
                                border: isSelected
                                    ? Border.all(color: Colors.purple.shade400, width: 3)
                                    : null,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    emoji,
                                    style: const TextStyle(fontSize: 48),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    moodName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  _lastSavedMood != 'Not logged yet'
                      ? 'Last mood logged: $_lastSavedMood'
                      : 'No mood logged yet.',
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _saveMoodEntry,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Mood'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.purple.shade400,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
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
