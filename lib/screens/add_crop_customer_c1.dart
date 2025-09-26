
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
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        setState(() => _loading = false);
        return;
      }

      final customerDoc =
          await FirebaseFirestore.instance.collection('customers').doc(uid).get();

      if (!customerDoc.exists ||
          !customerDoc.data()!.containsKey('lastLoginLocation') ||
          !customerDoc.data()!.containsKey('lastLoginAt')) {
        setState(() => _loading = false);
        return;
      }

      final GeoPoint customerPos = customerDoc['lastLoginLocation'];
      final DateTime loginAt = (customerDoc['lastLoginAt'] as Timestamp).toDate();
      final int customerWeek = _getWeekNumber(loginAt);
      final String selectedCrop = widget.cropName;

      // Efficient: load all farmers once and index by id
      final farmersSnapshot =
          await FirebaseFirestore.instance.collection('farmers').get();
      final Map<String, Map<String, dynamic>> farmersById = {
        for (final d in farmersSnapshot.docs) d.id: d.data()
      };

      // Load all harvests once
      final harvestsSnapshot =
          await FirebaseFirestore.instance.collection('Harvests').get();

      final List<Map<String, dynamic>> results = [];
      final Set<String> addedFarmerIds = {};

      for (var harvestDoc in harvestsSnapshot.docs) {
        final farmerId = harvestDoc.id;
        final List<dynamic> farmerHarvests = List.from(harvestDoc['harvests']);

        for (final entry in farmerHarvests) {
          if (entry['crop'] != selectedCrop) continue;

          // Parse harvest date
          late DateTime harvestDate;
          try {
            final raw = entry['harvestDate'];
            if (raw is Timestamp) {
              harvestDate = raw.toDate();
            } else if (raw is String) {
              harvestDate = DateTime.parse(raw);
            } else {
              continue;
            }
          } catch (_) {
            continue;
          }

          // Match by week number with customer's login week
          if (_getWeekNumber(harvestDate) != customerWeek) continue;

          // Only one card per farmer
          if (addedFarmerIds.contains(farmerId)) break;

          // Find farmer data efficiently from cache
          final farmerData = farmersById[farmerId];
          if (farmerData == null || !farmerData.containsKey('position')) continue;

          final GeoPoint farmerPos = farmerData['position'];
          final double proximityKm =
              (farmerData['proximity'] ?? 10).toDouble(); // delivery radius in km

          // Compute distance (km)
          final double distanceKm = Geolocator.distanceBetween(
                customerPos.latitude,
                customerPos.longitude,
                farmerPos.latitude,
                farmerPos.longitude,
              ) /
              1000.0;

          if (distanceKm <= proximityKm) {
            results.add({
              'farmerId': farmerId,
              'farmerName': farmerData['name'] ?? 'Unknown',
              'price': entry['expectedPrice'] ?? entry['price'] ?? 0,
              'distance': distanceKm,
              'quantity': entry['available'] ?? entry['quantity'],
              'phone': farmerData['phone'] ?? 'Unknown',
              'harvestDate': entry['harvestDate'],
              // keep original entry refs if needed later
              '_originalEntry': entry,
            });
            addedFarmerIds.add(farmerId);
            break; // stop scanning more harvests for this farmer
          }
        }
      }

      setState(() {
        _matchingFarmers = results;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error (fetch): $e');
      setState(() => _loading = false);
    }
  }

  int _getWeekNumber(DateTime date) {
    final beginningOfYear = DateTime(date.year, 1, 1);
    final daysDifference = date.difference(beginningOfYear).inDays;
    // Simple week-of-year approximation used in your code
    return ((daysDifference + beginningOfYear.weekday) / 7).ceil();
  }

  Future<void> _showQuantityDialog(Map<String, dynamic> farmer) async {
    final TextEditingController quantityController = TextEditingController();
    final TextEditingController locationController = TextEditingController();

    // Prefill address with customer's saved location if available
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final customerDoc = await FirebaseFirestore.instance
            .collection('customers')
            .doc(uid)
            .get();
        final savedLocation = customerDoc.data()?['location'];
        if (savedLocation is String && savedLocation.isNotEmpty) {
          locationController.text = savedLocation; // default to customer location
        }
      }
    } catch (e) {
      debugPrint('Prefill address error: $e');
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            title: Text('Order Details (max ${farmer['quantity']} kg)'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantity in kg',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: locationController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      hintText: 'Enter or confirm your location',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final quantityText = quantityController.text.trim();
                  final quantity = int.tryParse(quantityText);
                  if (quantity == null || quantity <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enter a valid quantity')),
                    );
                    return;
                  }

                  if (quantity > (farmer['quantity'] ?? 0)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Requested quantity exceeds available stock')),
                    );
                    return;
                  }

                  final location = locationController.text.trim();
                  if (location.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a location')),
                    );
                    return;
                  }

                  Navigator.pop(context); // close order details dialog

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
                    await _createScheduledOrder(
                      farmer,
                      quantity,
                      location: location,
                    );
                  } else {
                    await _createTransaction(
                      farmer,
                      quantity,
                      location: location,
                    );
                  }
                },
                child: const Text('Confirm'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _createTransaction(
    Map<String, dynamic> farmer, int quantity, {required String location}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final DateTime nowDate = DateTime.now();
    // Calculate next (or same) Sunday as delivery date
    // If you prefer ALWAYS next week even when today is Sunday, change daysToAdd == 0 ? 7 : 0
  int daysToAdd = DateTime.sunday - nowDate.weekday; // Sunday = 7
  if (daysToAdd <= 0) daysToAdd += 7; // if today is Sunday or past, go to next Sunday
    final DateTime deliveryDate = nowDate.add(Duration(days: daysToAdd));
    final Timestamp now = Timestamp.fromDate(nowDate);
    final Timestamp deliveryTs = Timestamp.fromDate(deliveryDate);

    // Fetch Customer Name
    final customerDoc = await FirebaseFirestore.instance
        .collection('customers')
        .doc(user.uid)
        .get();

  final customerName = customerDoc.data()?['Name'] ?? customerDoc.data()?['name'] ?? 'Unknown';
  final customerPhone = customerDoc.data()?['phone'] ?? customerDoc.data()?['Phone'] ?? 'Not Provided';
  final customerLocation = customerDoc.data()?['location'] ?? 'Not specified';

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
      // Delivery date set to nearest upcoming Sunday
      'Date': deliveryTs,
      // Order placed timestamp retained separately
      'orderPlacedAt': now,
      'location': location, // stored as 'location' per requirement
    };

    // Transaction data for farmer (add customer info)
    final transactionForFarmer = {
      ...transaction,
      'Customer ID': user.uid,
      'Customer Name': customerName,
      'customer_name': customerName,
      'Customer Email': user.email ?? 'unknown',
      'Customer Phone': customerPhone,
      'Customer Location': customerLocation,
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

      // Update Harvest quantity
      await _decrementHarvestQuantity(
        farmerId: farmer['farmerId'],
        crop: widget.cropName,
        price: farmer['price'],
        originalQuantity: farmer['quantity'],
        harvestDate: farmer['harvestDate'],
        decrementBy: quantity,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction created successfully!')),
      );

      Navigator.pop(context, 'updated');
    } catch (e) {
      debugPrint('Firestore write error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create transaction.')),
      );
    }
  }

  Future<void> _createScheduledOrder(
    Map<String, dynamic> farmer, int quantity, {required String location}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final DateTime nowDate = DateTime.now();
  int daysToAdd = DateTime.sunday - nowDate.weekday;
  if (daysToAdd <= 0) daysToAdd += 7; // always pick a future Sunday
    final DateTime deliveryDate = nowDate.add(Duration(days: daysToAdd));
    final Timestamp now = Timestamp.fromDate(nowDate);
    final Timestamp deliveryTs = Timestamp.fromDate(deliveryDate);

    final customerDoc = await FirebaseFirestore.instance
        .collection('customers')
        .doc(user.uid)
        .get();
  final customerName = customerDoc.data()?['Name'] ?? customerDoc.data()?['name'] ?? 'Unknown';
  final customerPhone = customerDoc.data()?['phone'] ?? customerDoc.data()?['Phone'] ?? 'Not Provided';
  final customerLocation = customerDoc.data()?['location'] ?? 'Not specified';

    final scheduledOrder = {
      'Crop': widget.cropName,
      'Quantity Sold (1kg)': quantity,
      'Sale Price Per kg': farmer['price'],
      'Status': 'Pending',
      'Farmer ID': farmer['farmerId'],
      'Farmer Name': farmer['farmerName'],
      'Phone_NO': farmer['phone'] ?? 'Unknown',
      'Harvest Date': farmer['harvestDate'],
      'Date': deliveryTs,
      'orderPlacedAt': now,
      'Customer ID': user.uid,
      'Customer Name': customerName,
      'customer_name': customerName,
      'Customer Email': user.email ?? 'unknown',
      'Customer Phone': customerPhone,
      'Customer Location': customerLocation,
      'scheduled': true,
      'location': location,
    };

    try {
      await FirebaseFirestore.instance
          .collection('ScheduledOrders')
          .doc(user.uid)
          .set({
        'orders': FieldValue.arrayUnion([scheduledOrder]),
      }, SetOptions(merge: true));

      // Also push into ongoing transactions so it shows under Recent Transactions as Pending
      await FirebaseFirestore.instance
          .collection('Ongoing_Trans_Cus')
          .doc(user.uid)
          .set({
        'transactions': FieldValue.arrayUnion([scheduledOrder]),
      }, SetOptions(merge: true));

      // Reserve (subtract) quantity immediately for scheduled orders too
      await _decrementHarvestQuantity(
        farmerId: farmer['farmerId'],
        crop: widget.cropName,
        price: farmer['price'],
        originalQuantity: farmer['quantity'],
        harvestDate: farmer['harvestDate'],
        decrementBy: quantity,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order scheduled successfully!')),
      );

      Navigator.pop(context, 'updated');
    } catch (e) {
      debugPrint('Firestore write error (scheduled): $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to schedule order.')),
      );
    }
  }

  Future<void> _decrementHarvestQuantity({
    required String farmerId,
    required String crop,
    required dynamic price,
    required dynamic originalQuantity,
    required dynamic harvestDate,
    required int decrementBy,
  }) async {
    final harvestDocRef =
        FirebaseFirestore.instance.collection('Harvests').doc(farmerId);

    final harvestDoc = await harvestDocRef.get();
    if (!harvestDoc.exists) return;

    List<dynamic> harvests = List.from(harvestDoc.data()!['harvests']);

    bool updated = false;
    for (int i = 0; i < harvests.length; i++) {
      final entry = harvests[i];

      final bool cropMatch = entry['crop'] == crop;
      final bool priceMatch = entry['expectedPrice'] == price;

      // match harvestDate regardless of stored type
      bool dateMatch = false;
      try {
        if (entry['harvestDate'] is Timestamp && harvestDate is Timestamp) {
          dateMatch = (entry['harvestDate'] as Timestamp)
              .toDate()
              .isAtSameMomentAs((harvestDate as Timestamp).toDate());
        } else if (entry['harvestDate'] is String && harvestDate is String) {
          dateMatch = DateTime.parse(entry['harvestDate']) == DateTime.parse(harvestDate);
        } else {
          final DateTime left = entry['harvestDate'] is Timestamp
              ? (entry['harvestDate'] as Timestamp).toDate()
              : DateTime.parse(entry['harvestDate'].toString());
          final DateTime right = harvestDate is Timestamp
              ? (harvestDate as Timestamp).toDate()
              : DateTime.parse(harvestDate.toString());
          dateMatch = left == right;
        }
      } catch (_) {
        dateMatch = false;
      }

      if (cropMatch && priceMatch && dateMatch) {
        final int currentAvailable = (entry['available'] ?? entry['quantity'] ?? 0) as int;
        int newAvailable = currentAvailable - decrementBy;
        if (newAvailable < 0) newAvailable = 0;
        harvests[i]['available'] = newAvailable;
        updated = true;
        break;
      }
    }

    // Fallback pass: if not updated (maybe price changed type), attempt loose crop/date match only
    if (!updated) {
      for (int i = 0; i < harvests.length; i++) {
        final entry = harvests[i];
        if (entry['crop'] != crop) continue;
        int currentAvailable = (entry['available'] ?? entry['quantity'] ?? 0) as int;
        int newAvailable = currentAvailable - decrementBy;
        if (newAvailable < 0) newAvailable = 0;
        harvests[i]['available'] = newAvailable;
        updated = true;
        break;
      }
    }

    if (!updated) {
      debugPrint('[Harvest Decrement] No matching harvest entry found for farmer=$farmerId crop=$crop');
    }

    await harvestDocRef.update({'harvests': harvests});
  }

  Future<double?> _fetchFarmerRating(String farmerId) async {
    final doc = await FirebaseFirestore.instance
        .collection('FarmerReviews')
        .doc(farmerId)
        .get();
    if (!doc.exists || doc.data() == null || !doc.data()!.containsKey('ratings')) {
      return null;
    }
    final List<dynamic> ratings = doc['ratings'] ?? [];
    if (ratings.isEmpty) return null;
    double avg = ratings
            .map((r) => (r['rating'] ?? 0).toDouble())
            .fold<double>(0.0, (a, b) => a + b) /
        ratings.length;
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
                            Expanded(
                              child: Text(
                                '${farmer['farmerName']} - LKR${farmer['price']}/kg',
                              ),
                            ),
                            FutureBuilder<double?>(
                              future: _fetchFarmerRating(farmer['farmerId']),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const SizedBox(
                                    width: 40,
                                    height: 16,
                                    child: LinearProgressIndicator(),
                                  );
                                }
                                if (!snapshot.hasData || snapshot.data == null) {
                                  return const Text(
                                    'No rating',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  );
                                }
                                return Row(
                                  children: [
                                    const Icon(Icons.star,
                                        color: Colors.amber, size: 18),
                                    Text(
                                      snapshot.data!.toStringAsFixed(1),
                                      style: const TextStyle(fontSize: 15),
                                    ),
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
                        onTap: () => _showQuantityDialog(farmer),
                      ),
                    );
                  },
                ),
    );
  }
}

