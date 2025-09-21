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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

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
        'phone': _phoneController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Save UID to SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('driverId', uid);

      // 4. Navigate to driver profile/dashboard
      Navigator.pushReplacementNamed(context, '/driverProfile');
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign up failed: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget buildInputField(String label, TextEditingController controller, {bool obscure = false, TextInputType? keyboardType}) {
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
          keyboardType: keyboardType,
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
              return AppLocalizations.of(context)!.pleaseEnterField(label);
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
                  gradient: LinearGradient(colors: [Color(0xFF8EF0D0), Color(0xFF53C49E)]),
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
                  gradient: LinearGradient(colors: [Color(0xFF7BE3C3), Color(0xFF49B893)]),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final h = constraints.maxHeight;
                const cardW = 540.0;
                const cardH = 640.0;
                final boxW = (w * 0.92).clamp(cardW + 40.0, 820.0).toDouble();
                final boxH = (h * 0.76).clamp(cardH + 40.0, 720.0).toDouble();
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
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 30, offset: const Offset(0, 18))],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
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
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10))],
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
                                      'CREATE DRIVER PROFILE',
                                      style: TextStyle(
                                        fontFamily: 'SFProDisplay',
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF5F5F5F),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                              const Text('Enter your details to get started', style: TextStyle(color: Color(0xFF666666), fontSize: 14)),
                              const SizedBox(height: 24),
                              AnimatedBuilder(
                                animation: _inputController,
                                builder: (context, child) {
                                  return Opacity(
                                    opacity: _inputController.value,
                                    child: Column(
                                      children: [
                                        buildInputField("Name", _nameController),
                                        buildInputField("Email", _emailController, keyboardType: TextInputType.emailAddress),
                                        buildInputField("Phone", _phoneController, keyboardType: TextInputType.phone),
                                        buildInputField("Password", _passwordController, obscure: true),
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
                                        onPressed: _isLoading ? null : _signUpDriver,
                                        child: _isLoading
                                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                            : const Text(
                                                'SIGN UP',
                                                style: TextStyle(
                                                  fontFamily: 'SFProDisplay',
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 16,
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                  Text(AppLocalizations.of(context)!.alreadyHaveAccount,
                                      style: const TextStyle(color: Colors.grey)),
                                  TextButton(
                                    onPressed: () => Navigator.pushNamed(context, '/driverLogIn'),
                  child: Text(AppLocalizations.of(context)!.login,
                                        style: const TextStyle(color: Color(0xFF2F2F2F), fontWeight: FontWeight.w600)),
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
            ),
          ),

          // Glassy back button
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: GlassyBackButton(
                margin: const EdgeInsets.only(top: 20, left: 20),
                onPressed: () => Navigator.pushReplacementNamed(context, '/driverLogIn'),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 