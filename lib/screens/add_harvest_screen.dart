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

  final double _temp = 10;   // Dummy environmental data
  final double _rain = 60;

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

  // ✅ Updated method to call OpenRouter Mixtral API
  Future<String> _askOpenRouterAPI(String crop) async {
    const String apiUrl = 'https://openrouter.ai/api/v1/chat/completions';
    const String apiKey = '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';

    final body = jsonEncode({
      "model": "mistralai/mixtral-8x7b-instruct",
      "messages": [
        {
          "role": "user",
          "content": "Give me 3 important precautions to take when growing $crop. Make it customized to the crop in conditions with temperature $_temp°C and rainfall $_rain mm. Make the advice specific to these weather conditions.Nothing else"
        }
      ]
    });

    try {
      final res = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
          'HTTP-Referer': 'https://your-app-name.com',
          'X-Title': 'Crop Precaution App',
        },
        body: body,
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['choices'][0]['message']['content'] ?? 'No precautions found.';
      } else {
        return 'Error: ${res.statusCode}\n${res.body}';
      }
    } catch (e) {
      return 'Network error: $e';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final crop = _selectedCrop ?? 'Unknown';
    setState(() => _precautions = 'Loading data …');

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
            ]),
          ),
          const SizedBox(height: 28),
          const Divider(),
          const SizedBox(height: 10),
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
        ]),
      ),
    );
  }
}
