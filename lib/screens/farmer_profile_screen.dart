import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'farmer_detail_screen.dart'; 

class FarmerProfileScreen extends StatelessWidget {
  const FarmerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmer Dashboard'),
        backgroundColor: const Color(0xFF02C697),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'View Profile',
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;

              final doc = await FirebaseFirestore.instance
                  .collection('farmers') // <-- Change this to your Farmer collection name
                  .doc(user?.uid)
                  .get();

              final farmerData = doc.data() ?? {
                "email": user?.email ?? '',
                "uid": user?.uid ?? '',
                "phone": "Not Provided",
                "name": "Not Provided",
              };

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FarmerDetailScreen(farmerData: farmerData),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/addHarvest');
        },
        backgroundColor: const Color(0xFF02C697),
        icon: const Icon(Icons.add),
        label: const Text("Add Harvest"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Crop Demand Trends',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('this_week')
                      .doc('trend')
                      .get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    if (data == null) {
                      return _buildEmptyState('No trend data available.');
                    }

                    final crops = ['tomato', 'carrot', 'brinjal'];
                    final cropNames = ['Tomato', 'Carrot', 'Brinjal'];
                    
                    return ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: crops.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        final cropKey = crops[index];
                        final cropName = cropNames[index];
                        final trendData = List<int>.from(data[cropKey] ?? [0, 0, 0, 0]);
                        
                        // Calculate average demand for overall score
                        final avgDemand = trendData.isNotEmpty 
                            ? trendData.reduce((a, b) => a + b) / trendData.length 
                            : 0;
                        
                        return Container(
                          width: 200,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cropName,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '4-Week Demand Forecast',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Week 1
                              _buildWeekDemand(context, 'Week 1', trendData.isNotEmpty ? trendData[0] : 0),
                              const SizedBox(height: 3),
                              // Week 2
                              _buildWeekDemand(context, 'Week 2', trendData.length > 1 ? trendData[1] : 0),
                              const SizedBox(height: 3),
                              // Week 3
                              _buildWeekDemand(context, 'Week 3', trendData.length > 2 ? trendData[2] : 0),
                              const SizedBox(height: 3),
                              // Week 4
                              _buildWeekDemand(context, 'Week 4', trendData.length > 3 ? trendData[3] : 0),
                              const SizedBox(height: 6),
                              const Divider(height: 1),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Avg Demand:',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                                                     Text(
                                     '${avgDemand.round()}%',
                                     style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                       color: _getDemandColor(avgDemand.toDouble()),
                                       fontWeight: FontWeight.bold,
                                     ),
                                   ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Ongoing Transactions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 220,
                child: FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('Ongoing_Trans_Farm')
                      .doc(userId)
                      .get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    if (data == null || !data.containsKey('transactions')) {
                      return _buildEmptyState('No transactions found.');
                    }
                    final transactions = List<Map<String, dynamic>>.from(data['transactions']);
                    if (transactions.isEmpty) {
                      return _buildEmptyState('No transactions available.');
                    }
                    return ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: transactions.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        final tx = transactions[index];
                        final crop = tx['Crop'] ?? 'Unknown';
                        final quantity = tx['Quantity Sold (1kg)'] ?? 0;
                        final price = tx['Sale Price Per kg'] ?? 0;
                        final status = tx['Status'] ?? 'Pending';
                        final customerName = tx['Farmer Name'] ?? 'N/A';
                        final phoneNO = tx['Phone_NO'] ?? 'N/A';
                        final deliveredOn = (tx['Date'] as Timestamp?)?.toDate() ?? DateTime.now();
                        return Container(
                          width: 220,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
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
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  _buildStatusChip(status),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('Customer: $customerName', style: Theme.of(context).textTheme.bodySmall),
                              Text('Contact: $phoneNO', style: Theme.of(context).textTheme.bodySmall),
                              Text('Deliver On: ${deliveredOn.day}/${deliveredOn.month}/${deliveredOn.year}', style: Theme.of(context).textTheme.bodySmall),
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildDetailBox('Quantity', '${quantity}kg', const Color(0xFFF3F4F6)),
                                  _buildDetailBox('Unit Price', 'LKR$price', const Color(0xFFF3F4F6)),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'My Harvest Listings',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('Harvests')
                    .doc(userId)
                    .get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  if (data == null || !data.containsKey('harvests')) {
                    return _buildEmptyState('No harvests found.');
                  }
                  final harvests = List<Map<String, dynamic>>.from(data['harvests']);
                  if (harvests.isEmpty) {
                    return _buildEmptyState('No harvest entries.');
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: harvests.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = harvests[index];
                      return GestureDetector(
                        onTap: () => _showHarvestDetails(context, item),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('${item['crop']} - ${item['quantity']}kg',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Planting: ${item['plantingDate']}', style: Theme.of(context).textTheme.bodySmall),
                                Text('Harvest: ${item['harvestDate']}', style: Theme.of(context).textTheme.bodySmall),
                                Text('Price: LKR${item['expectedPrice']} per kg', style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.info_outline,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final isCompleted = status.toLowerCase() == 'completed';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isCompleted ? const Color(0xFFE8F5F1) : const Color(0xFFFFF4E6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${status[0].toUpperCase()}${status.substring(1)}',
        style: TextStyle(
          color: isCompleted ? const Color(0xFF02C697) : const Color(0xFFFF9800),
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildDetailBox(String label, String value, Color bgColor) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekDemand(BuildContext context, String week, int demand) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          week,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        Text(
          '$demand%',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: _getDemandColor(demand.toDouble()),
          ),
        ),
      ],
    );
  }

  Color _getDemandColor(double demand) {
    if (demand >= 80) {
      return Colors.green[700]!;
    } else if (demand >= 60) {
      return Colors.orange[600]!;
    } else if (demand >= 40) {
      return Colors.amber[600]!;
    } else {
      return Colors.red[600]!;
    }
  }

  void _showHarvestDetails(BuildContext context, Map<String, dynamic> harvest) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 600),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Harvest Details',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF02C697),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey[100],
                          shape: const CircleBorder(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Crop and Quantity
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF02C697).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${harvest['crop']?.toString().toUpperCase()}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF02C697),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Quantity: ${harvest['quantity']} kg',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Basic Details
                  _buildDetailRow('Planting Date', harvest['plantingDate'] ?? 'N/A'),
                  _buildDetailRow('Harvest Date', harvest['harvestDate'] ?? 'N/A'),
                  _buildDetailRow('Expected Price', 'LKR ${harvest['expectedPrice']} per kg'),
                  _buildDetailRow('Available Quantity', '${harvest['available']} kg'),
                  const SizedBox(height: 20),
                  
                  // Precautions Section
                  if (harvest['precautions'] != null && harvest['precautions'].toString().isNotEmpty) ...[
                    Text(
                      'Crop Care Precautions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Text(
                        harvest['precautions'].toString(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                          color: Colors.orange[800],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  
                  // Close Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF02C697),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}