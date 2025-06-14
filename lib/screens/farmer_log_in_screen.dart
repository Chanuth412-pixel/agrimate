import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FarmerLogInScreen extends StatefulWidget {
  const FarmerLogInScreen({super.key});

  @override
  _FarmerLogInScreenState createState() => _FarmerLogInScreenState();
}

class _FarmerLogInScreenState extends State<FarmerLogInScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _logInFarmer() async {
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      final querySnapshot = await FirebaseFirestore.instance
          .collection('Farmers')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        if (doc['password'] == password) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('farmerId', doc.id);

          Navigator.pushReplacementNamed(context, '/farmerProfile');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Incorrect password.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email not found.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            left: 35,
            top: 63,
            child: const SizedBox(
              width: 305,
              height: 28,
              child: Text(
                'Farmer Profile',
                style: TextStyle(
                  color: Color(0xFF171717),
                  fontSize: 28,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w700,
                  height: 1.14,
                  letterSpacing: -0.80,
                ),
              ),
            ),
          ),
          Positioned(
            left: 35,
            top: 148,
            child: const SizedBox(
              width: 305,
              child: Text(
                'Let’s Sign You In',
                style: TextStyle(
                  color: Color(0xFF171717),
                  fontSize: 24,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w700,
                  height: 1.33,
                  letterSpacing: -0.80,
                ),
              ),
            ),
          ),
          Positioned(
            left: 35,
            top: 188,
            child: const SizedBox(
              width: 305,
              child: Opacity(
                opacity: 0.60,
                child: Text(
                  'Welcome back, you’ve been missed!',
                  style: TextStyle(
                    color: Color(0xFF171717),
                    fontSize: 14,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w500,
                    height: 1.71,
                    letterSpacing: -0.40,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 35,
            top: 252,
            child: buildInputField("Email", _emailController),
          ),
          Positioned(
            left: 35,
            top: 360,
            child: buildInputField("Password", _passwordController, obscure: true),
          ),
          Positioned(
            left: 35,
            top: 604,
            child: SizedBox(
              width: 305,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xCC02C697),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    _logInFarmer();
                  }
                },
                child: const Text(
                  'LOG IN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 40,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInputField(String label, TextEditingController controller, {bool obscure = false}) {
    return SizedBox(
      width: 305,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8F92A1),
              fontSize: 12,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w500,
              letterSpacing: -0.17,
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
              fontSize: 16,
              fontFamily: 'Roboto',
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
      ),
    );
  }
}
