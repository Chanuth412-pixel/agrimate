import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Firebase initialization options

// Import all the screens for routing
import 'screens/create_farmer_profile_screen.dart';
import 'screens/create_customer_profile_screen.dart';
import 'screens/farmer_profile_screen.dart';
import 'screens/customer_profile_screen.dart';
import 'screens/farmer_log_in_screen.dart';
import 'screens/customer_log_in_screen.dart';
import 'screens/role_selection_screen.dart';
import 'screens/add_harvest_screen.dart';
import 'screens/add_crop_customer_c1.dart';
import 'screens/splash_screen.dart'; // Splash screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agrimate',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'SFProDisplay',
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontFamily: 'SFProDisplay', fontWeight: FontWeight.bold, fontSize: 32),
          displayMedium: TextStyle(fontFamily: 'SFProDisplay', fontWeight: FontWeight.w600, fontSize: 28),
          displaySmall: TextStyle(fontFamily: 'SFProDisplay', fontWeight: FontWeight.w500, fontSize: 24),
          headlineLarge: TextStyle(fontFamily: 'SFProDisplay', fontWeight: FontWeight.bold, fontSize: 22),
          headlineMedium: TextStyle(fontFamily: 'SFProDisplay', fontWeight: FontWeight.w600, fontSize: 20),
          headlineSmall: TextStyle(fontFamily: 'SFProDisplay', fontWeight: FontWeight.w500, fontSize: 18),
          titleLarge: TextStyle(fontFamily: 'SFProDisplay', fontWeight: FontWeight.bold, fontSize: 20),
          titleMedium: TextStyle(fontFamily: 'SFProDisplay', fontWeight: FontWeight.w600, fontSize: 18),
          titleSmall: TextStyle(fontFamily: 'SFProDisplay', fontWeight: FontWeight.w500, fontSize: 16),
          bodyLarge: TextStyle(fontFamily: 'SFProDisplay', fontWeight: FontWeight.normal, fontSize: 16),
          bodyMedium: TextStyle(fontFamily: 'SFProDisplay', fontWeight: FontWeight.normal, fontSize: 14),
          bodySmall: TextStyle(fontFamily: 'SFProDisplay', fontWeight: FontWeight.w300, fontSize: 12),
          labelLarge: TextStyle(fontFamily: 'SFProDisplay', fontWeight: FontWeight.w500, fontSize: 14),
          labelMedium: TextStyle(fontFamily: 'SFProDisplay', fontWeight: FontWeight.w400, fontSize: 12),
          labelSmall: TextStyle(fontFamily: 'SFProDisplay', fontWeight: FontWeight.w300, fontSize: 10),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/createFarmerProfile': (context) => CreateFarmerProfileScreen(),
        '/createCustomerProfile': (context) => CreateCustomerProfileScreen(),
        '/farmerProfile': (context) => const FarmerProfileScreen(),
        '/addHarvest': (context) => const AddHarvestScreen(),
        '/customerProfile': (context) => const CustomerProfileScreen(),
        '/farmerLogIn': (context) => const FarmerLogInScreen(),
        '/customerLogIn': (context) => const CustomerLogInScreen(),

        // RoleSelectionScreen routes without any arguments
        '/farmerSelection': (context) => const RoleSelectionScreen(),
        '/customerSelection': (context) => const RoleSelectionScreen(),
        '/roleSelection': (context) => const RoleSelectionScreen(),
      },
    );
  }
}
