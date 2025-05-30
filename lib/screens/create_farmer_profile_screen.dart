import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';  // Import Firestore for saving data

class CreateFarmerProfileScreen extends StatefulWidget {
  const CreateFarmerProfileScreen({super.key});

  @override
  State<CreateFarmerProfileScreen> createState() =>
      _CreateFarmerProfileScreenState();
}

class _CreateFarmerProfileScreenState extends State<CreateFarmerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final locationController = TextEditingController();

  // Use a placeholder image instead of allowing the user to pick an image
  final String _defaultImageUrl =
      "https://cdn-icons-png.flaticon.com/512/4389/4389978.png";

  // Function to handle profile submission
  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // Firestore auto-generated unique ID
    DocumentReference docRef = FirebaseFirestore.instance.collection('farmers').doc();
    String uid = docRef.id; // Firestore's unique ID

    // Use the default image URL instead
    String? imageUrl = _defaultImageUrl;

    // Store the data in Firestore (without crops)
    try {
      await docRef.set({
        'name': nameController.text,
        'phone': phoneController.text,
        'location': locationController.text,
        'type': 'farmer',
        'profileImageUrl': imageUrl, // Store default image URL
        'createdAt': FieldValue.serverTimestamp(),  // Add a timestamp for profile creation
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Profile Created")));

      // Clear the form after submission
      _clearForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // Function to clear the entire form after submission
  void _clearForm() {
    nameController.clear();
    phoneController.clear();
    locationController.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Create Farmer Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Display a default image instead of allowing image selection
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(_defaultImageUrl),
              ),
              const SizedBox(height: 20),
              // Farmer Name
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(labelText: "Farmer Name"),
                validator: (val) => val!.isEmpty ? "Please enter a name" : null,
              ),
              // Phone Number
              TextFormField(
                controller: phoneController,
                decoration: InputDecoration(labelText: "Phone Number"),
                keyboardType: TextInputType.phone,
                validator: (val) => val!.isEmpty ? "Please enter a phone number" : null,
              ),
              // Location
              TextFormField(
                controller: locationController,
                decoration: InputDecoration(labelText: "Location (e.g., City or Lat/Lng)"),
                validator: (val) => val!.isEmpty ? "Please enter a location" : null,
              ),
              const SizedBox(height: 20),
              // Button to Create Farmer Profile (without crops)
              ElevatedButton(
                onPressed: _submitProfile,
                child: Text("Create Profile"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
