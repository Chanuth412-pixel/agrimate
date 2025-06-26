import 'package:flutter/material.dart';

class AddCropCustomerC1 extends StatelessWidget {
  final String cropName;

  const AddCropCustomerC1({Key? key, required this.cropName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Crop - $cropName'),
        backgroundColor: const Color(0xFF02C697),
      ),
      body: const Center(
        child: Text(''), // For now, still blank
      ),
    );
  }
}
