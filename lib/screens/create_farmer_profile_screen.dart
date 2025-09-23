import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../firestore_service.dart'; // Ensure this path matches your structure
import '../l10n/app_localizations.dart';
import '../widgets/glassy_back_button.dart';

class CreateFarmerProfileScreen extends StatefulWidget {
  const CreateFarmerProfileScreen({super.key});

  @override
  _CreateFarmerProfileScreenState createState() =>
      _CreateFarmerProfileScreenState();
}

class _CreateFarmerProfileScreenState extends State<CreateFarmerProfileScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();

  final nameController = TextEditingController();
  final locationController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

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

  // Method to create farmer profile
  Future<void> _createFarmerProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final name = nameController.text.trim();
    final location = locationController.text.trim().isEmpty ? 'Not specified' : locationController.text.trim();
    final phone = phoneController.text.trim().isEmpty ? 'Not specified' : phoneController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    // Check if passwords match
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.passwordsDoNotMatch)),
      );
      return;
    }

    try {
      // Get current location
      final position = await _getCurrentLocation();

      // Create user with Firebase Authentication
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final uid = userCredential.user?.uid;

      // Save farmer details in Firestore
      await FirebaseFirestore.instance.collection('farmers').doc(uid).set({
        'name': name,
        'location': location,
        'phone': phone,
        'email': email,
        'uid': uid,
        'createdAt': FieldValue.serverTimestamp(),
        'position': GeoPoint(position.latitude, position.longitude), // Save GPS location
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.profileCreatedSuccessfully)),
      );

      // Clear form inputs after successful profile creation
      _clearForm();
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.authError}: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.errorOccurred}: $e')),
      );
    }
  }

  // Method to get the current location of the user
  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Location services are disabled.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied.');
    }

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  // Method to clear the form inputs
  void _clearForm() {
    nameController.clear();
    locationController.clear();
    phoneController.clear();
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
  }

  // Method to build form input fields
  Widget _buildInputField(String label, TextEditingController controller,
      {bool obscure = false, TextInputType type = TextInputType.text, 
      IconData? icon, Widget? suffixIcon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: type,
          validator: (val) =>
              val == null || val.isEmpty ? 'Enter $label' : null,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          decoration: InputDecoration(
            prefixIcon: icon != null 
              ? Icon(icon, color: Colors.grey[600], size: 20)
              : null,
            suffixIcon: suffixIcon,
            hintText: label,
            hintStyle: TextStyle(
              color: Colors.grey[500],
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Light green gradient background
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFdfffd6), Color(0xFFc0f7b0)],
                ),
              ),
            ),
          ),

          // Centered white rounded container/card with soft shadow
          Positioned.fill(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Title: "Welcome Farmer!" (bold green)
                          AnimatedBuilder(
                            animation: _textController,
                            builder: (context, child) {
                              return Opacity(
                                opacity: _textController.value,
                                child: Text(
                                  AppLocalizations.of(context)!.welcomeFarmer,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          // Subtitle: "Let's grow together" (gray)
                          Text(
                            AppLocalizations.of(context)!.letsGrowTogether,
                            style: const TextStyle(
                              color: Color(0xFF666666), 
                              fontSize: 16
                            ),
                          ),
                          const SizedBox(height: 32),

                          AnimatedBuilder(
                            animation: _inputController,
                            builder: (context, child) {
                              return Opacity(
                                opacity: _inputController.value,
                                child: Column(
                                  children: [
                                    // Full Name (person icon)
                                    _buildInputField(
                                      AppLocalizations.of(context)!.fullName, 
                                      nameController,
                                      icon: Icons.person_outline,
                                    ),
                                    // Email/Phone (mail icon) - using email field for simplicity
                                    _buildInputField(
                                      AppLocalizations.of(context)!.emailPhone, 
                                      emailController, 
                                      type: TextInputType.emailAddress,
                                      icon: Icons.mail_outline,
                                    ),
                                    // Password (lock icon + show/hide toggle)
                                    _buildInputField(
                                      AppLocalizations.of(context)!.password, 
                                      passwordController, 
                                      obscure: _obscurePassword,
                                      icon: Icons.lock_outline,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                          color: Colors.grey[600],
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword = !_obscurePassword;
                                          });
                                        },
                                      ),
                                    ),
                                    // Confirm Password (lock icon + show/hide toggle)
                                    _buildInputField(
                                      AppLocalizations.of(context)!.confirmPassword, 
                                      confirmPasswordController, 
                                      obscure: _obscureConfirmPassword,
                                      icon: Icons.lock_outline,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                          color: Colors.grey[600],
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscureConfirmPassword = !_obscureConfirmPassword;
                                          });
                                        },
                                      ),
                                    ),
                                    // Hidden fields for existing functionality
                                    Visibility(
                                      visible: false,
                                      child: Column(
                                        children: [
                                          _buildInputField(AppLocalizations.of(context)!.location, locationController),
                                          _buildInputField(AppLocalizations.of(context)!.phoneNumber, phoneController, type: TextInputType.phone),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 24),
                          // Button: "Create Profile" (dark green, white text)
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
                                      backgroundColor: const Color(0xFF2E7D32),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12)
                                      ),
                                      elevation: 0,
                                    ),
                                    onPressed: _createFarmerProfile,
                                    child: Text(
                                      AppLocalizations.of(context)!.createProfile,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600, 
                                        fontSize: 16
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          // Footer: "Already have an account? Log in"
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.alreadyHaveAnAccount,
                                style: const TextStyle(color: Color(0xFF666666)),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pushReplacementNamed(context, '/farmerLogIn'),
                                child: Text(
                                  AppLocalizations.of(context)!.logIn,
                                  style: const TextStyle(
                                    color: Color(0xFF2E7D32),
                                    fontWeight: FontWeight.w600,
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
          ),

          // Back button
          Positioned(
            top: 40,
            left: 20,
            child: SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/farmerLogIn'),
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF2E7D32)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
