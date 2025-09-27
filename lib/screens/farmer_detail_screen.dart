import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/currency_util.dart';
import '../constants/app_constants.dart';

class FarmerDetailScreen extends StatelessWidget {
  final Map<String, dynamic> farmerData;

  const FarmerDetailScreen({Key? key, required this.farmerData})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
  final loc = AppLocalizations.of(context)!;
  // Fetching farmer data from the passed map with localized fallbacks
        String name = farmerData['name'] ?? loc.notProvided;
        String location = farmerData['location'] ?? loc.notProvided;
        String phone = farmerData['phone'] ?? loc.notProvided;
  String email = farmerData['email'] ?? loc.notProvided;
    String farmerId = farmerData['uid'] ?? farmerData['id'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC), // Light beige background
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          loc.farmerProfileTitle,
          style: const TextStyle(
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
          // Top section redesigned with Background.jpg and centered avatar + quick actions
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
                // Background image
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                    child: Image.asset(
                      'assets/images/Background.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Dark overlay for contrast
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
                // Centered avatar, name and location
                Align(
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Hero(
                        tag: 'farmer_${farmerId}',
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
                                .collection('farmers')
                                .doc(farmerId)
                                .snapshots(),
                            builder: (context, snapshot) {
                              final snapData = snapshot.data?.data() as Map<String, dynamic>?;
                              final latestUrl = snapData?['profileImageUrl'] ?? farmerData['profileImageUrl'];
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
                            // Make location reactive by listening to the farmer document
                            StreamBuilder<DocumentSnapshot>(
                              stream: farmerId.isEmpty
                                  ? const Stream.empty()
                                  : FirebaseFirestore.instance.collection('farmers').doc(farmerId).snapshots(),
                              builder: (context, snap) {
                                final data = snap.data?.data() as Map<String, dynamic>?;
                                final liveLocation = data?['location'] ?? location;
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      liveLocation.toString(),
                                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(width: 8),
                                    // Owner-only change location button
                                    if (FirebaseAuth.instance.currentUser?.uid == farmerId && farmerId.isNotEmpty)
                                      GestureDetector(
                                        onTap: () => showChangeLocationDialog(context, farmerId),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.18),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: const [
                                              Icon(Icons.edit_location, size: 14, color: Colors.white),
                                              SizedBox(width: 6),
                                              Text('Change', style: TextStyle(color: Colors.white, fontSize: 12)),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Quick actions removed as per request
              ],
            ),
          ),

          // Floating About card (replaces summary card)
          Transform.translate(
            offset: const Offset(0, -24),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _AboutFloatingCard(
                collection: 'farmers',
                docId: farmerId,
                canEdit: FirebaseAuth.instance.currentUser?.uid == farmerId && farmerId.isNotEmpty,
                fallback: (farmerData['description'] ?? loc.noDescriptionYet) as String,
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
                    const SizedBox(height: 0),

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
                                  Text(
                                    loc.contactInfo,
                                    style: const TextStyle(
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
                                label: loc.phone,
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

                    // Delivery Price Per Km (editable by owner)
                    _buildEarthyCard(
                      child: _DeliveryPriceSection(
                        farmerId: farmerId,
                        canEdit: FirebaseAuth.instance.currentUser?.uid == farmerId && farmerId.isNotEmpty,
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
                                   Text(
                                     loc.ratingsAndReviews,
                                     style: const TextStyle(
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

                    // Logout button at the bottom
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            await FirebaseAuth.instance.signOut();
                            if (context.mounted) {
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                '/farmerLogIn',
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
                             label: Text(loc.logOut),
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

  // Small round action button used in header
  Widget _roundHeaderAction({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.25),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  // Quick summary card displayed beneath header
  // Keeps data unchanged; purely presentation
  Widget _QuickSummaryCard({required String farmerId, required String phone, required String email}) {
    return Container(
      height: 86,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8)),
        ],
        border: Border.all(color: const Color(0xFF8FBC8F).withOpacity(0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _summaryItem(title: 'ID', value: farmerId.isNotEmpty ? farmerId.substring(0, 6) : 'N/A'),
          _divider(),
          _summaryItem(title: 'Phone', value: phone.isNotEmpty ? phone : 'N/A'),
          _divider(),
          _summaryItem(title: 'Email', value: email.isNotEmpty ? email : 'N/A'),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: double.infinity, color: const Color(0xFF8FBC8F).withOpacity(0.25));

  Widget _summaryItem({required String title, required String value}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: TextStyle(fontSize: 12, color: const Color(0xFF556B2F).withOpacity(0.6), fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF556B2F))),
        ],
      ),
    );
  }

  // Image upload removed per request

  // Glass morphism card widget (keeping for compatibility)
  Widget _buildGlassCard({required Widget child}) {
    return _buildEarthyCard(child: child);
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
        final loc = AppLocalizations.of(context)!;
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final desc = (data?['description'] ?? fallback) as String;
        return Container(
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
                  Text(
                    loc.about,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF556B2F)),
                  ),
                  const Spacer(),
                  if (canEdit)
                    OutlinedButton.icon(
                      onPressed: () => _showEditDescriptionDialog(context, collection, docId, desc),
                      icon: const Icon(Icons.edit, size: 16),
                      label: Text(loc.edit),
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
                  (desc).isNotEmpty ? desc : loc.noDescriptionYet,
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
        final loc = AppLocalizations.of(ctx)!;
        return AlertDialog(
          title: Text(loc.editDescription),
          content: SizedBox(
            width: 420,
            child: TextField(
              controller: controller,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: loc.descriptionHint,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(loc.cancel)),
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
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${loc.failedToSave}: $e')));
                  }
                }
              },
              child: Text(loc.save),
            ),
          ],
        );
      },
    );
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
      // Sort ratings newest first (createdAt) so recent reviews appear on top
      ratings.sort((a, b) {
        final aTs = (a is Map<String, dynamic>) ? a['createdAt'] : null;
        final bTs = (b is Map<String, dynamic>) ? b['createdAt'] : null;
        if (aTs is Timestamp && bTs is Timestamp) {
          return bTs.compareTo(aTs);
        }
        return 0;
      });
      double avg = ratings
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

// Delivery price per km section widget
class _DeliveryPriceSection extends StatefulWidget {
  final String farmerId;
  final bool canEdit;
  const _DeliveryPriceSection({required this.farmerId, required this.canEdit});

  @override
  State<_DeliveryPriceSection> createState() => _DeliveryPriceSectionState();
}

class _DeliveryPriceSectionState extends State<_DeliveryPriceSection> {
  bool _editing = false;
  final _controller = TextEditingController();
  int? _currentValue; // cached value for optimistic UI
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('farmers').doc(widget.farmerId).get();
      if (mounted) {
        final val = (snap.data()?['deliveryPricePerKm'] ?? AppConstants.defaultDeliveryPricePerKm);
        _currentValue = (val is int) ? val : (val is num ? val.toInt() : AppConstants.defaultDeliveryPricePerKm);
        _controller.text = _currentValue.toString();
        setState(() {});
      }
    } catch (_) {
      // silent fail; fallback remains AppConstants.defaultDeliveryPricePerKm
    }
  }

  Future<void> _save() async {
  final raw = _controller.text.trim();
  if (raw.isEmpty) return;
  final parsed = CurrencyUtil.parseToInt(raw);
    if (parsed == null || parsed <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid positive number')));
      return;
    }
    setState(() { _saving = true; });
    try {
      await FirebaseFirestore.instance.collection('farmers').doc(widget.farmerId).update({
        'deliveryPricePerKm': parsed,
        'deliveryPriceUpdatedAt': FieldValue.serverTimestamp(),
      });
      setState(() {
        _currentValue = parsed;
        _editing = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    } finally {
      if (mounted) setState(() { _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final valueDisplay = _currentValue != null ? '${CurrencyUtil.format(_currentValue!).replaceAll('.00', '')} / km' : 'Loading...';
    return Column(
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
              child: const Icon(Icons.local_shipping, color: Color(0xFF556B2F), size: 24),
            ),
            const SizedBox(width: 16),
            Text(
              loc.deliveryPrice,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF556B2F),
              ),
            ),
            const Spacer(),
            if (widget.canEdit && !_editing)
              OutlinedButton.icon(
                onPressed: () => setState(() { _editing = true; _controller.text = (_currentValue ?? 100).toString(); }),
                icon: const Icon(Icons.edit, size: 16),
                label: Text(loc.edit),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF556B2F),
                  side: BorderSide(color: const Color(0xFF8FBC8F).withOpacity(0.6)),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _editing ? _buildEditor(context) : _buildDisplay(valueDisplay),
        ),
      ],
    );
  }

  Widget _buildDisplay(String valueDisplay) {
    return Container(
      key: const ValueKey('display'),
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5DC).withOpacity(0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF8FBC8F).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.payments_outlined, color: Color(0xFF556B2F)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              valueDisplay,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF556B2F),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditor(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Container(
      key: const ValueKey('editor'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5DC).withOpacity(0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF8FBC8F).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: '${loc.deliveryPrice} (LKR / km)',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.currency_rupee),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(loc.save),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: _saving ? null : () => setState(() { _editing = false; }),
                child: Text(loc.cancel),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'This price is visible to customers during delivery cost estimation.',
            style: TextStyle(fontSize: 12, color: const Color(0xFF556B2F).withOpacity(0.7)),
          )
        ],
      ),
    );
  }

}

// Top-level function for showing change location dialog
Future<void> showChangeLocationDialog(BuildContext context, String farmerId) async {
    final TextEditingController locationController = TextEditingController();
    final loc = AppLocalizations.of(context)!;

    // Get current location
    try {
      final doc = await FirebaseFirestore.instance.collection('farmers').doc(farmerId).get();
      final currentLocation = doc.data()?['location'] ?? '';
      locationController.text = currentLocation;
    } catch (e) {
      // Handle error silently or show a message
    }

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Change Location'),
          content: TextField(
            controller: locationController,
            decoration: InputDecoration(
              labelText: loc.location,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.location_on),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(loc.cancel),
            ),
            FilledButton(
              onPressed: () async {
                final newLocation = locationController.text.trim();
                if (newLocation.isEmpty) return;
                
                try {
                  await FirebaseFirestore.instance
                      .collection('farmers')
                      .doc(farmerId)
                      .update({'location': newLocation});
                  
                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Location updated successfully')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${loc.failedToSave}: $e')),
                    );
                  }
                }
              },
              child: Text(loc.save),
            ),
          ],
        );
      },
    );
  }

