import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // This is the generated file
<<<<<<< HEAD
import 'create_farmer_profile_screen.dart';

=======
>>>>>>> 342e06ed1caacbcca71c104f21a2b079b8cdf416

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agrimate',
<<<<<<< HEAD
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: CreateFarmerProfileScreen(),
=======
      home: Scaffold(
        appBar: AppBar(title: Text('Agrimate Home')),
        body: Center(child: Text('Welcome to Agrimate')),
      ),
>>>>>>> 342e06ed1caacbcca71c104f21a2b079b8cdf416
    );
  }
}
