import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'driver_profile_screen.dart';

class FarmerDashboardScreen extends StatelessWidget {
  final List<Map<String, dynamic>> farmers = [
    {
      'id': 'h1UJlLNnfERq7UBByrXV8ydudrD3',
      'name': 'Farmer 1',
      'lat': 6.9265,
      'lng': 79.8473,
      'location': 'Colombo'
    },
    {
      'id': 'anotherFarmerId',
      'name': 'Farmer 2',
      'lat': 7.0,
      'lng': 80.0,
      'location': 'Kandy'
    },
    // Add more farmers as needed
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Farmers Dashboard')),
      body: ListView.builder(
        itemCount: farmers.length,
        itemBuilder: (context, index) {
          final farmer = farmers[index];
          return ListTile(
            title: Text(farmer['name']),
            subtitle: Text(farmer['location']),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DriverProfileScreen(
                    farmerLat: farmer['lat'],
                    farmerLng: farmer['lng'],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
