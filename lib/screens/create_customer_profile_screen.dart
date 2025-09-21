import 'package:flutter/material.dart';
import 'dart:ui';
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
    final bgAsset = 'assets/images/green_leaves_051.jpg';

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFA8E6CF), Color(0xFFBDF7E5)],
                ),
              ),
            ),
          ),

          Positioned(
            left: -40,
            top: -20,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(
                width: 180,
                height: 180,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF8EF0D0), Color(0xFF53C49E)],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: -50,
            bottom: 40,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(
                width: 220,
                height: 220,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF7BE3C3), Color(0xFF49B893)],
                  ),
                ),
              ),
            ),
          ),

          // Center image panel larger than the glass card
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenW = constraints.maxWidth;
                final screenH = constraints.maxHeight;
                const cardApproxW = 540.0;
                const cardApproxH = 640.0;
                final boxW = (screenW * 0.92).clamp(cardApproxW + 40.0, 820.0).toDouble();
                final boxH = (screenH * 0.76).clamp(cardApproxH + 40.0, 720.0).toDouble();
                return Center(
                  child: IgnorePointer(
                    ignoring: true,
                    child: Container(
                      width: boxW,
                      height: boxH,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        image: DecorationImage(image: AssetImage(bgAsset), fit: BoxFit.cover),
                        border: Border.all(color: Colors.white.withOpacity(0.5)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 30, offset: const Offset(0, 18)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Glass card with form
          Positioned.fill(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 540),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Colors.white.withOpacity(0.6), width: 1),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10)),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedBuilder(
                                animation: _textController,
                                builder: (context, child) {
                                  return Opacity(
                                    opacity: _textController.value,
                                    child: const Text(
                                      'SIGN UP',
                                      style: TextStyle(
                                        fontFamily: 'SFProDisplay',
                                        fontSize: 32,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF5F5F5F),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Create an account to continue!',
                                style: TextStyle(color: Color(0xFF666666), fontSize: 14),
                              ),
                              const SizedBox(height: 24),

                              AnimatedBuilder(
                                animation: _inputController,
                                builder: (context, child) {
                                  return Opacity(
                                    opacity: _inputController.value,
                                    child: Column(
                                      children: [
                                        _buildInputField('Name', nameController),
                                        _buildInputField('Location', locationController),
                                        _buildInputField('Phone Number', phoneController, type: TextInputType.phone),
                                        _buildInputField('Email', emailController, type: TextInputType.emailAddress),
                                        _buildInputField('Password', passwordController, obscure: true),
                                      ],
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 20),
                              AnimatedBuilder(
                                animation: _buttonController,
                                builder: (context, child) {
                                  return Opacity(
                                    opacity: _buttonController.value,
                                    child: SizedBox(
                                      width: double.infinity,
                                      height: 56,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF2F2F2F),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          elevation: 0,
                                        ),
                                        onPressed: _createCustomerProfile,
                                        child: const Text(
                                          'SIGN UP',
                                          style: TextStyle(fontFamily: 'SFProDisplay', fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: 1),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
