import 'package:flutter/material.dart';
import 'customer_detail_page.dart';  // Import the CustomerDetailPage

class CustomerProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Sample data, replace with dynamic data if needed
    Map<String, dynamic> customerData = {
      'name': 'John Doe',
      'location': 'New York',
      'phone': '+123456789',
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Customer Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Aligning the text to the left
          children: [
            // Display customer data in a neat format
            Text(
              'Name: ${customerData['name']}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            Text(
              'Location: ${customerData['location']}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            Text(
              'Phone: ${customerData['phone']}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 30), // Adding some space before the button section

            // Button to navigate to CustomerDetailPage
            ElevatedButton(
              onPressed: () {
                // Pass the customer data to the CustomerDetailPage
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CustomerDetailPage(customerData: customerData),
                  ),
                );
              },
              child: Text("View Customer Details"),
            ),
            
            SizedBox(height: 30), // Adding space before vegetable buttons

            // Vegetable Buttons
            Column(
              children: [
                VegetableButton(vegetableName: "Carrot", context: context),
                SizedBox(height: 10), // Add space between buttons
                VegetableButton(vegetableName: "Bean", context: context),
                SizedBox(height: 10),
                VegetableButton(vegetableName: "Cabbage", context: context),
                SizedBox(height: 10),
                VegetableButton(vegetableName: "Tomato", context: context),
                SizedBox(height: 10),
                VegetableButton(vegetableName: "Brinjal", context: context),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// A reusable widget for each vegetable button
class VegetableButton extends StatelessWidget {
  final String vegetableName;
  final BuildContext context;

  VegetableButton({required this.vegetableName, required this.context});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // Action for the vegetable button, for now just a placeholder
        print('Selected $vegetableName');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$vegetableName selected')),
        );
      },
      child: Text(vegetableName),
    );
  }
}
