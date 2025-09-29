import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/app_localizations.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

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

class _AddHarvestScreenState extends State<AddHarvestScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _insightsKey = GlobalKey();
  final GlobalKey _estimatedQtyKey = GlobalKey();
  final _planting = TextEditingController();
  final _harvest = TextEditingController();
  final _area = TextEditingController();
  final _price = TextEditingController();
  final _deliveryRadius = TextEditingController();

  final _crops = ['Tomato', 'Okra', 'Bean'];
  String? _selectedCrop;
  String _precautions = '';
  String _weatherSummary = '';
  String _demandSupplyStatus = '';
  String _actualPrecautions = '';
  bool _hasPreviewed = false;
  double _temp = 0;
  double _rain = 0;

  // UI state helpers
  bool _showCropSelectError = false; // show validation message when user tries preview without crop

  // Removed celebration animations (confetti / pulse) for simpler UX
  late final AnimationController _headerPulseController; // kept only if still used for subtle header pulse

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
    _headerPulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
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
  _headerPulseController.dispose();
    _scrollController.dispose();
    super.dispose();
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
    if (_selectedCrop == null) {
      setState(() => _showCropSelectError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a crop first.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
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

    setState(() {
      _precautions = txt;
      _actualPrecautions = txt;
      _demandSupplyStatus = demandSupplyStatus;
    });

    // Delay a frame then scroll to insights smoothly
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_insightsKey.currentContext != null) {
        final box = _insightsKey.currentContext!.findRenderObject() as RenderBox;
        final offset = box.localToGlobal(Offset.zero, ancestor: context.findRenderObject());
        final dy = offset.dy + _scrollController.offset - 100; // slight offset above header
        _scrollController.animateTo(
          dy.clamp(0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeInOutCubic,
        );
      }
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
    if (_selectedCrop == null) {
      setState(() => _showCropSelectError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a crop before submitting.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
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

      final harvestData = {
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
        // No deliveryRadius field here
      };

      // Add to Firestore
      await FirebaseFirestore.instance
          .collection('Harvests')
          .doc(user.uid)
          .set({
            'harvests': FieldValue.arrayUnion([harvestData])
          }, SetOptions(merge: true));

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

  // Removed confetti celebration

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

  // Removed _triggerConfetti()

  String _formatNumber(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  LinearGradient _timeOfDayGradient() {
    final hour = DateTime.now().hour;
    if (hour < 11) {
      // Morning warm fresh
      return const LinearGradient(
        colors: [Color(0xFFB2F7EF), Color(0xFF02C697)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (hour < 17) {
      // Midday vibrant greens
      return const LinearGradient(
        colors: [Color(0xFF02C697), Color(0xFF0E9F6E)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else {
      // Evening calm
      return const LinearGradient(
        colors: [Color(0xFF173F5F), Color(0xFF02C697)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
  }

  Widget _buildDynamicHeader() {
    final pulse = _headerPulseController.value;
    final gradient = _timeOfDayGradient();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.last.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Row(
          children: [
            // Pulsing eco icon badge
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 54 + pulse * 6,
                  height: 54 + pulse * 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.14 + pulse * 0.08),
                  ),
                ),
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.18),
                    border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.2),
                  ),
                  child: const Icon(Icons.eco, color: Colors.white, size: 26),
                )
              ],
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _greeting(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Plan Your Harvest',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Insights to maximize yield & profit',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.88),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  // Removed _buildConfettiOverlay()

  // Removed unused _dateField widget

  // Removed unused _textField widget

  @override
  Widget build(BuildContext context) {
    return Theme(
      // Local theme override removing blue splash/highlight effects
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        // Keep existing color scheme but ensure consistent primary
        colorScheme: Theme.of(context).colorScheme.copyWith(primary: const Color(0xFF02C697)),
      ),
      child: Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Add New Harvest',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontSize: 18,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: false,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Simplified plain white background (removed rounded colored container & dynamic header)
              Container(
                color: Colors.white,
                child: SafeArea(
                  bottom: true,
                  child: SingleChildScrollView(
                                controller: _scrollController,
                    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Simple top spacing (dynamic header removed for minimal design)
                        const SizedBox(height: 8),

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
                                    // Crop Selection (chips similar to trend chips)
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Wrap(
                                        spacing: 10,
                                        runSpacing: 10,
                                        children: _crops.map((c) {
                                          final selected = _selectedCrop == c;
                                          return InkWell(
                                            borderRadius: BorderRadius.circular(30),
                                            onTap: () {
                                              setState(() {
                                                _selectedCrop = c;
                                                _showCropSelectError = false; // clear error on selection
                                              });
                                              _onInputChanged();
                                            },
                                            child: AnimatedContainer(
                                              duration: const Duration(milliseconds: 220),
                                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(30),
                                                color: selected ? const Color(0xFF02C697) : Colors.white,
                                                border: Border.all(
                                                  color: selected ? const Color(0xFF02C697) : Colors.grey.shade300,
                                                  width: 1.4,
                                                ),
                                                boxShadow: selected
                                                    ? [
                                                        BoxShadow(
                                                          color: const Color(0xFF02C697).withOpacity(0.35),
                                                          blurRadius: 10,
                                                          offset: const Offset(0, 4),
                                                        )
                                                      ]
                                                    : [
                                                        BoxShadow(
                                                          color: Colors.black.withOpacity(0.03),
                                                          blurRadius: 4,
                                                          offset: const Offset(0, 2),
                                                        )
                                                      ],
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.eco,
                                                    size: 16,
                                                    color: selected ? Colors.white : const Color(0xFF02C697),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    c,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w600,
                                                      letterSpacing: 0.3,
                                                      color: selected ? Colors.white : Colors.black87,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    if (_showCropSelectError && _selectedCrop == null)
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Padding(
                                          padding: const EdgeInsets.only(top: 6, left: 4),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.error_outline, size: 14, color: Colors.red.shade400),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Select a crop to continue',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.red.shade400,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 20),

                                    // Date fields in a row
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                                    color: Color(0xFF02C697), // Matching primary color
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                              _DateField(
                                                label: 'Select date',
                                                icon: Icons.calendar_today,
                                                controller: _planting,
                                                onChanged: () => _onInputChanged(),
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
                                                    color: Color(0xFF02C697), // Matching primary color
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                              _DateField(
                                                label: 'Select date',
                                                icon: Icons.event,
                                                controller: _harvest,
                                                onChanged: () => _onInputChanged(),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),

                                    // Area and Price fields in a row (kept a fixed vertical size; dynamic estimate moved below)
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Padding(
                                                padding: EdgeInsets.only(left: 5, bottom: 5),
                                                child: Text(
                                                  'Planting Area (sq.m)',
                                                  style: TextStyle(
                                                    color: Color(0xFF02C697),
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
                                                  controller: _area,
                                                  keyboardType: TextInputType.number,
                                                  decoration: InputDecoration(
                                                    hintText: 'Enter area in sq.m',
                                                    border: InputBorder.none,
                                                    prefixIcon: const Icon(Icons.square_foot, color: Color(0xFF02C697)),
                                                    contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                                                  ),
                                                  validator: (v) => v == null || v.isEmpty ? 'Enter Area' : null,
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
                                                    color: Color(0xFF02C697),
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
                                                    prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF02C697)),
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
                                    // Animated estimated quantity BELOW the row so right column no longer shifts
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 450),
                                      switchInCurve: Curves.easeOutBack,
                                      switchOutCurve: Curves.easeIn,
                                      transitionBuilder: (child, anim) => SlideTransition(
                                        position: Tween<Offset>(begin: const Offset(0, -0.15), end: Offset.zero).animate(anim),
                                        child: FadeTransition(opacity: anim, child: child),
                                      ),
                                      child: (_hasPreviewed && _calculatedQtyPreview != null)
                                          ? Padding(
                                              key: _estimatedQtyKey,
                                              padding: const EdgeInsets.only(top: 12),
                                              child: DecoratedBox(
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF02C697).withOpacity(0.08),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                                  child: Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      const Icon(Icons.scale, color: Color(0xFF02C697), size: 20),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: Text(
                                                          'Estimated Quantity: ${_formatNumber(_calculatedQtyPreview!)} kg',
                                                          style: const TextStyle(
                                                            color: Color(0xFF02C697),
                                                            fontWeight: FontWeight.w700,
                                                            fontSize: 15,
                                                            height: 1.25,
                                                          ),
                                                          softWrap: true,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                    const SizedBox(height: 20),

                                    // Delivery Radius field
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: TextFormField(
                                        controller: _deliveryRadius,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'Delivery Radius (km)',
                                          hintText: 'Enter delivery radius',
                                          border: OutlineInputBorder(),
                                        ),
                                        validator: (val) {
                                          if (val == null || val.isEmpty) return 'Enter delivery radius';
                                          final num? value = num.tryParse(val);
                                          if (value == null || value < 0) return 'Enter a valid radius';
                                          return null;
                                        },
                                        onChanged: (value) => _onInputChanged(),
                                      ),
                                    ),

                                    // Preview and Submit Buttons
                                    Row(
                                      children: [
                                        Expanded(
                                          child: GestureDetector(
                                            behavior: HitTestBehavior.translucent,
                                            onTap: () {
                                              if (_selectedCrop == null) {
                                                // Provide immediate feedback instead of silent disable
                                                ScaffoldMessenger.of(context)
                                                  ..hideCurrentSnackBar()
                                                  ..showSnackBar(const SnackBar(
                                                    content: Text('Select a crop first to preview.'),
                                                    duration: Duration(seconds: 2),
                                                  ));
                                              }
                                            },
                                            child: _GradientButton(
                                              onTap: _selectedCrop == null ? null : _preview,
                                              colors: _selectedCrop == null
                                                  ? [Colors.grey.shade400, Colors.grey.shade500]
                                                  : const [Color(0xFFFFA726), Color(0xFFFF9800)],
                                              icon: Icons.preview,
                                              label: 'Preview',
                                              disabled: _selectedCrop == null,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 15),
                                        Expanded(
                                          child: _GradientButton(
                                            onTap: _hasPreviewed ? _submit : null,
                                            colors: _hasPreviewed
                                                ? const [Color(0xFF02C697), Color(0xFF019876)]
                                                : [Colors.grey.shade400, Colors.grey.shade500],
                                            icon: Icons.check_circle,
                                            label: 'Submit',
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
                        ),

                        // Information sections with cards
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Anchor key for auto-scroll after preview
                              SizedBox(key: _insightsKey, height: 0),
                              Row(
                                children: [
                                  Container(
                                    height: 34,
                                    width: 4,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF02C697),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Harvest Insights',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1F2A20),
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
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

                              // Price Analysis removed

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

                        const SizedBox(height: 40), // bottom breathing space to avoid overflow when keyboard opens
                      ],
                    ),
                  ),
                ),
              ),

              // Confetti overlay removed
            ],
          );
        },
      ),
    ), // end Scaffold
    ); // end Theme
  }

  Widget _buildInfoCard({required IconData icon, required String title, required String content, required Color iconColor}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: iconColor, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2A20),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  constraints: BoxConstraints(
                    maxHeight: content.length > 220 ? 260 : double.infinity,
                  ),
                  child: content.length > 220
                      ? SingleChildScrollView(
                          child: _insightText(content),
                        )
                      : _insightText(content),
                ),
                if (content.length > 220)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.swipe_down_alt, size: 18, color: Colors.grey[500]),
                        const SizedBox(width: 6),
                        Text(
                          'Scroll for more',
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[500],
                          ),
                        )
                      ],
                    ),
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _insightText(String content) => Text(
      content,
      style: TextStyle(
        fontSize: 13.5,
        height: 1.52,
        color: Colors.grey.shade800,
        fontWeight: FontWeight.w500,
      ),
    );

class _GradientButton extends StatelessWidget {
  final VoidCallback? onTap;
  final List<Color> colors;
  final IconData icon;
  final String label;
  final bool disabled;
  const _GradientButton({
    required this.onTap,
    required this.colors,
    required this.icon,
    required this.label,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: disabled ? 0.55 : 1,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.last.withOpacity(0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                )
              ],
            ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.4,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// Reusable date field widget with custom bottom sheet picker (no dark barrier overlay)
class _DateField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final VoidCallback onChanged;

  const _DateField({
    required this.label,
    required this.icon,
    required this.controller,
    required this.onChanged,
  });

  Future<void> _openPicker(BuildContext context) async {
    DateTime initial = DateTime.tryParse(controller.text) ?? DateTime.now();
    await showModalBottomSheet(
      context: context,
      barrierColor: Colors.transparent, // remove black overlay
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        DateTime tempDate = initial;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Pick Date',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              CalendarDatePicker(
                initialDate: initial,
                firstDate: DateTime(2023),
                lastDate: DateTime(2100),
                onDateChanged: (d) => tempDate = d,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        controller.text = DateFormat('yyyy-MM-dd').format(tempDate);
                        onChanged();
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF02C697),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Select', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          hintText: label,
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: const Color(0xFF02C697)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 15),
        ),
        validator: (v) => v == null || v.isEmpty ? 'Enter date' : null,
        onTap: () => _openPicker(context),
      ),
    );
  }
}

// Painter for lightweight confetti animation
class _ConfettiPainter extends CustomPainter {
  final double animationValue; // 0..1
  final double width;
  final double height;
  final int count;
  _ConfettiPainter({
    required this.animationValue,
    required this.width,
    required this.height,
    required this.count,
  });

  final List<Color> _colors = const [
    Color(0xFF02C697),
    Color(0xFF019876),
    Color(0xFFFFA726),
    Color(0xFFFF9800),
    Color(0xFF8BC34A),
    Color(0xFF26C6DA),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(1234); // deterministic each frame for stability of paths
    for (int i = 0; i < count; i++) {
      final progress = (animationValue + (i * 0.017)) % 1.0;
      final fallY = progress * (height * 0.75) + 30;
      final startXSeed = rnd.nextDouble();
      final drift = math.sin(progress * math.pi * 6 + i) * 40;
      final x = startXSeed * width + drift;
      final rotation = progress * math.pi * 2 + i;
      final color = _colors[i % _colors.length];
      final opacity = (1 - progress).clamp(0.0, 1.0);
      final paint = Paint()..color = color.withOpacity(opacity);
      final sizeFactor = 6 + (i % 5);
      canvas.save();
      canvas.translate(x, fallY);
      canvas.rotate(rotation);
      final rect = Rect.fromCenter(center: Offset.zero, width: sizeFactor.toDouble(), height: (sizeFactor * 1.4));
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(3));
      canvas.drawRRect(rrect, paint);
      // small leaf-like arc
      if (i % 3 == 0) {
        final leafPaint = Paint()..color = color.withOpacity(opacity * 0.7);
        final path = Path();
        path.moveTo(0, -sizeFactor * 0.6);
        path.quadraticBezierTo(sizeFactor * 0.6, 0, 0, sizeFactor * 0.6);
        path.quadraticBezierTo(-sizeFactor * 0.6, 0, 0, -sizeFactor * 0.6);
        canvas.drawPath(path, leafPaint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => oldDelegate.animationValue != animationValue;
}