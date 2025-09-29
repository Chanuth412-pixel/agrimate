import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_constants.dart';
import '../l10n/app_localizations.dart';
import '../utils/currency_util.dart';

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

  String get localizedCrop {
    final loc = AppLocalizations.of(context);
    switch (widget.cropName) {
      case 'tomato':
        return loc?.cropTomato ?? 'Tomato';
      case 'bean':
        return loc?.cropBeans ?? 'Bean';
      case 'okra':
        return loc?.cropOkra ?? 'Okra';
      default:
        return widget.cropName;
    }
  }

  /// -------------------------------------------------------------------------
  /// FETCHING LOGIC (Merged: batched farmer query + rating caching)
  /// -------------------------------------------------------------------------
  Future<void> _fetchMatchingFarmers() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        debugPrint('[FarmerFetch] User not authenticated');
        setState(() => _loading = false);
        return;
      }

      debugPrint('[FarmerFetch] User ID: $uid');
      final customerDoc =
          await FirebaseFirestore.instance.collection('customers').doc(uid).get();

      if (!customerDoc.exists) {
        debugPrint('[FarmerFetch] Customer document does not exist');
        setState(() => _loading = false);
        return;
      }

      final customerData = customerDoc.data()!;
      debugPrint('[FarmerFetch] Customer data: $customerData');

      if (!customerData.containsKey('lastLoginLocation') ||
          !customerData.containsKey('lastLoginAt')) {
        debugPrint('[FarmerFetch] Missing location or login time data');
        // Try to use current location as fallback
        await _useCurrentLocationFallback(uid);
        return;
      }

      final GeoPoint customerPos = customerDoc['lastLoginLocation'];
      final DateTime loginAt = (customerDoc['lastLoginAt'] as Timestamp).toDate();
      final int customerWeek = _getWeekNumber(loginAt);
      final String selectedCrop = widget.cropName;

      debugPrint('[FarmerFetch] Customer position: (${customerPos.latitude}, ${customerPos.longitude})');
      debugPrint('[FarmerFetch] Customer week: $customerWeek');
      debugPrint('[FarmerFetch] Selected crop: $selectedCrop');

      // Load all harvests once
      final harvestsSnapshot =
          await FirebaseFirestore.instance.collection('Harvests').get();

      debugPrint('[FarmerFetch] Found ${harvestsSnapshot.docs.length} harvest documents');

      // Step 1: find candidate farmer IDs based on crop + week
      final Set<String> candidateFarmerIds = {};
      for (var harvestDoc in harvestsSnapshot.docs) {
        final List<dynamic> farmerHarvests = List.from(harvestDoc['harvests'] ?? []);
        for (final entry in farmerHarvests) {
          if (entry['crop'] != selectedCrop) continue;

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

          if (_getWeekNumber(harvestDate) != customerWeek) continue;

          candidateFarmerIds.add(harvestDoc.id);
          break; // only need one match per farmer for candidate list
        }
      }

      debugPrint('[FarmerFetch] Found ${candidateFarmerIds.length} candidate farmers: $candidateFarmerIds');
      
      if (candidateFarmerIds.isEmpty) {
        debugPrint('[FarmerFetch] No candidate farmers found - checking specific filtering conditions...');
        await _debugFilteringConditions(harvestsSnapshot.docs, selectedCrop, customerWeek);
        setState(() {
          _matchingFarmers = [];
          _loading = false;
        });
        return;
      }

      // Step 2: fetch farmer data in batches (max 10 per whereIn)
      final Map<String, Map<String, dynamic>> farmersById = {};
      final ids = candidateFarmerIds.toList();
      debugPrint('[FarmerFetch] Fetching farmer data for ${ids.length} candidates');
      
      for (int i = 0; i < ids.length; i += 10) {
        final batchIds = ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10);
        debugPrint('[FarmerFetch] Batch ${i ~/ 10 + 1}: $batchIds');
        
        final farmersSnapshot = await FirebaseFirestore.instance
            .collection('farmers')
            .where(FieldPath.documentId, whereIn: batchIds)
            .get();

        debugPrint('[FarmerFetch] Found ${farmersSnapshot.docs.length} farmers in this batch');

        for (final d in farmersSnapshot.docs) {
          final data = d.data();
          debugPrint('[FarmerFetch] Farmer ${d.id}: $data');
          
          farmersById[d.id] = {
            'name': data['name'],
            'phone': data['phone'],
            'position': data['position'],
            'proximity': data['proximity'] ?? 10,
            'deliveryPricePerKm': data['deliveryPricePerKm'],
          };
        }
      }
      
      debugPrint('[FarmerFetch] Total farmers loaded: ${farmersById.length}');

      // Step 3: collect final results with distance + rating cache
      final List<Map<String, dynamic>> results = [];
      final Set<String> addedFarmerIds = {};

      for (var harvestDoc in harvestsSnapshot.docs) {
        final farmerId = harvestDoc.id;
        if (!candidateFarmerIds.contains(farmerId)) continue;

        final farmerData = farmersById[farmerId];
        if (farmerData == null) {
          debugPrint('[FarmerFetch] ❌ No farmer data found for $farmerId');
          continue;
        }
        if (!farmerData.containsKey('position')) {
          debugPrint('[FarmerFetch] ❌ Farmer $farmerId missing position data');
          continue;
        }

        final List<dynamic> farmerHarvests = List.from(harvestDoc['harvests'] ?? []);

        // Find the last entry matching the selected crop and customer week
        Map<String, dynamic>? lastMatchEntry;
        for (int i = 0; i < farmerHarvests.length; i++) {
          final entry = farmerHarvests[i];
          if (entry['crop'] != selectedCrop) continue;
          try {
            final raw = entry['harvestDate'];
            final DateTime hd = raw is Timestamp
                ? raw.toDate()
                : raw is String
                    ? DateTime.parse(raw)
                    : raw is DateTime
                        ? raw
                        : (() => DateTime.now())();
            if (_getWeekNumber(hd) == customerWeek) {
              lastMatchEntry = Map<String, dynamic>.from(entry as Map);
            }
          } catch (_) {
            continue;
          }
        }

        if (lastMatchEntry == null) continue; // no matching entry for crop+week
        if (addedFarmerIds.contains(farmerId)) continue;

        final GeoPoint farmerPos = farmerData['position'];
        final double proximityKm = (farmerData['proximity'] ?? 10).toDouble();
        final double distanceKm = Geolocator.distanceBetween(
              customerPos.latitude,
              customerPos.longitude,
              farmerPos.latitude,
              farmerPos.longitude,
            ) /
            1000.0;

        debugPrint('[FarmerFetch] Farmer $farmerId distance: ${distanceKm.toStringAsFixed(2)}km, max: ${proximityKm}km');

        if (distanceKm <= proximityKm) {
          debugPrint('[FarmerFetch] ✅ Farmer $farmerId within range');
          double avgRating = await _fetchFarmerRating(farmerId) ?? 0.0;

          results.add({
            'farmerId': farmerId,
            'farmerName': farmerData['name'] ?? 'Unknown',
            'price': lastMatchEntry['expectedPrice'] ?? lastMatchEntry['price'] ?? 0,
            'distance': distanceKm,
            'quantity': lastMatchEntry['available'] ?? lastMatchEntry['quantity'],
            'phone': farmerData['phone'] ?? 'Unknown',
            'harvestDate': lastMatchEntry['harvestDate'],
            'deliveryPricePerKm': (farmerData['deliveryPricePerKm'] ?? AppConstants.defaultDeliveryPricePerKm),
            'avgRating': avgRating,
            '_originalEntry': lastMatchEntry,
          });
          addedFarmerIds.add(farmerId);
        }
      }

      // Step 4: sort results by rating (descending)
      results.sort((a, b) => (b['avgRating'] as double).compareTo(a['avgRating'] as double));

      debugPrint('[FarmerFetch] Final results: ${results.length} farmers found');
      for (int i = 0; i < results.length; i++) {
        final farmer = results[i];
        debugPrint('[FarmerFetch] Result ${i + 1}: ${farmer['farmerName']} (${farmer['distance'].toStringAsFixed(1)}km, ${farmer['quantity']}kg, rating: ${farmer['avgRating']})');
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

  /// -------------------------------------------------------------------------
  /// Helpers & UI logic from Code 1 (preserved)
  /// -------------------------------------------------------------------------
  int _getWeekNumber(DateTime date) {
    final beginningOfYear = DateTime(date.year, 1, 1);
    final daysDifference = date.difference(beginningOfYear).inDays;
    return ((daysDifference + beginningOfYear.weekday) / 7).ceil();
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

  Future<void> _showQuantityDialog(Map<String, dynamic> farmer) async {
    final TextEditingController quantityController = TextEditingController();
    final TextEditingController locationController = TextEditingController();
  double? quantityVal; // allow decimal quantities for pricing display

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
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Quantity in kg',
                      hintText: 'e.g. 12.5',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val){
                      final parsed = double.tryParse(val.trim());
                      setStateDialog((){ quantityVal = parsed; });
                    },
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
                  const SizedBox(height: 20),
                  _CostPreview(
                    quantity: quantityVal,
                    unitPrice: (farmer['price'] ?? 0).toDouble(),
                    distanceKm: (farmer['distance'] as num).toDouble(),
                    ratePerKm: (farmer['deliveryPricePerKm'] ?? AppConstants.defaultDeliveryPricePerKm).toDouble(),
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
                  final quantity = double.tryParse(quantityText);
                  if (quantity == null || quantity <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enter a valid quantity')),
                    );
                    return;
                  }

                  final available = (farmer['quantity'] is num) ? (farmer['quantity'] as num).toDouble() : 0.0;
                  if (quantity > available) {
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
    Map<String, dynamic> farmer, double quantity, {required String location}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = Timestamp.now();

    // Fetch Customer Name
    final customerDoc = await FirebaseFirestore.instance
        .collection('customers')
        .doc(user.uid)
        .get();

    final customerName = customerDoc.data()?['Name'] ?? customerDoc.data()?['name'] ?? 'Unknown';
    final customerPhone = customerDoc.data()?['phone'] ?? customerDoc.data()?['Phone'] ?? 'Not Provided';
    final customerLocation = customerDoc.data()?['location'] ?? 'Not specified';

    // Derive pricing breakdown (align with scheduled order + customer profile breakdown widget)
    final double unitPrice = (farmer['price'] is num)
        ? (farmer['price'] as num).toDouble()
        : double.tryParse(farmer['price']?.toString() ?? '0') ?? 0;
    final double distanceKm = (farmer['distance'] is num)
        ? (farmer['distance'] as num).toDouble()
        : 0;
    final double ratePerKm = (farmer['deliveryPricePerKm'] is num)
        ? (farmer['deliveryPricePerKm'] as num).toDouble()
        : AppConstants.defaultDeliveryPricePerKm.toDouble();
    final double baseAmount = unitPrice * quantity;
    final double deliveryCost = distanceKm * ratePerKm;
    final double totalAmount = baseAmount + deliveryCost;

    final transaction = {
      'Crop': widget.cropName, // store canonical code
  'Quantity Sold (1kg)': quantity,
      'Sale Price Per kg': unitPrice,
      'Status': 'Pending',
      'Farmer ID': farmer['farmerId'],
      'Farmer Name': farmer['farmerName'],
      'Phone_NO': farmer['phone'] ?? 'Unknown',
      'Harvest Date': farmer['harvestDate'],
      'Date': now, // legacy field
      'orderPlacedAt': now, // explicit ordering timestamp used for sorting
      'location': location, // capture address / location similar to scheduled orders
      // Pricing breakdown fields (so Recent Transactions can show full price)
      'deliveryDistanceKm': distanceKm,
      'deliveryRatePerKm': ratePerKm,
      'baseAmount': baseAmount,
      'deliveryCost': deliveryCost,
      'totalAmount': totalAmount,
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
      await FirebaseFirestore.instance
          .collection('Ongoing_Trans_Cus')
          .doc(user.uid)
          .set({
        'transactions': FieldValue.arrayUnion([transaction]),
      }, SetOptions(merge: true));

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
        decrementBy: quantity.floor(), // use floor to avoid subtracting more than available
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
    Map<String, dynamic> farmer, double quantity, {required String location}) async {
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
      // Pricing breakdown same as immediate
      'deliveryDistanceKm': (farmer['distance'] as num).toDouble(),
      'deliveryRatePerKm': (farmer['deliveryPricePerKm'] ?? AppConstants.defaultDeliveryPricePerKm).toDouble(),
      'baseAmount': quantity * (farmer['price'] as num).toDouble(),
      'deliveryCost': (farmer['distance'] as num).toDouble() * (farmer['deliveryPricePerKm'] ?? AppConstants.defaultDeliveryPricePerKm).toDouble(),
      'totalAmount': quantity * (farmer['price'] as num).toDouble() + (farmer['distance'] as num).toDouble() * (farmer['deliveryPricePerKm'] ?? AppConstants.defaultDeliveryPricePerKm).toDouble(),
    };

    try {
      // Only store as a scheduled order; do NOT add to ongoing transactions yet.
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
    final harvestDocRef = FirebaseFirestore.instance.collection('Harvests').doc(farmerId);

    // Use a transaction to avoid race conditions when multiple orders happen concurrently
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final harvestDoc = await transaction.get(harvestDocRef);
      if (!harvestDoc.exists) {
        debugPrint('[Harvest Decrement] Harvest doc not found for $farmerId');
        return;
      }

      List<dynamic> harvests = List.from(harvestDoc.data()?['harvests'] ?? []);

      // Determine target week from the provided harvestDate
      DateTime? targetDate;
      try {
        if (harvestDate is Timestamp) {
          targetDate = harvestDate.toDate();
        } else if (harvestDate is String) {
          targetDate = DateTime.parse(harvestDate);
        } else if (harvestDate is DateTime) {
          targetDate = harvestDate;
        } else {
          targetDate = null;
        }
      } catch (e) {
        debugPrint('[Harvest Decrement] Failed to parse harvestDate: $e');
        targetDate = null;
      }

      int? targetWeek = targetDate != null ? _getWeekNumber(targetDate) : null;

  // Collect indices for the crop+week group
  final List<int> groupIndices = [];
  int? groupAvailable; // aggregated available for the group based on last entry
  int sumQuantityIfNoAvailable = 0;

      for (int i = 0; i < harvests.length; i++) {
        final entry = harvests[i];
        if (entry['crop'] != crop) continue;

        // Determine entry week
        int? entryWeek;
        try {
          final raw = entry['harvestDate'];
          if (raw is Timestamp) {
            entryWeek = _getWeekNumber(raw.toDate());
          } else if (raw is String) {
            entryWeek = _getWeekNumber(DateTime.parse(raw));
          } else if (raw is DateTime) {
            entryWeek = _getWeekNumber(raw);
          }
        } catch (_) {
          entryWeek = null;
        }

        // If we couldn't parse targetWeek, fall back to exact harvestDate equality check
        final bool sameGroup = targetWeek != null
            ? (entryWeek == targetWeek)
            : (() {
                try {
                  final left = entry['harvestDate'] is Timestamp
                      ? (entry['harvestDate'] as Timestamp).toDate()
                      : DateTime.parse(entry['harvestDate'].toString());
          final right = harvestDate is Timestamp
            ? harvestDate.toDate()
                      : DateTime.parse(harvestDate.toString());
                  return left == right;
                } catch (_) {
                  return false;
                }
              })();

        if (!sameGroup) continue;

  groupIndices.add(i);

        // We want to base from the last added entry's available when present
        final val = entry['available'];
        if (val is num) {
          groupAvailable = val.toInt();
        }

        // For backfill scenarios where available isn't set at all, we prepare a sum
        final q = entry['quantity'];
        if (q is num) sumQuantityIfNoAvailable += q.toInt();
      }

      if (groupIndices.isEmpty) {
        debugPrint('[Harvest Decrement] No matching crop+week group found for farmer=$farmerId crop=$crop');
        return;
      }

  // If no 'available' seen across the group, assume sum of quantities (legacy)
  final int currentGroupAvailable = (groupAvailable ?? sumQuantityIfNoAvailable);
      int newAvailable = currentGroupAvailable - decrementBy;
      if (newAvailable < 0) newAvailable = 0;

      // Update the aggregated available across all entries in the group
      for (final idx in groupIndices) {
        final mutable = Map<String, dynamic>.from(harvests[idx] as Map);
        mutable['available'] = newAvailable;
        harvests[idx] = mutable;
      }

      transaction.update(harvestDocRef, {'harvests': harvests});
    });
  }

  /// Helper method to use current location if login location is not available
  Future<void> _useCurrentLocationFallback(String uid) async {
    try {
      debugPrint('[FarmerFetch] Attempting to get current location as fallback');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      // Update customer document with current location
      await FirebaseFirestore.instance.collection('customers').doc(uid).update({
        'lastLoginLocation': GeoPoint(position.latitude, position.longitude),
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('[FarmerFetch] Updated customer location, retrying fetch...');
      // Retry fetching farmers
      _fetchMatchingFarmers();
    } catch (e) {
      debugPrint('[FarmerFetch] Failed to get current location: $e');
      setState(() => _loading = false);
    }
  }

  /// Debug method to understand why filtering conditions fail
  Future<void> _debugFilteringConditions(
      List<QueryDocumentSnapshot> harvestDocs, String selectedCrop, int customerWeek) async {
    debugPrint('[FarmerFetch] === DEBUGGING FILTERING CONDITIONS ===');
    debugPrint('[FarmerFetch] Looking for crop: $selectedCrop, week: $customerWeek');
    
    int totalHarvests = 0;
    int cropMatches = 0;
    int weekMatches = 0;
    
    for (var harvestDoc in harvestDocs) {
      debugPrint('[FarmerFetch] Checking farmer ${harvestDoc.id}');
      final List<dynamic> farmerHarvests = List.from(harvestDoc['harvests'] ?? []);
      debugPrint('[FarmerFetch] Farmer has ${farmerHarvests.length} harvests');
      
      for (final entry in farmerHarvests) {
        totalHarvests++;
        debugPrint('[FarmerFetch] Harvest entry: ${entry}');
        
        final entryCrop = entry['crop'];
        final bool cropMatch = entryCrop == selectedCrop;
        if (cropMatch) cropMatches++;
        
        debugPrint('[FarmerFetch] Crop match ($entryCrop == $selectedCrop): $cropMatch');
        
        if (cropMatch) {
          try {
            late DateTime harvestDate;
            final raw = entry['harvestDate'];
            if (raw is Timestamp) {
              harvestDate = raw.toDate();
            } else if (raw is String) {
              harvestDate = DateTime.parse(raw);
            } else {
              debugPrint('[FarmerFetch] Unknown date format: ${raw.runtimeType}');
              continue;
            }
            
            final harvestWeek = _getWeekNumber(harvestDate);
            final bool weekMatch = harvestWeek == customerWeek;
            if (weekMatch) weekMatches++;
            
            debugPrint('[FarmerFetch] Week match ($harvestWeek == $customerWeek): $weekMatch');
            
          } catch (e) {
            debugPrint('[FarmerFetch] Error parsing date: $e');
          }
        }
      }
    }
    
    debugPrint('[FarmerFetch] === SUMMARY ===');
    debugPrint('[FarmerFetch] Total harvests checked: $totalHarvests');
    debugPrint('[FarmerFetch] Crop matches: $cropMatches');
    debugPrint('[FarmerFetch] Week matches: $weekMatches');
  }

  @override
  Widget build(BuildContext context) {
    const double headerHeight = 170;
    final int count = _matchingFarmers.length;
    final String subtitle = _loading
        ? 'Fetching farmers near you'
        : (count == 0
            ? 'No farmers available this week'
            : '$count farmer${count == 1 ? '' : 's'} available this week');

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Content List
          if (_loading)
            const Center(child: CircularProgressIndicator(color: Color(0xFF02C697)))
          else if (count == 0)
            Padding(
              padding: EdgeInsets.only(top: headerHeight - 10),
              child: _buildEmptyState(),
            )
          else
            ListView.builder(
              padding: EdgeInsets.fromLTRB(16, headerHeight + 8, 16, 32),
              itemCount: count,
              itemBuilder: (context, index) {
                final farmer = _matchingFarmers[index];
                return _GlassFarmerCard(
                  farmer: farmer,
                  fetchRating: () async => farmer['avgRating'] as double?,
                  onTap: () => _showQuantityDialog(farmer),
                );
              },
            ),

          // Header
          _buildHeader(headerHeight, subtitle, localizedCrop),
        ],
      ),
    );
  }
}

// ---------- Glass Components & Helpers (from Code 1) ----------

class _GlassFarmerCard extends StatelessWidget {
  final Map<String, dynamic> farmer;
  final Future<double?> Function() fetchRating;
  final VoidCallback onTap;
  const _GlassFarmerCard({required this.farmer, required this.fetchRating, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final price = farmer['price'] ?? 0;
    final priceDisplay = CurrencyUtil.format(price).replaceAll('.00', '');
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: Colors.white.withOpacity(.55),
                border: Border.all(color: Colors.white.withOpacity(.65), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.06),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Leaf / crop icon avatar (replaces tractor/agriculture)
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF02C697), Color(0xFF019876)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF02C697).withOpacity(.35),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                      border: Border.all(color: Colors.white.withOpacity(.55), width: 2),
                    ),
                    child: const Icon(Icons.eco, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 16),
                  // Body
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                farmer['farmerName'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF142017),
                                  letterSpacing: .25,
                                ),
                              ),
                            ),
                            _RatingChip(fetchRating: fetchRating),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Detailed info (no boxes, clear labels)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _detailLine(label: 'Price per kg', value: priceDisplay + ' / kg', icon: Icons.sell_outlined),
                            _detailLine(label: 'Distance from you', value: (farmer['distance'] as num).toStringAsFixed(1) + ' km', icon: Icons.place_outlined),
                            _detailLine(label: 'Available quantity', value: '${farmer['quantity']} kg', icon: Icons.inventory_2_outlined),
                            if (farmer['deliveryPricePerKm'] != null)
                              _detailLine(label: 'Delivery rate', value: CurrencyUtil.format((farmer['deliveryPricePerKm'] as num).toDouble()).replaceAll('.00', '') + ' / km', icon: Icons.local_shipping_outlined),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _FlatAction(label: 'Order', icon: Icons.shopping_cart_checkout),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RatingChip extends StatelessWidget {
  final Future<double?> Function() fetchRating;
  const _RatingChip({required this.fetchRating});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<double?>(
      future: fetchRating(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.25),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2,color: Colors.white)),
          );
        }
        final rating = snapshot.data;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: const Color(0xFFFFD54F).withOpacity(.25),
            border: Border.all(color: const Color(0xFFFFB300).withOpacity(.6)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, color: Color(0xFFFF8F00), size: 16),
              const SizedBox(width: 4),
              Text(
                rating == null ? '—' : rating.toStringAsFixed(1),
                style: const TextStyle(color: Color(0xFF8D6E00), fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FlatAction extends StatelessWidget {
  final String label;
  final IconData icon;
  const _FlatAction({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF02C697).withOpacity(.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF02C697).withOpacity(.45)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: const Color(0xFF026E55)),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF024D3B),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  letterSpacing: .4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _miniStat(String label, String value) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      Text(label + ': ', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: Color(0xFF475467))),
      Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF1F2A20))),
    ],
  );
}

// New glass stat chip
Widget _statChip(IconData icon, String value) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white.withOpacity(.5),
          border: Border.all(color: Colors.white.withOpacity(.65)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: const Color(0xFF026E55)),
            const SizedBox(width: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF133027),
                letterSpacing: .2,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _detailLine({required String label, required String value, required IconData icon}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF026E55)),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: label + ': ',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF3D5247),
                    letterSpacing: .2,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF142017),
                    letterSpacing: .25,
                  ),
                ),
              ],
            ),
          ),
        )
      ],
    ),
  );
}

// Redesigned header with gradient background & glass back button
Widget _buildHeader(double height, String subtitle, String cropName) {
  return SizedBox(
    height: height,
    child: Stack(
      children: [
        // Gradient background with soft curve effect using container + shadow
        Container(
          height: height,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF02C697), Color(0xFF018A67)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
        ),
        // Subtle overlay pattern (optional light glaze)
        Container(
          height: height,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
            gradient: LinearGradient(
              colors: [Colors.white.withOpacity(.08), Colors.white.withOpacity(.02)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        // Content
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button glass
                _GlassBackButton(),
                const Spacer(),
                Text(
                  'Farmers • ',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: .4,
                  ),
                ),
                Text(
                  cropName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .5,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(.85),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: .3,
                  ),
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _GlassBackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: InkWell(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.18),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}

Widget _buildEmptyState() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF02C697).withOpacity(.08),
            border: Border.all(color: const Color(0xFF02C697).withOpacity(.35)),
          ),
          child: const Icon(Icons.nature_outlined, size: 40, color: Color(0xFF02C697)),
        ),
        const SizedBox(height: 20),
        const Text('No available farmers found', style: TextStyle(color: Color(0xFF1F2A20), fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text('Try again later or pick another crop', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
      ],
    ),
  );
}

class _CostPreview extends StatelessWidget {
  final double? quantity;
  final double unitPrice;
  final double distanceKm;
  final double ratePerKm;
  const _CostPreview({required this.quantity, required this.unitPrice, required this.distanceKm, required this.ratePerKm});

  @override
  Widget build(BuildContext context) {
  final q = quantity;
  final base = (q == null) ? null : q * unitPrice;
  final delivery = (q == null) ? null : distanceKm * ratePerKm;
    final total = (base != null && delivery != null) ? base + delivery : null;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: total == null
          ? _hint()
          : _breakdown(base!, delivery!, total),
    );
  }

  Widget _hint() {
    return Container(
      key: const ValueKey('hint'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFF0F9B79).withOpacity(.06),
        border: Border.all(color: const Color(0xFF0F9B79).withOpacity(.25)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: Color(0xFF0F9B79)),
          SizedBox(width: 8),
          Expanded(child: Text('Enter quantity to preview total cost', style: TextStyle(fontSize: 12, color: Color(0xFF0F9B79), fontWeight: FontWeight.w500)))
        ],
      ),
    );
  }

  Widget _breakdown(double base, double delivery, double total) {
    String f(num v)=> CurrencyUtil.format(v).replaceAll('.00','');
    return Container(
      key: const ValueKey('cost'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 12, offset: const Offset(0,4)),
        ],
        border: Border.all(color: const Color(0xFF0F9B79).withOpacity(.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Cost Summary', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1D2939))),
          const SizedBox(height: 8),
          _row('Base (${quantity} kg × LKR ${unitPrice.toStringAsFixed(0)})', f(base)),
          _row('Delivery (${distanceKm.toStringAsFixed(1)} km × LKR ${ratePerKm.toStringAsFixed(0)})', f(delivery)),
          const Divider(height: 20),
          _row('Total', f(total), emphasize: true),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 12.5, color: const Color(0xFF475467), fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500))),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: emphasize ? const Color(0xFF0F9B79) : const Color(0xFF1D2939))),
        ],
      ),
    );
  }
}
