  import 'package:flutter/material.dart';
  import 'package:http/http.dart' as http;
  import 'dart:convert';
  import 'package:flutter_map/flutter_map.dart';
  import 'package:latlong2/latlong.dart';
  import 'package:geolocator/geolocator.dart';
  import 'package:permission_handler/permission_handler.dart';
  import 'package:url_launcher/url_launcher.dart';

  // ⚠️ IMPORTANT: Set your Flask server IP here (e.g., http://192.168.0.195:5000)
  // For Android Emulator, use 'http://10.0.2.2:5000'
  const String _serverUrl = "http://10.0.2.2:5000";

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
  }

  class Poi {
    final LatLng location;
    final String name;
    final String? phone; // Field for phone number

    Poi(this.location, this.name, this.phone);
  }

  // ==========================================================
  // 1. SYMPTOM CHECKER PAGE (UI for Input and Prediction)
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
            setState(() {
              _topPrediction = topResult;
              _message = "Prediction complete: ${topResult.healthCondition}";
            });
            // *** DO NOT NAVIGATE AUTOMATICALLY HERE ***
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

    // *** NEW FUNCTION: Triggers navigation to the map finder ***
    void _findNearbySpecialist() {
      if (_topPrediction != null) {
        // Navigate to the map view, passing the required specialist name
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => SpecialistFinderMap(
            predictedSpecialist: _topPrediction!.doctorSpecialist,
          ),
        ));
      }
    }

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

              // *** NEW DOCTOR RECOMMENDATION BUTTON ***
              ElevatedButton.icon(
                onPressed: _findNearbySpecialist,
                icon: const Icon(Icons.location_on, size: 24),
                label: const Text("Find Specialist Nearby", style: TextStyle(fontSize: 16)),
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
  // 2. SPECIALIST FINDER MAP (UI for Location and POI Search)
  // ==========================================================

  class SpecialistFinderMap extends StatefulWidget {
    final String predictedSpecialist;

    const SpecialistFinderMap({super.key, required this.predictedSpecialist});

    @override
    State<SpecialistFinderMap> createState() => _SpecialistFinderMapState();
  }

  class _SpecialistFinderMapState extends State<SpecialistFinderMap> {
    LatLng _userLocation = const LatLng(37.7749, -122.4194); // Default to SF
    final MapController _mapController = MapController();
    List<Poi> _nearbyPois = [];
    bool _isLoading = true;
    String _statusMessage = 'Fetching location...';

    final double _searchRadiusMeters = 5000; // Search within 5km

    @override
    void initState() {
      super.initState();
      _determinePositionAndSearch();
    }

    // --- LOCATION PERMISSION AND FETCHING ---
    Future<void> _determinePositionAndSearch() async {
      // 1. Check/Request Permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          setState(() {
            _statusMessage = 'Location permissions denied. Showing default location.';
            _isLoading = false;
          });
          _fetchNearbyPois(_userLocation, widget.predictedSpecialist); // Search at default location
          return;
        }
      }

      // 2. Get Current Position
      try {
        setState(() { _statusMessage = 'Getting current location...'; });
        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        _userLocation = LatLng(position.latitude, position.longitude);

        // Move map to user location once coordinates are retrieved
        _mapController.move(_userLocation, 13.0);

        // 3. Search for Specialists
        setState(() { _statusMessage = 'Searching for ${widget.predictedSpecialist} nearby...'; });
        await _fetchNearbyPois(_userLocation, widget.predictedSpecialist);

      } catch (e) {
        setState(() {
          _statusMessage = 'Error getting location: $e. Searching at default location.';
        });
        _fetchNearbyPois(_userLocation, widget.predictedSpecialist); // Search at default location
      } finally {
        setState(() { _isLoading = false; });
      }
    }

    // --- OVERPASS API QUERY FUNCTION ---
    String _buildOverpassQuery(LatLng center, double radius, String specialist) {
      // We simplify the specialist name for the query (e.g., 'Orthopedist/Hand Surgeon' -> 'orthopedist')
      final queryTag = specialist.toLowerCase().split('/').first.trim();

      // Query looks for:
      // 1. Facilities tagged as hospital/doctors/clinic
      // 2. Facilities whose name contains the simplified specialist type
      return '''
        [out:json];
        (
          node(around:${radius}, ${center.latitude}, ${center.longitude})[amenity~"hospital|doctors|clinic"];
          node(around:${radius}, ${center.latitude}, ${center.longitude})[name~"$queryTag",i];
          way(around:${radius}, ${center.latitude}, ${center.longitude})[amenity~"hospital|doctors|clinic"];
        );
        out tags center;
      ''';
    }

    Future<void> _fetchNearbyPois(LatLng center, String specialist) async {
      final query = _buildOverpassQuery(center, _searchRadiusMeters, specialist);
      final url = Uri.parse('https://overpass-api.de/api/interpreter');

      try {
        final response = await http.post(url, body: {'data': query});

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List<Poi> fetchedPois = [];

          for (var element in data['elements']) {
            final lat = element['lat'] ?? element['center']?['lat'];
            final lon = element['lon'] ?? element['center']?['lon'];

            if (lat != null && lon != null) {
              final name = element['tags']?['name'] ?? 'Medical Facility';
              // Extract phone number
              final phone = element['tags']?['phone'] ?? element['tags']?['contact:phone'];

              fetchedPois.add(Poi(LatLng(lat, lon), name, phone));
            }
          }

          setState(() {
            _nearbyPois = fetchedPois.toSet().toList(); // Use Set to remove duplicates
            _statusMessage = '${_nearbyPois.length} ${widget.predictedSpecialist} facilities found near you.';
          });

        } else {
          setState(() { _statusMessage = 'Overpass API request failed (${response.statusCode}).'; });
        }
      } catch (e) {
        setState(() { _statusMessage = 'Network error during POI fetch: $e'; });
      }
    }

    // Function to launch the phone dialer
    Future<void> _launchPhoneDialer(String number) async {
      final uri = Uri(scheme: 'tel', path: number);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone dialer.')),
        );
      }
    }

    // Function to build POI Markers with Popups
    List<Marker> _buildPoiMarkers() {
      return [
        // 1. User Location Marker (Always show)
        Marker(
          point: _userLocation,
          width: 60,
          height: 60,
          child: const Icon(Icons.my_location, color: Colors.red, size: 35),
        ),
        // 2. Specialist Markers
        ..._nearbyPois.map((poi) {
          return Marker(
            point: poi.location,
            width: 200,
            height: 50,
            child: GestureDetector(
              onTap: () {
                _showPoiDetails(poi);
              },
              child: Column(
                children: [
                  const Icon(Icons.local_hospital, color: Colors.blue, size: 30),
                  Text(
                    poi.name,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ];
    }

    // --- DETAILS MODAL (With Phone Number) ---
    void _showPoiDetails(Poi poi) {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(poi.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
                const SizedBox(height: 10),
                Text('Predicted Specialist: ${widget.predictedSpecialist}', style: const TextStyle(fontSize: 16)),
                const Divider(),
                if (poi.phone != null && poi.phone!.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.phone, color: Colors.green),
                    title: Text(poi.phone!),
                    subtitle: const Text('Tap to Call'),
                    onTap: () {
                      Navigator.pop(context); // Close modal
                      _launchPhoneDialer(poi.phone!);
                    },
                  )
                else
                  const ListTile(
                    leading: Icon(Icons.phone_disabled, color: Colors.red),
                    title: Text('Phone number not available in OSM data.'),
                  ),
                const SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Nearby ${widget.predictedSpecialist}s',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: Colors.blue,
        ),
        body: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _userLocation,
                initialZoom: 13.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.specialistfinder',
                ),
                MarkerLayer(
                  markers: _buildPoiMarkers(),
                ),
              ],
            ),

            // Floating Status Card
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Card(
                color: Colors.white.withOpacity(0.9),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      _isLoading
                          ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.blue)
                          : Icon(_nearbyPois.isNotEmpty ? Icons.check_circle : Icons.warning, color: _nearbyPois.isNotEmpty ? Colors.green : Colors.orange),
                      const SizedBox(width: 10),
                      Expanded(child: Text(_statusMessage, style: const TextStyle(fontSize: 14))),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  void main() {
    runApp(const MaterialApp(
      home: SymptomCheckerPage(),
      debugShowCheckedModeBanner: false,
    ));
  }

