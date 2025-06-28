import 'package:flutter/material.dart';
import 'package:agrimate/screens/role_selection_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Debugging the splash screen lifecycle
    print("SplashScreen initialized");

    // Wait for the first frame to be built, then navigate
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("Post frame callback executed");

      Future.delayed(const Duration(seconds: 3), () {
        print("Navigating to RoleSelectionScreen...");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const RoleSelectionScreen(), // role = null by default
          ),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              'Welcome to Agrimate!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
