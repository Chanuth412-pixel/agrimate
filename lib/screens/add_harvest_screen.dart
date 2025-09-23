import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/app_localizations.dart';

class AddHarvestScreen extends StatefulWidget {
  const AddHarvestScreen({super.key});

  @override
  State<AddHarvestScreen> createState() => _AddHarvestScreenState();
}

class _AddHarvestScreenState extends State<AddHarvestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _planting = TextEditingController();
  final _harvest = TextEditingController();
  final _qty = TextEditingController();
  final _price = TextEditingController();

  final _crops = ['Tomato', 'Okra', 'Bean'];
  String? _selectedCrop;
  String _precautions = '';
  String _weatherSummary = '';
  String _demandSupplyStatus = '';
  String _priceStatus = '';
  String _actualPrecautions = '';
  bool _hasPreviewed = false;
  double _temp = 0;
  double _rain = 0;

  // Make last previewed values nullable
  String? _lastPreviewedCrop;
  String? _lastPreviewedPlanting;
  String? _lastPreviewedHarvest;
  String? _lastPreviewedQty;
  String? _lastPreviewedPrice;

  @override
  void initState() {
    super.initState();
    _planting.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _harvest.text = DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 60)));
  }

  void _clearPreviewedValues() {
    setState(() {
      _lastPreviewedCrop = '';
      _lastPreviewedPlanting = '';
      _lastPreviewedHarvest = '';
      _lastPreviewedQty = '';
      _lastPreviewedPrice = '';
      _hasPreviewed = false;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onInputChanged() {
    // Check if any input has changed since last preview
    if (_hasPreviewed) {
      bool hasChanged = _lastPreviewedCrop != _selectedCrop ||
          _lastPreviewedPlanting != _planting.text ||
          _lastPreviewedHarvest != _harvest.text ||
          _lastPreviewedQty != _qty.text ||
          _lastPreviewedPrice != _price.text;
      
      if (hasChanged) {
        setState(() {
          _hasPreviewed = false;
          _precautions = '';
          _demandSupplyStatus = '';
          _priceStatus = '';
          _weatherSummary = '';
          _actualPrecautions = '';
        });
      }
    }
  }

  void _calculateHarvestDate() {
    // Calculate 60 days from today
    DateTime sixtyDaysFromNow = DateTime.now().add(const Duration(days: 60));
    
    // Find the first Sunday after 60 days
    DateTime harvestDate = sixtyDaysFromNow;
    while (harvestDate.weekday != DateTime.sunday) {
      harvestDate = harvestDate.add(const Duration(days: 1));
    }
    
    _harvest.text = DateFormat('yyyy-MM-dd').format(harvestDate);
  }

  Future<void> _pickDate(TextEditingController ctr) async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(ctr.text) ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );
    if (d != null) ctr.text = DateFormat('yyyy-MM-dd').format(d);
  }

  // Function to fetch weather data for the next 5 days
  Future<void> _fetchWeatherData(String city) async {
    const String apiKey = '9fb4df22ed842a6a5b04febf271c4b1c'; // Hardcoded OpenWeather API key
    
    try {
      // Use Colombo's coordinates as default
      final lat = 6.9271;
      final lon = 79.8612;
      
      final response = await http.get(
        Uri.parse('https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&appid=$apiKey&units=metric')
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> forecasts = data['list'];
        
        double totalTemp = 0;
        double totalRain = 0;
        List<String> conditions = [];
        
        // Get unique daily forecasts
        var processedDays = 0;
        var currentDate = '';
        
        for (var forecast in forecasts) {
          var date = DateTime.fromMillisecondsSinceEpoch(forecast['dt'] * 1000);
          var dateStr = '${date.year}-${date.month}-${date.day}';
          
          if (dateStr != currentDate && processedDays < 5) {
            currentDate = dateStr;
            processedDays++;
            
            totalTemp += forecast['main']['temp'];
            totalRain += forecast['rain']?['3h'] ?? 0;
            conditions.add(forecast['weather'][0]['main']);
          }
        }

        _temp = totalTemp / processedDays;
        _rain = totalRain;

        // Check if weather conditions are ideal for the selected crop
        bool isIdealWeather = _checkIdealWeather(
          _selectedCrop ?? '',
          _temp,
          _rain,
          conditions,
        );

        setState(() {
          _weatherSummary = '''
Upcoming weather:
Average Temp: ${_temp.toStringAsFixed(1)}°C
Average Rainfall: ${_rain.toStringAsFixed(1)} mm
Weather is ${isIdealWeather ? 'IDEAL' : 'NOT IDEAL'} for ${_selectedCrop ?? 'selected crop'}
''';
        });
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      setState(() {
        _temp = 0;
        _rain = 0;
        _weatherSummary = 'Error fetching weather data: $e';
      });
    }
  }

  bool _checkIdealWeather(String crop, double temp, double rain, List<String> conditions) {
    // Count non-ideal conditions (rain, thunderstorm, snow)
    int nonIdealDays = conditions.where((condition) {
      final c = condition.toLowerCase();
      return c == 'rain' || c == 'thunderstorm' || c == 'snow';
    }).length;

    // If more than half the days have bad weather, it's not ideal
    if (nonIdealDays > conditions.length / 2) {
      return false;
    }

    // Check temperature and rainfall based on crop type
    switch (crop.toLowerCase()) {
      case 'tomato':
        return temp >= 20 && temp <= 30 && rain < 10; // Tomatoes prefer warm, not too wet
      case 'okra':
        return temp >= 25 && temp <= 35 && rain < 12; // Carrots prefer cooler temperatures
      case 'bean':
        return temp >= 18 && temp <= 25 && rain < 15; // Brinjal prefers warm weather
      default:
        return temp >= 18 && temp <= 30 && rain < 15; // General conditions
    }
  }

  // Check demand and supply from Firestore
  Future<String> _checkDemandSupply(String crop, int quantity) async {
    try {
      final supplyDoc = await FirebaseFirestore.instance
          .collection('this_week')
          .doc('supply')
          .get();
      
      final demandDoc = await FirebaseFirestore.instance
          .collection('this_week')
          .doc('demand')
          .get();

      if (supplyDoc.exists && demandDoc.exists) {
        final supplyData = supplyDoc.data() as Map<String, dynamic>;
        final demandData = demandDoc.data() as Map<String, dynamic>;

        // Debug: Print the actual data structure
        print('Supply Data: $supplyData');
        print('Demand Data: $demandData');
        print('Selected Crop: $crop');

        // Get current supply and demand for the selected crop
        final currentSupply = supplyData[crop] ?? 0;
        final currentDemand = demandData[crop] ?? 0;

        print('Current Supply for $crop: $currentSupply');
        print('Current Demand for $crop: $currentDemand');

        // Calculate new supply after adding this harvest
        final newSupply = currentSupply + quantity;

        if (newSupply >= currentDemand) {
          return '⚠️ CAUTION: Imbalanced quantity (mismatched with supply and demand) — likely to result in high excess.';
        } else {
          return '✅ Well-balanced quantity (based on supply and demand) — ideal for selling with minimal excess';
        }
      } else {
        return '❓ Unable to check demand/supply: Data not available.';
      }
    } catch (e) {
      return '❌ Error checking demand/supply: $e';
    }
  }

  // Check price against Firestore price collection
  Future<String> _checkPrice(String crop, int inputPrice) async {
    try {
      final priceDoc = await FirebaseFirestore.instance
          .collection('price')
          .doc(crop)
          .get();

      if (priceDoc.exists) {
        final priceData = priceDoc.data() as Map<String, dynamic>;
        final suggestedPrice = priceData['suggested_price'] ?? 0;
        final capPrice = priceData['cap_price'] ?? 0;

        print('Price Data for $crop: $priceData');
        print('Input Price: $inputPrice, Suggested Price: $suggestedPrice, Cap Price: $capPrice');

        if (inputPrice > capPrice) {
          return '❌ PRICE TOO HIGH: Your price (LKR $inputPrice) exceeds the cap price (LKR $capPrice) for $crop. Please reduce your price.';
        } else if (inputPrice < suggestedPrice) {
          return '⚠️ LOW PRICE: Your price (LKR $inputPrice) is below suggested price (LKR $suggestedPrice) for $crop. Consider increasing your price.';
        } else {
          return '✅ GOOD PRICE: Your price (LKR $inputPrice) is within acceptable range. Suggested: LKR $suggestedPrice, Cap: LKR $capPrice';
        }
      } else {
        return '❓ Unable to check price: Price data not available for $crop.';
      }
    } catch (e) {
      return '❌ Error checking price: $e';
    }
  }

  // Updated method to call OpenRouter Mixtral API
  Future<String> _askOpenRouterAPI(String crop) async {
    const String apiUrl = 'https://openrouter.ai/api/v1/chat/completions';
    final String apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';

    final body = jsonEncode({
      "model": "mistralai/mixtral-8x7b-instruct",
      "messages": [
        {
          "role": "system",
          "content": '''You are a farming expert who gives very brief, practical advice.
          Keep responses extremely short and simple.
          Use basic, everyday language.
          Focus only on the most important points.
          Each precaution should be maximum 8-10 words.'''
        },
        {
          "role": "user",
          "content": '''Given these conditions for $crop:
          - Temperature: $_temp°C
          - Rainfall: $_rain mm

          1. First, tell me if these conditions are GOOD or BAD in one word.
          2. Then give exactly 3 short, simple precautions.
          
          Format your response exactly like this:
          GOOD/BAD
          • First short precaution
          • Second short precaution
          • Third short precaution'''
        }
      ],
      "max_tokens": 100,
      "temperature": 0.7,
    });

    try {
      final res = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
          'HTTP-Referer': 'https://agrimate.app',
          'X-Title': 'Agrimate Crop Advice',
        },
        body: body,
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['choices'] != null && data['choices'].isNotEmpty) {
          return data['choices'][0]['message']['content'] ??
              'No precautions found.';
        } else {
          return 'Error: No valid response found.';
        }
      } else {
        return 'Error: ${res.statusCode}\n${res.body}';
      }
    } catch (e) {
      return 'Network error: $e';
    }
  }

  Future<void> _preview() async {
    if (!_formKey.currentState!.validate()) return;

    final crop = _selectedCrop ?? 'Unknown';
    setState(() {
      _hasPreviewed = true;
      _lastPreviewedCrop = crop;
      _lastPreviewedPlanting = _planting.text;
      _lastPreviewedHarvest = _harvest.text;
      _lastPreviewedQty = _qty.text;
      _lastPreviewedPrice = _price.text;
    });

    // Example city for weather fetching
    String city = "Kandy";
    await _fetchWeatherData(city);
    final txt = await _askOpenRouterAPI(crop);
    final demandSupplyStatus = await _checkDemandSupply(crop, int.parse(_qty.text));
    final priceStatus = await _checkPrice(crop, int.parse(_price.text));

    setState(() {
      _precautions = txt;
      _actualPrecautions = txt;
      _demandSupplyStatus = demandSupplyStatus;
      _priceStatus = priceStatus;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preview completed! You can now submit your harvest data.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  bool _hasDataChanged() {
    return _selectedCrop != _lastPreviewedCrop ||
           _planting.text != (_lastPreviewedPlanting ?? '') ||
           _harvest.text != (_lastPreviewedHarvest ?? '') ||
           _qty.text != (_lastPreviewedQty ?? '') ||
           _price.text != (_lastPreviewedPrice ?? '');
  }

  Future<void> _submit() async {
    if (!_hasPreviewed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please preview your data first before submitting!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_hasDataChanged()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data has changed since last preview. Please preview again.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to submit harvest data.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final harvestData = {
        'crop': _selectedCrop,
        'plantingDate': _planting.text,
        'harvestDate': _harvest.text,
        'quantity': int.parse(_qty.text),
        'price': int.parse(_price.text),
        'weather': {
          'temperature': _temp,
          'rainfall': _rain,
        },
        'precautions': _actualPrecautions,
        'farmerId': user.uid,
      };

      // Add to Firestore
      await FirebaseFirestore.instance
          .collection('Harvests')
          .doc(user.uid)
          .set({
            'harvests': FieldValue.arrayUnion([harvestData])
          }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harvest data submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Clear form and preview data
      setState(() {
        _selectedCrop = null;
        _planting.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
        _harvest.text = DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 60)));
        _qty.clear();
        _price.clear();
        _clearPreviewedValues();
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting harvest data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _dateField(String label, TextEditingController ctr, {bool isReadOnly = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: TextFormField(
          controller: ctr,
          readOnly: true,
          onTap: isReadOnly ? null : () => _pickDate(ctr),
          validator: (v) => v == null || v.isEmpty ? 'Enter $label' : null,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            suffixIcon: isReadOnly ? null : const Icon(Icons.calendar_today),
          ),
        ),
      );

  Widget _textField(String label, TextEditingController ctr,
      {TextInputType type = TextInputType.text}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: TextFormField(
          controller: ctr,
          keyboardType: type,
          validator: (v) => v == null || v.isEmpty ? 'Enter $label' : null,
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.addNewHarvest,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32), // Darker green for app bar
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE8F5E9), // Very light green
              Color(0xFFC8E6C9), // Light green
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with image
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Background pattern
                    Opacity(
                      opacity: 0.1,
                      child: Container(
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/agriculture_pattern.png'), // You would need to add this asset
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.eco,
                            size: 50,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Plan Your Harvest',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Get insights for better yield and profit',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Form Container
              Padding(
                padding: const EdgeInsets.all(20),
                child: Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Crop Selection
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: 'Select Crop',
                                labelStyle: const TextStyle(
                                  color: Color(0xFF2E7D32),
                                  fontWeight: FontWeight.w500,
                                ),
                                border: InputBorder.none,
                                prefixIcon: const Icon(Icons.eco, color: Color(0xFF2E7D32)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                              ),
                              value: _selectedCrop,
                              items: _crops.map((crop) {
                                return DropdownMenuItem(
                                  value: crop,
                                  child: Text(
                                    crop,
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _selectedCrop = value);
                                _onInputChanged();
                              },
                              validator: (v) => v == null ? 'Select crop' : null,
                              isExpanded: true,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Date fields in a row
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(left: 5, bottom: 5),
                                      child: Text(
                                        'Planting Date',
                                        style: TextStyle(
                                          color: Color(0xFF2E7D32),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.grey[300]!),
                                      ),
                                      child: TextFormField(
                                        controller: _planting,
                                        readOnly: true,
                                        decoration: InputDecoration(
                                          hintText: 'Select date',
                                          border: InputBorder.none,
                                          prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFF2E7D32)),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                                        ),
                                        onTap: () async {
                                          final picked = await showDatePicker(
                                            context: context,
                                            initialDate: DateTime.now(),
                                            firstDate: DateTime(2023),
                                            lastDate: DateTime(2100),
                                          );
                                          if (picked != null) {
                                            setState(() {
                                              _planting.text = DateFormat('yyyy-MM-dd').format(picked);
                                              _onInputChanged();
                                            });
                                          }
                                        },
                                        validator: (v) => v == null || v.isEmpty ? 'Enter Planting Date' : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(left: 5, bottom: 5),
                                      child: Text(
                                        'Harvest Date',
                                        style: TextStyle(
                                          color: Color(0xFF2E7D32),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.grey[300]!),
                                      ),
                                      child: TextFormField(
                                        controller: _harvest,
                                        readOnly: true,
                                        decoration: InputDecoration(
                                          hintText: 'Select date',
                                          border: InputBorder.none,
                                          prefixIcon: const Icon(Icons.event, color: Color(0xFF2E7D32)),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                                        ),
                                        validator: (v) => v == null || v.isEmpty ? 'Enter Harvest Date' : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Quantity and Price fields in a row
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(left: 5, bottom: 5),
                                      child: Text(
                                        'Quantity (kg)',
                                        style: TextStyle(
                                          color: Color(0xFF2E7D32),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.grey[300]!),
                                      ),
                                      child: TextFormField(
                                        controller: _qty,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          hintText: 'Enter quantity',
                                          border: InputBorder.none,
                                          prefixIcon: const Icon(Icons.scale, color: Color(0xFF2E7D32)),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                                        ),
                                        validator: (v) => v == null || v.isEmpty ? 'Enter Quantity' : null,
                                        onChanged: (value) => _onInputChanged(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(left: 5, bottom: 5),
                                      child: Text(
                                        'Price (LKR/kg)',
                                        style: TextStyle(
                                          color: Color(0xFF2E7D32),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.grey[300]!),
                                      ),
                                      child: TextFormField(
                                        controller: _price,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          hintText: 'Enter price',
                                          border: InputBorder.none,
                                          prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF2E7D32)),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                                        ),
                                        validator: (v) => v == null || v.isEmpty ? 'Enter Price' : null,
                                        onChanged: (value) => _onInputChanged(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 25),

                          // Preview and Submit Buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _preview,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF9800),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 3,
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.preview, size: 20, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text('Preview', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _hasPreviewed ? _submit : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _hasPreviewed ? const Color(0xFF2E7D32) : Colors.grey,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 3,
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.check_circle, size: 20, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text('Submit', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Information sections with cards
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Harvest Insights',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 15),
                    
                    // Weather Section
                    _buildInfoCard(
                      icon: Icons.wb_sunny,
                      title: 'Weather Forecast',
                      content: _weatherSummary.isEmpty 
                          ? 'Preview to see weather insights' 
                          : _weatherSummary,
                      iconColor: const Color(0xFFFFA726),
                    ),
                    const SizedBox(height: 15),

                    // Market Analysis Section
                    _buildInfoCard(
                      icon: Icons.trending_up,
                      title: 'Market Analysis',
                      content: _demandSupplyStatus.isEmpty 
                          ? 'Preview to see market analysis' 
                          : _demandSupplyStatus,
                      iconColor: const Color(0xFF2196F3),
                    ),
                    const SizedBox(height: 15),

                    // Price Analysis Section
                    _buildInfoCard(
                      icon: Icons.monetization_on,
                      title: 'Price Analysis',
                      content: _priceStatus.isEmpty 
                          ? 'Preview to see price analysis' 
                          : _priceStatus,
                      iconColor: const Color(0xFF4CAF50),
                    ),
                    const SizedBox(height: 15),

                    // Precautions Section
                    _buildInfoCard(
                      icon: Icons.health_and_safety,
                      title: 'Precautions for Crop Care',
                      content: _precautions.isEmpty 
                          ? 'Preview to see crop care recommendations' 
                          : _precautions,
                      iconColor: const Color(0xFFD32F2F),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String title, required String content, required Color iconColor}) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}