import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../l10n/app_localizations.dart';

class FarmerRouteScreen extends StatefulWidget {
  const FarmerRouteScreen({super.key});

  @override
  State<FarmerRouteScreen> createState() => _FarmerRouteScreenState();
}

class _FarmerRouteScreenState extends State<FarmerRouteScreen> {
  bool loading = true;
  List<Map<String, dynamic>> inProgressTransactions = [];
  Map<String, Map<String, dynamic>> customerDetails = {};
  
  @override
  void initState() {
    super.initState();
    _fetchInProgressTransactions();
  }

  Future<void> _fetchInProgressTransactions() async {
    setState(() => loading = true);
    
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Fetch farmer's pending transactions
      final doc = await FirebaseFirestore.instance
          .collection('Ongoing_Trans_Farm')
          .doc(userId)
          .get();

      if (!doc.exists) {
        setState(() => loading = false);
        return;
      }

      final data = doc.data() as Map<String, dynamic>;
      final transactions = List<Map<String, dynamic>>.from(data['transactions'] ?? []);
      
      // Filter in-progress transactions (matching actual status values)
      final inProgress = transactions
          .where((t) {
            final status = (t['Status'] ?? '').toString().toLowerCase();
            return status == 'in progress' || status == 'assigned' || status == 'in_transit';
          })
          .toList();

      // Fetch customer details
      final customerIds = inProgress
          .map((t) => t['Customer ID'] as String?)
          .whereType<String>()
          .toSet();

      final customerMap = <String, Map<String, dynamic>>{};
      for (final customerId in customerIds) {
        try {
          final customerDoc = await FirebaseFirestore.instance
              .collection('customers')
              .doc(customerId)
              .get();
          if (customerDoc.exists) {
            customerMap[customerId] = customerDoc.data() as Map<String, dynamic>;
          }
        } catch (e) {
          print('Error fetching customer $customerId: $e');
        }
      }

      setState(() {
        inProgressTransactions = inProgress;
        customerDetails = customerMap;
        loading = false;
      });
    } catch (e) {
      print('Error fetching transactions: $e');
      setState(() => loading = false);
    }
  }

  void _showOptimizedRoute(BuildContext context) async {
    final markers = <Marker>[];
    final polylines = <Polyline>[];
    
    // Farmer location (central Kandy as default - you can get this from farmer profile)
    final farmerLat = 7.2906;
    final farmerLng = 80.6337;
    final farmer = LatLng(farmerLat, farmerLng);
    
    // Customer locations (using dummy coordinates for now - you can replace with real customer coordinates)
    final customerLocations = <LatLng>[];
    for (int i = 0; i < inProgressTransactions.length && i < 5; i++) {
      // Generate dummy locations around Kandy (you can replace with real customer coordinates)
      final lat = 7.2906 + (i * 0.02) - 0.04;
      final lng = 80.6337 + (i * 0.02) - 0.04;
      customerLocations.add(LatLng(lat, lng));
    }

    if (customerLocations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No customers to route to')),
      );
      return;
    }

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
          return [start, end];
        }
      } catch (e) {
        return [start, end];
      }
    }

    // Optimize route using nearest neighbor algorithm
    final List<LatLng> optimizedOrder = [farmer];
    final List<LatLng> remaining = List.from(customerLocations);
    LatLng current = farmer;
    
    while (remaining.isNotEmpty) {
      remaining.sort((a, b) =>
          Distance().as(LengthUnit.Kilometer, current, a)
              .compareTo(Distance().as(LengthUnit.Kilometer, current, b)));
      final next = remaining.removeAt(0);
      optimizedOrder.add(next);
      current = next;
    }

    // Add farmer marker
    markers.add(
      Marker(
        width: 60.0,
        height: 60.0,
        point: farmer,
        child: const Icon(
          Icons.agriculture,
          color: Colors.green,
          size: 32.0,
        ),
      ),
    );

    // Add customer markers with numbers
    for (int i = 1; i < optimizedOrder.length; i++) {
      final customerPoint = optimizedOrder[i];
      markers.add(
        Marker(
          width: 80.0,
          height: 80.0,
          point: customerPoint,
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

    // Draw route segments
    for (int i = 0; i < optimizedOrder.length - 1; i++) {
      final points = await fetchRoute(optimizedOrder[i], optimizedOrder[i + 1]);
      polylines.add(
        Polyline(
          points: points,
          color: const Color(0xFF02C697),
          strokeWidth: 4.0,
        ),
      );
    }

    // Calculate total estimated delivery price (dummy calculation)
    final totalPrice = inProgressTransactions.fold<double>(
      0.0,
      (sum, tx) => sum + (double.tryParse(tx['Total Price']?.toString() ?? '0') ?? 0.0),
    );

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
                const Color(0xFF02C697).withOpacity(0.95),
                const Color(0xFF02C697).withOpacity(0.8),
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
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map, color: Colors.white, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Optimized Delivery Route',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Total Estimated Value: Rs. ${totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF02C697),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white, width: 2),
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
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF02C697),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  ),
                  child: const Text(
                    'Close Map', 
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Delivery Routes',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF2D3748),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3748)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF02C697),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header section with map button
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF02C697),
                          const Color(0xFF02C697).withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF02C697).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.local_shipping,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Delivery Routes',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${inProgressTransactions.length} in-progress deliveries',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (inProgressTransactions.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _showOptimizedRoute(context),
                              icon: const Icon(Icons.map, size: 20),
                              label: const Text('View Optimized Route'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF02C697),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (inProgressTransactions.isEmpty)
                    _buildEmptyState()
                  else ...[
                    // In-progress deliveries list
                    const Text(
                      'In-Progress Deliveries',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Transactions list
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: inProgressTransactions.length,
                      itemBuilder: (context, index) {
                        final transaction = inProgressTransactions[index];
                        return _buildTransactionCard(transaction, index + 1);
                      },
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction, int routeNumber) {
    final crop = transaction['Crop'] ?? 'Unknown Crop';
    final quantity = transaction['Quantity Sold (1kg)'] ?? 0;
    final customerId = transaction['Customer ID'] ?? '';
    final customer = customerDetails[customerId];
    final customerName = customer?['name'] ?? customer?['email'] ?? 'Unknown Customer';
    final contact = customer?['phone'] ?? '';
    final totalPrice = transaction['Total Price']?.toString() ?? '0';
    final date = transaction['Date'] != null
        ? (transaction['Date'] as Timestamp).toDate().toString().split(' ')[0]
        : 'No date';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with route number
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF02C697),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          '$routeNumber',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        crop,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                  ),
                ),
                child: const Text(
                  'In Progress',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Details
          _buildDetailRow(Icons.scale, 'Quantity', '$quantity kg'),
          _buildDetailRow(Icons.person_outline, 'Customer', customerName),
          if (contact.isNotEmpty)
            _buildDetailRow(Icons.phone, 'Contact', contact),
          _buildDetailRow(Icons.calendar_today, 'Date', date),
          _buildDetailRow(Icons.attach_money, 'Value', 'Rs. $totalPrice'),
          
          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (contact.isNotEmpty) {
                      // TODO: Implement phone call
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Calling $customerName...')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No contact number available')),
                      );
                    }
                  },
                  icon: const Icon(Icons.call, size: 16),
                  label: const Text('Contact'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF02C697),
                    side: const BorderSide(color: Color(0xFF02C697)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement individual route navigation
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Individual route navigation coming soon!'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.directions, size: 16),
                  label: const Text('Directions'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF02C697),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF2D3748),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Colors.green[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Pending Deliveries',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All your deliveries are completed or in progress. New routes will appear here when you have pending orders.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
