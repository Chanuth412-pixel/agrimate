import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../l10n/app_localizations.dart';
import '../widgets/glassy_back_button.dart';

class FarmerLogInScreen extends StatefulWidget {
  const FarmerLogInScreen({super.key});

  @override
  _FarmerLogInScreenState createState() => _FarmerLogInScreenState();
}

class _FarmerLogInScreenState extends State<FarmerLogInScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Animation controllers
  late AnimationController _logoController;
  late AnimationController _textController;
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
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    // Start the animations when the screen loads
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _textController.forward();
    });
    Future.delayed(const Duration(seconds: 1), () {
      _buttonController.forward();
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  Future<void> _logInFarmer() async {
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

      // 2. Fetch farmer profile from Firestore
      final docSnapshot =
          await FirebaseFirestore.instance.collection('farmers').doc(uid).get();

      if (!docSnapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Farmer profile not found.')),
        );
        return;
      }

      // 3. Save UID to SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('farmerId', uid);

      // 4. Navigate to farmer profile/dashboard
      Navigator.pushReplacementNamed(context, '/farmerProfile');
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
    final underlineColor = Colors.grey.shade400;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6E6E6E),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: underlineColor, width: 0.8),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF2F2F2F), width: 1.2),
            ),
            border: const UnderlineInputBorder(),
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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgAsset = 'assets/images/green_leaves_051.jpg';

    return Scaffold(
      body: Stack(
        children: [
          // Soft green gradient
          Positioned.fill(
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFA8E6CF), Color(0xFFBDF7E5)],
                ),
              ),
            ),
          ),

          // Blurred background accents
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

          // Centered decorative image panel (bigger than the login box)
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenW = constraints.maxWidth;
                final screenH = constraints.maxHeight;
                const cardApproxW = 420.0;
                const cardApproxH = 520.0;
                final boxW = (screenW * 0.92)
                    .clamp(cardApproxW + 40.0, 720.0)
                    .toDouble();
                final boxH = (screenH * 0.70)
                    .clamp(cardApproxH + 40.0, 620.0)
                    .toDouble();
                return Center(
                  child: IgnorePointer(
                    ignoring: true,
                    child: Container(
                      width: boxW,
                      height: boxH,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        image: DecorationImage(
                          image: AssetImage(bgAsset),
                          fit: BoxFit.cover,
                        ),
                        border: Border.all(color: Colors.white.withOpacity(0.5)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 30,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Content (glass card)
          Positioned.fill(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
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
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
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
                                      'LOGIN',
                                      style: TextStyle(
                                        fontFamily: 'SFProDisplay',
                                        fontSize: 34,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF5F5F5F),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                              Text(
                                AppLocalizations.of(context)!.pleaseSignIn,
                                style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 14,
                                  color: Color(0xFF666666),
                                ),
                              ),
                              const SizedBox(height: 28),
                              buildInputField('Username', _emailController),
                              const SizedBox(height: 18),
                              buildInputField('Password', _passwordController, obscure: true),
                              const SizedBox(height: 28),
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
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          elevation: 0,
                                        ),
                                        onPressed: () {
                                          if (_formKey.currentState?.validate() ?? false) {
                                            _logInFarmer();
                                          }
                                        },
                                        child: const Text(
                                          'SIGN IN',
                                          style: TextStyle(
                                            fontFamily: 'SFProDisplay',
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  AppLocalizations.of(context)!.forgotPassword,
                                  style: const TextStyle(
                                    color: Color(0xFF2F2F2F),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "Don't have an account?",
                                    style: TextStyle(color: Color(0xFF666666)),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pushNamed(context, '/createFarmerProfile'),
                                    child: Text(
                                      AppLocalizations.of(context)!.signUp,
                                      style: const TextStyle(color: Color(0xFF2F2F2F), fontWeight: FontWeight.w700),
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
            ),
          ),

          // Glassy back button
          /*Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: GlassyBackButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/roleSelection'),
              ),
            ),
          ), */

          // Glassy back button
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: GlassyBackButton(
                margin: const EdgeInsets.only(top: 20, left: 20),
                onPressed: () => Navigator.pushReplacementNamed(context, '/roleSelection'),
              ),
            ),
          ),

          // Page indicator at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                _IndicatorDot(active: false),
                SizedBox(width: 8),
                _IndicatorDot(active: true),
                SizedBox(width: 8),
                _IndicatorDot(active: false),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IndicatorDot extends StatelessWidget {
  final bool active;
  const _IndicatorDot({required this.active});
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: active ? 10 : 8,
      height: active ? 10 : 8,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF2F2F2F) : Colors.black26,
        shape: BoxShape.circle,
      ),
    );
  }
}
