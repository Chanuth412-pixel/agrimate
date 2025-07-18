import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
    setState(() {
      transactions = txs;
      customerDetails = customerMap;
      farmerDetails = farmerMap;
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
      builder: (context) => AlertDialog(
        // Remove the title
        // title: const Text('Segmented Shortest Routes: Farmer → Nearest → Next → Last'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              const Text('Total Delivery Price: Rs. 226.00',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue)),
              const SizedBox(height: 8),
              SizedBox(
                width: 400,
                height: 400,
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
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Driver Transactions')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : transactions.isEmpty
              ? const Center(child: Text('No transactions found.'))
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final tx = transactions[index];
                          final customerId = tx['Customer ID'] as String?;
                          final farmerId = tx['Farmer ID'] as String?;
                          final customerName = customerId != null && customerDetails[customerId] != null
                              ? (customerDetails[customerId]!['name'] ?? customerDetails[customerId]!['email'] ?? 'Unknown')
                              : 'Unknown';
                          return ListTile(
                            title: Text('Transaction ${index + 1}'),
                            subtitle: Text('Customer: $customerName'),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        onPressed: () => _showCustomersOnMap(context),
                        child: const Text('Show Optimized Route Map'),
                      ),
                    ),
                  ],
                ),
    );
  }
}

// NOTE: Do not use this screen with named routes unless you pass farmerId as an argument.
// Instead, always use Navigator.push with MaterialPageRoute and provide the required parameter, e.g.:
// Navigator.push(context, MaterialPageRoute(builder: (_) => DriverProfileScreen(farmerId: 'your_farmer_id')));
