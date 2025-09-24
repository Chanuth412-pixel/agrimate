import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

                      final transactions = List<Map<String, dynamic>>.from(data['transactions']);
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
    final customerName = tx['Farmer Name'] ?? 'N/A';
    final phoneNO = tx['Phone_NO'] ?? 'N/A';
    final deliveredOn = (tx['Date'] as Timestamp?)?.toDate() ?? DateTime.now();
    final deliveryMethod = tx['deliveryMethod'];
    final deliveryStatus = tx['Status'] ?? 'pending';
    final deliverStatus = tx['deliver_status'] ?? '';
    final deliveryGuyName = tx['delivery_guy_name'];
    final deliveryGuyPhone = tx['delivery_guy_phone'];
    final totalValue = (quantity * price).toStringAsFixed(2);

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
                Row(
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          crop,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        Text(
                          'Transaction ID: ${tx['Customer ID'] ?? 'N/A'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                _buildStatusChip(status),
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
                  Row(
                    children: [
                      const Icon(Icons.person, size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 8),
                      Text(customerName, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 8),
                      Text(phoneNO, style: const TextStyle(fontSize: 14)),
                    ],
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
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Order Details
            Row(
              children: [
                Expanded(
                  child: _buildDetailBox('Quantity', '${quantity}kg', Icons.scale),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDetailBox('Unit Price', 'LKR $price', Icons.attach_money),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDetailBox('Total Value', 'LKR $totalValue', Icons.account_balance_wallet),
                ),
              ],
            ),
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
                          Text('Driver: $deliveryGuyName', style: const TextStyle(fontSize: 14)),
                          if (tx['delivery_guy_id'] != null)
                            FutureBuilder<double?>(
                              future: _fetchDriverRating(tx['delivery_guy_id']),
                              builder: (context, snapshot) {
                                if (snapshot.hasData && snapshot.data != null) {
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Row(
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
                            Text('Phone: $deliveryGuyPhone', style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ],

            // Action Buttons
            const SizedBox(height: 16),
            if (deliveryMethod == null) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showDeliveryMethodDialog(context, tx, userId, transactions),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF02C697),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.local_shipping, size: 20),
                  label: const Text(
                    'Choose Delivery Method',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ] else if (deliveryMethod == 'delivery_guy' && status.toLowerCase() == 'pending') ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _markAsAssignedToDriver(userId, tx, transactions),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.assignment_turned_in, size: 20),
                  label: const Text(
                    'Assign to Driver',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'completed':
        backgroundColor = const Color(0xFFE8F5F1);
        textColor = const Color(0xFF02C697);
        break;
      case 'assigned':
        backgroundColor = const Color(0xFFE3F2FD);
        textColor = const Color(0xFF1976D2);
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
        '${status[0].toUpperCase()}${status.substring(1)}',
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildDetailBox(String label, String value, IconData icon) {
    return Container(
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
}