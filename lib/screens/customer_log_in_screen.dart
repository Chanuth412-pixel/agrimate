import 'package:flutter/material.dart';
import '../firestore_service.dart'; // Import FirestoreService for customer sign-in

class CustomerLogInScreen extends StatefulWidget {
  const CustomerLogInScreen({super.key});

  @override
  _CustomerLogInScreenState createState() => _CustomerLogInScreenState();
}

class _CustomerLogInScreenState extends State<CustomerLogInScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService(); // FirestoreService instance

  // Function to log in the customer
  Future<void> _logInCustomer() async {
    try {
      final id = _idController.text.trim(); // Unique ID entered by the user
      final name = _nameController.text.trim(); // Name entered by the user

      // Verify the Customer's Sign-In
      bool isVerified = await _firestoreService.verifyCustomerSignIn(id, name);

      if (isVerified) {
        // If verified, navigate to the Customer Profile Screen
        Navigator.pushReplacementNamed(context, '/customerProfile');
      } else {
        // If not verified, show an error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid ID or Name. Please try again.')),
        );
      }
    } catch (e) {
      // Handle errors (network issues, Firestore errors)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Customer Log In")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Input field for the Unique ID (for Customer)
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
              // Input field for the Customer's Name
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
              // Log In Button
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    _logInCustomer(); // Call the log-in function for Customer
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
