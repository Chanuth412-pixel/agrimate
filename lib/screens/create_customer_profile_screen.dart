import 'package:flutter/material.dart';
import 'package:agrimate/firestore_service.dart'; // Corrected path for Firestore service

class CreateCustomerProfileScreen extends StatefulWidget {
  @override
  _CreateCustomerProfileScreenState createState() =>
      _CreateCustomerProfileScreenState();
}

class _CreateCustomerProfileScreenState
    extends State<CreateCustomerProfileScreen> {
  final _formKey = GlobalKey<FormState>(); // Global key for form validation
  final FirestoreService _firestoreService = FirestoreService(); // Firestore service instance
  
  // TextEditingControllers to capture user inputs
  final nameController = TextEditingController();
  final locationController = TextEditingController();
  final phoneController = TextEditingController(); // Added controller for phone
  final preferredCropsController = TextEditingController();

  List<String> preferredCrops = []; // List to store preferred crops

  // Function to create customer profile
  void _createCustomerProfile() async {
    if (!_formKey.currentState!.validate()) return; // Validate the form fields

    // Get data from the controllers
    String name = nameController.text;
    String location = locationController.text;
    String phone = phoneController.text;  // Get phone number

    // Split the preferred crops into a list (comma-separated)
    preferredCrops = preferredCropsController.text
        .split(',')
        .map((crop) => crop.trim()) // Remove leading/trailing spaces
        .where((crop) => crop.isNotEmpty) // Remove any empty strings
        .toList();

    // If no valid crops are entered, show an error message
    if (preferredCrops.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter at least one valid crop'))); 
      return;
    }

    // Ensure location and phone are not empty
    if (location.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter a valid location and phone number')));
      return;
    }

    // Call Firestore service to create the customer profile
    try {
      // Pass the phone number along with name, location, and preferred crops
      await _firestoreService.createCustomerProfile(
        name, location, phone, preferredCrops);

      // Show a success message
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Customer Profile Created')));

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
    preferredCropsController.clear();
    setState(() {
      preferredCrops = []; // Clear the preferred crops list
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Customer Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey, // Assign the global key for form validation
          child: Column(
            children: [
              // Customer Name
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Customer Name'),
                validator: (val) => val!.isEmpty ? 'Please enter the name' : null,
              ),
              
              // Customer Location
              TextFormField(
                controller: locationController,
                decoration: InputDecoration(labelText: 'Location (e.g., City or Lat/Lng)'),
                validator: (val) => val!.isEmpty ? 'Please enter a location' : null,
              ),
              
              // Customer Phone Number (new input field)
              TextFormField(
                controller: phoneController,
                decoration: InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                validator: (val) => val!.isEmpty ? 'Please enter the phone number' : null,
              ),
              
              // Preferred Crops
              TextFormField(
                controller: preferredCropsController,
                decoration: InputDecoration(labelText: 'Preferred Crops (comma separated)'),
                validator: (val) => val!.isEmpty ? 'Please enter at least one preferred crop' : null,
              ),
              
              SizedBox(height: 20),
              
              // Submit button
              ElevatedButton(
                onPressed: _createCustomerProfile,  // Call the correct method
                child: Text('Create Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
