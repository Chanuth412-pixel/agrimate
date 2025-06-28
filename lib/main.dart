import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Firebase initialization options

// Import all the screens for routing
import 'screens/create_farmer_profile_screen.dart';
import 'screens/create_customer_profile_screen.dart';
import 'screens/profile_selection_screen.dart'; 
import 'screens/farmer_profile_screen.dart';
import 'screens/customer_profile_screen.dart';
import 'screens/farmer_log_in_screen.dart';  
import 'screens/customer_log_in_screen.dart'; 
import 'screens/role_selection_screen.dart';  
import 'screens/add_harvest_screen.dart';
import 'screens/add_crop_customer_c1.dart';
import 'screens/splash_screen.dart'; // Import the Splash Screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Firebase initialization options
  );

  // Run the app
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
        fontFamily: 'Roboto', // Theme color for the app
      ),
      initialRoute: '/', // Starting route when app loads

      // Define the routes for different screens
      routes: {
        '/': (context) => const SplashScreen(), // Splash screen
        '/profileSelection': (context) => const ProfileSelectionScreen(), // Profile selection screen
        '/createFarmerProfile': (context) => CreateFarmerProfileScreen(), // Create Farmer Profile screen
        '/createCustomerProfile': (context) => CreateCustomerProfileScreen(), // Create Customer Profile screen
        '/farmerProfile': (context) => const FarmerProfileScreen(), // Farmer Profile screen
        '/addHarvest': (context) => const AddHarvestScreen(), // Add Harvest screen
        '/customerProfile': (context) => const CustomerProfileScreen(), // Customer Profile screen
        '/farmerLogIn': (context) => const FarmerLogInScreen(), // Farmer Log In screen
        '/customerLogIn': (context) => const CustomerLogInScreen(), // Customer Log In screen
        '/farmerSelection': (context) => const RoleSelectionScreen(role: 'Farmer'), // Farmer role selection screen
        '/customerSelection': (context) => const RoleSelectionScreen(role: 'Customer'), // Customer role selection screen
      },

      // Handle dynamic routes with onGenerateRoute for role selection
      onGenerateRoute: (settings) {
        if (settings.name == '/roleSelection') {
          final String role = settings.arguments as String; // Get the role passed as an argument
          return MaterialPageRoute(
            builder: (context) => RoleSelectionScreen(role: role),
          );
        }

        return null; // If the route is not defined, return null
      },
    );
  }
}
