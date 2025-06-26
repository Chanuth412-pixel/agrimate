import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Firebase initialization options
// FirestoreService import

// Import all the screens for routing
import 'screens/create_farmer_profile_screen.dart';
import 'screens/create_customer_profile_screen.dart';
import 'screens/profile_selection_screen.dart';
import 'screens/farmer_profile_screen.dart';
import 'screens/customer_profile_screen.dart';
import 'screens/farmer_log_in_screen.dart';  // Correct import for Farmer Log In screen
import 'screens/customer_log_in_screen.dart'; // Correct import for Customer Log In screen
import 'screens/role_selection_screen.dart';  // RoleSelectionScreen import
import 'screens/add_harvest_screen.dart';
import 'screens/add_crop_customer_c1.dart';

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
        '/': (context) => ProfileSelectionScreen(),
        '/createFarmerProfile': (context) => CreateFarmerProfileScreen(),
        '/createCustomerProfile': (context) => CreateCustomerProfileScreen(),
        '/farmerProfile': (context) => const FarmerProfileScreen(),
        '/addHarvest': (context) => const AddHarvestScreen(),
        '/customerProfile': (context) => CustomerProfileScreen(),
        '/farmerLogIn': (context) => FarmerLogInScreen(),
        '/customerLogIn': (context) => CustomerLogInScreen(),
        '/farmerSelection': (context) => RoleSelectionScreen(role: 'Farmer'),
        '/addCropCustomer': (context) => const AddCropCustomerC1(cropName: ''),
  '/customerSelection': (context) => RoleSelectionScreen(role: 'Customer'),
      },
    );
  }
}

