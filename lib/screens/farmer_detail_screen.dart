import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FarmerDetailScreen extends StatelessWidget {
  final Map<String, dynamic> farmerData;

  // Constructor to receive farmer data from the previous screen
  const FarmerDetailScreen({super.key, required this.farmerData});

  @override
  Widget build(BuildContext context) {
    // Fetching farmer data from the passed map
    // String name = farmerData['name'] ?? 'N/A';
    // String location = farmerData['location'] ?? 'N/A';
    // String phone = farmerData['phone'] ?? 'N/A';
    String name = farmerData['name'] ?? 'Not Provided';
    String location = farmerData['location'] ?? 'Not Provided';
    String phone = farmerData['phone'] ?? 'Not Provided';
    String email = farmerData['email'] ?? 'Not Provided';
    String farmerId = farmerData['uid'] ?? farmerData['id'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmer Details'),
        backgroundColor: const Color(0xFF02C697),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profile Information',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text('Name: $name', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text('Location: $location', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text('Phone: $phone', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text('Email: $email', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            // Rating and Reviews Section
            const Text(
              'Rating & Reviews',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: _fetchFarmerReviews(farmerId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Text('Error loading reviews');
                  }
                  final data = snapshot.data;
                  if (data == null || (data['reviews'] as List).isEmpty) {
                    return const Text('No reviews yet.');
                  }
                  final avg = data['average'] as double?;
                  final reviews = data['reviews'] as List<dynamic>;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (avg != null)
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(avg.toStringAsFixed(1), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(' (${reviews.length} reviews)', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                          ],
                        ),
                      const SizedBox(height: 10),
                      const Text('All Reviews:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.separated(
                          itemCount: reviews.length,
                          separatorBuilder: (context, idx) => const Divider(),
                          itemBuilder: (context, idx) {
                            final review = reviews[idx];
                            return ListTile(
                              leading: Icon(Icons.account_circle, size: 36, color: Colors.grey[600]),
                              title: Text(review['reviewerName'] ?? 'Anonymous', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.star, color: Colors.amber, size: 18),
                                      const SizedBox(width: 2),
                                      Text((review['rating'] ?? 0).toString(), style: const TextStyle(fontSize: 15)),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(review['review'] ?? '', style: const TextStyle(fontSize: 15)),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchFarmerReviews(String farmerId) async {
    // Fetch reviews from the FarmerReviews collection
    final doc = await FirebaseFirestore.instance.collection('FarmerReviews').doc(farmerId).get();
    if (!doc.exists || doc.data() == null || !(doc.data()!.containsKey('ratings'))) {
      return {'average': null, 'reviews': []};
    }
    final List<dynamic> ratings = doc['ratings'] ?? [];
    if (ratings.isEmpty) {
      return {'average': null, 'reviews': []};
    }
    double avg = ratings.map((r) => (r['rating'] ?? 0).toDouble()).fold(0.0, (a, b) => a + b) / ratings.length;
    return {
      'average': avg,
      'reviews': ratings,
    };
  }
}
