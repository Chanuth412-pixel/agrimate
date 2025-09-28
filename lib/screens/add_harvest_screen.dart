import 'package:flutter/material.dart';
import 'dart:ui'; // For BackdropFilter (glassy UI)
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/app_localizations.dart';

double? _calculatedQtyPreview;
  // Helper to calculate quantity from area and crop

  Future<double> _calculateQuantityFromArea(String crop, double areaSqM) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('Crop qty per area').doc(crop.toLowerCase()).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final tonsPerHectare = data['tons_per_hectr'] ?? 0;
        // 1 hectare = 10,000 sq meters, 1 ton = 1000 kg
        double qtyKg = (tonsPerHectare * (areaSqM / 10000)) * 1000;
        return qtyKg;
      }
    } catch (e) {
      print('Error calculating quantity from area: $e');
    }
    return 0;
  }


class AddHarvestScreen extends StatefulWidget {
  const AddHarvestScreen({super.key});

  @override
  State<AddHarvestScreen> createState() => _AddHarvestScreenState();
}

class _AddHarvestScreenState extends State<AddHarvestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _planting = TextEditingController();
  final _harvest = TextEditingController();
  final _area = TextEditingController();
  final _price = TextEditingController();
  final _deliveryRadius = TextEditingController();

  // Internal crop identifiers; UI labels will use localization
  final _crops = ['tomato', 'okra', 'bean'];
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
  String? _lastPreviewedArea;
  String? _lastPreviewedPrice;
  String? _lastPreviewedDeliveryRadius;

  @override
  void initState() {
    super.initState();
    _planting.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _harvest.text = DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 60)));
    _fetchProximity();
  }

  Future<void> _fetchProximity() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _deliveryRadius.text = '2';
      return;
    }
    final doc = await FirebaseFirestore.instance.collection('farmers').doc(user.uid).get();
    if (doc.exists && doc.data() != null && doc.data()!.containsKey('proximity')) {
      _deliveryRadius.text = doc['proximity'].toString();
    } else {
      _deliveryRadius.text = '2';
    }
  }

  void _clearPreviewedValues() {
    setState(() {
      _lastPreviewedCrop = '';
      _lastPreviewedPlanting = '';
      _lastPreviewedHarvest = '';
      _lastPreviewedArea = '';
      _lastPreviewedPrice = '';
      _lastPreviewedDeliveryRadius = '';
      _hasPreviewed = false;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Week number helper (aligned with customer screen logic)
  int _getWeekNumber(DateTime date) {
    final beginningOfYear = DateTime(date.year, 1, 1);
    final daysDifference = date.difference(beginningOfYear).inDays;
    return ((daysDifference + beginningOfYear.weekday) / 7).ceil();
  }

  void _onInputChanged() {
    // Check if any input has changed since last preview
    if (_hasPreviewed) {
      bool hasChanged = _lastPreviewedCrop != _selectedCrop ||
          _lastPreviewedPlanting != _planting.text ||
          _lastPreviewedHarvest != _harvest.text ||
          _lastPreviewedArea != _area.text ||
          _lastPreviewedPrice != _price.text ||
          _lastPreviewedDeliveryRadius != _deliveryRadius.text;
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

  // Removed unused _calculateHarvestDate method

  // Removed unused _pickDate method

  // Function to fetch weather data for the next 5 days
  Future<void> _fetchWeatherData(String city) async {
    const String _fallbackKey = '9fb4df22ed842a6a5b04febf271c4b1c'; // Hardcoded fallback
    final String apiKey = dotenv.env['OPENWEATHER_API_KEY']?.trim().isNotEmpty == true
        ? dotenv.env['OPENWEATHER_API_KEY']!.trim()
        : _fallbackKey;
    
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

  // Enhanced method to generate comprehensive farming precautions
  Future<String> _getComprehensivePrecautions(String crop) async {
    final isWeatherGood = _checkIdealWeather(crop, _temp, _rain, []);
    final currentMonth = DateTime.now().month;
    final season = _getCurrentSeason(currentMonth);
    
    // Base weather analysis
    String weatherAnalysis = _analyzeWeatherConditions(crop, _temp, _rain, isWeatherGood);
    
    // Crop-specific detailed advice
    String cropAdvice = _getCropSpecificAdvice(crop, season, _temp, _rain);
    
    // Market timing insights
    String marketInsights = _getMarketTimingAdvice(crop, currentMonth);
    
    // Storage and handling tips
    String storageAdvice = _getStorageAdvice(crop, _temp, _rain);
    
    return '''$weatherAnalysis

$cropAdvice

$marketInsights

$storageAdvice''';
  }

  String _getCurrentSeason(int month) {
    if (month >= 12 || month <= 2) return 'Winter';
    if (month >= 3 && month <= 5) return 'Spring';
    if (month >= 6 && month <= 8) return 'Summer';
    return 'Autumn';
  }

  String _analyzeWeatherConditions(String crop, double temp, double rain, bool isIdeal) {
    String status = isIdeal ? "✅ FAVORABLE" : "⚠️ CHALLENGING";
    String icon = isIdeal ? "🌤️" : "⛈️";
    
    String tempAnalysis = "";
    if (temp < 15) {
      tempAnalysis = "Temperature is quite low - consider protection measures";
    } else if (temp > 35) {
      tempAnalysis = "High temperature detected - ensure adequate irrigation";
    } else {
      tempAnalysis = "Temperature is within acceptable range";
    }
    
    String rainAnalysis = "";
    if (rain > 15) {
      rainAnalysis = "Heavy rainfall expected - drainage and disease prevention critical";
    } else if (rain < 5) {
      rainAnalysis = "Low rainfall - irrigation planning essential";
    } else {
      rainAnalysis = "Moderate rainfall - good for most crops";
    }
    
    return '''$icon WEATHER ANALYSIS: $status
Current Conditions: ${temp.toStringAsFixed(1)}°C, ${rain.toStringAsFixed(1)}mm
• $tempAnalysis
• $rainAnalysis
• Monitor weather changes closely over next 7 days''';
  }

  String _getCropSpecificAdvice(String crop, String season, double temp, double rain) {
    switch (crop.toLowerCase()) {
      case 'tomato':
        return '''🍅 TOMATO CULTIVATION INSIGHTS:
• Plant 60cm apart for optimal air circulation
• Install support stakes early to prevent lodging
• Apply calcium-rich fertilizer to prevent blossom end rot
• Water consistently - irregular watering causes cracking
• Mulch around plants to retain moisture and prevent weeds
• Watch for early blight in humid conditions
• Harvest when fruit shows first color change for best storage''';
        
      case 'okra':
        return '''🌶️ OKRA CULTIVATION INSIGHTS:
• Thrives in warm weather (${temp > 25 ? 'current conditions ideal' : 'ensure warmth'})
• Space plants 30-45cm apart for good yield
• Harvest pods when 7-10cm long (daily picking increases yield)
• Cut stems at 45° angle to prevent water accumulation
• Apply balanced fertilizer every 3-4 weeks
• ${rain > 10 ? 'Ensure good drainage - okra hates waterlogged soil' : 'Water regularly but avoid overwatering'}
• Prune lower leaves touching ground to prevent disease''';
        
      case 'bean':
        return '''🫘 BEAN CULTIVATION INSIGHTS:
• Fix nitrogen naturally - minimal fertilizer needed initially
• Plant in well-draining soil (beans hate wet feet)
• Support climbing varieties with 2m poles or trellises
• ${temp < 20 ? 'Consider protection from cold - beans are frost-sensitive' : 'Temperature suitable for bean growth'}
• Harvest snap beans when pods snap cleanly
• Pick regularly to encourage continued production
• Avoid handling plants when wet to prevent disease spread
• Companion plant with corn and squash for natural support''';
        
      default:
        return '''🌱 GENERAL CULTIVATION INSIGHTS:
• Test soil pH - most vegetables prefer 6.0-7.0 pH
• Implement crop rotation to prevent soil depletion
• Use organic matter to improve soil structure
• Monitor for common pests weekly
• Apply mulch to conserve moisture and suppress weeds
• Water early morning to reduce disease risk
• Keep garden records for future planning''';
    }
  }

  String _getMarketTimingAdvice(String crop, int month) {
    Map<String, Map<int, String>> marketCalendar = {
      'tomato': {
        1: 'Peak demand season - excellent prices expected',
        2: 'High demand continues - good market window',
        3: 'Demand starts declining - plan for preservation',
        4: 'Low season begins - consider processed products',
        5: 'Off-season - focus on storage varieties',
        6: 'Market recovering - good time for greenhouse production',
        7: 'Demand increasing - plan next harvest cycle',
        8: 'Pre-peak season - prepare for high demand',
        9: 'Demand rising - excellent timing for harvest',
        10: 'Peak season approaching - maximize production',
        11: 'High demand period - optimal pricing',
        12: 'Premium prices due to scarcity'
      },
      'okra': {
        1: 'Off-season - premium prices for protected cultivation',
        2: 'Limited supply - good prices for quality produce',
        3: 'Season starting - plan for steady supply',
        4: 'Peak growing season - ensure consistent harvesting',
        5: 'High supply period - focus on quality differentiation',
        6: 'Market saturation possible - consider alternative varieties',
        7: 'Mid-season - maintain consistent quality',
        8: 'Late season - premium for extended harvest',
        9: 'Transition period - good for stored varieties',
        10: 'Early season prep - plan next cycle',
        11: 'Off-season - limited competition, good prices',
        12: 'Winter season - protected cultivation profitable'
      },
      'bean': {
        1: 'Import season - compete with quality and freshness',
        2: 'Late summer harvest - good storage varieties demand',
        3: 'Autumn planting season - plan for winter harvest',
        4: 'Good market window - steady demand',
        5: 'Peak harvest season - focus on rapid turnover',
        6: 'High supply - differentiate with organic/specialty varieties',
        7: 'Mid-season market - maintain quality standards',
        8: 'Late season - premium for extended harvest',
        9: 'Transition to stored varieties - good prices',
        10: 'Early season demand - plant for Christmas market',
        11: 'Premium season - limited fresh supply',
        12: 'Holiday demand - excellent pricing opportunity'
      }
    };

    String advice = marketCalendar[crop.toLowerCase()]?[month] ?? 
                   'Monitor local market conditions and adjust timing accordingly';
    
    return '''📈 MARKET TIMING INSIGHTS:
Current Month Analysis: $advice
• Research local wholesale prices before harvest
• Consider direct-to-consumer sales for better margins
• Plan harvest timing around local festivals and holidays
• Build relationships with consistent buyers early
• Keep harvest records to optimize future planting dates''';
  }

  String _getStorageAdvice(String crop, double temp, double rain) {
    String climateAdvice = temp > 30 ? 
        "High temperature requires immediate cooling after harvest" :
        temp < 15 ? 
        "Cool conditions good for storage - extend shelf life" :
        "Moderate temperature - standard storage protocols apply";
    
    String humidityAdvice = rain > 10 ?
        "High humidity increases spoilage risk - enhance ventilation" :
        "Low humidity conditions - prevent dehydration during storage";
    
    switch (crop.toLowerCase()) {
      case 'tomato':
        return '''📦 TOMATO STORAGE & HANDLING:
• $climateAdvice
• $humidityAdvice
• Harvest at breaker stage for longer storage (7-14 days)
• Store ripe tomatoes at 12-15°C, unripe at 18-21°C
• Never refrigerate unless fully ripe
• Handle gently - bruised tomatoes spoil quickly
• Use ethylene gas for controlled ripening
• Pack in single layers to prevent crushing''';
        
      case 'okra':
        return '''📦 OKRA STORAGE & HANDLING:
• $climateAdvice
• $humidityAdvice
• Harvest early morning when pods are cool and crisp
• Store at 7-10°C with 90-95% humidity for best quality
• Use perforated plastic bags to maintain humidity
• Shelf life: 7-10 days under optimal conditions
• Avoid washing until just before use
• Handle carefully - okra bruises easily affecting market value''';
        
      case 'bean':
        return '''📦 BEAN STORAGE & HANDLING:
• $climateAdvice
• $humidityAdvice
• For fresh beans: store at 4-7°C with high humidity
• For dried beans: ensure moisture content below 15%
• Use breathable containers for fresh beans
• Blanch and freeze for extended storage (up to 8 months)
• Check regularly for signs of moisture or pest damage
• Sort by size and quality before storage for better pricing''';
        
      default:
        return '''📦 GENERAL STORAGE GUIDELINES:
• $climateAdvice
• $humidityAdvice
• Cool immediately after harvest to extend shelf life
• Maintain consistent temperature and humidity
• Provide adequate ventilation to prevent moisture buildup
• Regular quality checks prevent spread of spoilage
• Use first-in-first-out principle for inventory management''';
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
      _lastPreviewedArea = _area.text;
      _lastPreviewedPrice = _price.text;
      _lastPreviewedDeliveryRadius = _deliveryRadius.text;
    });

    // Calculate quantity from area
    double areaSqM = double.tryParse(_area.text) ?? 0;
    double calculatedQty = await _calculateQuantityFromArea(crop, areaSqM);
    setState(() {
      _calculatedQtyPreview = calculatedQty;
    });

    // Example city for weather fetching
    String city = "Kandy";
    await _fetchWeatherData(city);
    final txt = await _getComprehensivePrecautions(crop);
    final demandSupplyStatus = await _checkDemandSupply(crop, calculatedQty.round());
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
      _area.text != (_lastPreviewedArea ?? '') ||
      _price.text != (_lastPreviewedPrice ?? '') ||
      _deliveryRadius.text != (_lastPreviewedDeliveryRadius ?? '');
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
            content: Text('User not logged in.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Calculate quantity from area
      final crop = _selectedCrop ?? 'Unknown';
      double areaSqM = double.tryParse(_area.text) ?? 0;
      double calculatedQty = await _calculateQuantityFromArea(crop, areaSqM);
      int deliveryRadiusValue = int.tryParse(_deliveryRadius.text) ?? 2;

      // Build new harvest entry (available will be calculated below)
      final Map<String, dynamic> harvestData = {
        'crop': _selectedCrop,
        'plantingDate': _planting.text,
        'harvestDate': _harvest.text,
        'quantity': calculatedQty.round(),
        'area': areaSqM,
        'price': int.parse(_price.text),
        'weather': {
          'temperature': _temp,
          'rainfall': _rain,
        },
        'precautions': _actualPrecautions,
        'farmerId': user.uid,
      };

      // Aggregate 'available' per crop and week: read-modify-write
      final harvestRef = FirebaseFirestore.instance.collection('Harvests').doc(user.uid);
      final harvestSnap = await harvestRef.get();
      final List<dynamic> existing = List<dynamic>.from(harvestSnap.data()?["harvests"] ?? []);

      // Compute week number for the new harvest
      DateTime newHarvestDate;
      try {
        newHarvestDate = DateTime.parse(_harvest.text);
      } catch (_) {
        // If parsing fails, fallback to today to avoid crash
        newHarvestDate = DateTime.now();
      }
      final int newWeek = _getWeekNumber(newHarvestDate);

      // Sum quantities for same crop and same week among existing entries
      int existingWeekSum = 0;
      for (final e in existing) {
        try {
          if (e is! Map) continue;
          if (e['crop'] != _selectedCrop) continue;
          final dynamic rawDate = e['harvestDate'];
          DateTime d;
          if (rawDate is Timestamp) {
            d = rawDate.toDate();
          } else if (rawDate is String) {
            d = DateTime.parse(rawDate);
          } else {
            continue;
          }
          if (_getWeekNumber(d) == newWeek) {
            final int q = (e['quantity'] ?? 0) is int
                ? (e['quantity'] ?? 0) as int
                : ((e['quantity'] ?? 0) as num).round();
            existingWeekSum += q;
          }
        } catch (_) {
          // ignore malformed entries
        }
      }

      final int newQty = calculatedQty.round();
      final int newAvailable = existingWeekSum + newQty;
      harvestData['available'] = newAvailable;

      // Update 'available' for existing entries in the same crop/week group
      final List<dynamic> updated = [];
      for (final e in existing) {
        if (e is! Map) {
          updated.add(e);
          continue;
        }
        try {
          if (e['crop'] == _selectedCrop) {
            final dynamic rawDate = e['harvestDate'];
            DateTime d;
            if (rawDate is Timestamp) {
              d = rawDate.toDate();
            } else if (rawDate is String) {
              d = DateTime.parse(rawDate);
            } else {
              updated.add(e);
              continue;
            }
            if (_getWeekNumber(d) == newWeek) {
              // Clone map to avoid modifying Firestore cached map directly
              final Map<String, dynamic> clone = Map<String, dynamic>.from(e);
              clone['available'] = newAvailable;
              updated.add(clone);
              continue;
            }
          }
          updated.add(e);
        } catch (_) {
          updated.add(e);
        }
      }

      // Append the new entry
      updated.add(harvestData);

      // Write back full array
      await harvestRef.set({'harvests': updated}, SetOptions(merge: true));

      // Update proximity in farmer profile if changed
      await FirebaseFirestore.instance
          .collection('farmers')
          .doc(user.uid)
          .update({'proximity': deliveryRadiusValue});

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
        _area.clear();
        _price.clear();
        _clearPreviewedValues();
      });
      await _fetchProximity();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting harvest data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Removed unused _dateField widget

  // Removed unused _textField widget

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Text(
            AppLocalizations.of(context)?.addNewHarvest ?? 'Add New Harvest',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontSize: 18,
              letterSpacing: .5,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F2027), // deep green/blue
                  Color(0xFF203A43), // teal-ish dark
                  Color(0xFF2C5364), // desaturated blue-green
                ],
              ),
            ),
          ),
          // Subtle overlay pattern using blur & opacity layers
          Positioned.fill(
            child: Opacity(
              opacity: 0.18,
              child: Image(
                image: AssetImage('assets/images/Add_harvest.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Scrollable content
          SingleChildScrollView(
            padding: const EdgeInsets.only(top: 110, bottom: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header glass panel
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _GlassPanel(
                    borderRadius: 30,
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 26),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.eco, size: 48, color: Colors.white.withOpacity(0.95)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppLocalizations.of(context)?.planYourHarvest ?? 'Plan Your Harvest',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: .8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AppLocalizations.of(context)?.harvestInsightsTagline ?? 'Get insights for better yield and profit',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(.85),
                            fontSize: 14,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Form Glass Card
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 10),
                  child: _GlassPanel(
                    borderRadius: 28,
                    padding: const EdgeInsets.all(22),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Crop Selection
                          _glassFieldWrapper(
                            child: DropdownButtonFormField<String>(
                              dropdownColor: const Color(0xFF122026),
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(context)?.selectCrop ?? 'Select Crop',
                                labelStyle: TextStyle(color: Colors.tealAccent.shade100, fontWeight: FontWeight.w600),
                                border: InputBorder.none,
                                prefixIcon: const Icon(Icons.eco, color: Color(0xFF14D6A2)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                              ),
                              value: _selectedCrop,
                              items: _crops.map((crop) {
                                final loc = AppLocalizations.of(context);
                                String label;
                                switch (crop) {
                                  case 'tomato':
                                    label = loc?.cropTomato ?? 'Tomato';
                                    break;
                                  case 'okra':
                                    label = loc?.cropOkra ?? 'Okra';
                                    break;
                                  case 'bean':
                                    label = loc?.cropBeans ?? 'Bean';
                                    break;
                                  default:
                                    label = crop;
                                }
                                return DropdownMenuItem(
                                  value: crop,
                                  child: Text(label),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _selectedCrop = value);
                                _onInputChanged();
                              },
                              validator: (v) => v == null ? (AppLocalizations.of(context)?.selectCrop ?? 'Select crop') : null,
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
                                    Padding(
                                      padding: EdgeInsets.only(left: 5, bottom: 5),
                                      child: Text(
                                        AppLocalizations.of(context)?.plantingDate ?? 'Planting Date',
                                        style: TextStyle(
                                          color: Colors.tealAccent.shade100,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    _glassFieldWrapper(
                                      child: TextFormField(
                                        controller: _planting,
                                        readOnly: true,
                                        decoration: InputDecoration(
                                          hintText: AppLocalizations.of(context)?.plantingDate ?? 'Select date',
                                          border: InputBorder.none,
                                          prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFF14D6A2)),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                                          hintStyle: TextStyle(color: Colors.white.withOpacity(.45)),
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
                                        validator: (v) => v == null || v.isEmpty ? (AppLocalizations.of(context)?.plantingDate ?? 'Enter Planting Date') : null,
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
                                    Padding(
                                      padding: EdgeInsets.only(left: 5, bottom: 5),
                                      child: Text(
                                        AppLocalizations.of(context)?.harvestDate ?? 'Harvest Date',
                                        style: TextStyle(
                                          color: Colors.tealAccent.shade100,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    _glassFieldWrapper(
                                      child: TextFormField(
                                        controller: _harvest,
                                        readOnly: true,
                                        decoration: InputDecoration(
                                          hintText: AppLocalizations.of(context)?.harvestDate ?? 'Select date',
                                          border: InputBorder.none,
                                          prefixIcon: const Icon(Icons.event, color: Color(0xFF14D6A2)),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                                          hintStyle: TextStyle(color: Colors.white.withOpacity(.45)),
                                        ),
                                        onTap: () async {
                                          // Use current field value if parsable; otherwise keep default (today + 60 days)
                                          DateTime initialDate;
                                          try {
                                            initialDate = DateTime.parse(_harvest.text);
                                          } catch (_) {
                                            initialDate = DateTime.now().add(const Duration(days: 60));
                                          }

                                          final picked = await showDatePicker(
                                            context: context,
                                            initialDate: initialDate,
                                            firstDate: DateTime(2023),
                                            lastDate: DateTime(2100),
                                          );
                                          if (picked != null) {
                                            setState(() {
                                              _harvest.text = DateFormat('yyyy-MM-dd').format(picked);
                                              _onInputChanged();
                                            });
                                          }
                                        },
                                        validator: (v) => v == null || v.isEmpty ? (AppLocalizations.of(context)?.harvestDate ?? 'Enter Harvest Date') : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Area and Price fields in a row
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(left: 5, bottom: 5),
                                      child: Text(
                                        AppLocalizations.of(context)?.plantingArea ?? 'Planting Area (sq.m)',
                                        style: TextStyle(
                                          color: Colors.tealAccent.shade100,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    _glassFieldWrapper(
                                      child: TextFormField(
                                        controller: _area,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          hintText: AppLocalizations.of(context)?.enterAreaSqm ?? 'Enter area in sq.m',
                                          border: InputBorder.none,
                                          prefixIcon: const Icon(Icons.square_foot, color: Color(0xFF14D6A2)),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                                          hintStyle: TextStyle(color: Colors.white.withOpacity(.45)),
                                        ),
                                        validator: (v) => v == null || v.isEmpty ? (AppLocalizations.of(context)?.enterAreaSqm ?? 'Enter Area') : null,
                                        onChanged: (value) => _onInputChanged(),
                                      ),
                                    ),
                                    if (_hasPreviewed && _calculatedQtyPreview != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 10),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.scale, color: Color(0xFF14D6A2), size: 20),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Estimated Quantity: ${_calculatedQtyPreview!.toStringAsFixed(0)} kg',
                                              style: const TextStyle(
                                                color: Color(0xFF14D6A2),
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
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
                                    Padding(
                                      padding: EdgeInsets.only(left: 5, bottom: 5),
                                      child: Text(
                                        AppLocalizations.of(context)?.priceLkrPerKg ?? 'Price (LKR/kg)',
                                        style: TextStyle(
                                          color: Colors.tealAccent.shade100,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    _glassFieldWrapper(
                                      child: TextFormField(
                                        controller: _price,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          hintText: AppLocalizations.of(context)?.priceLkrPerKg ?? 'Enter price',
                                          border: InputBorder.none,
                                          prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF14D6A2)),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                                          hintStyle: TextStyle(color: Colors.white.withOpacity(.45)),
                                        ),
                                        validator: (v) => v == null || v.isEmpty ? (AppLocalizations.of(context)?.priceLkrPerKg ?? 'Enter Price') : null,
                                        onChanged: (value) => _onInputChanged(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Delivery Radius field
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: _glassFieldWrapper(
                              child: TextFormField(
                                controller: _deliveryRadius,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: AppLocalizations.of(context)?.deliveryRadiusKm ?? 'Delivery Radius (km)',
                                  hintText: AppLocalizations.of(context)?.deliveryRadiusKm ?? 'Enter delivery radius',
                                  border: InputBorder.none,
                                  prefixIcon: const Icon(Icons.delivery_dining, color: Color(0xFF14D6A2)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                                  hintStyle: TextStyle(color: Colors.white.withOpacity(.45)),
                                ),
                                validator: (val) {
                                  if (val == null || val.isEmpty) return (AppLocalizations.of(context)?.deliveryRadiusKm ?? 'Enter delivery radius');
                                  final num? value = num.tryParse(val);
                                  if (value == null || value < 0) return 'Enter a valid radius';
                                  return null;
                                },
                                onChanged: (value) => _onInputChanged(),
                              ),
                            ),
                          ),

                          // Preview and Submit Buttons
                          Row(
                            children: [
                              Expanded(
                                child: _glassButton(
                                  onTap: _preview,
                                  gradientColors: const [Color(0xFFFFA726), Color(0xFFFF7043)],
                                  icon: Icons.preview,
                                  label: AppLocalizations.of(context)?.preview ?? 'Preview',
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: _glassButton(
                                  onTap: _hasPreviewed ? _submit : null,
                                  gradientColors: _hasPreviewed
                                      ? const [Color(0xFF02C697), Color(0xFF26D7A1)]
                                      : [Colors.grey.shade600, Colors.grey.shade500],
                                  icon: Icons.check_circle,
                                  label: AppLocalizations.of(context)?.submit ?? 'Submit',
                                  disabled: !_hasPreviewed,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Information sections with glass cards
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)?.harvestInsights ?? 'Harvest Insights',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 18),

                      _buildInfoCard(
                        icon: Icons.wb_sunny,
                        title: AppLocalizations.of(context)?.weatherForecast ?? 'Weather Forecast',
                        content: _weatherSummary.isEmpty
                            ? (AppLocalizations.of(context)?.previewWeatherInsights ?? 'Preview to see weather insights')
                            : _weatherSummary,
                        iconColor: const Color(0xFFFFA726),
                      ),
                      const SizedBox(height: 18),
                      _buildInfoCard(
                        icon: Icons.trending_up,
                        title: AppLocalizations.of(context)?.marketAnalysis ?? 'Market Analysis',
                        content: _demandSupplyStatus.isEmpty
                            ? (AppLocalizations.of(context)?.previewMarketAnalysis ?? 'Preview to see market analysis')
                            : _demandSupplyStatus,
                        iconColor: const Color(0xFF2196F3),
                      ),
                      const SizedBox(height: 18),
                      _buildInfoCard(
                        icon: Icons.monetization_on,
                        title: AppLocalizations.of(context)?.priceAnalysis ?? 'Price Analysis',
                        content: _priceStatus.isEmpty
                            ? (AppLocalizations.of(context)?.previewPriceAnalysis ?? 'Preview to see price analysis')
                            : _priceStatus,
                        iconColor: const Color(0xFF4CAF50),
                      ),
                      const SizedBox(height: 18),
                      _buildInfoCard(
                        icon: Icons.health_and_safety,
                        title: AppLocalizations.of(context)?.cropCarePrecautions ?? 'Precautions for Crop Care',
                        content: _precautions.isEmpty
                            ? (AppLocalizations.of(context)?.previewCropCareRecommendations ?? 'Preview to see crop care recommendations')
                            : _precautions,
                        iconColor: const Color(0xFFD32F2F),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String title, required String content, required Color iconColor}) {
    return _GlassPanel(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [iconColor.withOpacity(.85), iconColor.withOpacity(.55)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withOpacity(.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: .4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            constraints: BoxConstraints(
              maxHeight: content.length > 200 ? 300 : double.infinity,
            ),
            child: content.length > 200
                ? Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      child: Text(
                        content,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: Colors.white.withOpacity(.85),
                          height: 1.5,
                          letterSpacing: .2,
                        ),
                      ),
                    ),
                  )
                : Text(
                    content,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(.9),
                      height: 1.42,
                      letterSpacing: .2,
                    ),
                  ),
          ),
          if (content.length > 200)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.white.withOpacity(.55)),
                  const SizedBox(width: 4),
                  Text(
                    'Scroll for more details',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(.6),
                      fontStyle: FontStyle.italic,
                      letterSpacing: .3,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // --- Glass helpers ---
  Widget _GlassPanel({required Widget child, double borderRadius = 20, EdgeInsets? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.white.withOpacity(.25), width: 1),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(.12),
                Colors.white.withOpacity(.07),
                Colors.white.withOpacity(.04),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.45),
                blurRadius: 25,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          padding: padding ?? const EdgeInsets.all(18),
          child: child,
        ),
      ),
    );
  }

  Widget _glassFieldWrapper({required Widget child}) {
    return _GlassPanel(
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Theme(
        data: Theme.of(context).copyWith(
          inputDecorationTheme: const InputDecorationTheme(
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
          ),
          textTheme: Theme.of(context).textTheme.apply(bodyColor: Colors.white),
        ),
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: Colors.white),
          child: child,
        ),
      ),
    );
  }

  Widget _glassButton({
    required VoidCallback? onTap,
    required List<Color> gradientColors,
    required IconData icon,
    required String label,
    bool disabled = false,
  }) {
    return Opacity(
      opacity: disabled ? .55 : 1,
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: _GlassPanel(
          borderRadius: 18,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: gradientColors.reversed.toList(),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(icon, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 10),
              ShaderMask(
                shaderCallback: (rect) => LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(rect),
                blendMode: BlendMode.srcIn,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: .4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}