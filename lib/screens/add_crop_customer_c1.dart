import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
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

      // Load all harvests once
      final harvestsSnapshot =
          await FirebaseFirestore.instance.collection('Harvests').get();

      // Step 1: find candidate farmer IDs based on crop + week
      final Set<String> candidateFarmerIds = {};
      for (var harvestDoc in harvestsSnapshot.docs) {
        final List<dynamic> farmerHarvests = List.from(harvestDoc['harvests']);
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

      if (candidateFarmerIds.isEmpty) {
        setState(() {
          _matchingFarmers = [];
          _loading = false;
        });
        return;
      }

      // Step 2: fetch farmer data in batches (max 10 per whereIn)
      final Map<String, Map<String, dynamic>> farmersById = {};
      final ids = candidateFarmerIds.toList();
      for (int i = 0; i < ids.length; i += 10) {
        final batchIds = ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10);
        final farmersSnapshot = await FirebaseFirestore.instance
            .collection('farmers')
            .where(FieldPath.documentId, whereIn: batchIds)
            .get();

        for (final d in farmersSnapshot.docs) {
          final data = d.data();
          farmersById[d.id] = {
            'name': data['name'],
            'phone': data['phone'],
            'position': data['position'],
            'proximity': data['proximity'] ?? 10,
          };
        }
      }

      // Step 3: collect final results with distance + rating check
      final List<Map<String, dynamic>> results = [];
      final Set<String> addedFarmerIds = {};

      for (var harvestDoc in harvestsSnapshot.docs) {
        final farmerId = harvestDoc.id;
        if (!candidateFarmerIds.contains(farmerId)) continue;

        final farmerData = farmersById[farmerId];
        if (farmerData == null || !farmerData.containsKey('position')) continue;

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

          if (_getWeekNumber(harvestDate) != customerWeek) continue;

          if (addedFarmerIds.contains(farmerId)) break;

          final GeoPoint farmerPos = farmerData['position'];
          final double proximityKm = (farmerData['proximity'] ?? 10).toDouble();

          final double distanceKm = Geolocator.distanceBetween(
                customerPos.latitude,
                customerPos.longitude,
                farmerPos.latitude,
                farmerPos.longitude,
              ) /
              1000.0;

          if (distanceKm <= proximityKm) {
            // Fetch average rating
            double avgRating = await _fetchFarmerRating(farmerId) ?? 0.0;

            results.add({
              'farmerId': farmerId,
              'farmerName': farmerData['name'] ?? 'Unknown',
              'price': entry['expectedPrice'] ?? entry['price'] ?? 0,
              'distance': distanceKm,
              'quantity': entry['available'] ?? entry['quantity'],
              'phone': farmerData['phone'] ?? 'Unknown',
              'harvestDate': entry['harvestDate'],
              'deliveryPricePerKm': (farmerData['deliveryPricePerKm'] ?? AppConstants.defaultDeliveryPricePerKm),
              'avgRating': avgRating, // store rating for sorting
              '_originalEntry': entry,
            });
            addedFarmerIds.add(farmerId);
            break;
          }
        }
      }

      // Step 4: sort results by rating (descending)
      results.sort((a, b) => (b['avgRating'] as double).compareTo(a['avgRating'] as double));

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
    return ((daysDifference + beginningOfYear.weekday) / 7).ceil();
  }

  Future<void> _showQuantityDialog(Map<String, dynamic> farmer) async {
    // Always pull the most recent delivery price per km before showing dialog
    var currentFarmer = Map<String, dynamic>.from(farmer);
    try {
      final doc = await FirebaseFirestore.instance.collection('farmers').doc(farmer['farmerId']).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['deliveryPricePerKm'] != null) {
          currentFarmer['deliveryPricePerKm'] = data['deliveryPricePerKm'];
        }
      }
    } catch (e) {
      debugPrint('Failed to refresh deliveryPricePerKm: $e');
    }
    final TextEditingController quantityController = TextEditingController();
    final TextEditingController locationController = TextEditingController();
    int? quantityVal; // for dynamic pricing display

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
            title: Text('Order Details (max ${currentFarmer['quantity']} kg)'),
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
                    onChanged: (val){
                      final parsed = int.tryParse(val.trim());
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
                    unitPrice: (currentFarmer['price'] ?? 0).toDouble(),
                    distanceKm: (currentFarmer['distance'] as num).toDouble(),
                    ratePerKm: (currentFarmer['deliveryPricePerKm'] ?? AppConstants.defaultDeliveryPricePerKm).toDouble(),
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

                  if (quantity > (currentFarmer['quantity'] ?? 0)) {
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
                      currentFarmer,
                      quantity,
                      location: location,
                    );
                  } else {
                    await _createTransaction(
                      currentFarmer,
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

    final nowDate = DateTime.now();
    // Compute next nearest Sunday (always future Sunday, not today if today is Sunday)
    int daysToAdd = DateTime.sunday - nowDate.weekday;
    if (daysToAdd <= 0) daysToAdd += 7;
    final deliveryDate = nowDate.add(Duration(days: daysToAdd));
    final now = Timestamp.fromDate(nowDate);
    final deliveryTs = Timestamp.fromDate(deliveryDate);

    // Fetch Customer Name
    final customerDoc = await FirebaseFirestore.instance
        .collection('customers')
        .doc(user.uid)
        .get();

  final customerName = customerDoc.data()?['Name'] ?? customerDoc.data()?['name'] ?? 'Unknown';
  final customerPhone = customerDoc.data()?['phone'] ?? customerDoc.data()?['Phone'] ?? 'Not Provided';
  final customerLocation = customerDoc.data()?['location'] ?? 'Not specified';

    // Always fetch the latest farmer doc to reflect updated delivery price per km changes
    double latestRatePerKm = (farmer['deliveryPricePerKm'] ?? AppConstants.defaultDeliveryPricePerKm).toDouble();
    try {
      final latestFarmerDoc = await FirebaseFirestore.instance.collection('farmers').doc(farmer['farmerId']).get();
      if (latestFarmerDoc.exists) {
        final latestData = latestFarmerDoc.data();
        if (latestData != null && latestData['deliveryPricePerKm'] != null) {
          latestRatePerKm = (latestData['deliveryPricePerKm'] as num).toDouble();
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch latest farmer delivery price per km: $e');
    }

    // Delivery / pricing enrichment (same structure as scheduled orders for consistent UI)
    final double unitPrice = (farmer['price'] as num).toDouble();
    final double distanceKm = (farmer['distance'] as num?)?.toDouble() ?? 0.0;
    final double ratePerKm = latestRatePerKm;
    final double baseAmount = unitPrice * quantity;
    final double deliveryCost = distanceKm > 0 ? distanceKm * ratePerKm : 0.0;
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
      'Date': deliveryTs, // expected delivery date is next Sunday
      'orderPlacedAt': now, // used for sorting newest first
      'seen_farmer': false, // notification flag for farmer
      // Pricing breakdown fields
      'deliveryDistanceKm': distanceKm,
      'deliveryRatePerKm': ratePerKm,
      'baseAmount': baseAmount,
      'deliveryCost': deliveryCost,
      'totalAmount': totalAmount,
      'location': location,
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
      'seen_farmer': false,
      // Pricing breakdown same as immediate
      'deliveryDistanceKm': (farmer['distance'] as num).toDouble(),
  'deliveryRatePerKm': (farmer['deliveryPricePerKm'] ?? AppConstants.defaultDeliveryPricePerKm).toDouble(),
      'baseAmount': quantity * (farmer['price'] as num).toDouble(),
  'deliveryCost': (farmer['distance'] as num).toDouble() * (farmer['deliveryPricePerKm'] ?? AppConstants.defaultDeliveryPricePerKm).toDouble(),
  'totalAmount': quantity * (farmer['price'] as num).toDouble() + (farmer['distance'] as num).toDouble() * (farmer['deliveryPricePerKm'] ?? AppConstants.defaultDeliveryPricePerKm).toDouble(),
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Farmers • ${widget.cropName}'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0F9B79), Color(0xFF0F9B79), Color(0xFFdfffe9)],
                stops: [0, 0.35, 1],
              ),
            ),
          ),
          // Subtle leaf overlay (optional future asset)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white.withOpacity(.08), Colors.white.withOpacity(.02)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : _matchingFarmers.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                        itemCount: _matchingFarmers.length,
                        itemBuilder: (context, index) {
                          final farmer = _matchingFarmers[index];
                          return _GlassFarmerCard(
                            farmer: farmer,
                            fetchRating: () => _fetchFarmerRating(farmer['farmerId']),
                            onTap: () => _showQuantityDialog(farmer),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// ---------- Glass Components & Helpers ----------

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
      padding: const EdgeInsets.only(bottom: 18),
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                color: Colors.white.withOpacity(.18),
                border: Border.all(color: Colors.white.withOpacity(.35), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.15),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon badge
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(colors: [Color(0xFF56ab2f), Color(0xFFa8e063)]),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF56ab2f).withOpacity(.35), blurRadius: 12, offset: const Offset(0,6)),
                      ],
                    ),
                    child: const Icon(Icons.agriculture, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  // Textual content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                farmer['farmerName'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: .2,
                                ),
                              ),
                            ),
                            _RatingChip(fetchRating: fetchRating),
                          ],
                        ),
                        const SizedBox(height: 6),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(fontSize: 13.5, color: Colors.white70, height: 1.35),
                            children: [
                              TextSpan(text: 'Price: ', style: TextStyle(color: Colors.white.withOpacity(.75), fontWeight: FontWeight.w500)),
                              TextSpan(text: '$priceDisplay / kg\n'),
                              TextSpan(text: 'Distance: ', style: TextStyle(color: Colors.white.withOpacity(.75), fontWeight: FontWeight.w500)),
                              TextSpan(text: '${(farmer['distance'] as num).toStringAsFixed(1)} km\n'),
                              TextSpan(text: 'Available: ', style: TextStyle(color: Colors.white.withOpacity(.75), fontWeight: FontWeight.w500)),
                              TextSpan(text: '${farmer['quantity']} kg'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _Pill(label: 'Tap to Order', icon: Icons.shopping_cart_checkout, colors: const [Color(0xFF02C697), Color(0xFF00E8A0)]),
                        )
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            gradient: const LinearGradient(colors: [Color(0xFFFFC837), Color(0xFFFF8008)]),
            boxShadow: [BoxShadow(color: const Color(0xFFFFA726).withOpacity(.35), blurRadius: 10, offset: const Offset(0,4))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(
                rating == null ? '—' : rating.toStringAsFixed(1),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<Color> colors;
  const _Pill({required this.label, required this.icon, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [BoxShadow(color: colors.last.withOpacity(.35), blurRadius: 12, offset: const Offset(0,6))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
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
          padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(.18),
              border: Border.all(color: Colors.white.withOpacity(.35)),
            ),
          child: const Icon(Icons.nature_outlined, size: 46, color: Colors.white),
        ),
        const SizedBox(height: 24),
        const Text('No available farmers found', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('Try again later or pick another crop', style: TextStyle(color: Colors.white.withOpacity(.75), fontSize: 13)),
      ],
    ),
  );
}

class _CostPreview extends StatelessWidget {
  final int? quantity;
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
