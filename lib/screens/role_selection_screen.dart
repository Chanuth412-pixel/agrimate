import 'package:flutter/material.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  _RoleSelectionScreenState createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> with TickerProviderStateMixin {
  // Animation Controllers for both buttons
  late AnimationController _farmerButtonController;
  late AnimationController _customerButtonController;
  late AnimationController _fadeController;

  // Animation for both buttons (Scale up and down)
  late Animation<double> _farmerButtonScaleAnimation;
  late Animation<double> _customerButtonScaleAnimation;
  
  // Fade animation for buttons
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize AnimationControllers
    _farmerButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _customerButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Define the scaling animations for buttons
    _farmerButtonScaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(
        parent: _farmerButtonController,
        curve: Curves.easeInOut,
      ),
    );

    _customerButtonScaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(
        parent: _customerButtonController,
        curve: Curves.easeInOut,
      ),
    );

    // Fade-in animation for buttons
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeInOut,
      ),
    );

    // Start the fade animation when the screen loads
    _fadeController.forward();
  }

  @override
  void dispose() {
    _farmerButtonController.dispose();
    _customerButtonController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onFarmerButtonPressed() {
    _farmerButtonController.forward(); // Start animation
    Future.delayed(const Duration(milliseconds: 500), () {
      Navigator.pushNamed(context, '/farmerLogIn'); // Navigate to next screen after animation
    });
  }

  void _onCustomerButtonPressed() {
    _customerButtonController.forward(); // Start animation
    Future.delayed(const Duration(milliseconds: 500), () {
      Navigator.pushNamed(context, '/customerLogIn'); // Navigate to next screen after animation
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Select Role',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 50),

              // FARMER BUTTON with staggered animation and fade-in effect
              FadeTransition(
                opacity: _fadeAnimation,
                child: GestureDetector(
                  onTap: _onFarmerButtonPressed,
                  child: AnimatedBuilder(
                    animation: _farmerButtonController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _farmerButtonScaleAnimation.value,
                        child: Container(
                          width: 280,
                          height: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFF02C697),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                spreadRadius: 3,
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Text(
                            'Farmer',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // CUSTOMER BUTTON with staggered animation and fade-in effect
              FadeTransition(
                opacity: _fadeAnimation,
                child: GestureDetector(
                  onTap: _onCustomerButtonPressed,
                  child: AnimatedBuilder(
                    animation: _customerButtonController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _customerButtonScaleAnimation.value,
                        child: Container(
                          width: 280,
                          height: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFF02C697),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                spreadRadius: 3,
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Text(
                            'Customer',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
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
