import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences
import 'firestore_service.dart'; // Import FirestoreService
import 'farmer_detail_screen.dart'; // Import the screen to show farmer details

class FarmerProfileScreen extends StatefulWidget {
  const FarmerProfileScreen({super.key});

  @override
  _FarmerProfileScreenState createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen> {
  String? farmerId;

  @override
  void initState() {
    super.initState();
    _loadFarmerId();
  }

  // Load the farmerId from SharedPreferences
  Future<void> _loadFarmerId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      farmerId = prefs.getString('farmerId'); // Retrieve the farmerId from SharedPreferences
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Farmer Profile')),
      body: Center(
        child: farmerId == null
            ? CircularProgressIndicator()  // Show a loading indicator while fetching the ID
            : ElevatedButton(
                onPressed: () async {
                  // Fetch farmer profile from Firestore using the stored farmerId
                  var farmerData = await FirestoreService().getFarmerProfile(farmerId!);

                  if (farmerData != null) {
                    // Navigate to the FarmerDetailScreen with the fetched data
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FarmerDetailScreen(farmerData: farmerData),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Farmer profile not found')));
                  }
                },
                child: Text('View Farmer Profile'),
              ),
      ),
    );
  }
}
