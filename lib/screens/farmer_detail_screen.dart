import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui'; // For BackdropFilter (glass effect)

class FarmerDetailScreen extends StatelessWidget {
  final Map<String, dynamic> farmerData;

  // Constructor to receive farmer data from the previous screen
  const FarmerDetailScreen({super.key, required this.farmerData});

  @override
  Widget build(BuildContext context) {
    // Fetching farmer data from the passed map
    String name = farmerData['name'] ?? 'Not Provided';
    String location = farmerData['location'] ?? 'Not Provided';
    String phone = farmerData['phone'] ?? 'Not Provided';
    String email = farmerData['email'] ?? 'Not Provided';
    String farmerId = farmerData['uid'] ?? farmerData['id'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmer Details',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2E7D32), // Deep green
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/Background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
          child: Container(
            color: Colors.black.withOpacity(0.2),
            child: Column(
              children: [
                // Profile Header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B5E20).withOpacity(0.9), // Darker semi-transparent green
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/farmer_avatar.png', // Add a farmer avatar image to your assets
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.person,
                                size: 40,
                                color: Color(0xFF2E7D32),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on, 
                                    size: 16, color: Colors.white70),
                                const SizedBox(width: 4),
                                Text(
                                  location,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Contact Information Card
                          ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                              child: Container(
                                padding: const EdgeInsets.all(16.0),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Contact Information',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildInfoRow(Icons.phone, 'Phone', phone),
                                    const SizedBox(height: 12),
                                    _buildInfoRow(Icons.email, 'Email', email),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Rating and Reviews Section
                          ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                              child: Container(
                                padding: const EdgeInsets.all(16.0),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Rating & Reviews',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    FutureBuilder<Map<String, dynamic>>(
                                      future: _fetchFarmerReviews(farmerId),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return const Center(child: CircularProgressIndicator(
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ));
                                        }
                                        if (snapshot.hasError) {
                                          return const Text('Error loading reviews',
                                              style: TextStyle(color: Colors.white));
                                        }
                                        final data = snapshot.data;
                                        if (data == null || (data['reviews'] as List).isEmpty) {
                                          return Column(
                                            children: [
                                              const SizedBox(height: 20),
                                              Image.asset(
                                                'assets/images/no_reviews.png', // Add a no reviews illustration
                                                height: 100,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return const Icon(
                                                    Icons.reviews,
                                                    size: 60,
                                                    color: Colors.white,
                                                  );
                                                },
                                              ),
                                              const SizedBox(height: 10),
                                              const Text(
                                                'No reviews yet',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          );
                                        }
                                        final avg = data['average'] as double?;
                                        final reviews = data['reviews'] as List<dynamic>;
                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (avg != null)
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                        horizontal: 12, vertical: 6),
                                                    decoration: BoxDecoration(
                                                      color: _getRatingColor(avg),
                                                      borderRadius: BorderRadius.circular(20),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        const Icon(Icons.star, 
                                                            color: Colors.white, size: 20),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          avg.toStringAsFixed(1),
                                                          style: const TextStyle(
                                                            fontSize: 16,
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Text(
                                                    '${reviews.length} ${reviews.length == 1 ? 'Review' : 'Reviews'}',
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            const SizedBox(height: 16),
                                            const Text(
                                              'All Reviews',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            ListView.separated(
                                              physics: const NeverScrollableScrollPhysics(),
                                              shrinkWrap: true,
                                              itemCount: reviews.length,
                                              separatorBuilder: (context, idx) => const Divider(
                                                height: 20,
                                                thickness: 1,
                                                color: Colors.white54,
                                              ),
                                              itemBuilder: (context, idx) {
                                                final review = reviews[idx];
                                                return Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                                  child: Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      const Icon(Icons.account_circle, 
                                                          size: 40, color: Colors.white),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              review['reviewerName'] ?? 'Anonymous',
                                                              style: const TextStyle(
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: 16,
                                                                color: Colors.white,
                                                              ),
                                                            ),
                                                            const SizedBox(height: 4),
                                                            Row(
                                                              children: [
                                                                Icon(Icons.star, 
                                                                    color: Colors.amber, size: 18),
                                                                const SizedBox(width: 4),
                                                                Text(
                                                                  (review['rating'] ?? 0).toString(),
                                                                  style: const TextStyle(
                                                                    fontSize: 15,
                                                                    color: Colors.white,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            const SizedBox(height: 6),
                                                            Text(
                                                              review['review'] ?? '',
                                                              style: const TextStyle(
                                                                fontSize: 15,
                                                                color: Colors.white,
                                                              ),
                                                            ),
                                                            const SizedBox(height: 4),
                                                            if (review['timestamp'] != null)
                                                              Text(
                                                                _formatTimestamp(review['timestamp']),
                                                                style: const TextStyle(
                                                                  fontSize: 12,
                                                                  color: Colors.white70,
                                                                ),
                                                              ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.0) return Colors.green;
    if (rating >= 3.0) return Colors.orange;
    return Colors.red;
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }
    return '';
  }

  Future<Map<String, dynamic>> _fetchFarmerReviews(String farmerId) async {
    final doc = await FirebaseFirestore.instance
        .collection('FarmerReviews')
        .doc(farmerId)
        .get();
    if (!doc.exists || doc.data() == null || !(doc.data()!.containsKey('ratings'))) {
      return {'average': null, 'reviews': []};
    }
    final List<dynamic> ratings = doc['ratings'] ?? [];
    if (ratings.isEmpty) {
      return {'average': null, 'reviews': []};
    }
    double avg = ratings
        .map((r) => (r['rating'] ?? 0).toDouble())
        .fold(0.0, (a, b) => a + b) /
        ratings.length;
    return {
      'average': avg,
      'reviews': ratings,
    };
  }
}