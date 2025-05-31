import 'package:flutter/material.dart';
import 'package:agrimate/firestore_service.dart'; // Firestore service import

class CreateFarmerProfileScreen extends StatefulWidget {
  @override
  _CreateFarmerProfileScreenState createState() =>
      _CreateFarmerProfileScreenState();
}

class _CreateFarmerProfileScreenState
    extends State<CreateFarmerProfileScreen> {
  final _formKey = GlobalKey<FormState>(); // Global key for form validation
  final FirestoreService _firestoreService = FirestoreService(); // Firestore service instance

  // TextEditingControllers to capture user inputs
  final nameController = TextEditingController();
  final phoneController = TextEditingController(); // Controller for phone number
  final locationController = TextEditingController();

  // Function to create farmer profile
  void _createFarmerProfile() async {
    if (!_formKey.currentState!.validate()) return; // Validate the form fields

    // Get data from the controllers
    String name = nameController.text;
    String location = locationController.text;
    String phone = phoneController.text;  // Get phone number

    // Ensure location and phone are not empty
    if (location.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter a valid location and phone number')));
      return;
    }

    // Call Firestore service to create the farmer profile
    try {
      // Pass the phone number along with name and location
      await _firestoreService.createFarmerProfile(
        name, location, phone);

      // Show a success message
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Farmer Profile Created')));

      // Clear the form after submission
      _clearForm();
    } catch (e) {
      // Show error message if Firestore operation fails
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error creating profile: $e')));
    }
  }

  // Function to clear the form fields
  void _clearForm() {
    nameController.clear();
    locationController.clear();
    phoneController.clear(); // Clear phone number
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Farmer Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey, // Assign the global key for form validation
          child: Column(
            children: [
              // Farmer Name
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Farmer Name'),
                validator: (val) => val!.isEmpty ? 'Please enter the name' : null,
              ),
              
              // Farmer Location
              TextFormField(
                controller: locationController,
                decoration: InputDecoration(labelText: 'Location (e.g., City or Lat/Lng)'),
                validator: (val) => val!.isEmpty ? 'Please enter a location' : null,
              ),
              
              // Farmer Phone Number
              TextFormField(
                controller: phoneController,
                decoration: InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                validator: (val) => val!.isEmpty ? 'Please enter the phone number' : null,
              ),
              
              SizedBox(height: 20),
              
              // Submit button
              ElevatedButton(
                onPressed: _createFarmerProfile,  // Call the correct method
                child: Text('Create Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
