import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'add_crop_customer_c1.dart';
import 'customer_detail_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

const Map<String, List<Map<String, String>>> cropRecipes = {
  'Tomato': [
    {
      'name': 'Tomato Salad',
      'method': 'Slice fresh tomatoes, add olive oil, chopped basil, and feta cheese. Toss and serve chilled.'
    },
    {
      'name': 'Tomato Soup',
      'method': 'Cook tomatoes, garlic, and onion in a pot. Add herbs, simmer, then blend until smooth.'
    },
    {
      'name': 'Stuffed Tomatoes',
      'method': 'Hollow out tomatoes, fill with cooked quinoa, sautéed veggies, and herbs. Bake until tender.'
    }
  ],
  'Brinjal': [
    {
      'name': 'Brinjal Curry',
      'method': 'Cook eggplant with coconut milk, spices, and herbs until soft. Serve with rice.'
    },
    {
      'name': 'Grilled Brinjal',
      'method': 'Slice brinjal, brush with olive oil, grill with garlic until golden.'
    },
    {
      'name': 'Brinjal Stir Fry',
      'method': 'Stir fry eggplant with bell peppers, soy sauce, and ginger until cooked.'
    }
  ],
  'Carrot': [
    {
      'name': 'Carrot Soup',
      'method': 'Cook carrots, ginger, and onion in broth. Blend until smooth and creamy.'
    },
    {
      'name': 'Carrot Salad',
      'method': 'Grate carrots, mix with lemon juice, raisins, and nuts. Serve fresh.'
    },
    {
      'name': 'Carrot Stir Fry',
      'method': 'Stir fry carrots with peas, cumin, and coriander for a quick side dish.'
    }
  ],
};

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  String get _openAIApiKey => dotenv.env['OPENAI_API_KEY'] ?? '';

  Future<String> _fetchCustomRecipe({
    required String crop,
    required String amount,
    required String mealTime,
    String language = 'English',
  }) async {
    final prompt = language == 'Sinhala'
        ? 'ඔබට $amount ක් ඇති $crop සඳහා $mealTime සඳහා සෞඛ්‍ය සම්පන්න හා රසවත් වට්ටෝරුක් ලබා දෙන්න. වට්ටෝරු නම සහ විස්තරාත්මක ක්‍රමය ඇතුළත් කරන්න.'
        : 'Give me a healthy and tasty recipe using $amount of $crop for $mealTime. Include the recipe name and detailed method.';
    // Use the same endpoint/model as add_harvest_screen.dart (OpenRouter call)
    final response = await http.post(
      Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_openAIApiKey',
      },
      body: jsonEncode({
        'model': 'openai/gpt-3.5-turbo',
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
        'max_tokens': 400,
        'temperature': 0.7,
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'] ?? 'No recipe found.';
    } else {
      return 'Error: ${response.statusCode}\n${response.body}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Customer Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF02C697),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            tooltip: 'View Profile',
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              final doc = await FirebaseFirestore.instance
                  .collection('customers')
                  .doc(user?.uid)
                  .get();

              final customerData = doc.data() ?? {
                "Email": user?.email ?? '',
                "uid": user?.uid ?? '',
                "Phone": "Not Provided",
                "Name": "Not Provided",
              };

              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CustomerDetailPage(customerData: customerData),
                  ),
                );
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      backgroundColor: const Color(0xFFF5F5F7),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF02C697),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Explore recommended crops and manage your transactions',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.trending_up, color: Color(0xFF02C697)),
                      const SizedBox(width: 8),
                      Text(
                        'Recommended Crops',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 160,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        CropCard(
                          name: 'Tomato',
                          icon: Icons.local_florist,
                          color: const Color(0xFFE53935),
                          description: 'High demand',
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AddCropCustomerC1(cropName: 'Tomato'),
                              ),
                            );
                            if (result == 'updated') {
                              setState(() {});
                            }
                          },
                        ),
                        const SizedBox(width: 16),
                        CropCard(
                          name: 'Carrot',
                          icon: Icons.grass,
                          color: const Color(0xFFFF9800),
                          description: 'Best season',
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AddCropCustomerC1(cropName: 'Carrot'),
                              ),
                            );
                            if (result == 'updated') {
                              setState(() {});
                            }
                          },
                        ),
                        const SizedBox(width: 16),
                        CropCard(
                          name: 'Brinjal',
                          icon: Icons.emoji_nature,
                          color: const Color(0xFF7E57C2),
                          description: 'Good price',
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AddCropCustomerC1(cropName: 'Brinjal'),
                              ),
                            );
                            if (result == 'updated') {
                              setState(() {});
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      final crop = await showDialog<String>(
                        context: context,
                        builder: (context) => SimpleDialog(
                          title: const Text('Select a Crop'),
                          children: [
                            SimpleDialogOption(
                              onPressed: () => Navigator.pop(context, 'Tomato'),
                              child: const Text('Tomato'),
                            ),
                            SimpleDialogOption(
                              onPressed: () => Navigator.pop(context, 'Brinjal'),
                              child: const Text('Brinjal'),
                            ),
                            SimpleDialogOption(
                              onPressed: () => Navigator.pop(context, 'Carrot'),
                              child: const Text('Carrot'),
                            ),
                          ],
                        ),
                      );
                      if (crop != null) {
                        String? amount;
                        String? mealTime;
                        String language = 'English';
                        await showDialog(
                          context: context,
                          builder: (context) {
                            final amountController = TextEditingController();
                            String? selectedMealTime;
                            String selectedLanguage = 'English';
                            return AlertDialog(
                              title: Text('Customize Recipe for $crop'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(
                                    controller: amountController,
                                    keyboardType: TextInputType.text,
                                    decoration: const InputDecoration(
                                      labelText: 'Amount (e.g. 200g, 2 pieces)',
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  DropdownButtonFormField<String>(
                                    value: selectedMealTime,
                                    hint: const Text('Select Meal Time'),
                                    items: const [
                                      DropdownMenuItem(value: 'Breakfast', child: Text('Breakfast')),
                                      DropdownMenuItem(value: 'Brunch', child: Text('Brunch')),
                                      DropdownMenuItem(value: 'Lunch', child: Text('Lunch')),
                                      DropdownMenuItem(value: 'Dinner', child: Text('Dinner')),
                                      DropdownMenuItem(value: 'Snack', child: Text('Snack')),
                                    ],
                                    onChanged: (v) => selectedMealTime = v,
                                  ),
                                  const SizedBox(height: 12),
                                  DropdownButtonFormField<String>(
                                    value: selectedLanguage,
                                    items: const [
                                      DropdownMenuItem(value: 'English', child: Text('English')),
                                      DropdownMenuItem(value: 'Sinhala', child: Text('සිංහල')),
                                    ],
                                    onChanged: (v) => selectedLanguage = v ?? 'English',
                                    decoration: const InputDecoration(labelText: 'Recipe Language'),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    amount = amountController.text.trim();
                                    mealTime = selectedMealTime;
                                    language = selectedLanguage;
                                    if (amount != null && amount!.isNotEmpty && mealTime != null) {
                                      Navigator.pop(context);
                                    }
                                  },
                                  child: const Text('Get Recipe'),
                                ),
                              ],
                            );
                          },
                        );
                        if (amount != null && amount!.isNotEmpty && mealTime != null) {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(child: CircularProgressIndicator()),
                          );
                          final recipe = await _fetchCustomRecipe(
                            crop: crop,
                            amount: amount!,
                            mealTime: mealTime!,
                            language: language,
                          );
                          Navigator.pop(context); // Remove loading dialog
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('$crop Recipe'),
                              content: SingleChildScrollView(child: Text(recipe)),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Get Recipes'),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      const Icon(Icons.receipt_long, color: Color(0xFF02C697)),
                      const SizedBox(width: 8),
                      Text(
                        'Recent Transactions',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('Ongoing_Trans_Cus')
                        .doc(userId)
                        .get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final data =
                          snapshot.data!.data() as Map<String, dynamic>?;

                      if (data == null || !data.containsKey('transactions')) {
                        return _buildEmptyState();
                      }

                      final transactions =
                          List<Map<String, dynamic>>.from(data['transactions']);

                      if (transactions.isEmpty) {
                        return _buildEmptyState();
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final tx = transactions[index];
                          final crop = tx['Crop'];
                          final quantity = tx['Quantity Sold (1kg)'];
                          final price = tx['Sale Price Per kg'];
                          final status = tx['Status'];
                          final farmerName = tx['Farmer Name'] ?? 'N/A';
                          final phoneNO = tx['Phone_NO'];
                          final deliveredOn = (tx['Date'] as Timestamp).toDate();

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        crop,
                                        style:
                                            theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      _buildStatusChip(status),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _buildInfoRow(Icons.person_outline, 'Farmer',
                                      farmerName),
                                  const SizedBox(height: 8),
                                  _buildInfoRow(
                                      Icons.phone_outlined, 'Contact', phoneNO),
                                  const SizedBox(height: 8),
                                  _buildInfoRow(
                                    Icons.calendar_today_outlined,
                                    'Delivery',
                                    '${deliveredOn.day}/${deliveredOn.month}/${deliveredOn.year}',
                                  ),
                                  const Divider(height: 24),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildDetailBox(
                                        'Quantity',
                                        '${quantity}kg',
                                        const Color(0xFFF3F4F6),
                                      ),
                                      _buildDetailBox(
                                        'Unit Price',
                                        'LKR $price',
                                        const Color(0xFFF3F4F6),
                                      ),
                                      _buildDetailBox(
                                        'Total',
                                        'LKR ${price * quantity}',
                                        const Color(0xFFE8F5F1),
                                        valueColor: const Color(0xFF02C697),
                                      ),
                                    ],
                                  ),
                                ],
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
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No transactions yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your transactions will appear here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailBox(String label, String value, Color bgColor,
      {Color? valueColor}) {
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
                color: valueColor ?? Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CropCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final String description;
  final VoidCallback? onTap;

  const CropCard({
    super.key,
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
