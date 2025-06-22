import 'package:flutter/material.dart';

class CustomerDetailPage extends StatelessWidget {
  final Map<String, dynamic> customerData;  // Required named parameter

  // Constructor to receive customerData
  const CustomerDetailPage({super.key, required this.customerData});

  @override
  Widget build(BuildContext context) {
    // Extract customer data
    String name = customerData['name'] ?? 'N/A';
    String location = customerData['location'] ?? 'N/A';
    String phone = customerData['phone'] ?? 'N/A';

    return Scaffold(
      appBar: AppBar(title: const Text('Customer Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: $name', style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text('Location: $location', style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text('Phone: $phone', style: TextStyle(fontSize: 18)),
            // Add more fields if needed
          ],
        ),
      ),
    );
  }
}
