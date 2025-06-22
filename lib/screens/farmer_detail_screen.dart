import 'package:flutter/material.dart';

class FarmerDetailScreen extends StatelessWidget {
  final Map<String, dynamic> farmerData;

  // Constructor to receive farmer data from the previous screen
  const FarmerDetailScreen({super.key, required this.farmerData});

  @override
  Widget build(BuildContext context) {
    // Fetching farmer data from the passed map
    String name = farmerData['name'] ?? 'N/A';
    String location = farmerData['location'] ?? 'N/A';
    String phone = farmerData['phone'] ?? 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: Text('Farmer Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display farmer's name
            Text('Name: $name', style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            
            // Display farmer's location
            Text('Location: $location', style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            
            // Display farmer's phone number
            Text('Phone: $phone', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
