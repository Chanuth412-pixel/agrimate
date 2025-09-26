import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReviewTransactionScreen extends StatefulWidget {
  final Map<String, dynamic> transaction;
  const ReviewTransactionScreen({super.key, required this.transaction});

  @override
  State<ReviewTransactionScreen> createState() => _ReviewTransactionScreenState();
}

class _ReviewTransactionScreenState extends State<ReviewTransactionScreen> {
  double _farmerRating = 4.0;
  final TextEditingController _reviewController = TextEditingController();
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final tx = widget.transaction;
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF1D2939),
        title: const Text('Customer Feedback'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20,16,20,32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(tx),
            const SizedBox(height: 24),
            _buildRatingCard(),
            const SizedBox(height: 24),
            const Text('Feedback (optional)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF344054))),
            const SizedBox(height: 8),
            _buildFeedbackBox(),
            const SizedBox(height: 32),
            _buildActionRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> tx) {
    final crop = tx['Crop'];
    final quantity = tx['Quantity Sold (1kg)'];
    final price = tx['Sale Price Per kg'];
    final total = (quantity * price).toString();
    final farmerName = tx['Farmer Name'] ?? 'Farmer';
    return Container(
      padding: const EdgeInsets.fromLTRB(20,22,20,22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 18, offset: const Offset(0,6))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(crop, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1D2939))),
                const SizedBox(height: 6),
                Text('Farmer: $farmerName', style: const TextStyle(fontSize: 13, color: Color(0xFF475467))),
                const SizedBox(height: 4),
                Text('Quantity: ${quantity}kg  |  Unit: LKR $price', style: const TextStyle(fontSize: 12, color: Color(0xFF667085))),
                const SizedBox(height: 4),
                Text('Total: LKR $total', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1D2939))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF56ab2f), Color(0xFFa8e063)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.eco_rounded, color: Colors.white, size: 32),
          )
        ],
      ),
    );
  }

  Widget _buildRatingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20,26,20,26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 18, offset: const Offset(0,6))],
      ),
      child: Column(
        children: [
          const Text('Overall Rating', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1D2939))),
          const SizedBox(height: 8),
          Text(_farmerRating.toStringAsFixed(1), style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w700, color: Color(0xFF1D2939))),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final active = _farmerRating >= i + 1;
              return IconButton(
                onPressed: () => setState(() => _farmerRating = i + 1.0),
                icon: Icon(active ? Icons.star_rounded : Icons.star_border_rounded, color: const Color(0xFFFFB547), size: 34),
                padding: EdgeInsets.zero,
                splashRadius: 22,
              );
            }),
          ),
          const SizedBox(height: 4),
          const Text('Tap a star to set your rating', style: TextStyle(fontSize: 12, color: Color(0xFF667085))),
        ],
      ),
    );
  }

  Widget _buildFeedbackBox() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 12, offset: const Offset(0,4))],
      ),
      child: TextField(
        controller: _reviewController,
        maxLines: 5,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.all(16),
          hintText: 'Share your experience about quality, delivery, etc.',
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF98A2B3)),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildActionRow() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _submitting ? null : () => Navigator.pop(context, false),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Skip', style: TextStyle(color: Color(0xFF475467), fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _submitting ? null : _submitReview,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF02C697),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 2,
            ),
            child: _submitting
                ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Submit Review', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Future<void> _submitReview() async {
    setState(() => _submitting = true);
    try {
      final tx = widget.transaction;
      final farmerId = tx['Farmer ID'];
      if (farmerId != null) {
        final reviewsRef = FirebaseFirestore.instance.collection('FarmerReviews').doc(farmerId);
        final doc = await reviewsRef.get();
        final entry = {
          'rating': _farmerRating,
          'review': _reviewController.text.trim(),
          'createdAt': Timestamp.now(),
          'customerId': FirebaseAuth.instance.currentUser?.uid,
          'orderPlacedAt': tx['orderPlacedAt'],
          'crop': tx['Crop'],
          'quantity': tx['Quantity Sold (1kg)'],
        };
        if (doc.exists) {
          // Manually merge & sort so newest appears first
            final data = doc.data();
            final List<dynamic> existing = (data?['ratings'] as List<dynamic>? ?? []).toList();
            existing.add(entry);
            // Sort descending by createdAt (fallback keep order)
            existing.sort((a,b){
              final aTs = a is Map && a['createdAt'] is Timestamp ? a['createdAt'] as Timestamp : null;
              final bTs = b is Map && b['createdAt'] is Timestamp ? b['createdAt'] as Timestamp : null;
              if (aTs!=null && bTs!=null) return bTs.compareTo(aTs); // newest first
              return 0;
            });
            await reviewsRef.set({'ratings': existing});
        } else {
          await reviewsRef.set({'ratings': [entry]});
        }
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit review: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
