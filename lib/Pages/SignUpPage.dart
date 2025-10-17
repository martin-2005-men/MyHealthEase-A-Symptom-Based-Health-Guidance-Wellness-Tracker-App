import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:healthease_app/Pages/HomePage.dart';
import 'package:healthease_app/database/operations.dart';
import 'login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpPage extends StatelessWidget {
  SignUpPage({super.key});

  TextEditingController _name = TextEditingController();
  TextEditingController _age = TextEditingController();
  TextEditingController _email = TextEditingController();
  TextEditingController _pass = TextEditingController();
  final GlobalKey<FormState> _key = GlobalKey<FormState>();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _handleSignup(BuildContext context) async {
    if (_key.currentState!.validate()) {
      try {
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: _email.text.trim(),
          password: _pass.text.trim(),
        );

        if (userCredential.user != null) {
          final userUid = userCredential.user!.uid;

          try {
            // Save user data to Firestore using the user's UID as the document ID
            await FirebaseFirestore.instance.collection("USER").doc(userUid).set({
              "Name": _name.text.trim(),
              "Age": _age.text.trim(),
              "Email": _email.text.trim(),
              "createdAt": FieldValue.serverTimestamp(),
            });

            // Show a success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Account Created Successfully!"),
                backgroundColor: Colors.green,
              ),
            );

            // Navigate to the home page after a successful sign-up and data save
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomePage(),
              ),
            );
          } catch (firestoreError) {
            // Catch and handle errors specifically from the Firestore write
            print("Firestore Error: $firestoreError");
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Account created, but failed to save data. Please log in."),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } on FirebaseAuthException catch (error) {
        // Handle specific Firebase authentication errors
        String message = 'An error occurred. Please try again.';
        if (error.code == 'weak-password') {
          message = 'The password provided is too weak.';
        } else if (error.code == 'email-already-in-use') {
          message = 'An account already exists for that email.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
      } catch (e) {
        // Handle any other errors
        print("ERROR: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("An unknown error occurred."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  @override
  build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // allow moving when keyboard opens
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 5),
              Image(
                image: AssetImage('assets/imgs/logo.png'),
                width: double.maxFinite,
                height: 160,
              ),
              Container(
                child: Padding(
                  padding: const EdgeInsets.only(left: 30, right: 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 10),
                      Text(
                        "Sign Up",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Name",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Form(
                        key: _key,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 10),
                            TextFormField(
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Please enter your Name";
                                }
                                if (value.length < 2) {
                                  return "Name must be at least 2 characters";
                                }
                                if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(value)) {
                                  return "Name can only contain letters";
                                }
                                return null;
                              },
                              controller: _name,
                              decoration: InputDecoration(
                                hintText: "Enter your Name",
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.grey.withValues(alpha: 0.5),
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Age",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextFormField(
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Please enter your Age";
                                }
                                final age = int.tryParse(value);
                                if (age == null) {
                                  return "Please enter a valid number";
                                }
                                if (age <= 0) {
                                  return "Age must be greater than 0";
                                }
                                if (age > 120) {
                                  return "Please enter a realistic age";
                                }
                                return null;
                              },
                              controller: _age,
                              decoration: InputDecoration(
                                hintText: "Enter your Age",
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.grey.withValues(alpha: 0.5),
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 10),

                            Text(
                              "Email",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 10),
                            TextFormField(
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return "Please enter your Email";
                                } else if (!value.contains("@gmail.com")) {
                                  return "Enter Valid Email id";
                                }
                                return null;
                              },
                              controller: _email,
                              decoration: InputDecoration(
                                hintText: "Enter your email id",
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.grey.withValues(alpha: 0.5),
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Password",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextFormField(
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Please enter your Password";
                                }
                                if (value.length < 8) {
                                  return "Password must be at least 8 characters long";
                                }
                                return null;
                              },
                              controller: _pass,
                              decoration: InputDecoration(
                                hintText: "Enter your password",
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.grey.withValues(alpha: 0.5),
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                      GestureDetector(
                        onTap: () {
                          _handleSignup(context);
                        },
                        child: Container(
                          child: Center(
                            child: Text(
                              "Sign Up",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          height: 45,
                          width: 370,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white),
                          ),
                        ),
                      ),
                      SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Text(
                              "Already have an account!",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LoginPage(),
                                ),
                              );
                            },
                            child: Text(
                              "  Login in ",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 2,
                            width: 150,
                            color: Colors.grey.withValues(alpha: 0.6),
                          ),
                          Text(
                            "OR",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            height: 2,
                            width: 150,
                            color: Colors.grey.withValues(alpha: 0.6),
                          ),
                        ],
                      ),
                      SizedBox(height: 5),
                      GestureDetector(
                        onTap: ()  {
                          //
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                height: 50,
                                width: 300,
                                color: Colors.white,
                                child: Row(
                                  children: [
                                    Container(
                                      height: 30,
                                      width: 50,
                                      decoration: BoxDecoration(),
                                      child: Image(
                                        image: AssetImage(
                                          'assets/imgs/google.png',
                                        ),
                                        height: 5,
                                        width: 6,
                                      ),
                                    ),
                                    SizedBox(width: 50),
                                    Center(
                                      child: Text(
                                        "Sign in with Google",
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                width: double.maxFinite,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      offset: Offset(0, -10),
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 40,
                    ),
                  ],
                  color: Colors.blue,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
