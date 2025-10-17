import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:healthease_app/Pages/login.dart'; // Assuming this path is correct

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  // State variables to hold the user data and the loading state.
  String _name = "Loading...";
  String _email = "Loading...";
  String _age = "Loading...";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  // NOTE: Logic is unchanged as requested
  Future<void> _fetchUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    // Using the secure path /artifacts/{appId}/users/{userId}/... for private data
    //final appId = typeof __app_id !== 'undefined' ? __app_id : 'default-app-id';

    if (user != null) {
    final uid = user.uid;
    // Using a simplified collection path for the example, but note that best practice
    // is to use the full secure path for multi-user apps.
    final docRef = FirebaseFirestore.instance.collection('USER').doc(uid);

    try {
    final snapshot = await docRef.get();
    if (snapshot.exists) {
    final data = snapshot.data() as Map<String, dynamic>;
    setState(() {
    _name = data['Name']?.toString() ?? 'Name not found';
    _email = data['Email']?.toString() ?? 'Email not found';
    _age = data['Age']?.toString() ?? 'Age not found';
    _isLoading = false;
    });
    } else {
    // Handle the case where the user document doesn't exist
    setState(() {
    _name = "User data not found.";
    _email = user.email ?? 'Email not found.';
    _age = "Not available.";
    _isLoading = false;
    });
    }
    } catch (e) {
    // Handle any errors during the data fetch
    setState(() {
    _isLoading = false;
    _name = "Error loading data.";
    _email = "Error loading data.";
    _age = "Error loading data.";
    });
    print("Error fetching profile data: $e");
    }
    } else {
    // Handle the case where no user is logged in
    setState(() {
    _isLoading = false;
    _name = "User not logged in.";
    _email = "User not logged in.";
    _age = "User not logged in.";
    });
    }
  }

  // Custom Widget for a cleaner, modern info tile
  Widget _ProfileInfoTile({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Defining a modern color palette
    const Color primaryColor = Color(0xFF4A148C); // Deep Purple
    const Color accentColor = Color(0xFF00BFA5); // Teal Accent

    return Scaffold(
      backgroundColor: Colors.grey.shade50, // Light background
      appBar: AppBar(
        title: const Text("User Profile", style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Modern Profile Header
          Container(
            padding: const EdgeInsets.only(top: 20, bottom: 30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: accentColor, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: primaryColor,
                      child: const Icon(Icons.person, size: 60, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _email,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Info tiles using the custom widget
          _ProfileInfoTile(
            icon: Icons.person_outline,
            title: "Full Name",
            value: _name,
            iconColor: primaryColor,
          ),
          _ProfileInfoTile(
            icon: Icons.calendar_month,
            title: "Age",
            value: _age,
            iconColor: accentColor,
          ),
          _ProfileInfoTile(
            icon: Icons.alternate_email,
            title: "Email Address",
            value: _email,
            iconColor: Colors.red.shade400,
          ),

          const SizedBox(height: 40),

          // Logout button (Modern style)
          ElevatedButton.icon(
            onPressed: () async {
              // LOGIC UNCHANGED
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                      (Route<dynamic> route) => false,
                );
              }
            },
            icon: const Icon(Icons.logout, size: 24),
            label: const Text("Secure Logout", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 5,
            ),
          ),
        ],
      ),
    );
  }
}
