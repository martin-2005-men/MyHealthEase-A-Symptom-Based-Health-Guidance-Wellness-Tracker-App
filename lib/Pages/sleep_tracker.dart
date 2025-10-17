// This page allows the user to manually log sleep entries (bedtime and waketime).
// It stores the data persistently using SharedPreferences and displays a list of past entries.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// SleepTrackerPage is a StatefulWidget to manage the form state and sleep data.
class SleepTrackerPage extends StatefulWidget {
  const SleepTrackerPage({super.key});

  @override
  State<SleepTrackerPage> createState() => _SleepTrackerPageState();
}

class _SleepTrackerPageState extends State<SleepTrackerPage> {
  // State variables for the sleep tracker form.
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _bedtime;
  TimeOfDay? _waketime;
  final List<Map<String, dynamic>> _sleepEntries = [];

  @override
  void initState() {
    super.initState();
    // Load existing sleep entries from local storage when the page is initialized.
    _loadSleepEntries();
  }

  // Asynchronously loads sleep data from SharedPreferences.
  Future<void> _loadSleepEntries() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? entriesString = prefs.getString('sleepEntries');
    if (entriesString != null) {
      // Decode the JSON string back into a list of maps.
      final List<dynamic> decodedList = json.decode(entriesString);
      setState(() {
        _sleepEntries.clear();
        _sleepEntries.addAll(decodedList.cast<Map<String, dynamic>>());
      });
    }
  }

  // Asynchronously saves the current list of sleep entries to SharedPreferences.
  Future<void> _saveSleepEntries() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // Encode the list of maps into a JSON string for storage.
    final String encodedList = json.encode(_sleepEntries);
    await prefs.setString('sleepEntries', encodedList);
  }

  // Displays a date picker for selecting the sleep date.
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Displays a time picker for selecting bedtime or waketime.
  Future<void> _selectTime(bool isBedtime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isBedtime) {
          _bedtime = picked;
        } else {
          _waketime = picked;
        }
      });
    }
  }

  // Adds a new sleep entry and saves it to storage.
  void _addSleepEntry() {
    if (_bedtime != null && _waketime != null) {
      final DateTime bedTimeFull = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _bedtime!.hour,
          _bedtime!.minute);
      final DateTime wakeTimeFull = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _waketime!.hour,
          _waketime!.minute);

      // Handle cases where the waketime is on the next day.
      final Duration duration = wakeTimeFull.difference(bedTimeFull);
      if (duration.isNegative) {
        final nextDayWakeTime = wakeTimeFull.add(const Duration(days: 1));
        final nextDayDuration = nextDayWakeTime.difference(bedTimeFull);
        _addEntry(nextDayDuration.inMinutes.toDouble());
      } else {
        _addEntry(duration.inMinutes.toDouble());
      }
    }
  }

  // Helper function to add a new entry to the list and save.
  void _addEntry(double totalMinutes) {
    setState(() {
      _sleepEntries.add({
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'bedtime': _bedtime!.format(context),
        'waketime': _waketime!.format(context),
        'duration_minutes': totalMinutes,
      });
      // Sort entries to show the most recent one first.
      _sleepEntries.sort((a, b) => b['date'].compareTo(a['date']));
      _saveSleepEntries();
    });

    // Reset input fields after saving for the next entry.
    setState(() {
      _bedtime = null;
      _waketime = null;
    });
  }

  // Deletes a sleep entry from the list and storage.
  void _deleteSleepEntry(int index) {
    setState(() {
      _sleepEntries.removeAt(index);
      _saveSleepEntries();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual Sleep Tracker'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Date: ${DateFormat('MMMM d, yyyy').format(_selectedDate)}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: _selectDate,
                          child: const Text('Change Date'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Bedtime', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              ElevatedButton(
                                onPressed: () => _selectTime(true),
                                child: Text(_bedtime != null ? _bedtime!.format(context) : 'Select Bedtime'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Waketime', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              ElevatedButton(
                                onPressed: () => _selectTime(false),
                                child: Text(_waketime != null ? _waketime!.format(context) : 'Select Waketime'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _addSleepEntry,
                        icon: const Icon(Icons.add),
                        label: const Text('Log Sleep'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your Sleep Log',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _sleepEntries.isEmpty
                  ? Center(
                child: Text(
                  'No sleep entries yet. Log one above!',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              )
                  : ListView.builder(
                itemCount: _sleepEntries.length,
                itemBuilder: (context, index) {
                  final entry = _sleepEntries[index];
                  final double durationMinutes = entry['duration_minutes'];
                  final String durationString =
                      '${(durationMinutes / 60).floor()}h ${(durationMinutes % 60).round()}m';
                  return Dismissible(
                    key: Key(entry['date']),
                    onDismissed: (direction) {
                      _deleteSleepEntry(index);
                    },
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20.0),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    child: Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: const Icon(Icons.bedtime, color: Colors.blue),
                        title: Text(
                          'Date: ${entry['date']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Slept: ${entry['bedtime']} - ${entry['waketime']}\nTotal: $durationString',
                        ),
                        isThreeLine: true,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
