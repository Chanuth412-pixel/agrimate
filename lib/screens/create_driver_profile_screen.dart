import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../main.dart' show AppLocaleProvider;
import '../widgets/glassy_back_button.dart';

class CreateDriverProfileScreen extends StatefulWidget {
  const CreateDriverProfileScreen({super.key});

  @override
  _CreateDriverProfileScreenState createState() => _CreateDriverProfileScreenState();
}

class _CreateDriverProfileScreenState extends State<CreateDriverProfileScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool _isLoading = false;
  late AnimationController _textController;
  late AnimationController _inputController;
  late AnimationController _buttonController;

  @override
  void initState() {
    super.initState();
    _textController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
    _inputController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _buttonController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    Future.delayed(const Duration(milliseconds: 400), () => _inputController.forward());
    Future.delayed(const Duration(milliseconds: 900), () => _buttonController.forward());
  }

  @override
  void dispose() {
    _textController.dispose();
    _inputController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  Future<void> _signUpDriver() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Check if passwords match
    if (_passwordController.text.trim() != _confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.passwordsDoNotMatch)),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      // 1. Create user in Firebase Auth
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final uid = userCredential.user?.uid;
      if (uid == null) throw Exception('Failed to create user.');

      // 2. Create driver profile in Firestore
      await FirebaseFirestore.instance.collection('drivers').doc(uid).set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty ? 'Not specified' : _phoneController.text.trim(),
        'location': _locationController.text.trim().isEmpty ? 'Not specified' : _locationController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Save UID to SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('driverId', uid);

      // 4. Navigate to driver profile/dashboard
      Navigator.pushReplacementNamed(context, '/driverProfile');
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.signUpFailed}: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.errorOccurred}: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget buildInputField(String label, TextEditingController controller, 
      {bool obscure = false, TextInputType? keyboardType, IconData? icon, Widget? suffixIcon}) {
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
          keyboardType: keyboardType,
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
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter $label';
            }
            return null;
          },
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
                          // Title: "Welcome Driver!" (bold green)
                          AnimatedBuilder(
                            animation: _textController,
                            builder: (context, child) {
                              return Opacity(
                                opacity: _textController.value,
                                child: Text(
                                  AppLocalizations.of(context)!.welcomeDriver,
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
                                    buildInputField(
                                      AppLocalizations.of(context)!.fullName, 
                                      _nameController,
                                      icon: Icons.person_outline,
                                    ),
                                    // Email/Phone (mail icon) - using email field for simplicity
                                    buildInputField(
                                      AppLocalizations.of(context)!.emailPhone,
                                      _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      icon: Icons.mail_outline,
                                    ),
                                    // Location
                                    buildInputField(
                                      AppLocalizations.of(context)!.location,
                                      _locationController,
                                      icon: Icons.location_on_outlined,
                                    ),
                                    // Phone Number
                                    buildInputField(
                                      AppLocalizations.of(context)!.phoneNumber,
                                      _phoneController,
                                      keyboardType: TextInputType.phone,
                                      icon: Icons.phone_outlined,
                                    ),
                                    // Password (lock icon + show/hide toggle)
                                    buildInputField(
                                      AppLocalizations.of(context)!.password, 
                                      _passwordController, 
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
                                    buildInputField(
                                      AppLocalizations.of(context)!.confirmPassword, 
                                      _confirmPasswordController, 
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
                                    // (Previously hidden phone/location fields now visible above)
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
                                    onPressed: _isLoading ? null : _signUpDriver,
                                    child: _isLoading
                                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                        : Text(
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
                                onTap: () => Navigator.pushNamed(context, '/driverLogIn'),
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
                  onPressed: () => Navigator.pushReplacementNamed(context, '/driverLogIn'),
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