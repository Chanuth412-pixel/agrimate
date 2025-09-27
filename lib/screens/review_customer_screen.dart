import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReviewCustomerScreen extends StatefulWidget {
  final Map<String, dynamic> transaction;
  const ReviewCustomerScreen({super.key, required this.transaction});

  @override
  State<ReviewCustomerScreen> createState() => _ReviewCustomerScreenState();
}

class _ReviewCustomerScreenState extends State<ReviewCustomerScreen> {
  double _rating = 4.0;
  final TextEditingController _controller = TextEditingController();
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final tx = widget.transaction;
    final customerName = tx['Customer Name'] ?? tx['customer_name'] ?? 'Customer';
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF1D2939),
        title: const Text('Farmer Feedback'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20,16,20,32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummary(tx, customerName),
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

  Widget _buildSummary(Map<String, dynamic> tx, String customerName) {
    final crop = tx['Crop'] ?? 'Crop';
    final quantity = tx['Quantity Sold (1kg)'];
    final price = tx['Sale Price Per kg'];
    final total = (quantity != null && price != null) ? (quantity * price).toString() : '';
    return Container(
      padding: const EdgeInsets.fromLTRB(20,22,20,22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 18, offset: const Offset(0,6))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(crop, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1D2939))),
                const SizedBox(height: 6),
                Text('Customer: $customerName', style: const TextStyle(fontSize: 13, color: Color(0xFF475467))),
                if (total.isNotEmpty) const SizedBox(height: 4),
                if (total.isNotEmpty) Text('Quantity: ${quantity}kg  |  Unit: LKR $price', style: const TextStyle(fontSize: 12, color: Color(0xFF667085))),
                if (total.isNotEmpty) const SizedBox(height: 4),
                if (total.isNotEmpty) Text('Total: LKR $total', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1D2939))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF56ab2f), Color(0xFFa8e063)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 32),
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
          Text(_rating.toStringAsFixed(1), style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w700, color: Color(0xFF1D2939))),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final active = _rating >= i + 1;
              return IconButton(
                onPressed: () => setState(() => _rating = i + 1.0),
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
        controller: _controller,
        maxLines: 5,
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.all(16),
          hintText: 'Was the communication clear? Any issues receiving payment / confirmation?',
          hintStyle: TextStyle(fontSize: 13, color: Color(0xFF98A2B3)),
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
            onPressed: _submitting ? null : _submit,
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

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final tx = widget.transaction;
      final customerId = tx['Customer ID'];
      final farmerId = tx['Farmer ID'];
      if (customerId != null && farmerId != null) {
        final ref = FirebaseFirestore.instance.collection('CustomerReviews').doc(customerId);
        final doc = await ref.get();
        final entry = {
          'rating': _rating,
            'review': _controller.text.trim(),
            'createdAt': Timestamp.now(),
            'farmerId': farmerId,
            'orderPlacedAt': tx['orderPlacedAt'],
            'crop': tx['Crop'],
            'quantity': tx['Quantity Sold (1kg)'],
        };
        if (doc.exists) {
          await ref.update({'ratings': FieldValue.arrayUnion([entry])});
        } else {
          await ref.set({'ratings': [entry]});
        }
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to submit: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
