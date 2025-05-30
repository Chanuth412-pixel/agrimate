import 'package:flutter/material.dart';

class FarmerProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Farmer Profile')),
      body: Center(
        child: Text('Welcome to your Farmer Profile!', style: TextStyle(fontSize: 20)),
      ),
    );
  }
}
