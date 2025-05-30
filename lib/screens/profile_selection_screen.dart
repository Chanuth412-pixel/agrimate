import 'package:flutter/material.dart';

class ProfileSelectionScreen extends StatelessWidget {
  const ProfileSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Profile Type")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Please select your profile type:", style: TextStyle(fontSize: 20)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to Farmer Login or Sign Up
                Navigator.pushNamed(context, '/farmerSelection'); // Route to Farmer Sign Up / Log In
              },
              child: const Text("Farmer"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to Customer Login or Sign Up
                Navigator.pushNamed(context, '/customerSelection'); // Route to Customer Sign Up / Log In
              },
              child: const Text("Customer"),
            ),
          ],
        ),
      ),
    );
  }
}
