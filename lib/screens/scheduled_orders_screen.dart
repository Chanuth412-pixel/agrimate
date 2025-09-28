import 'dart:ui';
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
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            _buildHeader(170, 'Please log in to view scheduled orders', 'Scheduled Orders'),
            const Center(child: Text('Not logged in', style: TextStyle(color: Colors.black54))),
          ],
        ),
      );
    }

    const double headerHeight = 170;
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('ScheduledOrders')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Stack(
              children: [
                _buildHeader(headerHeight, 'Loading scheduled orders...', 'Scheduled Orders'),
                const Center(child: CircularProgressIndicator(color: Color(0xFF02C697))),
              ],
            );
          }
          final data = snapshot.data?.data();
          List<Map<String, dynamic>> orders = [];
          if (data is Map<String, dynamic>) {
            orders = data['orders'] != null
                ? (data['orders'] as List)
                    .where((e) => e is Map)
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList()
                : [];
          }
          final int count = orders.length;
          final subtitle = count == 0
              ? 'No scheduled orders'
              : (count == 1 ? '1 scheduled order' : '$count scheduled orders');
          final currentWeek = getWeekNumber(DateTime.now());

            if (count == 0) {
              return Stack(
                children: [
                  _buildHeader(headerHeight, subtitle, 'Scheduled Orders'),
                  Padding(
                    padding: EdgeInsets.only(top: headerHeight + 10),
                    child: _emptyOrders(),
                  ),
                ],
              );
            }

          return Stack(
            children: [
              // Orders list
              ListView.builder(
                padding: EdgeInsets.fromLTRB(16, headerHeight + 12, 16, 32),
                itemCount: orders.length + 1, // +1 for actions card
                itemBuilder: (context, idx) {
                  if (idx == 0) {
                    return _ScheduleActionsCard(
                      orders: orders,
                      userId: user.uid,
                      currentWeek: currentWeek,
                    );
                  }
                  final order = orders[idx - 1];
                  return _OrderCard(
                    order: order,
                    cropIcon: _getCropIcon(order['Crop']?.toString().toLowerCase() ?? ''),
                    currentWeek: currentWeek,
                    onDelete: () async {
                      final updatedOrders = List<Map<String, dynamic>>.from(orders)..remove(order);
                      await FirebaseFirestore.instance
                          .collection('ScheduledOrders')
                          .doc(user.uid)
                          .set({'orders': updatedOrders});
                    },
                  );
                },
              ),
              _buildHeader(headerHeight, subtitle, 'Scheduled Orders'),
            ],
          );
        },
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

// ===================== NEW DESIGN HELPERS (mirroring farmer screen) =====================

Widget _buildHeader(double height, String subtitle, String title) {
  return SizedBox(
    height: height,
    child: Stack(
      children: [
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
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _GlassBackButton(),
                const Spacer(),
                Text(
                  'Overview •',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: .4,
                  ),
                ),
                Text(
                  title,
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

class _ScheduleActionsCard extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  final String userId;
  final int currentWeek;
  const _ScheduleActionsCard({required this.orders, required this.userId, required this.currentWeek});

  @override
  Widget build(BuildContext context) {
    final showSchedule = orders.any((o) => (o['lastScheduledWeek'] as int? ?? -1) != currentWeek);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
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
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Manage Scheduled Orders',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF142017),
                    letterSpacing: .25,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _glassAction(
                      context,
                      icon: Icons.delete_sweep_outlined,
                      label: 'Clear All',
                      color: const Color(0xFFD32F2F),
                      onTap: () async {
                        await FirebaseFirestore.instance
                            .collection('ScheduledOrders')
                            .doc(userId)
                            .set({'orders': []});
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All scheduled orders cleared')));
                      },
                    ),
                    if (showSchedule) const SizedBox(width: 12),
                    if (showSchedule)
                      _glassAction(
                        context,
                        icon: Icons.schedule,
                        label: 'Schedule Week',
                        color: const Color(0xFF026E55),
                        onTap: () async {
                          final unavailable = <Map<String, dynamic>>[];
                          final available = <Map<String, dynamic>>[];
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
                                content: Text('Some crops are unavailable or have insufficient quantity: $crops. Proceed with available ones?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                  ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Proceed')),
                                ],
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
                                    ? 'Orders scheduled for this week!'
                                    : 'Some unavailable crops skipped, others scheduled.',
                              ),
                              backgroundColor: unavailable.isEmpty ? const Color(0xFF02C697) : Colors.orange,
                            ),
                          );
                        },
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
}

Widget _glassAction(BuildContext context, {required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
  return Expanded(
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: color.withOpacity(.12),
          border: Border.all(color: color.withOpacity(.45)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color.darken())),
          ],
        ),
      ),
    ),
  );
}

extension _ColorShade on Color {
  Color darken([double amount = .25]) {
    final hsl = HSLColor.fromColor(this);
    final h = hsl.hue;
    final s = hsl.saturation;
    final l = (hsl.lightness - amount).clamp(0.0, 1.0);
    return HSLColor.fromAHSL(hsl.alpha, h, s, l).toColor();
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final IconData cropIcon;
  final int currentWeek;
  final VoidCallback onDelete;
  const _OrderCard({required this.order, required this.cropIcon, required this.currentWeek, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final lastScheduledWeek = order['lastScheduledWeek'] as int?;
    final alreadyScheduled = lastScheduledWeek == currentWeek;
    final quantity = order['Quantity Sold (1kg)'];
    final unitPrice = order['Sale Price Per kg'];
    final farmerName = order['Farmer Name'] ?? 'Unknown';
    final harvestDate = order['Harvest Date'];
    String? harvestDisplay;
    if (harvestDate is Timestamp) {
      harvestDisplay = harvestDate.toDate().toIso8601String().split('T').first;
    } else if (harvestDate is String) {
      harvestDisplay = harvestDate.split('T').first;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
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
                  child: Icon(cropIcon, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              order['Crop']?.toString() ?? 'Crop',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF142017),
                                letterSpacing: .25,
                              ),
                            ),
                          ),
                          if (alreadyScheduled)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF02C697).withOpacity(.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF02C697).withOpacity(.6)),
                              ),
                              child: const Text(
                                'This week',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF024D3B),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _detailLine(label: 'Quantity', value: '$quantity kg', icon: Icons.inventory_2_outlined),
                      _detailLine(label: 'Price per kg', value: 'LKR $unitPrice', icon: Icons.sell_outlined),
                      _detailLine(label: 'Farmer', value: farmerName, icon: Icons.person_outline),
                      if (harvestDisplay != null)
                        _detailLine(label: 'Harvest date', value: harvestDisplay, icon: Icons.calendar_today_outlined),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _orderActionButton(icon: Icons.delete_outline, label: 'Remove', onTap: onDelete),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _orderActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.red.withOpacity(.45)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: Colors.red.shade700),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: Colors.red.shade800,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  letterSpacing: .3,
                ),
              ),
            ],
          ),
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

Widget _emptyOrders() {
  return Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
            Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF02C697).withOpacity(.12),
              border: Border.all(color: const Color(0xFF02C697).withOpacity(.4)),
            ),
            child: const Icon(Icons.schedule, size: 44, color: Color(0xFF02C697)),
          ),
          const SizedBox(height: 26),
          const Text('No scheduled orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF142017))),
          const SizedBox(height: 8),
          Text('Once you schedule orders they will appear here with weekly status.', style: TextStyle(fontSize: 13, color: Colors.grey.shade600), textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}