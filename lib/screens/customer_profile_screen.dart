import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/app_localizations.dart';
import 'customer_detail_page.dart';
import 'review_transaction_screen.dart';
import 'add_crop_customer_c1.dart';
import 'scheduled_orders_screen.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  Map<String, String> cropDescriptions = {
    'tomato': 'Loading...',
    'bean': 'Loading...',
    'okra': 'Loading...',
  };

  @override
  void initState() {
    super.initState();
    _fetchCropInsights();
  }

  Future<void> _fetchCropInsights() async {
    try {
      // Simple fallback descriptions
      setState(() {
        cropDescriptions = {
          'tomato': 'Premium Quality',
          'bean': 'Fresh Stock',
          'okra': 'Best Price'
        };
      });
    } catch (e) {
      // On error, use simple two-word fallback descriptions
      setState(() {
        cropDescriptions = {
          'tomato': 'Premium Quality',
          'bean': 'Fresh Stock',
          'okra': 'Best Price'
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Stack(
        children: [
          // Background image with gradient overlay
          Container(
            height: 220,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/customer_page.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          // Main content
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Header section
                  Container(
                    height: 180,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                StreamBuilder<DocumentSnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('customers')
                                      .doc(FirebaseAuth.instance.currentUser?.uid)
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) {
                                      return const CircularProgressIndicator(color: Colors.white);
                                    }
                                    
                                    final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                                    final customerName = data['Name'] ?? 'Customer';
                                    
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Welcome ${customerName.isNotEmpty ? customerName : 'Customer'}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 28,
                                            fontWeight: FontWeight.w800,
                                            shadows: [
                                              Shadow(
                                                offset: Offset(2, 2),
                                                blurRadius: 5,
                                                color: Colors.black87,
                                              ),
                                              Shadow(
                                                offset: Offset(-1, -1),
                                                blurRadius: 3,
                                                color: Colors.black54,
                                              ),
                                              Shadow(
                                                offset: Offset(1, -1),
                                                blurRadius: 2,
                                                color: Colors.black45,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          '🛒 Fresh crops at your fingertips',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            shadows: [
                                              Shadow(
                                                offset: Offset(2, 2),
                                                blurRadius: 4,
                                                color: Colors.black87,
                                              ),
                                              Shadow(
                                                offset: Offset(-1, -1),
                                                blurRadius: 2,
                                                color: Colors.black54,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 28),
                              onPressed: () async {
                                final user = FirebaseAuth.instance.currentUser;
                                final doc = await FirebaseFirestore.instance
                                    .collection('customers')
                                    .doc(user?.uid)
                                    .get();

                                final customerData = doc.data() ?? {
                                  "Email": user?.email ?? '',
                                  "uid": user?.uid ?? '',
                                  "Phone": "Not Provided",
                                  "Name": "Not Provided",
                                };

                                if (context.mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CustomerDetailPage(customerData: customerData),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Content section
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        
                        // Recommended Crops Card
                        _buildRecommendedCropsCard(),
                        
                        // Recent Transactions Card
                        _buildRecentTransactionsCard(),
                        
                        const SizedBox(height: 100), // Space for floating action button
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ScheduledOrdersScreen()),
          );
        },
        backgroundColor: const Color(0xFF02C697),
        icon: const Icon(Icons.shopping_cart, color: Colors.white),
        label: const Text('Schedule Order', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  // New card-based methods similar to farmer profile
  Widget _buildRecommendedCropsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF02C697).withOpacity(0.2),
                        const Color(0xFF02C697).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF02C697).withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.trending_up_rounded,
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
                        'Recommended Crops',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF2D3748),
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '🌱 Fresh crops available for you',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Removed inline 'Scheduled' button per new design directive.
              ],
            ),
            const SizedBox(height: 16),
            // Height matches new square-image CropCard (1:1 image + meta)
            SizedBox(
              height: 228,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  CropCard(
                    name: AppLocalizations.of(context)?.cropTomato ?? 'Tomato',
                    imagePath: 'assets/images/tomato1.png',
                    color: const Color(0xFFE53935),
                    description: cropDescriptions['tomato'] ?? 'High demand',
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddCropCustomerC1(cropName: 'tomato'),
                        ),
                      );
                      if (result == 'updated') {
                        setState(() {});
                      }
                    },
                  ),
                  const SizedBox(width: 16),
                  CropCard(
                    name: AppLocalizations.of(context)?.cropBeans ?? 'Beans',
                    imagePath: 'assets/images/beans1.png',
                    color: const Color(0xFF4CAF50),
                    description: cropDescriptions['bean'] ?? 'Best season',
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddCropCustomerC1(cropName: 'bean'),
                        ),
                      );
                      if (result == 'updated') {
                        setState(() {});
                      }
                    },
                  ),
                  const SizedBox(width: 16),
                  CropCard(
                    name: AppLocalizations.of(context)?.cropOkra ?? 'Okra',
                    imagePath: 'assets/images/okra1.png',
                    color: const Color(0xFF7CB342),
                    description: cropDescriptions['okra'] ?? 'Good price',
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddCropCustomerC1(cropName: 'okra'),
                        ),
                      );
                      if (result == 'updated') {
                        setState(() {});
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactionsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF02C697).withOpacity(0.2),
                        const Color(0xFF02C697).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF02C697).withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
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
                        'Recent Transactions',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF2D3748),
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '📋 Track your order history',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('Ongoing_Trans_Cus')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(color: Color(0xFF02C697)),
                    ),
                  );
                }

                final data = snapshot.data!.data() as Map<String, dynamic>?;

                if (data == null || !data.containsKey('transactions')) {
                  return _buildEmptyState();
                }

                final transactions = List<Map<String, dynamic>>.from(data['transactions']);
                // Sort newest first using orderPlacedAt if present else Date
                transactions.sort((a, b) {
                  dynamic aKey = a['orderPlacedAt'] ?? a['Date'];
                  dynamic bKey = b['orderPlacedAt'] ?? b['Date'];
                  if (aKey is Timestamp && bKey is Timestamp) {
                    return bKey.compareTo(aKey); // descending
                  }
                  return 0;
                });

                // Keep all transactions until status becomes 'confirmed'
                final filtered = transactions.where((tx) {
                  // Only hide if explicitly archived
                  final archived = tx['archived'] == true;
                  return !archived;
                }).toList();

                if (filtered.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  // Show all pending/unconfirmed
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final tx = filtered[index];
                    return _buildTransactionItem(tx);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> tx) {
    final crop = tx['Crop'];
    final quantity = tx['Quantity Sold (1kg)'];
    final price = tx['Sale Price Per kg'];
    final status = tx['Status'];
    final farmerName = tx['Farmer Name'] ?? 'N/A';
    final phoneNO = tx['Phone_NO'];
    final deliveredOn = (tx['Date'] as Timestamp).toDate();
    final deliveryGuyName = tx['delivery_guy_name'];
    final deliveryGuyPhone = tx['delivery_guy_phone'];
    final reviewed = tx['reviewed'] == true;
  final shippingAddress = tx['shippingAddress'] ?? tx['location'];
  final deliveryMethod = tx['deliveryMethod'];
  final farmerDelivered = tx['farmerDelivered'] == true;
  final canDelete = status.toLowerCase() == 'delivered';
  final declinedReason = tx['declineReason'];
  final cancelledReason = tx['cancelReason'];
  final isDeclined = status.toString().toLowerCase() == 'declined';
  final isCancelled = status.toString().toLowerCase() == 'cancelled';
  final canArchive = canDelete || isDeclined || isCancelled;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            const Color(0xFF02C697).withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF02C697).withOpacity(0.1),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                crop,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              _buildStatusChip(status),
            ],
          ),
              if (canArchive)
                IconButton(
                  tooltip: 'Remove from list',
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () => _archiveTransaction(tx),
                ),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.person_outline, 'Farmer', farmerName),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.phone_outlined, 'Contact', phoneNO),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.calendar_today_outlined,
            'Delivery',
            '${deliveredOn.day}/${deliveredOn.month}/${deliveredOn.year}',
          ),
          if (deliveryMethod != null && deliveryMethod.toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.local_shipping,
              'Method',
              deliveryMethod == 'self' ? 'Farmer Delivery' : deliveryMethod == 'delivery_guy' ? 'Delivery Guy' : deliveryMethod.toString(),
            ),
          ],
          if (shippingAddress != null) ...[
            const SizedBox(height: 8),
            const Divider(height: 16),
            const Text(
              'Shipping Details',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (shippingAddress != null && shippingAddress.toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: _buildInfoRow(
                  Icons.location_on_outlined,
                  'Address',
                  shippingAddress,
                ),
              ),
          ],
          if (deliveryGuyName != null && deliveryGuyName.toString().isNotEmpty) ...[
            const Divider(height: 16),
            _buildInfoRow(Icons.delivery_dining, 'Delivery Guy', deliveryGuyName),
            if (deliveryGuyPhone != null && deliveryGuyPhone.toString().isNotEmpty)
              _buildInfoRow(Icons.phone, 'Driver Phone', deliveryGuyPhone),
          ],
          if (isDeclined && declinedReason != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE11D48).withOpacity(.35)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFE11D48)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Declined Reason', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFE11D48))),
                        const SizedBox(height: 4),
                        Text(declinedReason.toString(), style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ]
          else if (isCancelled && cancelledReason != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF97316).withOpacity(.35)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFFF97316)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Cancelled Reason', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFF97316))),
                        const SizedBox(height: 4),
                        Text(cancelledReason.toString(), style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDetailBox(
                'Quantity',
                '${quantity}kg',
                const Color(0xFFF3F4F6),
              ),
              _buildDetailBox(
                'Unit Price',
                'LKR $price',
                const Color(0xFFF3F4F6),
              ),
              _buildDetailBox(
                'Total',
                _formatTotalWithDelivery(tx, price, quantity),
                const Color(0xFFE8F5F1),
                valueColor: const Color(0xFF02C697),
              ),
            ],
          ),
          // Pricing breakdown (items + delivery + total)
          if (tx.containsKey('deliveryRatePerKm') && tx.containsKey('deliveryDistanceKm'))
            Padding(
              padding: const EdgeInsets.only(top: 14.0),
              child: _buildPricingBreakdown(tx, price, quantity),
            ),
          if (status.toLowerCase() == 'delivered' && !reviewed)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: _GlassyActionButton(
                icon: Icons.rate_review,
                label: 'Leave Review',
                gradientColors: const [Color(0xFFf6d365), Color(0xFFfda085)],
                onPressed: () async {
                  await _openReviewScreen(tx);
                  if (mounted) setState(() {});
                },
              ),
            ),
          if (status.toString().toLowerCase() == 'pending')
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: _GlassyActionButton(
                icon: Icons.cancel_schedule_send,
                label: 'Cancel Order',
                gradientColors: const [Color(0xFFee0979), Color(0xFFff6a00)],
                onPressed: () async {
                  final reason = await _showCancelReasonDialog(context);
                  if (reason != null && reason.trim().isNotEmpty) {
                    final ok = await _showCancelConfirm(context);
                    if (ok == true) {
                      await _cancelCustomerOrder(tx, reason.trim());
                      if (mounted) setState(() {});
                    }
                  }
                },
              ),
            ),
          if (status == 'delivered' && reviewed)
            const Padding(
              padding: EdgeInsets.only(top: 12.0),
              child: _GlassyBadge(
                icon: Icons.check_box,
                label: 'Reviewed',
                colors: [Color(0xFFa8e063), Color(0xFF56ab2f)],
              ),
            ),
          if (status.toLowerCase() == 'in progress' && farmerDelivered)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: _GlassyActionButton(
                icon: Icons.check_circle,
                label: 'Confirm Delivery',
                gradientColors: const [Color(0xFF56ab2f), Color(0xFFa8e063)],
                onPressed: () async {
                  await _confirmCustomerDelivery(tx, openReview: true);
                  if (mounted) setState(() {});
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: const Column(
        children: [
          Icon(
            Icons.receipt_long,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Your order history will appear here',
            style: TextStyle(
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatTotalWithDelivery(Map<String, dynamic> tx, dynamic price, dynamic quantity){
    try {
      // Safely parse unit price & quantity (fallback to 0 if null / invalid)
      final double unit = (price is num)
          ? price.toDouble()
          : double.tryParse(price?.toString() ?? '') ?? 0;
      final double qty = (quantity is num)
          ? quantity.toDouble()
          : double.tryParse(quantity?.toString() ?? '') ?? 0;

      // Prefer stored totalAmount ONLY if it's actually a numeric value
      if (tx['totalAmount'] is num) {
        final total = (tx['totalAmount'] as num).toDouble();
        return 'LKR ${total.toStringAsFixed(0)}';
      }

      final base = unit * qty;
      double delivery = 0;
      final distRaw = tx['deliveryDistanceKm'];
      final rateRaw = tx['deliveryRatePerKm'];
      final dist = (distRaw is num)
          ? distRaw.toDouble()
          : double.tryParse(distRaw?.toString() ?? '');
      final rate = (rateRaw is num)
          ? rateRaw.toDouble()
          : double.tryParse(rateRaw?.toString() ?? '');
      if (dist != null && rate != null) {
        delivery = dist * rate;
      }

      final total = base + delivery;
      return 'LKR ${total.toStringAsFixed(0)}';
    } catch (_) {
      return 'LKR 0';
    }
  }

  String _formatDeliveryBreakdown(Map<String, dynamic> tx) {
    try {
      if (tx['deliveryDistanceKm'] is! num || tx['deliveryRatePerKm'] is! num) return 'N/A';
      final dist = (tx['deliveryDistanceKm'] as num).toDouble();
      final rate = (tx['deliveryRatePerKm'] as num).toDouble();
      final cost = (tx['deliveryCost'] is num)
          ? (tx['deliveryCost'] as num).toDouble()
          : dist * rate;
      return '${dist.toStringAsFixed(1)} km x LKR ${rate.toStringAsFixed(0)} = LKR ${cost.toStringAsFixed(0)}';
    } catch (_) {
      return 'N/A';
    }
  }

  Widget _buildPricingBreakdown(Map<String, dynamic> tx, dynamic price, dynamic quantity) {
    double unit = 0, qty = 0, base = 0, delivery = 0, total = 0, dist = 0, rate = 0;
    try {
      unit = (price is num) ? price.toDouble() : double.parse(price.toString());
      qty = (quantity is num) ? quantity.toDouble() : double.parse(quantity.toString());
      base = unit * qty;
      if (tx['deliveryDistanceKm'] is num) dist = (tx['deliveryDistanceKm'] as num).toDouble();
      if (tx['deliveryRatePerKm'] is num) rate = (tx['deliveryRatePerKm'] as num).toDouble();
      if (tx['deliveryCost'] is num) {
        delivery = (tx['deliveryCost'] as num).toDouble();
      } else if (dist > 0 && rate > 0) {
        delivery = dist * rate;
      }
      if (tx['totalAmount'] is num) {
        total = (tx['totalAmount'] as num).toDouble();
      } else {
        total = base + delivery;
      }
    } catch (_) {}

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF02C697).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF02C697).withOpacity(0.15)),
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
          _pricingLine('Items', 'LKR ${base.toStringAsFixed(2)}'),
          if (delivery > 0)
            _pricingLine(
              'Delivery${(dist > 0 && rate > 0) ? ' (${dist.toStringAsFixed(1)}km x LKR ${rate.toStringAsFixed(0)})' : ''}',
              'LKR ${delivery.toStringAsFixed(2)}',
            ),
          const Divider(height: 18),
          _pricingLine('Total', 'LKR ${total.toStringAsFixed(2)}', emphasize: true),
        ],
      ),
    );
  }

  Widget _pricingLine(String label, String value, {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
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

  Widget _buildStatusChip(String status) {
    Color bgColor;
    Color textColor;
    String displayText;

    switch (status.toLowerCase()) {
      case 'pending':
        bgColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        displayText = 'Pending';
        break;
      case 'in progress':
        bgColor = Colors.amber.shade100;
        textColor = Colors.amber.shade900;
        displayText = 'In Progress';
        break;
      case 'in_transit': // legacy
        bgColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        displayText = 'In Transit';
        break;
      case 'delivered':
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        displayText = 'Delivered';
        break;
      case 'declined':
        bgColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        displayText = 'Declined';
        break;
      case 'cancelled':
        bgColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        displayText = 'Cancelled';
        break;
      default:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade800;
        displayText = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
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
            fontSize: 13,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailBox(String label, String value, Color bgColor, {Color? valueColor}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showReviewDialog(BuildContext context, Map<String, dynamic> tx, VoidCallback onReviewSubmitted) async {
    double farmerRating = 3.0;
    final reviewController = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave a Review'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Rate the Farmer:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () => farmerRating = index + 1.0,
                    child: Icon(
                      index < farmerRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 30,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              const Text('Write a Review:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: reviewController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Share your experience...',
                  border: OutlineInputBorder(),
                ),
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
              // Submit review logic here
              Navigator.pop(context);
              onReviewSubmitted();
            },
            child: const Text('Submit Review'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmCustomerDelivery(Map<String, dynamic> tx, {bool openReview = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final docRef = FirebaseFirestore.instance.collection('Ongoing_Trans_Cus').doc(user.uid);
    final snap = await docRef.get();
    if (!snap.exists) return;
    final data = snap.data() as Map<String, dynamic>?;
    if (data == null || !data.containsKey('transactions')) return;
    List<dynamic> list = List.from(data['transactions']);
    bool updated = false;
    for (int i = 0; i < list.length; i++) {
      final item = list[i];
      if (item is Map<String, dynamic> &&
          item['Crop'] == tx['Crop'] &&
          item['Farmer ID'] == tx['Farmer ID'] &&
          item['orderPlacedAt'] == tx['orderPlacedAt']) {
        item['Status'] = 'delivered';
        item['customerConfirmedAt'] = Timestamp.now();
        list[i] = item;
        updated = true;
        break;
      }
    }
    if (updated) {
      await docRef.update({'transactions': list});
      // Also reflect on farmer side
      final farmerId = tx['Farmer ID'];
      if (farmerId != null) {
        final farmDoc = await FirebaseFirestore.instance.collection('Ongoing_Trans_Farm').doc(farmerId).get();
        if (farmDoc.exists) {
          final fData = farmDoc.data();
          if (fData != null && fData.containsKey('transactions')) {
            List<dynamic> fList = List.from(fData['transactions']);
            for (int j = 0; j < fList.length; j++) {
              final fItem = fList[j];
              if (fItem is Map<String, dynamic> &&
                  fItem['Crop'] == tx['Crop'] &&
                  fItem['Customer ID'] == user.uid &&
                  fItem['orderPlacedAt'] == tx['orderPlacedAt']) {
                fItem['Status'] = 'delivered';
                fItem['customerConfirmedAt'] = Timestamp.now();
                fList[j] = fItem;
                break;
              }
            }
            await FirebaseFirestore.instance.collection('Ongoing_Trans_Farm').doc(farmerId).update({'transactions': fList});
          }
        }
      }
      if (openReview) await _openReviewScreen(tx);
    }
  }

  Future<void> _openReviewScreen(Map<String, dynamic> tx) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewTransactionScreen(transaction: tx),
      ),
    );
    if (result == true) {
      // Mark reviewed in both customer and farmer docs
      await _markReviewed(tx);
    }
  }

  Future<void> _markReviewed(Map<String, dynamic> tx) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final docRef = FirebaseFirestore.instance.collection('Ongoing_Trans_Cus').doc(user.uid);
    final snap = await docRef.get();
    if (snap.exists) {
      final data = snap.data() as Map<String, dynamic>?;
      if (data != null && data.containsKey('transactions')) {
        List<dynamic> list = List.from(data['transactions']);
        for (int i = 0; i < list.length; i++) {
          final item = list[i];
            if (item is Map<String, dynamic> &&
                item['Crop'] == tx['Crop'] &&
                item['Farmer ID'] == tx['Farmer ID'] &&
                item['orderPlacedAt'] == tx['orderPlacedAt']) {
              item['reviewed'] = true;
              list[i] = item;
              break;
            }
        }
        await docRef.update({'transactions': list});
      }
    }
    final farmerId = tx['Farmer ID'];
    if (farmerId != null) {
      final farmDoc = await FirebaseFirestore.instance.collection('Ongoing_Trans_Farm').doc(farmerId).get();
      if (farmDoc.exists) {
        final fData = farmDoc.data();
        if (fData != null && fData.containsKey('transactions')) {
          List<dynamic> fList = List.from(fData['transactions']);
          for (int j = 0; j < fList.length; j++) {
            final fItem = fList[j];
            if (fItem is Map<String, dynamic> &&
                fItem['Crop'] == tx['Crop'] &&
                fItem['Customer ID'] == FirebaseAuth.instance.currentUser?.uid &&
                fItem['orderPlacedAt'] == tx['orderPlacedAt']) {
              fItem['reviewed'] = true;
              fList[j] = fItem;
              break;
            }
          }
          await FirebaseFirestore.instance.collection('Ongoing_Trans_Farm').doc(farmerId).update({'transactions': fList});
        }
      }
    }
  }

  Future<void> _archiveTransaction(Map<String, dynamic> tx) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final docRef = FirebaseFirestore.instance.collection('Ongoing_Trans_Cus').doc(user.uid);
    final snap = await docRef.get();
    if (!snap.exists) return;
    final data = snap.data() as Map<String, dynamic>?;
    if (data == null || !data.containsKey('transactions')) return;
    List<dynamic> list = List.from(data['transactions']);
    for (int i = 0; i < list.length; i++) {
      final item = list[i];
      if (item is Map<String, dynamic> &&
          item['Crop'] == tx['Crop'] &&
          item['Farmer ID'] == tx['Farmer ID'] &&
          item['orderPlacedAt'] == tx['orderPlacedAt']) {
        item['archived'] = true;
        list[i] = item;
        break;
      }
    }
    await docRef.update({'transactions': list});
    if (mounted) setState(() {});
  }

  Future<String?> _showCancelReasonDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Order'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter reason for cancellation',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Back')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showCancelConfirm(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Cancellation'),
        content: const Text('Are you sure you want to cancel this order? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelCustomerOrder(Map<String, dynamic> tx, String reason) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final docRef = FirebaseFirestore.instance.collection('Ongoing_Trans_Cus').doc(user.uid);
    final snap = await docRef.get();
    if (!snap.exists) return;
    final data = snap.data() as Map<String, dynamic>?;
    if (data == null || !data.containsKey('transactions')) return;
    List<dynamic> list = List.from(data['transactions']);
    bool updated = false;
    for (int i = 0; i < list.length; i++) {
      final item = list[i];
      if (item is Map<String, dynamic> &&
          item['Crop'] == tx['Crop'] &&
          item['Farmer ID'] == tx['Farmer ID'] &&
          item['orderPlacedAt'] == tx['orderPlacedAt']) {
        if ((item['Status'] ?? '').toString().toLowerCase() == 'pending') {
          item['Status'] = 'Cancelled';
          item['cancelReason'] = reason;
          item['cancelledAt'] = Timestamp.now();
          list[i] = item;
          updated = true;
        }
        break;
      }
    }
    if (updated) {
      await docRef.update({'transactions': list});
      // Mirror to farmer side
      final farmerId = tx['Farmer ID'];
      if (farmerId != null) {
        final farmDoc = await FirebaseFirestore.instance.collection('Ongoing_Trans_Farm').doc(farmerId).get();
        if (farmDoc.exists) {
          final fData = farmDoc.data();
          if (fData != null && fData.containsKey('transactions')) {
            List<dynamic> fList = List.from(fData['transactions']);
            for (int j = 0; j < fList.length; j++) {
              final fItem = fList[j];
              if (fItem is Map<String, dynamic> &&
                  fItem['Crop'] == tx['Crop'] &&
                  fItem['Customer ID'] == FirebaseAuth.instance.currentUser?.uid &&
                  fItem['orderPlacedAt'] == tx['orderPlacedAt']) {
                if ((fItem['Status'] ?? '').toString().toLowerCase() == 'pending') {
                  fItem['Status'] = 'Cancelled';
                  fItem['cancelReason'] = reason;
                  fItem['cancelledAt'] = Timestamp.now();
                  fList[j] = fItem;
                }
                break;
              }
            }
            await FirebaseFirestore.instance.collection('Ongoing_Trans_Farm').doc(farmerId).update({'transactions': fList});
          }
        }
      }
    }
  }
}

// ===== Glassy UI Components (top-level) =====
class _GlassyActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<Color> gradientColors;
  final VoidCallback onPressed;
  const _GlassyActionButton({required this.icon, required this.label, required this.gradientColors, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradientColors),
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(color: gradientColors.last.withOpacity(.35), blurRadius: 12, offset: const Offset(0,6)),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.25),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(4),
              child: Icon(icon, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _GlassyBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<Color> colors;
  const _GlassyBadge({required this.icon, required this.label, required this.colors});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: colors.last.withOpacity(.35), blurRadius: 8, offset: const Offset(0,4)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class CropCard extends StatelessWidget {
  final String name;
  final String imagePath;
  final Color color;
  final String description;
  final VoidCallback onTap;

  const CropCard({
    super.key,
    required this.name,
    required this.imagePath,
    required this.color,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 168,
        height: 228,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Full 1:1 image (square)
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.low,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: .2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 11.5,
                height: 1.2,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Container(
              width: 32,
              height: 3,
              decoration: BoxDecoration(
                color: color.withOpacity(.55),
                borderRadius: BorderRadius.circular(4),
              ),
            )
          ],
        ),
      ),
    );
  }
}