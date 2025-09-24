import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FarmerDetailScreen extends StatelessWidget {
  final Map<String, dynamic> farmerData;

  const FarmerDetailScreen({Key? key, required this.farmerData})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Fetching farmer data from the passed map
    String name = farmerData['name'] ?? 'Not Provided';
    String location = farmerData['location'] ?? 'Not Provided';
    String phone = farmerData['phone'] ?? 'Not Provided';
    String email = farmerData['email'] ?? 'Not Provided';
    String farmerId = farmerData['uid'] ?? farmerData['id'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC), // Light beige background
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Farmer Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: Column(
        children: [
          // Top section with background image and farmer details
          Container(
            height: 400,
            width: double.infinity,
            decoration: BoxDecoration(
              image: const DecorationImage(
                image: AssetImage('assets/images/green_leaves_051.jpg'),
                fit: BoxFit.cover,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.6),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),

                      // Welcome message
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: const Text(
                          '🌾 Welcome to AgriMate 🌾',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Profile Picture with earthy styling
                      Hero(
                        tag: 'farmer_${farmerId}',
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF8FBC8F), // Soft sage green
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: farmerData['profileImageUrl'] != null
                                ? Image.network(
                                    farmerData['profileImageUrl'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: const Color(0xFF8FBC8F),
                                        child: const Icon(
                                          Icons.person,
                                          size: 60,
                                          color: Colors.white,
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    color: const Color(0xFF8FBC8F),
                                    child: const Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Name with agricultural styling
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 2),
                              blurRadius: 4,
                              color: Colors.black26,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),

                      // Location with agricultural theme
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF9ACD32,
                          ).withOpacity(0.3), // Yellow-green
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 18,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              location,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Main Content Area with earthy theme
          Expanded(
            child: Container(
              color: const Color(0xFFF5F5DC), // Light beige
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Contact Information Card
                    _buildEarthyCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF8FBC8F,
                                  ).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.contact_phone,
                                  color: Color(0xFF556B2F), // Dark olive green
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Text(
                                'Contact Information',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF556B2F), // Dark olive green
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          _buildContactRow(
                            icon: Icons.phone,
                            label: 'Phone',
                            value: phone,
                            onTap: () => _launchPhone(phone),
                          ),
                          const SizedBox(height: 16),
                          _buildContactRow(
                            icon: Icons.email,
                            label: 'Email',
                            value: email,
                            onTap: () => _launchEmail(email),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Reviews Section
                    _buildEarthyCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFDAA520,
                                  ).withOpacity(0.2), // Goldenrod
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFFDAA520), // Goldenrod
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Text(
                                'Ratings & Reviews',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF556B2F), // Dark olive green
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          FutureBuilder<Map<String, dynamic>>(
                            future: _fetchFarmerReviews(farmerId),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return _buildLoadingState();
                              }
                              if (snapshot.hasError) {
                                return _buildErrorState();
                              }
                              final data = snapshot.data;
                              if (data == null ||
                                  (data['reviews'] as List).isEmpty) {
                                return _buildEmptyReviewsState();
                              }
                              final avg = data['average'] as double?;
                              final reviews = data['reviews'] as List<dynamic>;
                              return _buildReviewsContent(avg, reviews);
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Earthy themed card widget
  Widget _buildEarthyCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        border: Border.all(
          color: const Color(
            0xFF8FBC8F,
          ).withOpacity(0.3), // Soft sage green border
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFF556B2F,
            ).withOpacity(0.1), // Dark olive green shadow
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  // Glass morphism card widget (keeping for compatibility)
  Widget _buildGlassCard({required Widget child}) {
    return _buildEarthyCard(child: child);
  }

  // Contact row widget with earthy theme
  Widget _buildContactRow({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5DC), // Light beige background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(
            0xFF8FBC8F,
          ).withOpacity(0.3), // Soft sage green border
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFF8FBC8F,
                    ).withOpacity(0.2), // Soft sage green
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF556B2F), // Dark olive green
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(
                            0xFF556B2F,
                          ).withOpacity(0.7), // Dark olive green
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF556B2F), // Dark olive green
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: const Color(0xFF8FBC8F), // Soft sage green
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Loading state for reviews with earthy theme
  Widget _buildLoadingState() {
    return Container(
      height: 100,
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            Color(0xFF8FBC8F),
          ), // Soft sage green
        ),
      ),
    );
  }

  // Error state for reviews with earthy theme
  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE4E1), // Misty rose background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFCD853F).withOpacity(0.3), // Peru color border
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: const Color(0xFFCD853F), // Peru color
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'Unable to load reviews',
            style: TextStyle(
              color: const Color(0xFFCD853F), // Peru color
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please check your connection and try again',
            style: TextStyle(
              color: const Color(0xFFCD853F).withOpacity(0.7), // Peru color
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Empty reviews state with earthy theme
  Widget _buildEmptyReviewsState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5DC).withOpacity(0.5), // Light beige
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF8FBC8F).withOpacity(0.3), // Soft sage green
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.rate_review_outlined,
            color: const Color(0xFF8FBC8F), // Soft sage green
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'No reviews yet',
            style: TextStyle(
              color: const Color(0xFF556B2F), // Dark olive green
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to review this farmer',
            style: TextStyle(
              color: const Color(
                0xFF556B2F,
              ).withOpacity(0.7), // Dark olive green
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Reviews content widget with earthy theme
  Widget _buildReviewsContent(double? avg, List<dynamic> reviews) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Average rating display
        if (avg != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _getRatingColor(avg).withOpacity(0.1),
                  _getRatingColor(avg).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _getRatingColor(avg).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getRatingColor(avg).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    avg.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _getRatingColor(avg),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < avg.round()
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: const Color(0xFFDAA520), // Goldenrod
                            size: 20,
                          );
                        }),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getRatingDescription(avg),
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(
                            0xFF556B2F,
                          ).withOpacity(0.7), // Dark olive green
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Reviews list
        Text(
          'Recent Reviews (${reviews.length})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF556B2F), // Dark olive green
          ),
        ),
        const SizedBox(height: 12),
        ...reviews.take(3).map<Widget>((review) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildReviewCard(review),
          );
        }).toList(),
      ],
    );
  }

  // Individual review card with earthy theme
  Widget _buildReviewCard(Map<String, dynamic> review) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5DC).withOpacity(0.7), // Light beige
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF8FBC8F).withOpacity(0.3), // Soft sage green
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF8FBC8F), // Soft sage green
                child: Text(
                  (review['reviewerName'] ?? 'A')[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['reviewerName'] ?? 'Anonymous',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF556B2F), // Dark olive green
                      ),
                    ),
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < (review['rating'] ?? 0)
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: const Color(0xFFDAA520), // Goldenrod
                            size: 14,
                          );
                        }),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(review['timestamp']),
                          style: TextStyle(
                            fontSize: 12,
                            color: const Color(
                              0xFF556B2F,
                            ).withOpacity(0.6), // Dark olive green
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review['comment'] != null &&
              review['comment'].toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review['comment'].toString(),
              style: TextStyle(
                fontSize: 14,
                color: const Color(
                  0xFF556B2F,
                ).withOpacity(0.8), // Dark olive green
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Helper method to get rating color (agricultural theme)
  Color _getRatingColor(double rating) {
    if (rating >= 4.0) {
      return const Color(0xFF228B22); // Forest Green - Excellent
    } else if (rating >= 3.0) {
      return const Color(0xFF9ACD32); // Yellow Green - Good
    } else if (rating >= 2.0) {
      return const Color(0xFFDAA520); // Goldenrod - Average
    }
    return const Color(0xFFCD853F); // Peru - Poor
  }

  // Helper method to get rating description
  String _getRatingDescription(double rating) {
    if (rating >= 4.0) {
      return 'Excellent farmer with great reviews';
    } else if (rating >= 3.0) {
      return 'Good farmer with positive feedback';
    } else if (rating >= 2.0) {
      return 'Average farmer with mixed reviews';
    }
    return 'Needs improvement based on reviews';
  }

  // Helper method to format timestamp
  String _formatDate(dynamic timestamp) {
    if (timestamp != null) {
      final date = (timestamp as Timestamp).toDate();
      return '${date.day}/${date.month}/${date.year}';
    }
    return '';
  }

  // Method to fetch farmer reviews from Firestore
  Future<Map<String, dynamic>> _fetchFarmerReviews(String farmerId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('FarmerReviews')
          .doc(farmerId)
          .get();
      if (!doc.exists ||
          doc.data() == null ||
          !(doc.data()!.containsKey('ratings'))) {
        return {'average': null, 'reviews': []};
      }
      final List<dynamic> ratings = doc['ratings'] ?? [];
      if (ratings.isEmpty) {
        return {'average': null, 'reviews': []};
      }
      double avg =
          ratings
              .map((r) => (r['rating'] ?? 0).toDouble())
              .fold(0.0, (a, b) => a + b) /
          ratings.length;
      return {'average': avg, 'reviews': ratings};
    } catch (e) {
      throw Exception('Failed to load reviews: $e');
    }
  }

  // Method to launch phone calls
  Future<void> _launchPhone(String phone) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  // Method to launch email
  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }
}
