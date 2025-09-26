import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomerDetailPage extends StatelessWidget {
  final Map<String, dynamic> customerData;

  const CustomerDetailPage({super.key, required this.customerData});

  @override
  Widget build(BuildContext context) {
    final String name = customerData['name'] ?? 'Not Provided';
    final String location = customerData['location'] ?? 'Not Provided';
    final String phone = customerData['phone'] ?? 'Not Provided';
    final String email = customerData['email'] ?? 'Not Provided';
    final String customerId = customerData['uid'] ?? customerData['id'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Customer Profile',
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
          // Header with background and centered avatar
          Container(
            height: 280,
            width: double.infinity,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                    child: Image.asset(
                      'assets/images/customer_page.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.25),
                          Colors.black.withOpacity(0.55),
                        ],
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Hero(
                        tag: 'customer_$customerId',
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF8FBC8F),
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('customers')
                                .doc(customerId)
                                .snapshots(),
                            builder: (context, snapshot) {
                              final snapData = snapshot.data?.data() as Map<String, dynamic>?;
                              final latestUrl = snapData?['profileImageUrl'] ?? customerData['profileImageUrl'];
                              final updatedAt = (snapData?['profileImageUpdatedAt'] as Timestamp?)?.millisecondsSinceEpoch;
                              final hasUrl = latestUrl != null && latestUrl.toString().isNotEmpty;
                              return ClipOval(
                                child: hasUrl
                                    ? Image.network(
                                        updatedAt != null ? '$latestUrl?v=$updatedAt' : latestUrl,
                                        key: ValueKey(updatedAt ?? latestUrl),
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Container(
                                            color: const Color(0xFF8FBC8F),
                                            child: const Center(
                                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                            ),
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: const Color(0xFF8FBC8F),
                                            child: const Icon(Icons.person, size: 60, color: Colors.white),
                                          );
                                        },
                                      )
                                    : Container(
                                        color: const Color(0xFF8FBC8F),
                                        child: const Icon(Icons.person, size: 60, color: Colors.white),
                                      ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.2,
                          shadows: [Shadow(color: Colors.black45, offset: Offset(0,1), blurRadius: 4)],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on, size: 16, color: Colors.white),
                            const SizedBox(width: 6),
                            Text(
                              location,
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Floating About card (replaces summary card)
          Transform.translate(
            offset: const Offset(0, -24),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _AboutFloatingCard(
                collection: 'customers',
                docId: customerId,
                canEdit: FirebaseAuth.instance.currentUser?.uid == customerId && customerId.isNotEmpty,
                fallback: (customerData['description'] ?? 'No description added yet.') as String,
              ),
            ),
          ),

          // Main content
          Expanded(
            child: Container(
              color: const Color(0xFFF5F5DC),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
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
                                  color: const Color(0xFF8FBC8F).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.contact_phone,
                                  color: Color(0xFF556B2F),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Text(
                                'Contact Information',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF556B2F),
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

                    _buildEarthyCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDAA520).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFFDAA520),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Text(
                                'Ratings & Reviews',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF556B2F),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          FutureBuilder<Map<String, dynamic>>(
                            future: _fetchCustomerReviews(customerId),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return _buildLoadingState();
                              }
                              if (snapshot.hasError) {
                                return _buildErrorState();
                              }
                              final data = snapshot.data;
                              if (data == null || (data['reviews'] as List).isEmpty) {
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

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            await FirebaseAuth.instance.signOut();
                            if (context.mounted) {
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                '/customerLogIn',
                                (route) => false,
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Logout failed: $e')),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text('Log out'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE53935),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Earthy themed card
  Widget _buildEarthyCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFF8FBC8F).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF556B2F).withOpacity(0.1),
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

  // Reviews UI helpers (reuse styles from farmer screen)
  Widget _buildLoadingState() {
    return SizedBox(
      height: 100,
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8FBC8F)),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE4E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCD853F).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFCD853F), size: 48),
          const SizedBox(height: 12),
          const Text('Unable to load reviews', style: TextStyle(color: Color(0xFFCD853F), fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Please check your connection and try again', style: TextStyle(color: const Color(0xFFCD853F).withOpacity(0.7), fontSize: 14), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildEmptyReviewsState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5DC).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8FBC8F).withOpacity(0.3)),
      ),
      child: const Column(
        children: [
          Icon(Icons.rate_review_outlined, color: Color(0xFF8FBC8F), size: 48),
          SizedBox(height: 12),
          Text('No reviews yet', style: TextStyle(color: Color(0xFF556B2F), fontSize: 16, fontWeight: FontWeight.w600)),
          SizedBox(height: 8),
          Text('Be the first to review this customer', style: TextStyle(color: Color(0xFF556B2F), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildReviewsContent(double? avg, List<dynamic> reviews) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _getRatingColor(avg)),
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
                            index < avg.round() ? Icons.star_rounded : Icons.star_border_rounded,
                            color: const Color(0xFFDAA520),
                            size: 20,
                          );
                        }),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getRatingDescription(avg),
                        style: TextStyle(fontSize: 14, color: const Color(0xFF556B2F).withOpacity(0.7), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        Text('Recent Reviews (${reviews.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF556B2F))),
        const SizedBox(height: 12),
        ...reviews.take(3).map<Widget>((r) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _buildReviewCard(r as Map<String, dynamic>))).toList(),
      ],
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5DC).withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8FBC8F).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF8FBC8F),
                child: Text(
                  (review['reviewerName'] ?? 'A').toString().characters.first.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review['reviewerName'] ?? 'Anonymous', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF556B2F))),
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < (review['rating'] ?? 0) ? Icons.star_rounded : Icons.star_border_rounded,
                            color: const Color(0xFFDAA520),
                            size: 14,
                          );
                        }),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(review['timestamp']),
                          style: TextStyle(fontSize: 12, color: const Color(0xFF556B2F).withOpacity(0.6)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review['comment'] != null && review['comment'].toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review['comment'].toString(),
              style: TextStyle(fontSize: 14, color: const Color(0xFF556B2F).withOpacity(0.8), height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  // Contact row helper (same earthy style)
  Widget _buildContactRow({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5DC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8FBC8F).withOpacity(0.3)),
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
                    color: const Color(0xFF8FBC8F).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: const Color(0xFF556B2F), size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(fontSize: 14, color: const Color(0xFF556B2F).withOpacity(0.7), fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(value, style: const TextStyle(fontSize: 16, color: Color(0xFF556B2F), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Color(0xFF8FBC8F), size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.0) return const Color(0xFF228B22);
    if (rating >= 3.0) return const Color(0xFF9ACD32);
    if (rating >= 2.0) return const Color(0xFFDAA520);
    return const Color(0xFFCD853F);
  }

  String _getRatingDescription(double rating) {
    if (rating >= 4.0) return 'Excellent with great reviews';
    if (rating >= 3.0) return 'Good with positive feedback';
    if (rating >= 2.0) return 'Average with mixed reviews';
    return 'Needs improvement based on reviews';
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }
    return '';
  }

  Future<Map<String, dynamic>> _fetchCustomerReviews(String customerId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('CustomerReviews').doc(customerId).get();
      if (!doc.exists || doc.data() == null || !(doc.data()!.containsKey('ratings'))) {
        return {'average': null, 'reviews': []};
      }
      final List<dynamic> ratings = doc['ratings'] ?? [];
      if (ratings.isEmpty) return {'average': null, 'reviews': []};
      final double avg = ratings.map((r) => (r['rating'] ?? 0).toDouble()).fold(0.0, (a, b) => a + b) / ratings.length;
      return {'average': avg, 'reviews': ratings};
    } catch (e) {
      throw Exception('Failed to load reviews: $e');
    }
  }

  Future<void> _launchPhone(String phone) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  // About floating card under header (editable by owner)
  Widget _AboutFloatingCard({
    required String collection,
    required String docId,
    required bool canEdit,
    required String fallback,
  }) {
    return StreamBuilder<DocumentSnapshot>(
      stream: docId.isEmpty
          ? const Stream.empty()
          : FirebaseFirestore.instance.collection(collection).doc(docId).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final desc = (data?['description'] ?? fallback) as String;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8)),
            ],
            border: Border.all(color: const Color(0xFF8FBC8F).withOpacity(0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8FBC8F).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.info_outline, color: Color(0xFF556B2F), size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'About',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF556B2F)),
                  ),
                  const Spacer(),
                  if (canEdit)
                    OutlinedButton.icon(
                      onPressed: () => _showEditDescriptionDialog(context, collection, docId, desc),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF556B2F),
                        side: BorderSide(color: const Color(0xFF8FBC8F).withOpacity(0.6)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5DC).withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF8FBC8F).withOpacity(0.3)),
                ),
                child: Text(
                  (desc).isNotEmpty ? desc : 'No description added yet.',
                  style: const TextStyle(fontSize: 14, color: Color(0xFF556B2F), height: 1.4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showEditDescriptionDialog(BuildContext context, String collection, String docId, String initial) async {
    final controller = TextEditingController(text: initial);
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Edit description'),
          content: SizedBox(
            width: 420,
            child: TextField(
              controller: controller,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Tell others about you... (preferences, interests, etc.)',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final text = controller.text.trim();
                try {
                  await FirebaseFirestore.instance.collection(collection).doc(docId).update({
                    'description': text,
                    'descriptionUpdatedAt': FieldValue.serverTimestamp(),
                  });
                  if (context.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}