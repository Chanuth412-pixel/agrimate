import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'review_customer_screen.dart';

class OngoingTransactionsScreen extends StatefulWidget {
  const OngoingTransactionsScreen({super.key});

  @override
  State<OngoingTransactionsScreen> createState() => _OngoingTransactionsScreenState();
}

class _OngoingTransactionsScreenState extends State<OngoingTransactionsScreen> {
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/Background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with greeting and back button
              Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.black.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('farmers')
                      .doc(userId)
                      .get(),
                  builder: (context, snapshot) {
                    String farmerName = 'Farmer';
                    if (snapshot.hasData && snapshot.data!.exists) {
                      final data = snapshot.data!.data() as Map<String, dynamic>?;
                      farmerName = data?['name'] ?? 'Farmer';
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row with back button and title
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getGreeting(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    farmerName,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Page title
                        Text(
                          'Ongoing Transactions',
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              // Content area
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('Ongoing_Trans_Farm')
                        .doc(userId)
                        .get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(
                              color: Color(0xFF02C697),
                            ),
                          ),
                        );
                      }

                      final data = snapshot.data!.data() as Map<String, dynamic>?;
                      if (data == null || !data.containsKey('transactions')) {
                        return _buildEmptyState('No transactions found.');
                      }

                      var rawList = List<Map<String, dynamic>>.from(data['transactions']);
                      // Mark any unseen transactions as seen (batch in-memory update then push once)
                      bool needUpdate = false;
                      for (final tx in rawList) {
                        if (tx['seen_farmer'] != true) {
                          tx['seen_farmer'] = true;
                          needUpdate = true;
                        }
                      }
                      if (needUpdate && userId != null) {
                        FirebaseFirestore.instance
                            .collection('Ongoing_Trans_Farm')
                            .doc(userId)
                            .update({'transactions': rawList})
                            .catchError((e){ debugPrint('Failed to mark seen: $e'); });
                      }
                      // Sort newest first by orderPlacedAt fallback Date
                      rawList.sort((a, b) {
                        dynamic aKey = a['orderPlacedAt'] ?? a['Date'];
                        dynamic bKey = b['orderPlacedAt'] ?? b['Date'];
                        if (aKey is Timestamp && bKey is Timestamp) {
                          return bKey.compareTo(aKey);
                        }
                        return 0;
                      });
                      // Filter out archived transactions for farmer view
                      final transactions = rawList.where((t) => t['archived_farmer'] != true).toList();
                      if (transactions.isEmpty) {
                        return _buildEmptyState('No ongoing transactions.');
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.all(24),
                        itemCount: transactions.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final tx = transactions[index];
                          return _buildTransactionCard(tx, userId, transactions);
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No Ongoing Transactions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> tx, String? userId, List<Map<String, dynamic>> transactions) {
    final crop = tx['Crop'] ?? 'Unknown';
    final quantity = tx['Quantity Sold (1kg)'] ?? 0;
  final price = tx['Sale Price Per kg'] ?? 0;
    final status = tx['Status'] ?? 'Pending';
  final initialCustomerName = tx['Customer Name'] ?? tx['customerName'] ?? tx['customer_name'] ?? 'Unknown';
  final customerPhoneRaw = tx['Customer Phone'] ?? tx['customer_phone'] ?? '';
  // Prefer per-order shipping location if provided, fallback to stored customer profile location fields
  final customerLocation = tx['location'] ?? tx['shippingAddress'] ?? tx['Customer Location'] ?? tx['customer_location'] ?? ''; 
    final deliveredOn = (tx['Date'] as Timestamp?)?.toDate() ?? DateTime.now();
    final deliveryMethod = tx['deliveryMethod'];
    final deliveryStatus = tx['Status'] ?? 'pending';
    final deliverStatus = tx['deliver_status'] ?? '';
    final deliveryGuyName = tx['delivery_guy_name'];
    final deliveryGuyPhone = tx['delivery_guy_phone'];
  // Base item total
  final double baseAmount = (quantity is num ? quantity.toDouble() : 0) * (price is num ? price.toDouble() : 0);
  // Delivery enrichment (if not already stored, compute fallback later)
  final double? storedDeliveryCost = (tx['deliveryCost'] is num) ? (tx['deliveryCost'] as num).toDouble() : null;
  final double? distanceKm = (tx['deliveryDistanceKm'] is num) ? (tx['deliveryDistanceKm'] as num).toDouble() : null;
  final double? ratePerKm = (tx['deliveryRatePerKm'] is num) ? (tx['deliveryRatePerKm'] as num).toDouble() : null;
  final double deliveryCost = storedDeliveryCost ?? ((distanceKm != null && ratePerKm != null) ? distanceKm * ratePerKm : 0);
  final double totalWithDelivery = (tx['totalAmount'] is num)
      ? (tx['totalAmount'] as num).toDouble()
      : baseAmount + deliveryCost;
  final totalValue = totalWithDelivery.toStringAsFixed(2);
  final customerId = tx['Customer ID'];
  final farmerId = tx['Farmer ID'];
  final orderPlacedAt = tx['orderPlacedAt'];
  final cropKey = tx['Crop'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with crop name and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF02C697).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.eco,
                          color: Color(0xFF02C697),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              crop,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3748),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Transaction ID: ${tx['Customer ID'] ?? 'N/A'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStatusChip(status),
                    if (status.toLowerCase() == 'delivered') ...[
                      const SizedBox(width: 8),
                      Tooltip(
                        message: 'Remove from your list',
                        child: InkWell(
                          onTap: () => _archiveTransactionFarmer(userId, tx, transactions),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Customer Information
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Customer Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Customer Name with fallback lookup if unknown
                  if (initialCustomerName != 'Unknown' && initialCustomerName != 'N/A')
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: Color(0xFF64748B)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            initialCustomerName,
                            style: const TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  else
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('customers').doc(tx['Customer ID']).get(),
                      builder: (context, snap) {
                        String name = initialCustomerName;
                        if (snap.hasData && snap.data!.exists) {
                          final d = snap.data!.data() as Map<String, dynamic>?;
                          name = d?['name'] ?? d?['Name'] ?? initialCustomerName;
                        }
                        return Row(
                          children: [
                            const Icon(Icons.person, size: 16, color: Color(0xFF64748B)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  const SizedBox(height: 8),
                  if (customerPhoneRaw.toString().trim().isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 16, color: Color(0xFF64748B)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            customerPhoneRaw,
                            style: const TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  else
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('customers').doc(tx['Customer ID']).get(),
                      builder: (context, snap) {
                        String phone = 'Not Provided';
                        if (snap.hasData && snap.data!.exists) {
                          final d = snap.data!.data() as Map<String, dynamic>?;
                          phone = d?['phone'] ?? d?['Phone'] ?? d?['Phone_NO'] ?? phone;
                        }
                        return Row(
                          children: [
                            const Icon(Icons.phone, size: 16, color: Color(0xFF64748B)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                phone,
                                style: const TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 8),
                      Text(
                        'Deliver by: ${deliveredOn.day}/${deliveredOn.month}/${deliveredOn.year}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  if (customerLocation.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Color(0xFF64748B)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            customerLocation,
                            style: const TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Order Details
            Row(
              children: [
                _buildDetailBox('Quantity', '${quantity}kg', Icons.scale),
                const SizedBox(width: 12),
                _buildDetailBox('Unit Price', 'LKR $price', Icons.attach_money),
                const SizedBox(width: 12),
                _buildDetailBox('Total Value', 'LKR $totalValue', Icons.account_balance_wallet),
              ],
            ),
            if (deliveryCost > 0) ...[
              const SizedBox(height: 12),
              _buildDeliveryBreakdown(baseAmount, deliveryCost, distanceKm, ratePerKm, totalWithDelivery),
            ],
            const SizedBox(height: 16),

            // Delivery Information
            if (deliveryMethod != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          deliveryMethod == 'self' ? Icons.person_pin_circle : Icons.local_shipping,
                          size: 20,
                          color: const Color(0xFF22C55E),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          deliveryMethod == 'self' ? 'Self Delivery' : 'Delivery Guy Assigned',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF22C55E),
                          ),
                        ),
                      ],
                    ),
                    if (deliveryMethod == 'delivery_guy' && deliverStatus == 'assigned' && deliveryGuyName != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.person, size: 16, color: Color(0xFF64748B)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Driver: $deliveryGuyName',
                              style: const TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (tx['delivery_guy_id'] != null)
                            FutureBuilder<double?>(
                              future: _fetchDriverRating(tx['delivery_guy_id']),
                              builder: (context, snapshot) {
                                if (snapshot.hasData && snapshot.data != null) {
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.star, color: Colors.amber, size: 15),
                                        Text(snapshot.data!.toStringAsFixed(1), style: const TextStyle(fontSize: 13)),
                                      ],
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                        ],
                      ),
                      if (deliveryGuyPhone != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.phone, size: 16, color: Color(0xFF64748B)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Phone: $deliveryGuyPhone',
                                style: const TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ],

            // Action Buttons (Three separate controls)
            const SizedBox(height: 16),
            Row(
              children: [
                // 1. Select Delivery Method
                Expanded(
                  child: ElevatedButton(
                    onPressed: deliveryMethod == null
                        ? () => _showDeliveryMethodDialog(context, tx, userId, transactions)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: deliveryMethod == null ? const Color(0xFF02C697) : Colors.grey.shade400,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                    child: const Text(
                      'Method',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 2. Approve Order (Farmer confirms & locks in progress)
                Expanded(
                  child: ElevatedButton(
          onPressed: (status.toLowerCase() == 'pending' && deliveryMethod != null)
            ? () async {
                final ok = await _showIrreversibleConfirm(context,
                  title: 'Approve Order?',
                  message: 'Once you approve this order it will move to In Progress and you cannot revert to Pending. Continue?');
                if (ok == true) {
                  await _approveOrder(userId, tx, transactions);
                }
              }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (status.toLowerCase() == 'pending' && deliveryMethod != null)
                          ? Colors.blueAccent
                          : Colors.grey.shade400,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                    child: const Text(
                      'Approve',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 3. Mark Farmer Delivered (customer still must confirm)
                Expanded(
                  child: ElevatedButton(
          onPressed: (status.toLowerCase() == 'in progress' || status.toLowerCase() == 'assigned')
            ? () async {
                final ok = await _showIrreversibleConfirm(context,
                  title: 'Mark As Delivered?',
                  message: 'Once marked, customer will be asked to confirm. Status stays In Progress until customer confirms. Continue?');
                if (ok == true) {
                  await _confirmDelivered(userId, tx, transactions);
                }
              }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (status.toLowerCase() == 'in_transit' || status.toLowerCase() == 'assigned')
                          ? Colors.green
                          : Colors.grey.shade400,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                    child: const Text('Delivered', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Customer Review (customer -> farmer) display & Farmer Review button
            FutureBuilder<Map<String, dynamic>?>(
              future: (status.toLowerCase() == 'delivered') ? _fetchCustomerToFarmerReview(farmerId, customerId, orderPlacedAt, cropKey) : Future.value(null),
              builder: (context, snapshot) {
                final customerReview = snapshot.data;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (customerReview != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Customer Feedback', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                ...List.generate(5, (i)=>Icon(i < (customerReview['rating']?.round() ?? 0) ? Icons.star : Icons.star_border, size: 16, color: Colors.amber)),
                                const SizedBox(width: 6),
                                Text((customerReview['rating'] ?? 0).toStringAsFixed(1), style: const TextStyle(fontSize: 12,fontWeight: FontWeight.w600)),
                              ],
                            ),
                            if ((customerReview['review'] ?? '').toString().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(customerReview['review'], style: const TextStyle(fontSize: 13)),
                            ]
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (status.toLowerCase() == 'delivered' && tx['farmerReviewedCustomer'] != true)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.rate_review, size: 18),
                          label: const Text('Review Customer'),
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReviewCustomerScreen(transaction: tx),
                              ),
                            );
                            if (result == true) {
                              await _markFarmerReviewedCustomer(tx);
                              setState(() {});
                            }
                          },
                        ),
                      ),
                    if (tx['farmerReviewedCustomer'] == true) ...[
                      Row(
                        children: const [
                          Icon(Icons.check_circle, color: Colors.green, size: 16),
                          SizedBox(width: 6),
                          Text('You reviewed this customer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ]
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'delivered':
      case 'completed':
        backgroundColor = const Color(0xFFE8F5F1);
        textColor = const Color(0xFF02C697);
        break;
      case 'assigned':
        backgroundColor = const Color(0xFFE3F2FD);
        textColor = const Color(0xFF1976D2);
        break;
      case 'in progress':
        backgroundColor = const Color(0xFFFFF9C4);
        textColor = const Color(0xFFF57F17);
        break;
      case 'pending':
      default:
        backgroundColor = const Color(0xFFFFF4E6);
        textColor = const Color(0xFFFF9800);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.split(' ').map((w)=> w.isEmpty? '' : '${w[0].toUpperCase()}${w.substring(1)}').join(' '),
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildDetailBox(String label, String value, IconData icon) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: const Color(0xFF02C697),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryBreakdown(double base, double delivery, double? dist, double? rate, double total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF02C697).withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF02C697).withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.delivery_dining, size: 18, color: Color(0xFF02C697)),
              SizedBox(width: 6),
              Text('Pricing Breakdown', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          _line('Items', 'LKR ${base.toStringAsFixed(2)}'),
          if (delivery > 0)
            _line(
              'Delivery${(dist != null && rate != null) ? ' (${dist.toStringAsFixed(1)}km x LKR ${rate.toStringAsFixed(0)})' : ''}',
              'LKR ${delivery.toStringAsFixed(2)}',
            ),
          const Divider(height: 18),
          _line('Total', 'LKR ${total.toStringAsFixed(2)}', emphasize: true),
        ],
      ),
    );
  }

  Widget _line(String label, String value, {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: emphasize ? const Color(0xFF2D3748) : Colors.grey[700],
                fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
              color: emphasize ? const Color(0xFF02C697) : const Color(0xFF2D3748),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeliveryMethodDialog(BuildContext context, Map<String, dynamic> tx, String? userId, List<Map<String, dynamic>> transactions) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Choose Delivery Method',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.person, size: 20),
                  label: const Text('Deliver Myself'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF02C697),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    await _updateDeliveryMethod(userId, tx, transactions, 'self');
                    if (mounted) Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.delivery_dining, size: 20),
                  label: const Text('Assign to Delivery Guy'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    await _updateDeliveryMethod(userId, tx, transactions, 'delivery_guy');
                    if (mounted) Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateDeliveryMethod(String? userId, Map<String, dynamic> tx, List<Map<String, dynamic>> transactions, String method) async {
    if (userId == null) return;
    
    final updatedTx = Map<String, dynamic>.from(tx);
    updatedTx['deliveryMethod'] = method;
    
    final updatedTransactions = transactions.map((t) => t == tx ? updatedTx : t).toList();
    
    await FirebaseFirestore.instance
        .collection('Ongoing_Trans_Farm')
        .doc(userId)
        .update({'transactions': updatedTransactions});
    // Mirror delivery method to customer side so customer can view it
    final customerId = tx['Customer ID'];
    if (customerId != null) {
      final cusDoc = await FirebaseFirestore.instance
          .collection('Ongoing_Trans_Cus')
          .doc(customerId)
          .get();
      if (cusDoc.exists) {
        final data = cusDoc.data();
        if (data != null && data.containsKey('transactions')) {
          List<dynamic> list = List.from(data['transactions']);
            for (int i = 0; i < list.length; i++) {
              final item = list[i];
              if (item is Map<String, dynamic> &&
                  item['Crop'] == tx['Crop'] &&
                  item['Farmer ID'] == tx['Farmer ID'] &&
                  item['orderPlacedAt'] == tx['orderPlacedAt']) {
                item['deliveryMethod'] = method;
                list[i] = item;
                break;
              }
            }
          await FirebaseFirestore.instance
              .collection('Ongoing_Trans_Cus')
              .doc(customerId)
              .update({'transactions': list});
        }
      }
    }

    setState(() {});
  }

  Future<void> _markAsAssignedToDriver(String? userId, Map<String, dynamic> tx, List<Map<String, dynamic>> transactions) async {
    if (userId == null) return;
    
    final updatedTxs = transactions.map((t) {
      if (t['Date'] == tx['Date'] && t['Customer ID'] == tx['Customer ID']) {
        final updated = Map<String, dynamic>.from(t);
        updated['Status'] = 'assigned';
        return updated;
      }
      return t;
    }).toList();
    
    await FirebaseFirestore.instance
        .collection('Ongoing_Trans_Farm')
        .doc(userId)
        .update({'transactions': updatedTxs});
    
    setState(() {});
  }

  Future<void> _approveOrder(String? userId, Map<String, dynamic> tx, List<Map<String, dynamic>> transactions) async {
    if (userId == null) return;
    final updatedTx = Map<String, dynamic>.from(tx);
    // Move status forward: pending -> in_transit (or assigned if delivery guy selected earlier)
    if ((updatedTx['Status'] ?? '').toString().toLowerCase() == 'pending') {
      updatedTx['Status'] = 'In Progress';
    }
    final updatedTransactions = transactions.map((t) => t == tx ? updatedTx : t).toList();
    await FirebaseFirestore.instance
        .collection('Ongoing_Trans_Farm')
        .doc(userId)
        .update({'transactions': updatedTransactions});
    // Mirror status for customer side
    final customerId = updatedTx['Customer ID'];
    if (customerId != null) {
  await _updateCustomerSideStatus(customerId, tx, 'In Progress');
    }
    setState(() {});
  }

  Future<void> _confirmDelivered(String? userId, Map<String, dynamic> tx, List<Map<String, dynamic>> transactions) async {
    if (userId == null) return;
    final updatedTx = Map<String, dynamic>.from(tx);
    // Keep status In Progress until customer confirms; just flag internal marker
    if ((updatedTx['Status'] ?? '').toString().toLowerCase() != 'delivered') {
      updatedTx['Status'] = 'In Progress';
    }
    final updatedTransactions = transactions.map((t) => t == tx ? updatedTx : t).toList();
    await FirebaseFirestore.instance
        .collection('Ongoing_Trans_Farm')
        .doc(userId)
        .update({'transactions': updatedTransactions});
    // Instead of marking delivered for customer immediately, flag farmerDelivered
    final customerId = updatedTx['Customer ID'];
    if (customerId != null) {
      await _flagFarmerDeliveredOnCustomer(customerId, tx);
    }
    setState(() {});
  }

  Future<bool?> _showIrreversibleConfirm(BuildContext context, {required String title, required String message}) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF02C697)),
            child: const Text('Confirm'),
          )
        ],
      ),
    );
  }

  Future<void> _updateCustomerSideStatus(String customerId, Map<String, dynamic> tx, String newStatus) async {
    final cusDoc = await FirebaseFirestore.instance.collection('Ongoing_Trans_Cus').doc(customerId).get();
    if (!cusDoc.exists) return;
    final data = cusDoc.data();
    if (data == null || !data.containsKey('transactions')) return;
    List<dynamic> list = List.from(data['transactions']);
    for (int i = 0; i < list.length; i++) {
      final item = list[i];
      if (item is Map<String, dynamic> &&
          item['Crop'] == tx['Crop'] &&
          item['Farmer ID'] == tx['Farmer ID'] &&
          item['orderPlacedAt'] == tx['orderPlacedAt']) {
        item['Status'] = newStatus;
        list[i] = item;
        break;
      }
    }
    await FirebaseFirestore.instance.collection('Ongoing_Trans_Cus').doc(customerId).update({'transactions': list});
  }

  Future<void> _flagFarmerDeliveredOnCustomer(String customerId, Map<String, dynamic> tx) async {
    final cusDoc = await FirebaseFirestore.instance.collection('Ongoing_Trans_Cus').doc(customerId).get();
    if (!cusDoc.exists) return;
    final data = cusDoc.data();
    if (data == null || !data.containsKey('transactions')) return;
    List<dynamic> list = List.from(data['transactions']);
    for (int i = 0; i < list.length; i++) {
      final item = list[i];
      if (item is Map<String, dynamic> &&
          item['Crop'] == tx['Crop'] &&
          item['Farmer ID'] == tx['Farmer ID'] &&
          item['orderPlacedAt'] == tx['orderPlacedAt']) {
        // Keep status as In Progress if already set, otherwise set to In Progress
        final currentStatus = (item['Status'] ?? '').toString();
        if (currentStatus.toLowerCase() != 'delivered') {
          item['Status'] = 'In Progress';
        }
        item['farmerDelivered'] = true;
        item['farmerDeliveredAt'] = Timestamp.now();
        list[i] = item;
        break;
      }
    }
    await FirebaseFirestore.instance.collection('Ongoing_Trans_Cus').doc(customerId).update({'transactions': list});
  }

  Future<double?> _fetchDriverRating(String driverId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('DriverReviews').doc(driverId).get();
      if (!doc.exists || doc.data() == null || !(doc.data()!.containsKey('ratings'))) {
        return null;
      }
      final List<dynamic> ratings = doc['ratings'] ?? [];
      if (ratings.isEmpty) return null;
      double avg = ratings.map((r) => (r['rating'] ?? 0).toDouble()).fold(0.0, (a, b) => a + b) / ratings.length;
      return avg;
    } catch (e) {
      return null;
    }
  }

  Future<void> _archiveTransactionFarmer(String? userId, Map<String, dynamic> tx, List<Map<String, dynamic>> transactions) async {
    if (userId == null) return;
    final updated = transactions.map((item) {
      if (item['Crop'] == tx['Crop'] &&
          item['Customer ID'] == tx['Customer ID'] &&
          item['orderPlacedAt'] == tx['orderPlacedAt']) {
        final copy = Map<String, dynamic>.from(item);
        copy['archived_farmer'] = true;
        return copy;
      }
      return item;
    }).toList();
    await FirebaseFirestore.instance
        .collection('Ongoing_Trans_Farm')
        .doc(userId)
        .update({'transactions': updated});
    setState(() {});
  }

  Future<Map<String, dynamic>?> _fetchCustomerToFarmerReview(String? farmerId, String? customerId, dynamic orderPlacedAt, String crop) async {
    try {
      if (farmerId == null || customerId == null || orderPlacedAt == null) return null;
      final doc = await FirebaseFirestore.instance.collection('FarmerReviews').doc(farmerId).get();
      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null || !data.containsKey('ratings')) return null;
      final List<dynamic> ratings = data['ratings'] ?? [];
      for (final r in ratings) {
        if (r is Map<String, dynamic> &&
            r['customerId'] == customerId &&
            r['orderPlacedAt'] == orderPlacedAt &&
            r['crop'] == crop) {
          return r;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _markFarmerReviewedCustomer(Map<String, dynamic> tx) async {
    final farmerId = FirebaseAuth.instance.currentUser?.uid;
    if (farmerId == null) return;
    // Update farmer side
    final farmDoc = await FirebaseFirestore.instance.collection('Ongoing_Trans_Farm').doc(farmerId).get();
    if (farmDoc.exists) {
      final fData = farmDoc.data();
      if (fData != null && fData.containsKey('transactions')) {
        List<dynamic> list = List.from(fData['transactions']);
        for (int i = 0; i < list.length; i++) {
          final item = list[i];
          if (item is Map<String, dynamic> &&
              item['Crop'] == tx['Crop'] &&
              item['Customer ID'] == tx['Customer ID'] &&
              item['orderPlacedAt'] == tx['orderPlacedAt']) {
            item['farmerReviewedCustomer'] = true;
            list[i] = item;
            break;
          }
        }
        await FirebaseFirestore.instance.collection('Ongoing_Trans_Farm').doc(farmerId).update({'transactions': list});
      }
    }
    // Update customer side flag
    final customerId = tx['Customer ID'];
    if (customerId != null) {
      final cusDoc = await FirebaseFirestore.instance.collection('Ongoing_Trans_Cus').doc(customerId).get();
      if (cusDoc.exists) {
        final cData = cusDoc.data();
        if (cData != null && cData.containsKey('transactions')) {
          List<dynamic> list = List.from(cData['transactions']);
          for (int i = 0; i < list.length; i++) {
            final item = list[i];
            if (item is Map<String, dynamic> &&
                item['Crop'] == tx['Crop'] &&
                item['Farmer ID'] == tx['Farmer ID'] &&
                item['orderPlacedAt'] == tx['orderPlacedAt']) {
              item['farmerReviewedCustomer'] = true;
              list[i] = item;
              break;
            }
          }
          await FirebaseFirestore.instance.collection('Ongoing_Trans_Cus').doc(customerId).update({'transactions': list});
        }
      }
    }
  }
}