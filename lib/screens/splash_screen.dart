import 'package:flutter/material.dart';
import 'package:agrimate/screens/role_selection_screen.dart';

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
    // Keep navigation/auth logic intact: navigate after ~3 seconds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(_splashDuration, () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const RoleSelectionScreen(),
          ),
        );
      });
    });
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
