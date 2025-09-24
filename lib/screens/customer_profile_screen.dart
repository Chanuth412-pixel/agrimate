import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'customer_detail_page.dart';
import 'add_crop_customer_c1.dart';
import 'scheduled_orders_screen.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  Map<String, String> cropDescriptions = {
    'Tomato': 'Loading...',
    'Bean': 'Loading...',
    'Okra': 'Loading...',
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
          'Tomato': 'Premium Quality',
          'Bean': 'Fresh Stock',
          'Okra': 'Best Price'
        };
      });
    } catch (e) {
      // On error, use simple two-word fallback descriptions
      setState(() {
        cropDescriptions = {
          'Tomato': 'Premium Quality',
          'Bean': 'Fresh Stock',
          'Okra': 'Best Price'
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
                                        const Text(
                                          'Welcome back!',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
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
                                        const SizedBox(height: 4),
                                        Text(
                                          customerName,
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
        label: const Text('Quick Order', style: TextStyle(color: Colors.white)),
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
                ElevatedButton.icon(
                  icon: const Icon(Icons.schedule, size: 16),
                  label: const Text('Scheduled'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF02C697),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ScheduledOrdersScreen()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  CropCard(
                    name: 'Tomato',
                    imagePath: 'assets/images/tomato.png',
                    color: const Color(0xFFE53935),
                    description: cropDescriptions['Tomato'] ?? 'High demand',
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddCropCustomerC1(cropName: 'Tomato'),
                        ),
                      );
                      if (result == 'updated') {
                        setState(() {});
                      }
                    },
                  ),
                  const SizedBox(width: 16),
                  CropCard(
                    name: 'Bean',
                    imagePath: 'assets/images/bean.png',
                    color: const Color(0xFF4CAF50),
                    description: cropDescriptions['Bean'] ?? 'Best season',
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddCropCustomerC1(cropName: 'Bean'),
                        ),
                      );
                      if (result == 'updated') {
                        setState(() {});
                      }
                    },
                  ),
                  const SizedBox(width: 16),
                  CropCard(
                    name: 'Okra',
                    imagePath: 'assets/images/okra.png',
                    color: const Color(0xFF7CB342),
                    description: cropDescriptions['Okra'] ?? 'Good price',
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddCropCustomerC1(cropName: 'Okra'),
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

                if (transactions.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transactions.length > 3 ? 3 : transactions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
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
          if (deliveryGuyName != null && deliveryGuyName.toString().isNotEmpty) ...[
            const Divider(height: 16),
            _buildInfoRow(Icons.delivery_dining, 'Delivery Guy', deliveryGuyName),
            if (deliveryGuyPhone != null && deliveryGuyPhone.toString().isNotEmpty)
              _buildInfoRow(Icons.phone, 'Driver Phone', deliveryGuyPhone),
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
                'LKR ${price * quantity}',
                const Color(0xFFE8F5F1),
                valueColor: const Color(0xFF02C697),
              ),
            ],
          ),
          if (status == 'delivered' && !reviewed)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.rate_review, color: Colors.white, size: 18),
                label: const Text('Leave Review'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 15),
                ),
                onPressed: () {
                  _showReviewDialog(context, tx, () {
                    if (mounted) setState(() {});
                  });
                },
              ),
            ),
          if (status == 'delivered' && reviewed)
            const Padding(
              padding: EdgeInsets.only(top: 12.0),
              child: Text('✅ Reviewed', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
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
      case 'in_transit':
        bgColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        displayText = 'In Transit';
        break;
      case 'delivered':
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        displayText = 'Delivered';
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
      child: Container(
        width: 140,
        height: 160,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}