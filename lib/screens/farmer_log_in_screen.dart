import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';  // Import Firestore for accessing the Farmer's collection
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences

class FarmerLogInScreen extends StatefulWidget {
  const FarmerLogInScreen({super.key});

  @override
  _FarmerLogInScreenState createState() => _FarmerLogInScreenState();
}

class _FarmerLogInScreenState extends State<FarmerLogInScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  // Function to log in the farmer
  Future<void> _logInFarmer() async {
    try {
      final id = _idController.text.trim();  // Unique ID entered by the user (Firestore document ID)
      final name = _nameController.text.trim(); // Name entered by the user

      // Fetch the document from Firestore based on the farmer's ID
      DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
          .collection('Farmers')
          .doc(id)  // Use the document ID directly (no need for where() query)
          .get();

      if (docSnapshot.exists) {
        // Check if the name matches the one in Firestore
        if (docSnapshot['name'] == name) {
          // Save the farmerId in SharedPreferences
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('farmerId', id); // Store the farmer's ID

          // Navigate to the Farmer Profile screen
          Navigator.pushReplacementNamed(context, '/farmerProfile');
        } else {
          // Name doesn't match, show an error
          print('Name does not match ID in Firestore.');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Name does not match ID.')),
          );
        }
      } else {
        // No document found with the given uniqueID
        print('No matching profile found for this ID.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No profile found for this ID.')),
        );
      }
    } catch (e) {
      // Handle errors (e.g., network issues, Firestore errors)
      print('Error during login: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Farmer Log In")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Input field for the Unique ID (for Farmer)
              TextFormField(
                controller: _idController,
                decoration: const InputDecoration(labelText: "Unique ID"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your Unique ID';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Input field for the Farmer's Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Name"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  // Check if the form is valid
                  if (_formKey.currentState?.validate() ?? false) {
                    // Call the logInFarmer function to verify the ID and Name
                    _logInFarmer();
                  }
                },
                child: const Text("Log In"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
