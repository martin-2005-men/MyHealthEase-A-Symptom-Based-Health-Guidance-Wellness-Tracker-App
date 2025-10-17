import 'package:flutter/material.dart';
import 'package:healthease_app/Pages/SignUpPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:healthease_app/Pages/dashboard.dart';
import 'package:healthease_app/Pages/profile.dart';
import 'package:healthease_app/authentication/auth.dart';
import 'HomePage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}
final GlobalKey<FormState> _key = GlobalKey<FormState>();

TextEditingController _email = TextEditingController();
TextEditingController _password = TextEditingController();

Future<void> login(String email, String password, BuildContext context) async {
  try {
    UserCredential userCredential = await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);

    //print("User logged in: ${userCredential.user?.uid}");

    // Navigate to HomePage after successful login
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
    );
  } on FirebaseAuthException catch (e) {
    if (e.code == 'user-not-found') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("User not found")));
    } else if (e.code == 'wrong-password') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Wrong password provided.")));
      print("Wrong password provided.");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Invalid email or password")));
      //print("Login error: ${e.message}");
    }
  }
}

// Function to send a password reset email
Future<void> forgotPassword(String email, BuildContext context) async {
  try {
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter your email address.")),
      );
      return;
    }

    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Password reset link sent to your email.")),
    );
  } on FirebaseAuthException catch (e) {
    if (e.code == 'user-not-found') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No user found with that email.")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: Could not send reset email.")),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("An unexpected error occurred.")),
    );
    print("Error sending password reset email: $e");
  }
}

class _LoginPageState extends State<LoginPage> {
  @override
  build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: Center(
          child: Column(
            children: [
              SizedBox(height: 10),
              Image(
                image: AssetImage('assets/imgs/logo.png'),
                width: double.maxFinite,
                height: 200,
              ),
              Center(
                child: Text(
                  "Welcome Back!",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 21),
              SingleChildScrollView(
                child: Container(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 30, right: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 20),
                        Text(
                          "Login in",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          "Email",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Form(
                          key: _key,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                              SizedBox(height: 20),
                              Text(
                                "Password",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextFormField(
                                controller: _password,
                                validator: (value) {
                                  if (value!.isEmpty) {
                                    return "Please Enter Password";
                                  }
                                },
                                obscureText: true,
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
                        SizedBox(height: 20),
                        GestureDetector(
                          onTap: () {
                            // Call the new forgot password function
                            forgotPassword(_email.text, context);
                          },
                          child: Text(
                            "Forget Password?",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: 30),
                        GestureDetector(
                          onTap: () {
                            if (_key.currentState!.validate()) {
                              login(_email.text, _password.text, context);
                            }
                          },
                          child: Container(
                            child: Center(
                              child: Text(
                                "Login in",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 25,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            height: 70,
                            width: 370,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white),
                            ),
                          ),
                        ),

                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: Text(
                                "Don't have an account?",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SignUpPage(),
                                  ),
                                );
                              },
                              child: Text(
                                " Sign Up",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
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
                        SizedBox(height: 20),
                        Row(
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

                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  height: 654,
                  width: double.maxFinite,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        offset: Offset(0, -10),
                        color: Colors.black.withValues(alpha: 0.3),
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
              ),
            ],
          ),
        ),
        );
    }
}
