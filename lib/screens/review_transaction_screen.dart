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
      appBar: AppBar(
        title: const Text('Review Order'),
        backgroundColor: const Color(0xFF02C697),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryCard(tx),
              const SizedBox(height: 24),
              const Text('Rate the Farmer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: List.generate(5, (i) => IconButton(
                  onPressed: () => setState(() => _farmerRating = i + 1.0),
                  icon: Icon(
                    i < _farmerRating ? Icons.star : Icons.star_border,
                    size: 32,
                    color: Colors.amber,
                  ),
                )),
              ),
              const SizedBox(height: 24),
              const Text('Feedback (optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _reviewController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Share your experience about quality, delivery, etc.',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _submitting ? null : () => Navigator.pop(context, false),
                      child: const Text('Skip'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submitReview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF02C697),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _submitting
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Submit Review'),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(crop, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Farmer: $farmerName'),
          const SizedBox(height: 4),
            Text('Quantity: ${quantity}kg  |  Unit: LKR $price'),
          const SizedBox(height: 4),
          Text('Total: LKR $total', style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
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
          await reviewsRef.update({
            'ratings': FieldValue.arrayUnion([entry])
          });
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
