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
  // ─── controllers ─────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _planting = TextEditingController();
  final _harvest  = TextEditingController();
  final _qty      = TextEditingController();
  final _price    = TextEditingController();

  // ─── dropdown list ───────────────────────────────────────────
  final _crops = ['Tomato', 'Carrot', 'Brinjal'];
  String? _selectedCrop;

  // ─── output text ─────────────────────────────────────────────
  String _precautions = '';

  // dummy environment values
  final double _temp = 10;
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

  // ─── GEMINI 1.0 PRO  (stable v1) ─────────────────────────────
  Future<String> _askGemini({
    required String crop,
    required double t,
    required double r,
  }) async {
    const key   = 'AIzaSyAnW6rLBhz6p6VC-Rmq6a08ZpdxjlYOkzg';
    const model = 'models/gemini-1.0-pro';

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1/$model:generateContent?key=$key');

    final prompt = '''
You are an expert agricultural assistant. The farmer grows $crop.
Current temperature = $t °C, rainfall = $r mm.
Ideal for $crop: 15–25 °C and 80–120 mm rainfall.
List three concise precautions in bullet points.
''';

    // Console debug
    print('🔸 POST $uri');
    try {
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ]
        }),
      );

      print('🔸 Status ${res.statusCode}');
      print('🔸 Body   ${res.body.length > 400 ? res.body.substring(0, 400) + "…" : res.body}');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['candidates'][0]['content']['parts'][0]['text'] ?? '';
      }
      if (res.statusCode == 429 || res.statusCode == 403) {
        return 'Gemini quota exceeded or key disabled.';
      }
      return 'Gemini error ${res.statusCode}:\n${res.body}';
    } catch (e) {
      return 'Network error: $e';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final crop = _selectedCrop ?? 'Unknown';
    setState(() => _precautions = 'Loading Gemini precautions …');

    final txt = await _askGemini(crop: crop, t: _temp, r: _rain);

    setState(() =>
        _precautions = '**⚠️ This is not ideal for $crop.**\n\n$txt');
  }

  // ─── field helpers ───────────────────────────────────────────
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

  // ─── build UI ───────────────────────────────────────────────
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
