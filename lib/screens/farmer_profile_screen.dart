import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FarmerProfileScreen extends StatelessWidget {
  const FarmerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmer Dashboard'),
        backgroundColor: const Color(0xFF02C697),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/addHarvest');
        },
        backgroundColor: const Color(0xFF02C697),
        icon: const Icon(Icons.add),
        label: const Text("Add Harvest"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Crop Demand Trends',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              flex: 1,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('cropListings')
                    .where('farmerId', isEqualTo: userId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();

                  final crops = snapshot.data!.docs;

                  if (crops.isEmpty) {
                    return const Center(child: Text('No crops listed.'));
                  }

                  return ListView.builder(
                    itemCount: crops.length,
                    itemBuilder: (context, index) {
                      final crop = crops[index];
                      final demand = crop['demandScore'] ?? 0;

                      return Card(
                        child: ListTile(
                          title: Text('${crop['cropName']} - ₹${crop['price']}/kg'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Quantity: ${crop['quantity']} kg'),
                              Text('Demand Score: $demand/100'),
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: demand / 100,
                                color: Colors.green,
                                backgroundColor: Colors.grey[300],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ongoing Transactions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              flex: 1,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('transactions')
                    .where('farmerId', isEqualTo: userId)
                    .where('status', isNotEqualTo: 'completed')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();

                  final transactions = snapshot.data!.docs;

                  if (transactions.isEmpty) {
                    return const Center(child: Text('No ongoing transactions.'));
                  }

                  return ListView.builder(
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final tx = transactions[index];
                      return Card(
                        child: ListTile(
                          title: Text('${tx['crop']} - ${tx['quantity']}kg'),
                          subtitle: Text('Customer: ${tx['customerId']}'),
                          trailing: Text('₹${tx['pricePerKg']}'),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
