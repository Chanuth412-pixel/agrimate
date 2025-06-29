import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateCustomerProfileScreen extends StatefulWidget {
  const CreateCustomerProfileScreen({super.key});

  @override
  _CreateCustomerProfileScreenState createState() =>
      _CreateCustomerProfileScreenState();
}

class _CreateCustomerProfileScreenState extends State<CreateCustomerProfileScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final locationController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // Animation controllers
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _inputController;
  late AnimationController _buttonController;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _inputController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    // Start animations
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _textController.forward();
    });
    Future.delayed(const Duration(seconds: 1), () {
      _inputController.forward();
    });
    Future.delayed(const Duration(seconds: 1), () {
      _buttonController.forward();
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _inputController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  // Method to create customer profile
  Future<void> _createCustomerProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final name = nameController.text.trim();
    final location = locationController.text.trim();
    final phone = phoneController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    try {
      // Step 1: Create user with FirebaseAuth
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final uid = userCredential.user?.uid;

      // Step 2: Save customer details in Firestore
      await FirebaseFirestore.instance.collection('customers').doc(uid).set({
        'name': name,
        'location': location,
        'phone': phone,
        'email': email,
        'uid': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer profile created successfully')),
      );

      // Clear form inputs after successful profile creation
      _clearForm();
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Auth error: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // Method to clear the form inputs
  void _clearForm() {
    nameController.clear();
    locationController.clear();
    phoneController.clear();
    emailController.clear();
    passwordController.clear();
  }

  // Method to build form input fields
  Widget _buildInputField(String label, TextEditingController controller,
      {bool obscure = false, TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8F92A1),
              fontSize: 12,
              fontFamily: 'DM Sans',
              fontWeight: FontWeight.w500,
              letterSpacing: -0.17,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 44,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFF02C697),
                  width: 1,
                  style: BorderStyle.solid,
                ),
              ),
            ),
            child: TextFormField(
              controller: controller,
              obscureText: obscure,
              keyboardType: type,
              validator: (val) =>
                  val == null || val.isEmpty ? 'Enter $label' : null,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.only(bottom: 4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Container(
          width: 375,
          height: 812,
          decoration: const BoxDecoration(color: Colors.white),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Customer Profile',
                        style: TextStyle(
                          color: Color(0xFF171717),
                          fontSize: 28,
                          fontFamily: 'DM Sans',
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.80,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  const Opacity(
                    opacity: 0.20,
                    child: Divider(color: Color(0xFF8F92A1), thickness: 1),
                  ),
                  const SizedBox(height: 34),
                  const Text(
                    'Getting Started',
                    style: TextStyle(
                      color: Color(0xFF171717),
                      fontSize: 24,
                      fontFamily: 'DM Sans',
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.80,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create an account to continue!',
                    style: TextStyle(
                      color: Color(0xFF171717),
                      fontSize: 14,
                      fontFamily: 'DM Sans',
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.40,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Logo Animation
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _logoController.value,
                        child: Center(
                          child: SizedBox(
                            width: 175,
                            height: 175,
                            child: Image.asset('images/logo.png'), // Replace with your logo path
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Input Fields with Fade-in Animation
                  AnimatedBuilder(
                    animation: _inputController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _inputController.value,
                        child: Column(
                          children: [
                            _buildInputField('Name', nameController),
                            _buildInputField('Location', locationController),
                            _buildInputField('Phone Number', phoneController,
                                type: TextInputType.phone),
                            _buildInputField('Email', emailController,
                                type: TextInputType.emailAddress),
                            _buildInputField('Password', passwordController,
                                obscure: true),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  // Sign-up Button with Fade-in Animation
                  AnimatedBuilder(
                    animation: _buttonController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _buttonController.value,
                        child: SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xCC02C697),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            onPressed: _createCustomerProfile,
                            child: const Text(
                              'SIGN UP',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontFamily: 'DM Sans',
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
