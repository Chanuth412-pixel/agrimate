import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomerLogInScreen extends StatefulWidget {
  const CustomerLogInScreen({super.key});

  @override
  _CustomerLogInScreenState createState() => _CustomerLogInScreenState();
}

class _CustomerLogInScreenState extends State<CustomerLogInScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _logInCustomer() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      // 1. Authenticate with Firebase
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final uid = userCredential.user?.uid;

      if (uid == null) {
        throw Exception("Login failed: UID is null.");
      }

      // 2. Fetch customer profile from Firestore
      final docSnapshot =
          await FirebaseFirestore.instance.collection('customers').doc(uid).get();

      if (!docSnapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer profile not found.')),
        );
        return;
      }

      // 3. Save UID to SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('customerId', uid);

      // 4. Optionally: Save login location
      final position = await _getCurrentLocation();
      if (position != null) {
        await FirebaseFirestore.instance.collection('customers').doc(uid).update({
          'lastLoginLocation': GeoPoint(position.latitude, position.longitude),
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
      }

      // 5. Navigate to customer profile/dashboard
      Navigator.pushReplacementNamed(context, '/customerProfile');
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  Widget buildInputField(String label, TextEditingController controller,
      {bool obscure = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF8F92A1),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 10),
            border: InputBorder.none,
          ),
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 16,
            color: Colors.black,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your $label';
            }
            return null;
          },
        ),
        const Divider(
          color: Color(0xFF8F92A1),
          thickness: 1,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // White Background
      body: SizedBox(
        width: 375,
        height: 812,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 35),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Customer Login',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF171717),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Please sign in to continue.',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF171717),
                      ),
                    ),
                    const SizedBox(height: 40),
                    buildInputField("Email", _emailController),
                    const SizedBox(height: 20),
                    buildInputField("Password", _passwordController, obscure: true),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF14DAE2), // Button Color
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onPressed: () {
                          if (_formKey.currentState?.validate() ?? false) {
                            _logInCustomer();
                          }
                        },
                        child: const Text(
                          'LOG IN',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: const Color(0xFF14DAE2),
                          fontFamily: 'Roboto',
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Don\'t have an account?',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/createAccount');
                          },
                          child: const Text(
                            'Sign up',
                            style: TextStyle(
                              color: Color(0xFF14DAE2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
