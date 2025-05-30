import 'package:flutter/material.dart';

class RoleSelectionScreen extends StatelessWidget {
  final String role; // This will pass either "Farmer" or "Customer"

  // Constructor to accept the role
  RoleSelectionScreen({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$role Selection')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Would you like to Sign Up or Log In as a $role?',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to Sign Up screen based on role
                Navigator.pushNamed(
                  context,
                  role == 'Farmer' ? '/createFarmerProfile' : '/createCustomerProfile',
                );
              },
              child: Text('Sign Up as $role'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to Log In screen based on role
                Navigator.pushNamed(
                  context,
                  role == 'Farmer' ? '/farmerLogIn' : '/customerLogIn',
                );
              },
              child: Text('Log In as $role'),
            ),
          ],
        ),
      ),
    );
  }
}
