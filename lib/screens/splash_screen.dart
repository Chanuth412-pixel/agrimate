import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agrimate/screens/role_selection_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  // Adjust this to change how long the splash screen stays visible
  static const Duration _splashDuration = Duration(seconds: 5);

  late final AnimationController _titleController;
  late final Animation<double> _titleScale;
  late final Animation<double> _titleOpacity;

  @override
  void initState() {
    super.initState();
    // Title animation: gentle breathing scale + fade in/out
    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _titleScale = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeInOut),
    );
    _titleOpacity = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeInOut),
    );
    // Navigate after splash based on auth + profile role
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateNext();
    });
  }

  Future<void> _navigateNext() async {
    // Show splash for configured duration
    await Future.delayed(_splashDuration);
    if (!mounted) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // Not signed in -> go to role selection
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
        );
        return;
      }

  final uid = user.uid;
  final prefs = await SharedPreferences.getInstance();
  final lastRoute = prefs.getString('last_route');
      // Determine role from Firestore by checking which profile exists
      final farmersDoc = await FirebaseFirestore.instance.collection('farmers').doc(uid).get();
      if (farmersDoc.exists) {
        if (!mounted) return;
        // Allow only farmer-safe routes to restore
        const farmerAllowed = <String>{
          '/farmerProfile',
          '/addHarvest',
          '/scheduledOrders',
          '/ongoingTransactions',
        };
        if (lastRoute != null && farmerAllowed.contains(lastRoute)) {
          Navigator.pushReplacementNamed(context, lastRoute);
        } else {
          Navigator.pushReplacementNamed(context, '/farmerProfile');
        }
        return;
      }

      final customersDoc = await FirebaseFirestore.instance.collection('customers').doc(uid).get();
      if (customersDoc.exists) {
        if (!mounted) return;
        const customerAllowed = <String>{
          '/customerProfile',
          // Add more customer routes here when they become named routes
        };
        if (lastRoute != null && customerAllowed.contains(lastRoute)) {
          Navigator.pushReplacementNamed(context, lastRoute);
        } else {
          Navigator.pushReplacementNamed(context, '/customerProfile');
        }
        return;
      }

      final driversDoc = await FirebaseFirestore.instance.collection('drivers').doc(uid).get();
      if (driversDoc.exists) {
        if (!mounted) return;
        const driverAllowed = <String>{
          '/driverProfile',
        };
        if (lastRoute != null && driverAllowed.contains(lastRoute)) {
          Navigator.pushReplacementNamed(context, lastRoute);
        } else {
          Navigator.pushReplacementNamed(context, '/driverProfile');
        }
        return;
      }

      // Signed in but no profile found -> let user pick role
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
      );
    } catch (_) {
      // On any error, fall back to role selection to avoid blocking
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const greenDark = Color(0xFF2E7D32);
    const greyText = Color(0xFF666666);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFDFFFD6), // #dfffd6
              Color(0xFFC0F7B0), // #c0f7b0
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Center content: logo, title, tagline
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // App logo / animation
                      const SizedBox(
                        height: 140,
                        width: 140,
                        child: Image(
                          image: AssetImage('assets/images/tracktor.gif'),
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Animated App name
                      ScaleTransition(
                        scale: _titleScale,
                        child: FadeTransition(
                          opacity: _titleOpacity,
                          child: Text(
                            'AGRIMATE',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: greenDark,
                              letterSpacing: 1.2,
                              shadows: [
                                Shadow(
                                  color: Color(0x332E7D32),
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Tagline
                      const Text(
                        "Let's grow together",
                        style: TextStyle(
                          fontSize: 16,
                          color: greyText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom loading indicator
              const Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: SizedBox(
                  height: 32,
                  width: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(greenDark),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
