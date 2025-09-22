import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});
  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool loading = true;
  List<Map<String, dynamic>> transactions = [];
  Map<String, Map<String, dynamic>> customerDetails = {};
  Map<String, Map<String, dynamic>> farmerDetails = {};
  Map<String, List<Map<String, dynamic>>> _ordersByFarmer = {};
  Map<String, dynamic> _farmerInfo = {};

  @override
  void initState() {
    super.initState();
    _fetchTransactionsAndCustomers();
  }

  Future<void> _fetchTransactionsAndCustomers() async {
    setState(() => loading = true);
    // Fetch all documents in Ongoing_Trans_Farm and collect all transactions arrays
    final allDocs = await _firestore.collection('Ongoing_Trans_Farm').get();
    List<Map<String, dynamic>> txs = [];
    for (var doc in allDocs.docs) {
      final data = doc.data();
      if (data['transactions'] is List) {
        txs.addAll(List<Map<String, dynamic>>.from(data['transactions']));
      }
    }
    // Fetch all unique customer IDs
    final customerIds = txs.map((tx) => tx['Customer ID'] as String?).whereType<String>().toSet();
    final customerDocs = await Future.wait(customerIds.map((id) =>
        _firestore.collection('customers').doc(id).get()));
    final customerMap = <String, Map<String, dynamic>>{};
    for (var doc in customerDocs) {
      if (doc.exists) {
        customerMap[doc.id] = doc.data() as Map<String, dynamic>;
      }
    }
    // Fetch all unique farmer UIDs from transactions
    final farmerUids = txs.map((tx) => tx['Farmer ID'] as String?).whereType<String>().toSet();
    final farmerDocs = await Future.wait(farmerUids.map((id) =>
        _firestore.collection('farmers').doc(id).get()));
    final farmerMap = <String, Map<String, dynamic>>{};
    for (var doc in farmerDocs) {
      if (doc.exists) {
        farmerMap[doc.id] = doc.data() as Map<String, dynamic>;
      }
    }
    // Group transactions by farmer, but only include those with deliveryMethod == 'delivery_guy', Status == 'Pending', and deliver_status != 'assigned'
    final Map<String, List<Map<String, dynamic>>> ordersByFarmer = {};
    final Map<String, dynamic> farmerInfo = {};
    for (var tx in txs) {
      final farmerId = tx['Farmer ID'];
      if (farmerId == null) continue;
      if (tx['deliveryMethod'] == 'delivery_guy' && (tx['Status'] ?? '').toLowerCase() == 'pending' && (tx['deliver_status'] ?? '') != 'assigned') {
        ordersByFarmer.putIfAbsent(farmerId, () => []).add(tx);
        if (farmerMap[farmerId] != null) {
          farmerInfo[farmerId] = farmerMap[farmerId];
        }
      }
    }
    setState(() {
      transactions = txs;
      customerDetails = customerMap;
      farmerDetails = farmerMap;
      _ordersByFarmer = ordersByFarmer;
      _farmerInfo = farmerInfo;
      loading = false;
    });
  }

  void _showCustomersOnMap(BuildContext context) async {
    final markers = <Marker>[];
    final polylines = <Polyline>[];
    // Farmer location (central Kandy)
    final farmerLat = 7.2906;
    final farmerLng = 80.6337;
    final farmer = LatLng(farmerLat, farmerLng);
    // Customer locations (dummy)
    final customers = [
      LatLng(7.3176, 80.6337), // 3km North
      LatLng(7.2816, 80.6337), // 1km South
      LatLng(7.2906, 80.6427), // 1km East
    ];
    // ORS API key
    final apiKey = 'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjQyMTE3MTg5NWU4MTQ1MWI5NDNjYThmMDY3ZDc4NmI5IiwiaCI6Im11cm11cjY0In0=';
    // Helper to fetch a route between two points
    Future<List<LatLng>> fetchRoute(LatLng start, LatLng end) async {
      try {
        final url = Uri.parse('https://api.openrouteservice.org/v2/directions/driving-car/geojson');
        final body = jsonEncode({
          'coordinates': [
            [start.longitude, start.latitude],
            [end.longitude, end.latitude],
          ],
          'instructions': false,
        });
        final response = await http.post(
          url,
          headers: {
            'Authorization': apiKey,
            'Content-Type': 'application/json',
          },
          body: body,
        );
        if (response.statusCode == 200) {
          final geojson = jsonDecode(response.body);
          final coordsList = geojson['features'][0]['geometry']['coordinates'] as List;
          return coordsList.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
        } else {
          // Fallback: straight line
          return [start, end];
        }
      } catch (e) {
        // Fallback: straight line
        return [start, end];
      }
    }
    // Greedy nearest-neighbor order: farmer -> nearest -> next nearest -> last
    final List<LatLng> order = [farmer];
    final List<LatLng> remaining = List.from(customers);
    LatLng current = farmer;
    while (remaining.isNotEmpty) {
      remaining.sort((a, b) =>
        Distance().as(LengthUnit.Kilometer, current, a)
          .compareTo(Distance().as(LengthUnit.Kilometer, current, b)));
      final next = remaining.removeAt(0);
      order.add(next);
      current = next;
    }
    // Add farmer marker (orange)
    markers.add(
      Marker(
        width: 60.0,
        height: 60.0,
        point: farmer,
        child: const Icon(
          Icons.agriculture,
          color: Colors.orange,
          size: 32.0,
        ),
      ),
    );
    // Add customer markers (red, with numbers 1, 2, 3 according to order)
    for (int i = 1; i < order.length; i++) {
      final c = order[i];
      markers.add(
        Marker(
          width: 80.0,
          height: 80.0,
          point: c,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.location_on,
                color: Colors.red,
                size: 40.0,
              ),
              Positioned(
                top: 18,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$i',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    // Draw each segment in the same color (blue)
    for (int i = 0; i < 3; i++) {
      final points = await fetchRoute(order[i], order[i + 1]);
      polylines.add(
        Polyline(
          points: points,
          color: Colors.blue,
          strokeWidth: 4.0,
        ),
      );
    }
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.green.shade100.withOpacity(0.9),
                Colors.lightGreen.shade100.withOpacity(0.9),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade800,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map, color: Colors.white, size: 24),
                      SizedBox(width: 8),
                      Text('Optimized Delivery Route',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white,
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Text('Total Delivery Price: Rs. 226.00',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green.shade800,
                      )),
                ),
                const SizedBox(height: 16),
                Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.green.shade400, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: FlutterMap(
                      options: MapOptions(
                        center: farmer,
                        zoom: 12.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                          subdomains: const ['a', 'b', 'c'],
                          userAgentPackageName: 'com.example.agrimate',
                        ),
                        PolylineLayer(polylines: polylines),
                        MarkerLayer(markers: markers),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  ),
                  child: const Text('Close Map', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final driverId = user?.uid;
    // Ongoing deliveries for this driver
    final List<Map<String, dynamic>> ongoingDeliveries = transactions.where((tx) =>
      tx['deliver_status'] == 'assigned' && tx['delivery_guy_id'] == driverId
    ).toList();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/Background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Container(
            color: Colors.white.withOpacity(0.1),
            child: loading
                ? _buildLoadingScreen()
                : _ordersByFarmer.isEmpty && ongoingDeliveries.isEmpty
                    ? _buildEmptyState()
                    : _buildContent(context, ongoingDeliveries, driverId),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white.withOpacity(0.2),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade700),
              strokeWidth: 4,
            ),
            const SizedBox(height: 20),
            Text(
              'Loading Deliveries...',
              style: TextStyle(
                color: Colors.green.shade800,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Please wait while we fetch your orders',
              style: TextStyle(
                color: Colors.green.shade600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white.withOpacity(0.15),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2,
              size: 80,
              color: Colors.green.shade300,
            ),
            const SizedBox(height: 20),
            Text(
              'No Deliveries Available',
              style: TextStyle(
                color: Colors.green.shade800,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'There are currently no pending deliveries assigned to you.',
              style: TextStyle(
                color: Colors.green.shade600,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<Map<String, dynamic>> ongoingDeliveries, String? driverId) {
    return Column(
      children: [
        // App Bar with Glass Effect
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Row(
              children: [
                Icon(Icons.local_shipping, color: Colors.green.shade700),
                const SizedBox(width: 10),
                const Text(
                  'Driver Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            centerTitle: true,
          ),
        ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ongoing Deliveries Section
                if (ongoingDeliveries.isNotEmpty) ...[
                  _buildSectionHeader('🚚 Ongoing Deliveries', Icons.delivery_dining),
                  const SizedBox(height: 10),
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Colors.white.withOpacity(0.1),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: ListView.builder(
                        itemCount: ongoingDeliveries.length,
                        itemBuilder: (context, index) {
                          final tx = ongoingDeliveries[index];
                          return _buildDeliveryCard(tx, true);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Available Farmers Section
                _buildSectionHeader('👨‍🌾 Available Farmers', Icons.agriculture),
                const SizedBox(height: 10),
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.white.withOpacity(0.1),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: _ordersByFarmer.keys.isEmpty
                        ? Center(
                            child: Text(
                              'No farmers with pending deliveries',
                              style: TextStyle(
                                color: Colors.green.shade600,
                                fontSize: 16,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _ordersByFarmer.keys.length,
                            itemBuilder: (context, index) {
                              final farmerId = _ordersByFarmer.keys.elementAt(index);
                              final farmer = _farmerInfo[farmerId] ?? {};
                              return _buildFarmerCard(farmerId, farmer);
                            },
                          ),
                  ),
                ),

                // Map Button
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: LinearGradient(
                        colors: [
                          Colors.green.shade600,
                          Colors.lightGreen.shade600,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.shade800.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => _showCustomersOnMap(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.map, color: Colors.white, size: 24),
                          const SizedBox(width: 10),
                          Text(
                            'View Optimized Route',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.shade800.withOpacity(0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryCard(Map<String, dynamic> tx, bool isOngoing) {
    final crop = tx['Crop'] ?? '';
    final status = tx['Status'] ?? '';
    final quantity = tx['Quantity Sold (1kg)'] ?? '';
    final farmerName = tx['Farmer Name'] ?? 'Unknown';
    final customerId = tx['Customer ID'] ?? '';
    final customerName = customerId != '' && customerDetails[customerId] != null
        ? (customerDetails[customerId]!['name'] ?? customerDetails[customerId]!['email'] ?? 'Unknown')
        : 'Unknown';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            Colors.green.shade50.withOpacity(0.8),
            Colors.lightGreen.shade50.withOpacity(0.8),
          ],
        ),
        border: Border.all(color: Colors.green.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade100.withOpacity(0.5),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.local_shipping,
            color: Colors.green.shade700,
            size: 30,
          ),
        ),
        title: Text(
          crop,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green.shade800,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: $status', style: TextStyle(color: Colors.green.shade600)),
            Text('Quantity: $quantity kg', style: TextStyle(color: Colors.green.shade600)),
            Text('Farmer: $farmerName', style: TextStyle(color: Colors.green.shade600)),
            Text('Customer: $customerName', style: TextStyle(color: Colors.green.shade600)),
          ],
        ),
        trailing: isOngoing && status != 'in_transit'
            ? Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade400, Colors.orange.shade600],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ElevatedButton(
                  onPressed: () async {
                    await _markAsInTransit(tx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text(
                    'Picked Up',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              )
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Text(
                  'In Transit',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildFarmerCard(String farmerId, Map<String, dynamic> farmer) {
    final orders = _ordersByFarmer[farmerId] ?? [];
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.8),
            Colors.green.shade50.withOpacity(0.7),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.green.shade300),
          ),
          child: Icon(
            Icons.agriculture,
            color: Colors.green.shade700,
            size: 28,
          ),
        ),
        title: Text(
          farmer['name'] ?? 'Unknown Farmer',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green.shade900,
            fontSize: 16,
            shadows: [
              Shadow(
                offset: const Offset(0, 1),
                blurRadius: 2.0,
                color: Colors.black.withOpacity(0.2),
              ),
            ],
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (farmer['phone'] != null)
              Text('📞 ${farmer['phone']}', style: TextStyle(color: Colors.green.shade600)),
            Text('📦 ${orders.length} order(s) pending', style: TextStyle(color: Colors.orange.shade600)),
          ],
        ),
        trailing: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade500, Colors.lightGreen.shade500],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: ElevatedButton(
            onPressed: () => _showOrdersForFarmer(context, farmerId),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text(
              'View Orders',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  void _showOrdersForFarmer(BuildContext context, String farmerId) {
    final orders = _ordersByFarmer[farmerId] ?? [];
    final farmer = _farmerInfo[farmerId] ?? {};
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.green.shade100.withOpacity(0.95),
                Colors.lightGreen.shade100.withOpacity(0.95),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade800,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.agriculture, color: Colors.white, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Orders from ${farmer['name'] ?? 'Farmer'}',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 400,
                  height: 300,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: orders.length,
                    itemBuilder: (context, idx) {
                      final tx = orders[idx];
                      return _buildOrderItem(tx, idx + 1);
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        await _assignAllDeliveriesForFarmer(farmerId, orders);
                        Navigator.pop(context);
                        _fetchTransactionsAndCustomers();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Take All Deliveries'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> tx, int orderNumber) {
    final crop = tx['Crop'] ?? '';
    final status = tx['Status'] ?? '';
    final quantity = tx['Quantity Sold (1kg)'] ?? '';
    final customerId = tx['Customer ID'] ?? '';
    final customerName = customerId != '' && customerDetails[customerId] != null
        ? (customerDetails[customerId]!['name'] ?? customerDetails[customerId]!['email'] ?? 'Unknown')
        : 'Unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade100,
          child: Text('$orderNumber', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold)),
        ),
        title: Text(crop, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: $status', style: TextStyle(color: Colors.green.shade600)),
            Text('Quantity: $quantity kg', style: TextStyle(color: Colors.green.shade600)),
            Text('Customer: $customerName', style: TextStyle(color: Colors.green.shade600)),
          ],
        ),
      ),
    );
  }

  Future<void> _assignAllDeliveriesForFarmer(String farmerId, List<Map<String, dynamic>> orders) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final driverId = user.uid;
    // Fetch driver name and phone from 'drivers' collection
    final driverDoc = await _firestore.collection('drivers').doc(driverId).get();
    final driverName = driverDoc.data()?['name'] ?? 'Unknown';
    final driverPhone = driverDoc.data()?['phone'] ?? '';
    final docRef = _firestore.collection('Ongoing_Trans_Farm').doc(farmerId);
    final doc = await docRef.get();
    if (!doc.exists) return;
    final data = doc.data() as Map<String, dynamic>;
    final txs = List<Map<String, dynamic>>.from(data['transactions'] ?? []);

    // Batch update all eligible transactions (those in orders)
    final updatedTxs = txs.map((t) {
      final isEligible = orders.any((o) => o['Date'] == t['Date'] && o['Customer ID'] == t['Customer ID']);
      if (isEligible) {
        final updated = Map<String, dynamic>.from(t);
        updated['deliver_status'] = 'assigned';
        updated['delivery_guy_id'] = driverId;
        updated['delivery_guy_name'] = driverName;
        updated['delivery_guy_phone'] = driverPhone;
        return updated;
      }
      return t;
    }).toList();
    await docRef.update({'transactions': updatedTxs});

    // Add all to Ongoing_Trans_Deliver for this driver
    final farmerDoc = await _firestore.collection('farmers').doc(farmerId).get();
    final farmerData = farmerDoc.data() ?? {};
    for (final tx in orders) {
      final customerId = tx['Customer ID'];
      Map<String, dynamic> customerData = {};
      if (customerId != null) {
        final customerDoc = await _firestore.collection('customers').doc(customerId).get();
        customerData = customerDoc.data() ?? {};
      }
      final deliveryTx = {
        ...tx,
        'deliver_status': 'assigned',
        'delivery_guy_id': driverId,
        'delivery_guy_name': driverName,
        'delivery_guy_phone': driverPhone,
        'farmer_name': farmerData['name'] ?? '',
        'farmer_phone': farmerData['phone'] ?? '',
        'farmer_email': farmerData['email'] ?? '',
        'customer_name': customerData['name'] ?? '',
        'customer_phone': customerData['phone'] ?? '',
        'customer_email': customerData['email'] ?? '',
      };
      await _firestore.collection('Ongoing_Trans_Deliver').doc(driverId).set({
        'transactions': FieldValue.arrayUnion([deliveryTx])
      }, SetOptions(merge: true));
      // Update customer transaction with delivery guy info
      await _updateCustomerTransaction(
        customerId: customerId,
        date: tx['Date'],
        updates: {
          'deliver_status': 'assigned',
          'delivery_guy_id': driverId,
          'delivery_guy_name': driverName,
          'delivery_guy_phone': driverPhone,
        },
      );
    }
  }

  Future<void> _markAsInTransit(Map<String, dynamic> tx) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final driverId = user.uid;
    final farmerId = tx['Farmer ID'];
    final customerId = tx['Customer ID'];
    final date = tx['Date'];
    // Update in Ongoing_Trans_Farm
    final farmDocRef = _firestore.collection('Ongoing_Trans_Farm').doc(farmerId);
    final farmDoc = await farmDocRef.get();
    if (farmDoc.exists) {
      final data = farmDoc.data() as Map<String, dynamic>;
      final txs = List<Map<String, dynamic>>.from(data['transactions'] ?? []);
      final updatedTxs = txs.map((t) {
        if (t['Date'] == date && t['Customer ID'] == customerId) {
          final updated = Map<String, dynamic>.from(t);
          updated['Status'] = 'in_transit';
          return updated;
        }
        return t;
      }).toList();
      await farmDocRef.update({'transactions': updatedTxs});
    }
    // Update in Ongoing_Trans_Deliver
    final deliverDocRef = _firestore.collection('Ongoing_Trans_Deliver').doc(driverId);
    final deliverDoc = await deliverDocRef.get();
    if (deliverDoc.exists) {
      final data = deliverDoc.data() as Map<String, dynamic>;
      final txs = List<Map<String, dynamic>>.from(data['transactions'] ?? []);
      final updatedTxs = txs.map((t) {
        if (t['Date'] == date && t['Customer ID'] == customerId) {
          final updated = Map<String, dynamic>.from(t);
          updated['Status'] = 'in_transit';
          return updated;
        }
        return t;
      }).toList();
      await deliverDocRef.update({'transactions': updatedTxs});
    }
    // Update in Ongoing_Trans_Cus for the customer
    await _updateCustomerTransaction(
      customerId: customerId,
      date: date,
      updates: {'Status': 'in_transit'},
    );
    await _fetchTransactionsAndCustomers();
  }

  Future<void> _updateCustomerTransaction({
    required String customerId,
    required dynamic date,
    required Map<String, dynamic> updates,
  }) async {
    final docRef = _firestore.collection('Ongoing_Trans_Cus').doc(customerId);
    final doc = await docRef.get();
    if (!doc.exists) return;
    final data = doc.data() as Map<String, dynamic>;
    final txs = List<Map<String, dynamic>>.from(data['transactions'] ?? []);
    final updatedTxs = txs.map((t) {
      if (t['Date'] == date) {
        final updated = Map<String, dynamic>.from(t);
        updates.forEach((key, value) => updated[key] = value);
        return updated;
      }
      return t;
    }).toList();
    await docRef.update({'transactions': updatedTxs});
  }
}

// NOTE: Do not use this screen with named routes unless you pass farmerId as an argument.
// Instead, always use Navigator.push with MaterialPageRoute and provide the required parameter, e.g.:
// Navigator.push(context, MaterialPageRoute(builder: (_) => DriverProfileScreen(farmerId: 'your_farmer_id')));
