import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddCropCustomerC1 extends StatefulWidget {
  final String cropName;

  const AddCropCustomerC1({Key? key, required this.cropName}) : super(key: key);

  @override
  State<AddCropCustomerC1> createState() => _AddCropCustomerC1State();
}

class _AddCropCustomerC1State extends State<AddCropCustomerC1> {
  List<Map<String, dynamic>> _matchingFarmers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchMatchingFarmers();
  }

  Future<void> _fetchMatchingFarmers() async {
    try {
      final String selectedCrop = widget.cropName;
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final customerDoc = await FirebaseFirestore.instance.collection('customers').doc(uid).get();
      if (!customerDoc.exists || !customerDoc.data()!.containsKey('lastLoginLocation')) {
        setState(() => _loading = false);
        return;
      }

      final GeoPoint customerPos = customerDoc['lastLoginLocation'];
      final DateTime loginAt = (customerDoc['lastLoginAt'] as Timestamp).toDate();
      final int customerWeek = _getWeekNumber(loginAt);

      final harvestsSnapshot = await FirebaseFirestore.instance.collection('Harvests').get();
      final List<Map<String, dynamic>> results = [];
      final Set<String> addedFarmerIds = {};

      for (var harvestDoc in harvestsSnapshot.docs) {
        final farmerId = harvestDoc.id;
        final farmerHarvests = List.from(harvestDoc['harvests']);

        for (final entry in farmerHarvests) {
          if (entry['crop'] != selectedCrop) continue;

          late DateTime harvestDate;
          try {
            harvestDate = DateTime.parse(entry['harvestDate']);
          } catch (_) {
            continue;
          }

          final int harvestWeek = _getWeekNumber(harvestDate);
          if (harvestWeek != customerWeek) continue;

          if (addedFarmerIds.contains(farmerId)) break;

          final farmerDoc = await FirebaseFirestore.instance.collection('farmers').doc(farmerId).get();
          if (!farmerDoc.exists || !farmerDoc.data()!.containsKey('position')) continue;

          final GeoPoint farmerPos = farmerDoc['position'];
          final double proximity = (farmerDoc['proximity'] ?? 10).toDouble();

          final double distance = Geolocator.distanceBetween(
            customerPos.latitude,
            customerPos.longitude,
            farmerPos.latitude,
            farmerPos.longitude,
          ) / 1000;

          if (distance <= proximity) {
            results.add({
              'farmerId': farmerId,
              'farmerName': farmerDoc['name'],
              'price': entry['expectedPrice'],
              'distance': distance,
              'quantity': entry['available'] ?? entry['quantity'],
              'phone': farmerDoc['phone'] ?? 'Unknown',
              'harvestDate': entry['harvestDate'],
            });
            addedFarmerIds.add(farmerId);
            break;
          }
        }
      }

      setState(() {
        _matchingFarmers = results;
        _loading = false;
      });
    } catch (e) {
      print('Error: $e');
      setState(() => _loading = false);
    }
  }

  int _getWeekNumber(DateTime date) {
    final beginningOfYear = DateTime(date.year, 1, 1);
    final daysDifference = date.difference(beginningOfYear).inDays;
    return ((daysDifference + beginningOfYear.weekday) / 7).ceil();
  }

  void _showQuantityDialog(Map<String, dynamic> farmer) {
    final TextEditingController _quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter Quantity (max  ${farmer['quantity']} kg)'),
          content: TextField(
            controller: _quantityController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Quantity in kg',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final quantityText = _quantityController.text.trim();
                final quantity = int.tryParse(quantityText);
                if (quantity == null || quantity <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enter a valid quantity')),
                  );
                  return;
                }

                if (quantity > farmer['quantity']) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Requested quantity exceeds available stock')),
                  );
                  return;
                }

                Navigator.pop(context); // Close dialog
                // Ask if the user wants to schedule the order
                final schedule = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Schedule Order'),
                    content: const Text('Do you want to schedule this order?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('No'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Yes'),
                      ),
                    ],
                  ),
                );
                if (schedule == true) {
                  await _createScheduledOrder(farmer, quantity);
                } else {
                  await _createTransaction(farmer, quantity);
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createTransaction(Map<String, dynamic> farmer, int quantity) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final now = Timestamp.now();

  // Fetch Customer Name
  final customerDoc = await FirebaseFirestore.instance
      .collection('customers')
      .doc(user.uid)
      .get();

  final customerName = customerDoc.data()?['Name'] ?? 'Unknown';

  // Transaction data for customer
  final transaction = {
    'Crop': widget.cropName,
    'Quantity Sold (1kg)': quantity,
    'Sale Price Per kg': farmer['price'],
    'Status': 'Pending',
    'Farmer ID': farmer['farmerId'],
    'Farmer Name': farmer['farmerName'],
    'Phone_NO': farmer['phone'] ?? 'Unknown',
    'Harvest Date': farmer['harvestDate'],
    'Date': now,
  };

  // Transaction data for farmer (add customer info)
  final transactionForFarmer = {
    ...transaction,
    'Customer ID': user.uid,
    'Customer Name': customerName,
    'Customer Email': user.email ?? 'unknown',
  };

  try {
    // Update Customer's Ongoing Transactions
    await FirebaseFirestore.instance
        .collection('Ongoing_Trans_Cus')
        .doc(user.uid)
        .set({
          'transactions': FieldValue.arrayUnion([transaction]),
        }, SetOptions(merge: true));

    // Update Farmer's Ongoing Transactions
    await FirebaseFirestore.instance
        .collection('Ongoing_Trans_Farm')
        .doc(farmer['farmerId'])
        .set({
          'transactions': FieldValue.arrayUnion([transactionForFarmer]),
        }, SetOptions(merge: true));

    // 🔸 Update Harvest quantity
    final harvestDocRef = FirebaseFirestore.instance
        .collection('Harvests')
        .doc(farmer['farmerId']);

    final harvestDoc = await harvestDocRef.get();
    if (harvestDoc.exists) {
      List<dynamic> harvests = harvestDoc.data()!['harvests'];

      // Find the matching harvest entry
      for (int i = 0; i < harvests.length; i++) {
        var entry = harvests[i];
        if (entry['crop'] == widget.cropName &&
          entry['expectedPrice'] == farmer['price'] &&
          entry['quantity'] == farmer['quantity'] &&
          entry['harvestDate'] == farmer['harvestDate']) {


          // Update the quantity
          int currentAvailable = entry['available'] ?? entry['quantity'];
          int newAvailable = currentAvailable - quantity;
          if (newAvailable < 0) newAvailable = 0;

          harvests[i]['available'] = newAvailable;


          break;
        }
      }

      // Update the harvest document
      await harvestDocRef.update({'harvests': harvests});
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaction created successfully!')),
    );

    Navigator.pop(context, 'updated');
  } catch (e) {
    print('Firestore write error: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to create transaction.')),
    );
  }
}

  Future<void> _createScheduledOrder(Map<String, dynamic> farmer, int quantity) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final now = Timestamp.now();
    final customerDoc = await FirebaseFirestore.instance
        .collection('customers')
        .doc(user.uid)
        .get();
    final customerName = customerDoc.data()?['Name'] ?? 'Unknown';
    final scheduledOrder = {
      'Crop': widget.cropName,
      'Quantity Sold (1kg)': quantity,
      'Sale Price Per kg': farmer['price'],
      'Status': 'Pending',
      'Farmer ID': farmer['farmerId'],
      'Farmer Name': farmer['farmerName'],
      'Phone_NO': farmer['phone'] ?? 'Unknown',
      'Harvest Date': farmer['harvestDate'],
      'Date': now,
      'Customer ID': user.uid,
      'Customer Name': customerName,
      'Customer Email': user.email ?? 'unknown',
    };
    try {
      await FirebaseFirestore.instance
          .collection('ScheduledOrders')
          .doc(user.uid)
          .set({
            'orders': FieldValue.arrayUnion([scheduledOrder]),
          }, SetOptions(merge: true));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order scheduled successfully!')),
      );
      Navigator.pop(context, 'updated');
    } catch (e) {
      print('Firestore write error (scheduled): $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to schedule order.')),
      );
    }
  }

  Future<double?> _fetchFarmerRating(String farmerId) async {
    final doc = await FirebaseFirestore.instance.collection('FarmerReviews').doc(farmerId).get();
    if (!doc.exists || doc.data() == null || !(doc.data()!.containsKey('ratings'))) {
      return null;
    }
    final List<dynamic> ratings = doc['ratings'] ?? [];
    if (ratings.isEmpty) return null;
    double avg = ratings.map((r) => (r['rating'] ?? 0).toDouble()).fold(0.0, (a, b) => a + b) / ratings.length;
    return avg;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Farmers for ${widget.cropName}'),
        backgroundColor: const Color(0xFF02C697),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _matchingFarmers.isEmpty
              ? const Center(child: Text('No available farmers found.'))
              : ListView.builder(
                  itemCount: _matchingFarmers.length,
                  itemBuilder: (context, index) {
                    final farmer = _matchingFarmers[index];
                    return Card(
                      child: ListTile(
                        title: Row(
                          children: [
                            Expanded(child: Text('${farmer['farmerName']} - LKR${farmer['price']}/kg')),
                            FutureBuilder<double?>(
                              future: _fetchFarmerRating(farmer['farmerId']),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const SizedBox(width: 40, height: 16, child: LinearProgressIndicator());
                                }
                                if (!snapshot.hasData || snapshot.data == null) {
                                  return const Text('No rating', style: TextStyle(fontSize: 13, color: Colors.grey));
                                }
                                return Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 18),
                                    Text(snapshot.data!.toStringAsFixed(1), style: const TextStyle(fontSize: 15)),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                        subtitle: Text(
                          'Distance: ${farmer['distance'].toStringAsFixed(1)} km\n'
                          'Available Quantity: ${farmer['quantity']} kg',
                        ),
                        onTap: () {
                          _showQuantityDialog(farmer);
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
