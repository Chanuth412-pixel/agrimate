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
      appBar: AppBar(
        title: const Text('Review Customer'),
        backgroundColor: const Color(0xFF02C697),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummary(tx, customerName),
              const SizedBox(height: 24),
              const Text('Rate the Customer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: List.generate(5, (i) => IconButton(
                  onPressed: () => setState(() => _rating = i + 1.0),
                  icon: Icon(i < _rating ? Icons.star : Icons.star_border, size: 32, color: Colors.amber),
                )),
              ),
              const SizedBox(height: 24),
              const Text('Feedback (optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Was the communication clear? Any issues receiving payment / confirmation?',
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
                      onPressed: _submitting ? null : _submit,
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
              )
            ],
          ),
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
          Text('Customer: $customerName'),
          const SizedBox(height: 4),
          if (total.isNotEmpty) Text('Quantity: ${quantity}kg  |  Unit: LKR $price'),
          if (total.isNotEmpty) const SizedBox(height: 4),
          if (total.isNotEmpty) Text('Total: LKR $total', style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
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
