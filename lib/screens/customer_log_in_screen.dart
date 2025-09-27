import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../widgets/glassy_back_button.dart';

class CustomerLogInScreen extends StatefulWidget {
  const CustomerLogInScreen({super.key});

  @override
  _CustomerLogInScreenState createState() => _CustomerLogInScreenState();
}

class _CustomerLogInScreenState extends State<CustomerLogInScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoggingIn = false;
  bool _showDomainSuggestion = false;

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

  Future<void> _logInCustomer() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      setState(() => _isLoggingIn = true);
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final uid = userCredential.user?.uid;
      if (uid == null) {
        throw Exception("Login failed: UID is null.");
      }

      // Fetch customer profile from Firestore
      final docRef = FirebaseFirestore.instance.collection('customers').doc(uid);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.profileNotFound)),
        );
        return;
      }

      // Save UID to SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('customerId', uid);

      // Update login location only on first login
      final customerData = docSnapshot.data();
      final locationAlreadySet = customerData != null &&
          customerData.containsKey('lastLoginLocation');

      if (!locationAlreadySet) {
        final position = await _getCurrentLocation();
        if (position != null) {
          await docRef.update({
            'lastLoginLocation': GeoPoint(position.latitude, position.longitude),
            'locationSet': true,
            'lastLoginAt': FieldValue.serverTimestamp(),
          });
        }
      }

      // Navigate to customer dashboard/profile
      Navigator.pushReplacementNamed(context, '/customerProfile');
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context)!.loginFailed}: ${e.message}'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context)!.errorOccurred}: $e'),
        ),
      );
    }
    finally {
      if (mounted) setState(() => _isLoggingIn = false);
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
      {bool obscure = false, IconData? icon, Widget? suffixIcon}) {
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
        child: Stack(
          children: [
            TextFormField(
              controller: controller,
              obscureText: obscure,
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
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: controller == _emailController
                  ? (val) {
                      if (val.isNotEmpty && !val.contains('@') && !val.contains(' ')) {
                        setState(() => _showDomainSuggestion = true);
                      } else if (val.contains('@') || val.isEmpty) {
                        if (_showDomainSuggestion) setState(() => _showDomainSuggestion = false);
                      }
                    }
                  : null,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  if (label == AppLocalizations.of(context)!.emailPhone) {
                    return AppLocalizations.of(context)!.enterEmail;
                  } else if (label == AppLocalizations.of(context)!.password) {
                    return AppLocalizations.of(context)!.enterPassword;
                  }
                  return 'Please enter $label';
                }
                return null;
              },
            ),
            if (controller == _emailController && _showDomainSuggestion)
              Positioned(
                right: 10,
                top: 10,
                child: GestureDetector(
                  onTap: () {
                    final current = _emailController.text.trim();
                    if (current.isNotEmpty && !current.contains('@')) {
                      setState(() {
                        _emailController.text = '$current@gmail.com';
                        _emailController.selection = TextSelection.fromPosition(
                          TextPosition(offset: _emailController.text.length),
                        );
                        _showDomainSuggestion = false;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withOpacity(.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF2E7D32).withOpacity(.35), width: 1),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.auto_fix_high, size: 14, color: Color(0xFF2E7D32)),
                        SizedBox(width: 4),
                        Text(
                          '+ @gmail.com',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
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
          // Centered white card
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
                          AnimatedBuilder(
                            animation: _textController,
                            builder: (context, child) {
                              return Opacity(
                                opacity: _textController.value,
                                child: Text(
                                  AppLocalizations.of(context)!.welcomeBackCustomer,
                                  style: const TextStyle(
                                    fontSize: 25,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context)!.letsGrowTogether,
                            style: const TextStyle(
                              color: Color(0xFF666666),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 32),
                          buildInputField(
                            AppLocalizations.of(context)!.emailPhone,
                            _emailController,
                            icon: Icons.mail_outline,
                          ),
                          buildInputField(
                            AppLocalizations.of(context)!.password,
                            _passwordController,
                            obscure: _obscurePassword,
                            icon: Icons.lock_outline,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey[600],
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
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
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                    onPressed: () {
                                      if (_formKey.currentState?.validate() ?? false) {
                                        _logInCustomer();
                                      }
                                    },
                                    child: Text(
                                      AppLocalizations.of(context)!.logIn,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.dontHaveAccount + " ",
                                style: const TextStyle(color: Color(0xFF666666)),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pushNamed(
                                    context, '/createCustomerProfile'),
                                child: Text(
                                  AppLocalizations.of(context)!.createProfile,
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
                  onPressed: () => Navigator.pushReplacementNamed(
                      context, '/roleSelection'),
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF2E7D32)),
                ),
              ),
            ),
          ),

          if (_isLoggingIn)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.35),
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        width: 240,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.85),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFF2E7D32).withOpacity(.25), width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(.2),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 58,
                              height: 58,
                              child: CircularProgressIndicator(
                                strokeWidth: 5,
                                valueColor: AlwaysStoppedAnimation(Color(0xFF2E7D32)),
                              ),
                            ),
                            const SizedBox(height: 22),
                            Text(
                              AppLocalizations.of(context)!.logIn,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2E7D32),
                                letterSpacing: .4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Authenticating...',
                              style: TextStyle(
                                fontSize: 13.5,
                                color: Colors.grey.shade700,
                                letterSpacing: .3,
                              ),
                            ),
                          ],
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
