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
        fontFamily: 'Roboto',
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
