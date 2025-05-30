import 'package:flutter/material.dart';

class CustomerProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customer Profile')),
      body: const Center(
        child: Text('Welcome to your Customer Profile!', style: TextStyle(fontSize: 20)),
      ),
    );
  }
}
