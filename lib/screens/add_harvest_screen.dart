import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


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

  final _crops = ['tomato', 'carrot', 'brinjal'];
  final _cropDisplayNames = ['Tomato', 'Carrot', 'Brinjal'];
  // Note: Make sure these exact names match the field names in your Firestore documents
  String? _selectedCrop;
  
  // Store the last previewed values to detect changes
  String? _lastPreviewedCrop;
  String? _lastPreviewedPlanting;
  String? _lastPreviewedHarvest;
  String? _lastPreviewedQty;
  String? _lastPreviewedPrice;
  String _precautions = '';
  String _weatherSummary = '';
  String _demandSupplyStatus = '';
  String _priceStatus = '';
  String _actualPrecautions = ''; // Store the actual precautions separately
  bool _hasPreviewed = false;

  double _temp = 0; // To hold the fetched temperature
  double _rain = 0; // To hold the fetched rainfall data

  @override
  void initState() {
    super.initState();
    _planting.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _calculateHarvestDate();
    
    // Add listeners to detect input changes
    _planting.addListener(_onInputChanged);
    _harvest.addListener(_onInputChanged);
    _qty.addListener(_onInputChanged);
    _price.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _planting.removeListener(_onInputChanged);
    _harvest.removeListener(_onInputChanged);
    _qty.removeListener(_onInputChanged);
    _price.removeListener(_onInputChanged);
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
    const String apiKey = '9fb4df22ed842a6a5b04febf271c4b1c'; // OpenWeather API Key
    const String baseUrl = 'https://api.openweathermap.org/data/2.5/forecast';

    try {
      final response = await http.get(Uri.parse(
          '$baseUrl?q=$city&units=metric&cnt=5&appid=$apiKey')); // Fetch 5-day forecast

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> forecasts = data['list'];

        double totalTemp = 0;
        double totalRain = 0;

        // Calculate the average temperature and total rainfall for the next 5 days
        for (var forecast in forecasts) {
          totalTemp += forecast['main']['temp'];
          totalRain += forecast['rain']?['3h'] ?? 0; // Rain in the last 3 hours, if available
        }

        _temp = totalTemp / forecasts.length; // Average temperature
        _rain = totalRain / forecasts.length; // Average rainfall

        setState(() {
          _weatherSummary =
              'Upcoming weather:\nAverage Temp: $_temp°C\nAverage Rainfall: $_rain mm';
        });
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      setState(() {
        _temp = 0;
        _rain = 0;
        _weatherSummary = 'Error fetching weather data';
      });
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
          "role": "user",
          "content":
              "Given the following weather data, tell me in the first line whether the conditions are in the ideal range for farming $crop. Then list 3 important precautions to take, each with a short explanation. Make the advice specific to the crop and the given weather conditions (temperature: $_temp°C, rainfall: $_rain mm). Use clear, simple language. Return nothing else apart from the three precautions and the first-line assessment"
        }
      ]
    });

    try {
      final res = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey', // Ensure this is correct
          'HTTP-Referer': 'https://your-app-name.com',
          'X-Title': 'Crop Precaution App',
        },
        body: body,
      );

      // Log the response body for debugging
      print('Response Body: ${res.body}'); // Debug log to inspect the actual response

      if (res.statusCode == 200) {
        // Try to parse the response body
        final data = jsonDecode(res.body);

        // Check if the 'choices' field exists and extract content
        if (data['choices'] != null && data['choices'].isNotEmpty) {
          return data['choices'][0]['message']['content'] ??
              'No precautions found.';
        } else {
          // If the 'choices' field is missing or empty, return an appropriate message
          return 'Error: No valid response found in the "choices" field.';
        }
      } else {
        // If the response is not successful, log the error
        return 'Error: ${res.statusCode}\n${res.body}';
      }
    } catch (e) {
      // Handle network or other errors gracefully
      return 'Network error: $e';
    }
  }

  Future<void> _preview() async {
    if (!_formKey.currentState!.validate()) return;

    final crop = _selectedCrop ?? 'Unknown';
    final quantity = int.parse(_qty.text);
    final price = int.parse(_price.text);
    
    setState(() {
      _precautions = 'Loading data...';
      _demandSupplyStatus = 'Checking demand/supply...';
      _priceStatus = 'Checking price...';
    });

    // Fetch weather + precautions + demand/supply + price
    String city = "Kandy";
    await _fetchWeatherData(city);
    final txt = await _askOpenRouterAPI(crop);
    final demandSupplyStatus = await _checkDemandSupply(crop, quantity);
    final priceStatus = await _checkPrice(crop, price);

    setState(() {
      _precautions = 'Precautions for $crop\n\n$txt';
      _actualPrecautions = txt; // Store the actual precautions without the header
      _demandSupplyStatus = demandSupplyStatus;
      _priceStatus = priceStatus;
      _hasPreviewed = true;
      
      // Store the current values for change detection
      _lastPreviewedCrop = crop;
      _lastPreviewedPlanting = _planting.text;
      _lastPreviewedHarvest = _harvest.text;
      _lastPreviewedQty = _qty.text;
      _lastPreviewedPrice = _price.text;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preview completed! You can now submit your harvest data.'),
        backgroundColor: Colors.green,
      ),
    );
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

    // Check if price is acceptable before submitting
    final crop = _selectedCrop ?? 'Unknown';
    final price = int.parse(_price.text);
    final priceStatus = await _checkPrice(crop, price);
    
    if (priceStatus.contains('❌ PRICE TOO HIGH')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot submit: Price exceeds cap price!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final quantity = int.parse(_qty.text);
    
    setState(() => _precautions = 'Saving data...');

    // Build harvest data object
    final harvestEntry = {
      'crop': crop,
      'plantingDate': _planting.text,
      'harvestDate': _harvest.text,
      'quantity': quantity,
      'available': quantity,
      'expectedPrice': price,
      'precautions': _actualPrecautions, // Use the stored actual precautions
    };

    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance
          .collection('Harvests')
          .doc(userId)
          .set({
            'harvests': FieldValue.arrayUnion([harvestEntry]),
          }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harvest data submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Reset the form after successful submission
      setState(() {
        _hasPreviewed = false;
        _precautions = '';
        _demandSupplyStatus = '';
        _priceStatus = '';
        _weatherSummary = '';
        _actualPrecautions = '';
        _planting.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
        _calculateHarvestDate();
        _qty.clear();
        _price.clear();
        _selectedCrop = null;
        
        // Reset the last previewed values
        _lastPreviewedCrop = null;
        _lastPreviewedPlanting = null;
        _lastPreviewedHarvest = null;
        _lastPreviewedQty = null;
        _lastPreviewedPrice = null;
      });
    } catch (e) {
      print('Error saving data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error saving harvest data'),
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
      appBar: AppBar(title: const Text('Add New Harvest'), backgroundColor: const Color(0xFF02C697)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Form(
            key: _formKey,
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Select Crop', border: OutlineInputBorder()),
                  value: _selectedCrop,
                  items: _crops.asMap().entries.map((entry) {
                    int index = entry.key;
                    String cropValue = entry.value;
                    String displayName = _cropDisplayNames[index];
                    return DropdownMenuItem(
                      value: cropValue,
                      child: Text(displayName),
                    );
                  }).toList(),
                  onChanged: (v) {
                    setState(() => _selectedCrop = v);
                    _onInputChanged(); // Trigger change detection
                  },
                  validator: (v) => v == null ? 'Select crop' : null,
                ),
              ),
              _dateField('Planting Date', _planting),
              _dateField('Harvest Date',  _harvest, isReadOnly: true),
              _textField('Quantity (kg)',         _qty,   type: TextInputType.number),
              _textField('Expected Price (LKR/kg)', _price, type: TextInputType.number),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _preview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Preview'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _hasPreviewed ? _submit : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _hasPreviewed ? const Color(0xFF02C697) : Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Submit'),
                    ),
                  ),
                ],
              ),
            ])),
          const SizedBox(height: 28),
          const Divider(),
          const SizedBox(height: 10),
          const Text('Upcoming Weather', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(_weatherSummary, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 20),
          const Text('Market Analysis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _demandSupplyStatus.isEmpty
              ? const Text(
                  'Click Preview to check market conditions.',
                  style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                )
              : Text(_demandSupplyStatus, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 20),
          const Text('Price Analysis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _priceStatus.isEmpty
              ? const Text(
                  'Click Preview to check price recommendations.',
                  style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                )
              : Text(_priceStatus, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 20),
          const Text('Precautions for Crop Care', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _precautions.isEmpty
              ? const Text(
                  '• Ensure proper irrigation.\n'
                  '• Use organic fertilizers.\n'
                  '• Regularly inspect for pests.\n'
                  '• Follow seasonal planting guidelines.',
                  style: TextStyle(fontSize: 14),
                )
              : Text(_precautions, style: const TextStyle(fontSize: 14)),
        ])),
    );
  }
}