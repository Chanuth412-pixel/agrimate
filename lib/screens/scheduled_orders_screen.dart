import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:intl/intl.dart';

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
        appBar: AppBar(title: const Text('Scheduled Orders')),
        body: const Center(child: Text('Not logged in')),
      );
    }

    final currentWeek = getWeekNumber(DateTime.now());

    // rest of your build() remains the same...

    return Scaffold(
      appBar: AppBar(title: const Text('Scheduled Orders')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('ScheduledOrders')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data?.data();
          if (data is! Map<String, dynamic>) return const Center(child: Text('Invalid data format.'));
          final orders = data['orders'] != null
            ? (data['orders'] as List)
                .where((e) => e is Map)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList()
            : [];
          final now = DateTime.now();
          final currentWeek = getWeekNumber(DateTime.now());
          if (orders.isEmpty) {
            return const Center(child: Text('No scheduled orders found.'));
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        // Clear all scheduled orders
                        await FirebaseFirestore.instance
                            .collection('ScheduledOrders')
                            .doc(user.uid)
                            .set({'orders': []});
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Clear All'),
                    ),
                    const SizedBox(width: 16),
                    if (orders.any((order) => (order['lastScheduledWeek'] as int? ?? -1) != currentWeek))
                      ElevatedButton(
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
                              builder: (context) => AlertDialog(
                                title: const Text('Unavailable Crops'),
                                content: Text('The following crops are unavailable or do not have enough quantity: $crops.\n\nDo you want to proceed with the available crops only?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Proceed'),
                                  ),
                                ],
                              ),
                            );
                            if (proceed != true) return;
                          }
                          // Only schedule available orders
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
                            // Add to Ongoing_Trans_Cus
                            batch.set(
                              FirebaseFirestore.instance.collection('Ongoing_Trans_Cus').doc(userId),
                              {'transactions': FieldValue.arrayUnion([order])},
                              SetOptions(merge: true),
                            );
                            // Add to Ongoing_Trans_Farm
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
                          // Update scheduled orders with new lastScheduledWeek
                          batch.set(docRef, {'orders': updatedOrders});
                          await batch.commit();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(unavailable.isEmpty
                              ? 'Scheduled orders added to transactions for this week!'
                              : 'Some crops were unavailable and skipped. Others scheduled.')),
                          );
                        },
                        child: const Text('Schedule for This Week'),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, idx) {
                    final order = orders[idx];
                    final lastScheduledWeek = order['lastScheduledWeek'] as int?;
                    final alreadyScheduled = lastScheduledWeek == currentWeek;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                      child: ListTile(
                        title: Text('${order['Crop']} - ${order['Quantity Sold (1kg)']}kg'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Farmer: ${order['Farmer Name']}'),
                            Text('Status: ${order['Status']}'),
                            if (alreadyScheduled)
                              const Text('Scheduled for this week', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('LKR ${order['Sale Price Per kg']}'),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Delete',
                              onPressed: () async {
                                final updatedOrders = List<Map<String, dynamic>>.from(orders)..removeAt(idx);
                                await FirebaseFirestore.instance
                                    .collection('ScheduledOrders')
                                    .doc(user.uid)
                                    .set({'orders': updatedOrders});
                              },
                            ),
                          ],
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
    );
  }
}