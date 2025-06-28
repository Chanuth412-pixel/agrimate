import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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

  final _crops = ['Tomato', 'Carrot', 'Brinjal'];
  String? _selectedCrop;
  String _precautions = '';
  String _weatherSummary = '';

  double _temp = 0; // To hold the fetched temperature
  double _rain = 0; // To hold the fetched rainfall data

  @override
  void initState() {
    super.initState();
    _planting.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
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

  // Updated method to call OpenRouter Mixtral API
  Future<String> _askOpenRouterAPI(String crop) async {
    const String apiUrl = 'https://openrouter.ai/api/v1/chat/completions';
    const String apiKey =
        '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'; // Your OpenRouter API key

    final body = jsonEncode({
      "model": "mistralai/mixtral-8x7b-instruct",
      "messages": [
        {
          "role": "user",
          "content":
              "Give me 3 important precautions to take when growing $crop. Make it customized to the crop in conditions with temperature $_temp°C and rainfall $_rain mm. Make the advice specific to these weather conditions. Nothing else and give nothing more than the 3 precautions"
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final crop = _selectedCrop ?? 'Unknown';
    setState(() => _precautions = 'Loading data …');

    // Example city for weather fetching, you can replace it with user input
    String city = "Kandy"; // Replace this with the actual city for weather data
    await _fetchWeatherData(city); // Fetch the weather data (temp and rain)

    // Fetch crop precautions based on weather
    final txt = await _askOpenRouterAPI(crop);

    setState(() => _precautions = '**Precautions for $crop**\n\n$txt');
  }

  Widget _dateField(String label, TextEditingController ctr) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: TextFormField(
          controller: ctr,
          readOnly: true,
          onTap: () => _pickDate(ctr),
          validator: (v) => v == null || v.isEmpty ? 'Enter $label' : null,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            suffixIcon: const Icon(Icons.calendar_today),
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
              _dateField('Planting Date', _planting),
              _dateField('Harvest Date',  _harvest),
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Select Crop', border: OutlineInputBorder()),
                  value: _selectedCrop,
                  items: _crops.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => _selectedCrop = v),
                  validator: (v) => v == null ? 'Select crop' : null,
                ),
              ),
              _textField('Quantity (kg)',         _qty,   type: TextInputType.number),
              _textField('Expected Price (₹/kg)', _price, type: TextInputType.number),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF02C697),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Submit Harvest Details'),
                ),
              ),
            ])),
          const SizedBox(height: 28),
          const Divider(),
          const SizedBox(height: 10),
          const Text('Upcoming Weather', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(_weatherSummary, style: const TextStyle(fontSize: 14)),
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
