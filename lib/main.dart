import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Firebase initialization options
import 'firestore_service.dart'; // FirestoreService import

// Import all the screens for routing
import 'screens/create_farmer_profile_screen.dart';
import 'screens/create_customer_profile_screen.dart';
import 'screens/profile_selection_screen.dart';
import 'screens/farmer_profile_screen.dart';
import 'screens/customer_profile_screen.dart';
import 'screens/farmer_log_in_screen.dart';  // Correct import for Farmer Log In screen
import 'screens/customer_log_in_screen.dart'; // Correct import for Customer Log In screen
import 'screens/role_selection_screen.dart';  // RoleSelectionScreen import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Firebase initialization options
  );

  // Run the app
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
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
        '/': (context) => ProfileSelectionScreen(),  // Initial screen where user selects profile
        '/createFarmerProfile': (context) => CreateFarmerProfileScreen(),  // Farmer Sign-Up
        '/createCustomerProfile': (context) => CreateCustomerProfileScreen(),  // Customer Sign-Up
        '/farmerProfile': (context) => FarmerProfileScreen(),  // Farmer Profile
        '/customerProfile': (context) => CustomerProfileScreen(),  // Customer Profile
        '/farmerLogIn': (context) => FarmerLogInScreen(),  // Correct import for Farmer Log In screen
        '/customerLogIn': (context) => CustomerLogInScreen(),  // Correct import for Customer Log In screen
        '/farmerSelection': (context) => RoleSelectionScreen(role: 'Farmer'),  // Farmer Role Selection
        '/customerSelection': (context) => RoleSelectionScreen(role: 'Customer'),  // Customer Role Selection
      },
    );
  }
}
