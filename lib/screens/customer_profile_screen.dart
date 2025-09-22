import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'add_crop_customer_c1.dart';
import 'customer_detail_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'scheduled_orders_screen.dart';

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
  Map<String, String> cropDescriptions = {
    'Tomato': 'High demand',
    'Bean': 'Best season',
    'Okra': 'Good price',
  };

  @override
  void initState() {
    super.initState();
    _fetchCropInsights();
  }

  Future<void> _fetchCropInsights() async {
    try {
      final response = await http.post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openAIApiKey',
          'HTTP-Referer': 'https://agrimate.app',
          'X-Title': 'Agrimate Market Insights',
        },
        body: jsonEncode({
          'model': 'mistralai/mixtral-8x7b-instruct',
          'messages': [
            {
              'role': 'system',
              'content': '''You are an agricultural market expert who provides positive and encouraging market insights.
              You must respond with EXACTLY two words for each crop insight.
              Focus on benefits and quality that motivate customers to buy.
              Do not use any special characters, just two simple words.'''
            },
            {
              'role': 'user',
              'content': '''Give a positive TWO-WORD insight for each crop that would motivate customers to buy.
              No special characters, no hyphens, no exclamation marks - just two simple words:

              Tomato: (focus on freshness/quality)
              Bean: (focus on value/availability)
              Okra: (focus on season/price)
              
              Format: Crop: word word (exactly two words, no punctuation)'''
            }
          ],
          'max_tokens': 100,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        
        // Parse the response and update descriptions
        final lines = content.split('\n');
        for (var line in lines) {
          line = line.trim();
          if (line.isEmpty) continue;
          
          // Clean up the text - remove all special characters and extra spaces
          String cleanText(String text) {
            return text
              .replaceAll(RegExp(r'[^\w\s]'), '') // Remove special characters
              .replaceAll(RegExp(r'\s+'), ' ') // Replace multiple spaces with single space
              .trim();
          }
          
          if (line.toLowerCase().contains('tomato')) {
            String insight = cleanText(line.replaceAll(RegExp(r'Tomato:?', caseSensitive: false), ''));
            cropDescriptions['Tomato'] = insight.isNotEmpty ? insight : 'Premium Quality';
          } else if (line.toLowerCase().contains('bean')) {
            String insight = cleanText(line.replaceAll(RegExp(r'Bean:?', caseSensitive: false), ''));
            cropDescriptions['Bean'] = insight.isNotEmpty ? insight : 'Fresh Stock';
          } else if (line.toLowerCase().contains('okra')) {
            String insight = cleanText(line.replaceAll(RegExp(r'Okra:?', caseSensitive: false), ''));
            cropDescriptions['Okra'] = insight.isNotEmpty ? insight : 'Best Price';
          }
        }
        
        if (mounted) {
          setState(() {});
        }
      } else {
        // On error, use simple two-word fallback descriptions
        setState(() {
          cropDescriptions = {
            'Tomato': 'Premium Quality',
            'Bean': 'Fresh Stock',
            'Okra': 'Best Price'
          };
        });
      }
    } catch (e) {
      // On error, use simple two-word fallback descriptions
      setState(() {
        cropDescriptions = {
          'Tomato': 'Premium Quality',
          'Bean': 'Fresh Stock',
          'Okra': 'Best Price'
        };
      });
    }
  }

  Future<String> _fetchCustomRecipe({
    required String crop,
    required String amount,
    required String mealTime,
    String language = 'English',
  }) async {
    print('DEBUG: OPENAI_API_KEY = ${_openAIApiKey.substring(0, 10)}...'); // Debug print with partial key
    final prompt = language == 'Sinhala'
        ? 'ඔබට $amount ක් ඇති $crop සඳහා $mealTime සඳහා සෞඛ්‍ය සම්පන්න හා රසවත් වට්ටෝරුක් ලබා දෙන්න. වට්ටෝරු නම සහ විස්තරාත්මක ක්‍රමය ඇතුළත් කරන්න.'
        : 'Give me a healthy and tasty recipe using $amount of $crop for $mealTime. Include the recipe name and detailed method.';
    
    try {
      final response = await http.post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openAIApiKey',
          'HTTP-Referer': 'https://agrimate.app',
          'X-Title': 'Agrimate Recipe Generator',
        },
        body: jsonEncode({
          'model': 'mistralai/mixtral-8x7b-instruct',
          'messages': [
            {'role': 'system', 'content': 'You are a helpful cooking assistant that provides detailed recipes.'},
            {'role': 'user', 'content': prompt}
          ],
          'max_tokens': 400,
          'temperature': 0.7,
        }),
      );

      print('DEBUG: API Response Status: ${response.statusCode}'); // Debug print
      print('DEBUG: API Response Body: ${response.body}'); // Debug print

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] ?? 'No recipe found.';
      } else {
        print('DEBUG: API Error: ${response.statusCode} - ${response.body}'); // Debug print
        return 'Error: Unable to generate recipe. Please try again later.';
      }
    } catch (e) {
      print('DEBUG: Exception: $e'); // Debug print
      return 'Error: Something went wrong. Please check your internet connection and try again.';
    }
  }

  Future<String> _generateThisWeeksOrder(String customerId, BuildContext context) async {
    print('In _generateThisWeeksOrder for $customerId');
    final today = DateTime.now();
    final weekOfYear = int.parse(DateFormat('w').format(today));
    final scheduled = await FirebaseFirestore.instance
        .collection('ScheduledOrders')
        .where('customerId', isEqualTo: customerId)
        .where('active', isEqualTo: true)
        .get();
    if (scheduled.docs.isEmpty) {
      return 'No scheduled orders found.';
    }
    bool anyCreated = false;
    for (final doc in scheduled.docs) {
      print('Checking scheduled order: ${doc.id}');
      final data = doc.data();
      final startDate = (data['startDate'] as Timestamp).toDate();
      final startWeek = int.parse(DateFormat('w').format(startDate));
      final weeks = data['weeks'] ?? 1;
      final deliveredWeeks = List<int>.from(data['deliveredWeeks'] ?? []);
      final farmerId = data['farmerId'];
      final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
      if (weekOfYear >= startWeek && weekOfYear < startWeek + weeks && !deliveredWeeks.contains(weekOfYear)) {
        // Create the order in Ongoing_Trans_Cus and Ongoing_Trans_Farm
        await _createWeeklyOrder(customerId, farmerId, items);
        // Mark this week as delivered
        await doc.reference.update({
          'deliveredWeeks': FieldValue.arrayUnion([weekOfYear])
        });
        anyCreated = true;
      }
    }
    return anyCreated ? "This week's order generated!" : 'No new order needed for this week.';
  }

  Future<void> _createWeeklyOrder(String customerId, String farmerId, List<Map<String, dynamic>> items) async {
    final now = DateTime.now();
    final orderData = {
      'CropList': items,
      'Status': 'Pending',
      'Farmer ID': farmerId,
      'Customer ID': customerId,
      'Date': now,
    };
    // Add to Ongoing_Trans_Cus
    await FirebaseFirestore.instance.collection('Ongoing_Trans_Cus').doc(customerId).set({
      'transactions': FieldValue.arrayUnion([orderData])
    }, SetOptions(merge: true));
    // Add to Ongoing_Trans_Farm
    await FirebaseFirestore.instance.collection('Ongoing_Trans_Farm').doc(farmerId).set({
      'transactions': FieldValue.arrayUnion([orderData])
    }, SetOptions(merge: true));
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
                      ElevatedButton.icon(
                        icon: const Icon(Icons.schedule),
                        label: const Text('View Scheduled Orders'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF02C697),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          textStyle: const TextStyle(fontSize: 15),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ScheduledOrdersScreen()),
                          );
                        },
                      ),
                      const SizedBox(width: 16),
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
                          imagePath: 'assets/images/tomato.png',
                          color: const Color(0xFFE53935),
                          description: cropDescriptions['Tomato'] ?? 'High demand',
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
                          name: 'Bean',
                          imagePath: 'assets/images/bean.png',
                          color: const Color(0xFF4CAF50),
                          description: cropDescriptions['Bean'] ?? 'Best season',
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AddCropCustomerC1(cropName: 'Bean'),
                              ),
                            );
                            if (result == 'updated') {
                              setState(() {});
                            }
                          },
                        ),
                        const SizedBox(width: 16),
                        CropCard(
                          name: 'Okra',
                          imagePath: 'assets/images/okra.png',
                          color: const Color(0xFF7CB342),
                          description: cropDescriptions['Okra'] ?? 'Good price',
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AddCropCustomerC1(cropName: 'Okra'),
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
                              onPressed: () => Navigator.pop(context, 'Bean'),
                              child: const Text('Bean'),
                            ),
                            SimpleDialogOption(
                              onPressed: () => Navigator.pop(context, 'Okra'),
                              child: const Text('Okra'),
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
                          final deliveryGuyName = tx['delivery_guy_name'];
                          final deliveryGuyPhone = tx['delivery_guy_phone'];
                          final farmerId = tx['Farmer ID'];
                          final date = tx['Date'];
                          final deliveryGuyId = tx['delivery_guy_id'];
                          final reviewed = tx['reviewed'] == true;

                          print('TX: status=${tx['Status']} reviewed=${tx['reviewed']} FarmerID=${tx['Farmer ID']} DriverID=${tx['delivery_guy_id']}');
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
                                  if (deliveryGuyName != null && deliveryGuyName.toString().isNotEmpty) ...[
                                    const Divider(height: 24),
                                    _buildInfoRow(Icons.delivery_dining, 'Delivery Guy', deliveryGuyName),
                                    if (deliveryGuyPhone != null && deliveryGuyPhone.toString().isNotEmpty)
                                      _buildInfoRow(Icons.phone, 'Driver Phone', deliveryGuyPhone),
                                  ],
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
                                  if (status == 'in_transit')
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12.0),
                                      child: ElevatedButton.icon(
                                        icon: const Icon(Icons.check_circle, color: Colors.white, size: 18),
                                        label: const Text('Mark as Delivered'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          textStyle: const TextStyle(fontSize: 15),
                                        ),
                                        onPressed: () async {
                                          await _markAsDelivered(
                                            context: context,
                                            customerId: FirebaseAuth.instance.currentUser?.uid,
                                            farmerId: farmerId,
                                            deliveryGuyId: deliveryGuyId,
                                            date: date,
                                          );
                                        },
                                      ),
                                    ),
                                  if (status == 'delivered' && !reviewed)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12.0),
                                      child: ElevatedButton.icon(
                                        icon: const Icon(Icons.rate_review, color: Colors.white, size: 18),
                                        label: const Text('Leave Review'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          textStyle: const TextStyle(fontSize: 15),
                                        ),
                                        onPressed: () {
                                          print('Leave Review button pressed for tx: ${tx['Farmer ID']}');
                                          _showReviewDialog(context, tx, () {
                                            if (mounted) setState(() {});
                                          });
                                        },
                                      ),
                                    ),
                                  if (status == 'delivered' && reviewed)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 12.0),
                                      child: Text('Delivered', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
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

  Future<void> _markAsDelivered({
    required BuildContext context,
    required String? customerId,
    required String? farmerId,
    required String? deliveryGuyId,
    required dynamic date,
  }) async {
    if (customerId == null || farmerId == null || date == null) return;
    // Update in Ongoing_Trans_Cus
    final cusDocRef = FirebaseFirestore.instance.collection('Ongoing_Trans_Cus').doc(customerId);
    final cusDoc = await cusDocRef.get();
    if (cusDoc.exists) {
      final data = cusDoc.data() as Map<String, dynamic>;
      final txs = List<Map<String, dynamic>>.from(data['transactions'] ?? []);
      final updatedTxs = txs.map((t) {
        if (t['Date'] == date) {
          final updated = Map<String, dynamic>.from(t);
          updated['Status'] = 'delivered';
          return updated;
        }
        return t;
      }).toList();
      await cusDocRef.update({'transactions': updatedTxs});
    }
    // Update in Ongoing_Trans_Farm
    final farmDocRef = FirebaseFirestore.instance.collection('Ongoing_Trans_Farm').doc(farmerId);
    final farmDoc = await farmDocRef.get();
    if (farmDoc.exists) {
      final data = farmDoc.data() as Map<String, dynamic>;
      final txs = List<Map<String, dynamic>>.from(data['transactions'] ?? []);
      final updatedTxs = txs.map((t) {
        if (t['Date'] == date && t['Customer ID'] == customerId) {
          final updated = Map<String, dynamic>.from(t);
          updated['Status'] = 'delivered';
          return updated;
        }
        return t;
      }).toList();
      await farmDocRef.update({'transactions': updatedTxs});
    }
    // Update in Ongoing_Trans_Deliver
    if (deliveryGuyId != null) {
      final deliverDocRef = FirebaseFirestore.instance.collection('Ongoing_Trans_Deliver').doc(deliveryGuyId);
      final deliverDoc = await deliverDocRef.get();
      if (deliverDoc.exists) {
        final data = deliverDoc.data() as Map<String, dynamic>;
        final txs = List<Map<String, dynamic>>.from(data['transactions'] ?? []);
        final updatedTxs = txs.map((t) {
          if (t['Date'] == date && t['Customer ID'] == customerId) {
            final updated = Map<String, dynamic>.from(t);
            updated['Status'] = 'delivered';
            return updated;
          }
          return t;
        }).toList();
        await deliverDocRef.update({'transactions': updatedTxs});
      }
    }
    if (context.mounted) setState(() {});
  }

  Future<void> _showReviewDialog(BuildContext context, Map<String, dynamic> tx, VoidCallback onReviewSubmitted) async {
    print('Opening review dialog for tx: ${tx['Farmer ID']}');

    double farmerRating = 5;
    String farmerReview = '';
    double driverRating = 5;
    String driverReview = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Leave a Review'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Farmer Review'),
                  _buildRatingBar((rating) => setState(() => farmerRating = rating), currentRating: farmerRating),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Farmer Review'),
                    onChanged: (v) => farmerReview = v,
                  ),
                  const SizedBox(height: 16),
                  const Text('Driver Review'),
                  _buildRatingBar((rating) => setState(() => driverRating = rating), currentRating: driverRating),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Driver Review'),
                    onChanged: (v) => driverReview = v,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  print('Submit button pressed in review dialog');
                  await _submitReview(
                    tx: tx,
                    farmerRating: farmerRating,
                    farmerReview: farmerReview,
                    driverRating: driverRating,
                    driverReview: driverReview,
                  );
                  print('Reviews submitted.');
                  Navigator.of(context).pop(); // close dialog
                  onReviewSubmitted(); // <-- reload parent
                },
                child: const Text('Submit'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRatingBar(void Function(double) onRatingUpdate, {required double currentRating}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            Icons.star,
            color: index < currentRating ? Colors.amber : Colors.grey,
          ),
          iconSize: 28,
          onPressed: () => onRatingUpdate(index + 1.0),
        );
      }),
    );
  }

  Future<void> _submitReview({
    required Map<String, dynamic> tx,
    required double farmerRating,
    required String farmerReview,
    required double driverRating,
    required String driverReview,
  }) async {
    print('In _submitReview');
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('No user logged in.');
      return;
    }

    final reviewerId = user.uid;
    final reviewerName = user.displayName ?? user.email ?? 'Customer';

    String? farmerId = tx['Farmer ID'];
    String? driverId = tx['delivery_guy_id'];
    final date = tx['Date'];
    final customerId = reviewerId;
    // If missing, fetch from Ongoing_Trans_Farm
    if (farmerId == null || driverId == null) {
      final ids = await _getFarmAndDriverIdsFromFarmCollection(
        customerId: customerId,
        date: date,
      );
      farmerId ??= ids?['farmerId'];
      driverId ??= ids?['driverId'];
    }
    print('Farmer ID: $farmerId');
    if (farmerId != null) {
      try {
        await FirebaseFirestore.instance.collection('FarmerReviews').doc(farmerId).set({
          'ratings': FieldValue.arrayUnion([
            {
              'rating': farmerRating,
              'review': farmerReview,
              'reviewerId': reviewerId,
              'reviewerName': reviewerName,
              'date': DateTime.now(), // <-- Fix here
            }
          ])
        }, SetOptions(merge: true));
        print('Farmer review written.');
      } catch (e) {
        print('Error writing farmer review: $e');
      }
    }
    print('Driver ID: $driverId');
    if (driverId != null) {
      try {
        await FirebaseFirestore.instance.collection('DriverReviews').doc(driverId).set({
          'ratings': FieldValue.arrayUnion([
            {
              'rating': driverRating,
              'review': driverReview,
              'reviewerId': reviewerId,
              'reviewerName': reviewerName,
              'date': DateTime.now(), // <-- Fix here
            }
          ])
        }, SetOptions(merge: true));
        print('Driver review written.');
      } catch (e) {
        print('Error writing driver review: $e');
      }
    }

    // Mark this transaction as reviewed in Ongoing_Trans_Cus
    final cusDocRef = FirebaseFirestore.instance.collection('Ongoing_Trans_Cus').doc(customerId);
    final cusDoc = await cusDocRef.get();
    if (cusDoc.exists) {
      try {
        final data = cusDoc.data() as Map<String, dynamic>;
        final txs = List<Map<String, dynamic>>.from(data['transactions'] ?? []);
        final updatedTxs = txs.map((t) {
          if (t['Date'] == date) {
            final updated = Map<String, dynamic>.from(t);
            updated['reviewed'] = true;
            return updated;
          }
          return t;
        }).toList();
        await cusDocRef.update({'transactions': updatedTxs});
        print('Marked as reviewed in Ongoing_Trans_Cus.');
      } catch (e) {
        print('Error updating reviewed flag in Ongoing_Trans_Cus: $e');
      }
    }
  }

  Future<Map<String, String>?> _getFarmAndDriverIdsFromFarmCollection({
    required String customerId,
    required dynamic date,
  }) async {
    // Search all docs in Ongoing_Trans_Farm for a transaction with this customerId and date
    final farmDocs = await FirebaseFirestore.instance.collection('Ongoing_Trans_Farm').get();
    for (final doc in farmDocs.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final txs = List<Map<String, dynamic>>.from(data['transactions'] ?? []);
      for (final t in txs) {
        if (t['Date'] == date && t['Customer ID'] == customerId) {
          return {
            'farmerId': t['Farmer ID'],
            'driverId': t['delivery_guy_id'],
          };
        }
      }
    }
    return null;
  }
}

class CropCard extends StatelessWidget {
  final String name;
  final String imagePath;
  final Color color;
  final String description;
  final VoidCallback? onTap;

  const CropCard({
    super.key,
    required this.name,
    required this.imagePath,
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
        height: 160,
        padding: const EdgeInsets.all(12),
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
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}