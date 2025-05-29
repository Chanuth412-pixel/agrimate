import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CreateFarmerProfileScreen extends StatefulWidget {
  const CreateFarmerProfileScreen({super.key});

  @override
  State<CreateFarmerProfileScreen> createState() => _CreateFarmerProfileScreenState();
}

class _CreateFarmerProfileScreenState extends State<CreateFarmerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final locationController = TextEditingController();
  final cropNameController = TextEditingController();
  final cropQtyController = TextEditingController();
  final cropPriceController = TextEditingController();

  File? _imageFile;
  final picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;

    String uid = DateTime.now().millisecondsSinceEpoch.toString(); // temporary UID
    String? imageUrl;

    if (_imageFile != null) {
      final ref = FirebaseStorage.instance.ref().child('users/$uid/profile.jpg');
      await ref.putFile(_imageFile!);
      imageUrl = await ref.getDownloadURL();
    }

    final crop = {
      'name': cropNameController.text,
      'quantity': int.tryParse(cropQtyController.text) ?? 0,
      'price': double.tryParse(cropPriceController.text) ?? 0.0,
    };

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'name': nameController.text,
      'phone': phoneController.text,
      'location': locationController.text,
      'type': 'farmer',
      'profileImageUrl': imageUrl ?? '',
      'crops': [crop],
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Profile Created")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Create Farmer Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                child: _imageFile == null ? Icon(Icons.camera_alt) : null,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: nameController,
              decoration: InputDecoration(labelText: "Farmer Name"),
              validator: (val) => val!.isEmpty ? "Required" : null,
            ),
            TextFormField(
              controller: phoneController,
              decoration: InputDecoration(labelText: "Phone Number"),
              keyboardType: TextInputType.phone,
              validator: (val) => val!.isEmpty ? "Required" : null,
            ),
            TextFormField(
              controller: locationController,
              decoration: InputDecoration(labelText: "Location (e.g., City or Lat/Lng)"),
              validator: (val) => val!.isEmpty ? "Required" : null,
            ),
            Divider(height: 30),
            Text("Add Crop Details", style: TextStyle(fontWeight: FontWeight.bold)),
            TextFormField(
              controller: cropNameController,
              decoration: InputDecoration(labelText: "Crop Name"),
              validator: (val) => val!.isEmpty ? "Required" : null,
            ),
            TextFormField(
              controller: cropQtyController,
              decoration: InputDecoration(labelText: "Quantity (e.g., 50)"),
              keyboardType: TextInputType.number,
              validator: (val) => val!.isEmpty ? "Required" : null,
            ),
            TextFormField(
              controller: cropPriceController,
              decoration: InputDecoration(labelText: "Price per Unit"),
              keyboardType: TextInputType.number,
              validator: (val) => val!.isEmpty ? "Required" : null,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitProfile,
              child: Text("Create Profile"),
            )
          ]),
        ),
      ),
    );
  }
}