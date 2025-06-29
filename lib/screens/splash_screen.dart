import 'package:flutter/material.dart';
import 'package:agrimate/screens/role_selection_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _sizeAnimation;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Debugging the splash screen lifecycle
    print("SplashScreen initialized");

    // Initialize AnimationController
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();

    // Size animation: Starts small and grows bigger
    _sizeAnimation = Tween<double>(begin: 50, end: 300).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    // Color animation: From white to green
    _colorAnimation = ColorTween(begin: Colors.white, end: Colors.green).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    // Fade animation for the text and progress indicator
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    // Wait for the first frame to be built, then navigate after 3 seconds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("Post frame callback executed");

      Future.delayed(const Duration(seconds: 3), () {
        print("Navigating to RoleSelectionScreen...");
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
    _controller.dispose(); // Dispose the animation controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            color: _colorAnimation.value, // Background color animation
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Growing green dot animation
                  Container(
                    width: _sizeAnimation.value,
                    height: _sizeAnimation.value,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle, // Circular dot
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Fade transition for the following content
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        const Icon(
                          Icons.agriculture, // This icon represents the theme of your app
                          size: 120,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'AGRI-MATE',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Welcome to Agrimate!',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 30),
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white), // Loader color
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
