import 'package:flutter/material.dart';

class FarmerDetailScreen extends StatelessWidget {
  final Map<String, dynamic> farmerData;

  // Constructor to receive farmer data from the previous screen
  const FarmerDetailScreen({super.key, required this.farmerData});

  @override
  Widget build(BuildContext context) {
    // Fetching farmer data from the passed map
    // String name = farmerData['name'] ?? 'N/A';
    // String location = farmerData['location'] ?? 'N/A';
    // String phone = farmerData['phone'] ?? 'N/A';
    String name = farmerData['name'] ?? 'Not Provided';
    String location = farmerData['location'] ?? 'Not Provided';
    String phone = farmerData['phone'] ?? 'Not Provided';
    String email = farmerData['email'] ?? 'Not Provided';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmer Details'),
        backgroundColor: const Color(0xFF02C697),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profile Information',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text('Name: $name', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text('Location: $location', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text('Phone: $phone', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text('Email: $email', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            //Text('User ID: $uid', style: const TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
