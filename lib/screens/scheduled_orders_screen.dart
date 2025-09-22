import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ScheduledOrdersScreen extends StatelessWidget {
  const ScheduledOrdersScreen({Key? key}) : super(key: key);

  int getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysOffset = firstDayOfYear.weekday - 1;
    final firstMonday = firstDayOfYear.subtract(Duration(days: daysOffset));
    final diff = date.difference(firstMonday);
    return (diff.inDays / 7).ceil();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0F4F0),
        appBar: AppBar(
          title: const Text('Scheduled Orders'),
          backgroundColor: const Color(0xFF2E7D32),
          elevation: 0,
        ),
        body: const Center(
          child: Text(
            'Not logged in',
            style: TextStyle(color: Color(0xFF558B2F)),
          ),
        ),
      );
    }

    final currentWeek = getWeekNumber(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F0),
      appBar: AppBar(
        title: const Text(
          'Scheduled Orders',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF0F4F0),
              Color(0xFFE8F5E8),
            ],
          ),
        ),
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('ScheduledOrders')
              .doc(user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                ),
              );
            }
            final data = snapshot.data?.data();
            if (data is! Map<String, dynamic>) {
              return const Center(
                child: Text(
                  'Invalid data format.',
                  style: TextStyle(color: Color(0xFF558B2F)),
                ),
              );
            }
            final orders = data['orders'] != null
                ? (data['orders'] as List)
                    .where((e) => e is Map)
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList()
                : [];
            final now = DateTime.now();
            final currentWeek = getWeekNumber(DateTime.now());
            
            if (orders.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/Add_harvest.jpg', 
                      height: 150,
                      color: const Color(0xFF81C784),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No scheduled orders found.',
                      style: TextStyle(
                        color: Color(0xFF558B2F),
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              );
            }
            
            return Column(
              children: [
                // Header Section with Glass Effect
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Manage Your Scheduled Orders',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Clear All Button
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.red.shade400,
                                    Colors.red.shade600,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('ScheduledOrders')
                                      .doc(user.uid)
                                      .set({'orders': []});
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.clear_all, size: 18, color: Colors.white),
                                    SizedBox(width: 6),
                                    Text(
                                      'Clear All',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Schedule for This Week Button
                          if (orders.any((order) => (order['lastScheduledWeek'] as int? ?? -1) != currentWeek))
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF4CAF50),
                                      Color(0xFF2E7D32),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final unavailable = <Map<String, dynamic>>[];
                                    final available = <Map<String, dynamic>>[];
                                    final userId = user.uid;
                                    for (final order in orders) {
                                      final lastScheduledWeek = order['lastScheduledWeek'] as int?;
                                      if (lastScheduledWeek == currentWeek) {
                                        available.add(order);
                                        continue;
                                      }
                                      final farmerId = order['Farmer ID'];
                                      if (farmerId == null) {
                                        unavailable.add(order);
                                        continue;
                                      }
                                      final harvestDoc = await FirebaseFirestore.instance.collection('Harvests').doc(farmerId).get();
                                      if (!harvestDoc.exists) {
                                        unavailable.add(order);
                                        continue;
                                      }
                                      final harvests = List.from(harvestDoc['harvests'] ?? []);
                                      final match = harvests.firstWhere(
                                        (h) => h['crop'] == order['Crop'] &&
                                               h['expectedPrice'] == order['Sale Price Per kg'] &&
                                               h['harvestDate'] == order['Harvest Date'],
                                        orElse: () => null,
                                      );
                                      final reqQty = order['Quantity Sold (1kg)'] ?? 0;
                                      final availQty = match != null ? (match['available'] ?? match['quantity'] ?? 0) : 0;
                                      if (match == null || availQty < reqQty) {
                                        unavailable.add(order);
                                      } else {
                                        available.add(order);
                                      }
                                    }
                                    if (unavailable.isNotEmpty) {
                                      final crops = unavailable.map((o) => o['Crop']).join(', ');
                                      final proceed = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => Dialog(
                                          backgroundColor: Colors.white.withOpacity(0.95),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(20),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.warning_amber_rounded,
                                                  color: Colors.orange.shade700,
                                                  size: 50,
                                                ),
                                                const SizedBox(height: 16),
                                                const Text(
                                                  'Unavailable Crops',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF2E7D32),
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                Text(
                                                  'The following crops are unavailable or do not have enough quantity: $crops.\n\nDo you want to proceed with the available crops only?',
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    color: Color(0xFF558B2F),
                                                  ),
                                                ),
                                                const SizedBox(height: 20),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: TextButton(
                                                        onPressed: () => Navigator.pop(context, false),
                                                        style: TextButton.styleFrom(
                                                          backgroundColor: Colors.grey.shade300,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(10),
                                                          ),
                                                        ),
                                                        child: const Text(
                                                          'Cancel',
                                                          style: TextStyle(color: Colors.grey),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: ElevatedButton(
                                                        onPressed: () => Navigator.pop(context, true),
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: const Color(0xFF4CAF50),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(10),
                                                          ),
                                                        ),
                                                        child: const Text(
                                                          'Proceed',
                                                          style: TextStyle(color: Colors.white),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                      if (proceed != true) return;
                                    }
                                    final batch = FirebaseFirestore.instance.batch();
                                    final docRef = FirebaseFirestore.instance.collection('ScheduledOrders').doc(userId);
                                    final updatedOrders = <Map<String, dynamic>>[];
                                    for (final order in orders) {
                                      final lastScheduledWeek = order['lastScheduledWeek'] as int?;
                                      final isAvailable = available.contains(order);
                                      if (lastScheduledWeek == currentWeek || !isAvailable) {
                                        updatedOrders.add(order);
                                        continue;
                                      }
                                      batch.set(
                                        FirebaseFirestore.instance.collection('Ongoing_Trans_Cus').doc(userId),
                                        {'transactions': FieldValue.arrayUnion([order])},
                                        SetOptions(merge: true),
                                      );
                                      final farmerId = order['Farmer ID'];
                                      if (farmerId != null) {
                                        batch.set(
                                          FirebaseFirestore.instance.collection('Ongoing_Trans_Farm').doc(farmerId),
                                          {
                                            'transactions': FieldValue.arrayUnion([
                                              {
                                                ...order,
                                                'Customer ID': userId,
                                                'Customer Name': order['Customer Name'] ?? '',
                                                'Customer Email': order['Customer Email'] ?? '',
                                              }
                                            ]),
                                          },
                                          SetOptions(merge: true),
                                        );
                                      }
                                      updatedOrders.add({...order, 'lastScheduledWeek': currentWeek});
                                    }
                                    batch.set(docRef, {'orders': updatedOrders});
                                    await batch.commit();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          unavailable.isEmpty
                                            ? 'Scheduled orders added to transactions for this week!'
                                            : 'Some crops were unavailable and skipped. Others scheduled.',
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                        backgroundColor: unavailable.isEmpty ? const Color(0xFF4CAF50) : Colors.orange,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.schedule, size: 18, color: Colors.white),
                                      SizedBox(width: 6),
                                      Text(
                                        'Schedule This Week',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Orders List
                Expanded(
                  child: ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (context, idx) {
                      final order = orders[idx];
                      final lastScheduledWeek = order['lastScheduledWeek'] as int?;
                      final alreadyScheduled = lastScheduledWeek == currentWeek;
                      
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                        child: GlassCard(
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFC8E6C9)),
                              ),
                              child: Icon(
                                _getCropIcon(order['Crop']?.toString().toLowerCase() ?? ''),
                                color: const Color(0xFF2E7D32),
                                size: 24,
                              ),
                            ),
                            title: Text(
                              '${order['Crop']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  '${order['Quantity Sold (1kg)']} kg • LKR ${order['Sale Price Per kg']}',
                                  style: const TextStyle(
                                    color: Color(0xFF558B2F),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Farmer: ${order['Farmer Name']}',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                if (alreadyScheduled)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5E9),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFF4CAF50)),
                                    ),
                                    child: const Text(
                                      'Scheduled for this week',
                                      style: TextStyle(
                                        color: Color(0xFF2E7D32),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.red.shade100),
                                ),
                                child: Icon(
                                  Icons.delete_outline,
                                  color: Colors.red.shade600,
                                  size: 20,
                                ),
                              ),
                              tooltip: 'Delete',
                              onPressed: () async {
                                final updatedOrders = List<Map<String, dynamic>>.from(orders)..removeAt(idx);
                                await FirebaseFirestore.instance
                                    .collection('ScheduledOrders')
                                    .doc(user.uid)
                                    .set({'orders': updatedOrders});
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  IconData _getCropIcon(String cropName) {
    if (cropName.contains('rice') || cropName.contains('paddy')) {
      return Icons.grass;
    } else if (cropName.contains('vegetable') || cropName.contains('green')) {
      return Icons.eco;
    } else if (cropName.contains('fruit')) {
      return Icons.apple;
    } else if (cropName.contains('grain') || cropName.contains('wheat')) {
      return Icons.grain;
    } else {
      return Icons.spa;
    }
  }
}

// Glassmorphism Card Widget
class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blurRadius;

  const GlassCard({
    Key? key,
    required this.child,
    this.borderRadius = 16,
    this.blurRadius = 20,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: blurRadius,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: child,
    );
  }
}