import 'package:flutter/material.dart';

class CustomerDetailPage extends StatelessWidget {
  final Map<String, dynamic> customerData;

  const CustomerDetailPage({super.key, required this.customerData});

  @override
  Widget build(BuildContext context) {
    // Extract customer data with safe fallbacks
    String name = customerData['name'] ?? 'Not Provided';
    String location = customerData['location'] ?? 'Not Provided';
    String phone = customerData['phone'] ?? 'Not Provided';
    String email = customerData['email'] ?? 'Not Provided';
    //String uid = customerData['uid'] ?? 'Unavailable';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Details'),
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
