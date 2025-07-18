import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../main.dart' show AppLocaleProvider;

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  _RoleSelectionScreenState createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> with TickerProviderStateMixin {
  // Animation Controllers for all three buttons
  late AnimationController _farmerButtonController;
  late AnimationController _customerButtonController;
  late AnimationController _driverButtonController;  // Animation controller for Driver button
  late AnimationController _fadeController;

  // Animation for all three buttons (Scale up and down)
  late Animation<double> _farmerButtonScaleAnimation;
  late Animation<double> _customerButtonScaleAnimation;
  late Animation<double> _driverButtonScaleAnimation;  // Animation for Driver button
  
  // Fade animation for buttons
  late Animation<double> _fadeAnimation;
  Locale? _selectedLocale;

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

    _driverButtonController = AnimationController(  // Initialize the driver button controller
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

    _driverButtonScaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(
        parent: _driverButtonController,
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedLocale ??= Localizations.localeOf(context);
  }

  @override
  void dispose() {
    _farmerButtonController.dispose();
    _customerButtonController.dispose();
    _driverButtonController.dispose();  // Dispose the driver controller
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

  void _onDriverButtonPressed() {  // Handle driver button press
    _driverButtonController.forward(); // Start animation
    Future.delayed(const Duration(milliseconds: 500), () {
      Navigator.pushNamed(context, '/driverLogIn');
    });
  }

  void _changeLanguage(Locale locale) {
    AppLocaleProvider.of(context)?.setLocale(locale);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Language selection dropdown at the top right
          Positioned(
            right: 20,
            top: 20,
            child: DropdownButton<Locale>(
              value: _selectedLocale ?? Localizations.localeOf(context),
              icon: const Icon(Icons.language),
              underline: Container(),
              items: const [
                DropdownMenuItem(
                  value: Locale('en'),
                  child: Text('English'),
                ),
                DropdownMenuItem(
                  value: Locale('si'),
                  child: Text('සිංහල'),
                ),
              ],
              onChanged: (locale) {
                if (locale != null) {
                  _changeLanguage(locale);
                }
              },
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppLocalizations.of(context)!.selectRole,
                    style: const TextStyle(
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
                              child: Text(
                                AppLocalizations.of(context)!.farmer,
                                style: const TextStyle(
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
                              child: Text(
                                AppLocalizations.of(context)!.customer,
                                style: const TextStyle(
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

                  // DRIVER BUTTON with staggered animation and fade-in effect
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: GestureDetector(
                      onTap: _onDriverButtonPressed,
                      child: AnimatedBuilder(
                        animation: _driverButtonController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _driverButtonScaleAnimation.value,
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
                              child: Text(
                                AppLocalizations.of(context)!.driver,
                                style: const TextStyle(
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
        ],
      ),
    );
  }
}
