import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:weather_icons/weather_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'farmer_detail_screen.dart';
import 'ongoing_transactions_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class FarmerProfileScreen extends StatefulWidget {
  const FarmerProfileScreen({super.key});

  @override
  State<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen> {
  final Map<String, List<Map<String, dynamic>>> _weatherData = {};
  static const String apiKey = '9fb4df22ed842a6a5b04febf271c4b1c';
  final ScrollController _trendsScrollController = ScrollController();
  final ScrollController _transactionsScrollController = ScrollController();

  // Chart navigation state
  int _currentChartIndex = 0;
  final List<List<int>> _cropData = [
    [65, 70, 75, 80], // Tomato
    [50, 55, 60, 58], // Carrot
    [45, 48, 52, 49], // Brinjal
  ];
  final List<String> _cropNames = ['Tomato', 'Carrot', 'Brinjal'];

  static const double _trendScrollDistance = 300.0;
  static const double _transactionScrollDistance = 500.0;

  @override
  void initState() {
    super.initState();
    // _loadWeatherData(); // Commented out for now - will implement later with OpenWeatherMap API
  }

  @override
  void dispose() {
    _trendsScrollController.dispose();
    _transactionsScrollController.dispose();
    super.dispose();
  }

  void _scrollTrends(bool forward) {
    if (_trendsScrollController.hasClients) {
      final double targetPosition = forward
          ? _trendsScrollController.offset + _trendScrollDistance
          : _trendsScrollController.offset - _trendScrollDistance;
      
      _trendsScrollController.animateTo(
        targetPosition.clamp(
          0.0,
          _trendsScrollController.position.maxScrollExtent,
        ),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _scrollTransactions(bool forward) {
    if (_transactionsScrollController.hasClients) {
      final double targetPosition = forward
          ? _transactionsScrollController.offset + _transactionScrollDistance
          : _transactionsScrollController.offset - _transactionScrollDistance;
      
      _transactionsScrollController.animateTo(
        targetPosition.clamp(
          0.0,
          _transactionsScrollController.position.maxScrollExtent,
        ),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/addHarvest');
        },
        backgroundColor: const Color(0xFF02C697),
        elevation: 4,
        icon: const Icon(Icons.add),
        label: const Text(
          "Add Harvest",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          // Top section with background image and greeting
          Container(
            width: double.infinity,
            height: 220, // Fixed height for the header section
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/Background.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('farmers')
                        .doc(FirebaseAuth.instance.currentUser?.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator(color: Colors.white));
                      }

                      final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                      final farmerName = data['name'] ?? 'Farmer';

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3), // Increased from 0.25
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.5), // Increased from 0.4
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3), // Increased shadow
                                      blurRadius: 10, // Increased blur
                                      offset: const Offset(0, 3), // Increased offset
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.wb_sunny_outlined,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Good Morning!',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withOpacity(0.5), // Stronger shadow
                                            offset: const Offset(1, 1),
                                            blurRadius: 4, // Increased blur
                                          ),
                                          Shadow(
                                            color: Colors.black.withOpacity(0.3), // Additional shadow
                                            offset: const Offset(2, 2),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      farmerName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black54, // Stronger shadow
                                            offset: Offset(1, 1),
                                            blurRadius: 5, // Increased blur
                                          ),
                                          Shadow(
                                            color: Colors.black26, // Additional shadow
                                            offset: Offset(2, 2),
                                            blurRadius: 10,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          /*
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25), // Increased from 0.2
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.4), // Increased from 0.3
                                width: 1.5, // Increased border width
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2), // Stronger shadow
                                  blurRadius: 8, // Increased blur
                                  offset: const Offset(0, 3), // Increased offset
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      '�️',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '28°C', // TODO: Replace with OpenWeatherMap API data.main.temp
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withOpacity(0.4),
                                            offset: const Offset(1, 1),
                                            blurRadius: 3,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  width: 1,
                                  height: 20,
                                  color: Colors.white.withOpacity(0.3),
                                ),
                                Row(
                                  children: [
                                    const Text(
                                      '🌧️',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '2.3mm', // TODO: Replace with OpenWeatherMap API data.rain['1h'] or data.rain['3h']
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withOpacity(0.4),
                                            offset: const Offset(1, 1),
                                            blurRadius: 3,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  width: 1,
                                  height: 20,
                                  color: Colors.white.withOpacity(0.3),
                                ),
                                Text(
                                  '🌾 Today\'s Overview',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.4),
                                        offset: const Offset(1, 1),
                                        blurRadius: 3,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          */
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          
          // Main content area with white background
          Expanded(
            child: Container(
              color: const Color(0xFFF8F9FA),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    
                    // Crop Demand Trends Card (with navigation)
                    _buildCropDemandTrendsCard(),
                    
                    // Ongoing Transactions Card
                    _buildOngoingTransactionsCard(),
                    
                    // My Harvest Listings Card
                    _buildHarvestListingsCard(),
                    
                    const SizedBox(height: 100), // Space for floating action button
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /*
  Widget _buildTodayWeatherWidget() {
    // TODO: Replace hardcoded values with OpenWeatherMap API data
    // API endpoint: https://api.openweathermap.org/data/2.5/weather?lat={lat}&lon={lon}&appid={API_KEY}&units=metric
    // For current weather: current temperature, condition, humidity, wind speed
    // For daily summary: min/max temp, rainfall amount, average conditions
    
    // HARDCODED VALUES - Replace with API data
    final double currentTemp = 28.5; // API: data.main.temp
    final double minTemp = 22.0;     // API: data.main.temp_min  
    final double maxTemp = 32.0;     // API: data.main.temp_max
    final double rainfall = 2.3;     // API: data.rain['1h'] or data.rain['3h'] 
    final int humidity = 68;         // API: data.main.humidity
    final double windSpeed = 12.5;   // API: data.wind.speed
    final String condition = "Partly Cloudy"; // API: data.weather[0].description
    final String weatherIcon = "🌤️"; // API: Map weather icon code to emoji
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            const Color(0xFF02C697).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF02C697).withOpacity(0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF02C697).withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF02C697).withOpacity(0.2),
                      const Color(0xFF02C697).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.wb_sunny,
                  color: Color(0xFF02C697),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Today's Weather",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    Text(
                      'Colombo, Sri Lanka • ${_getCurrentDate()}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Main Weather Display
          Row(
            children: [
              // Current Temperature and Condition
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          weatherIcon,
                          style: const TextStyle(fontSize: 32),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${currentTemp.toInt()}°C',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF2D3748),
                              ),
                            ),
                            Text(
                              condition,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF02C697).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'H: ${maxTemp.toInt()}° L: ${minTemp.toInt()}°',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF02C697),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Weather Stats
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    _buildWeatherStat('💧', 'Rainfall', '${rainfall}mm'),
                    const SizedBox(height: 12),
                    _buildWeatherStat('💨', 'Humidity', '$humidity%'),
                    const SizedBox(height: 12),
                    _buildWeatherStat('🌪️', 'Wind', '${windSpeed}km/h'),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Weather Summary Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.withOpacity(0.1),
                  Colors.green.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.green.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.agriculture,
                  color: Colors.green,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    // TODO: Generate dynamic message based on weather conditions and crops
                    'Good conditions for farming activities today',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  */

  Widget _buildWeatherStat(String emoji, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D3748),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[now.month - 1]} ${now.day}';
  }

  Widget _buildTransactionsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF02C697).withOpacity(0.2),
                        const Color(0xFF02C697).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF02C697).withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.trending_up_rounded,
                    color: const Color(0xFF02C697),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Crop Demand Trends',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF2D3748),
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '📈 Track market demands across crops',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 250, // Reduced height to prevent overflow
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    const Color(0xFF02C697).withOpacity(0.03),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF02C697).withOpacity(0.1),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF02C697).withOpacity(0.1),
                    spreadRadius: 2, // Reduced from 3
                    blurRadius: 12, // Reduced from 15
                    offset: const Offset(0, 4), // Reduced from 5
                  ),
                ],
              ),
              child: FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('this_week')
                    .doc('trend')
                    .get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  if (data == null) {
                    return _buildEmptyState('No trend data available.');
                  }

                  final crops = ['tomato', 'carrot', 'brinjal'];
                  final cropNames = ['Tomato', 'Carrot', 'Brinjal'];
                  
                  return Column(
                    children: [
                      // Navigation Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Swipe or tap to navigate',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    // TODO: Implement chart navigation
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Previous chart')),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF02C697).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFF02C697).withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.chevron_left,
                                      color: Color(0xFF02C697),
                                      size: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    // TODO: Implement chart navigation
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Next chart')),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF02C697).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFF02C697).withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.chevron_right,
                                      color: Color(0xFF02C697),
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Charts
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: _buildTrendCard('Tomato', [65, 70, 75, 80]),
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

  Widget _buildCropDemandTrendsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  flex: 2,
                  child: Text(
                    'Crop Demand Trends',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Flexible(
                  flex: 1,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        onPressed: _currentChartIndex > 0
                            ? () {
                                setState(() {
                                  _currentChartIndex--;
                                });
                              }
                            : null,
                        icon: Icon(
                          Icons.chevron_left,
                          size: 20,
                          color: _currentChartIndex > 0
                              ? const Color(0xFF02C697)
                              : Colors.grey,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          _cropNames[_currentChartIndex],
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF02C697),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        onPressed: _currentChartIndex < _cropNames.length - 1
                            ? () {
                                setState(() {
                                  _currentChartIndex++;
                                });
                              }
                            : null,
                        icon: Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: _currentChartIndex < _cropNames.length - 1
                              ? const Color(0xFF02C697)
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current: ₹${_cropData[_currentChartIndex][_cropData[_currentChartIndex].length - 1]} per kg',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF02C697),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(
                        _cropData[_currentChartIndex].length,
                        (index) {
                          double maxValue = _cropData[_currentChartIndex]
                              .reduce((a, b) => a > b ? a : b)
                              .toDouble();
                          double minValue = _cropData[_currentChartIndex]
                              .reduce((a, b) => a < b ? a : b)
                              .toDouble();
                          double normalizedHeight = maxValue > minValue
                              ? ((_cropData[_currentChartIndex][index] - minValue) / 
                                 (maxValue - minValue)) * 60 + 20
                              : 40;
                          
                          bool isLatest = index == _cropData[_currentChartIndex].length - 1;
                          
                          return Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    '₹${_cropData[_currentChartIndex][index]}',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: 16,
                                    height: normalizedHeight,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: isLatest
                                            ? [
                                                const Color(0xFF02C697),
                                                const Color(0xFF02C697).withOpacity(0.8),
                                              ]
                                            : [
                                                const Color(0xFF02C697).withOpacity(0.6),
                                                const Color(0xFF02C697).withOpacity(0.4),
                                              ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'W${index + 1}',
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOngoingTransactionsCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const OngoingTransactionsScreen(),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF02C697).withOpacity(0.2),
                      const Color(0xFF02C697).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF02C697).withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Color(0xFF02C697),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ongoing Transactions',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF2D3748),
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'View and manage your active transactions',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Color(0xFF02C697),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHarvestListingsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF02C697).withOpacity(0.2),
                        const Color(0xFF02C697).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF02C697).withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.eco_rounded,
                    color: const Color(0xFF02C697),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Harvest Listings',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF2D3748),
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '🌱 Manage your crop inventory',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('Harvests')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(color: Color(0xFF02C697)),
                    ),
                  );
                }

                final data = snapshot.data!.data() as Map<String, dynamic>?;
                if (data == null || !data.containsKey('harvests')) {
                  return _buildEmptyState('No harvests found.');
                }

                final harvests = List<Map<String, dynamic>>.from(data['harvests']);
                if (harvests.isEmpty) {
                  return _buildEmptyState('No harvest entries.');
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: harvests.length > 3 ? 3 : harvests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = harvests[index];
                    return GestureDetector(
                      onTap: () => _showHarvestDetails(context, item),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF02C697).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF02C697).withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF02C697).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.eco,
                                color: Color(0xFF02C697),
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['crop'] ?? 'Unknown Crop',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: Color(0xFF2D3748),
                                    ),
                                  ),
                                  Text(
                                    'Qty: ${item['quantity']} kg • LKR ${item['price']}/kg',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getHarvestStatusColor(item).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _getHarvestStatus(item),
                                    style: TextStyle(
                                      color: _getHarvestStatusColor(item),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 14,
                                  color: Colors.grey[400],
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
    );
  }

  // Add other required methods here
  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade50,
            Colors.orange.shade100,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long,
                color: Colors.orange.shade700,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Transactions Overview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn('Pending', '2', Colors.orange),
              _buildStatColumn('Ongoing', '1', Colors.blue),
              _buildStatColumn('Completed', '5', Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTrendCard(String cropName, List<int> trendData) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            const Color(0xFF02C697).withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF02C697).withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF02C697).withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with better spacing
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6), // Reduced padding
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getDemandColor(
                        trendData.isNotEmpty 
                          ? trendData.reduce((a, b) => a + b) / trendData.length 
                          : 0
                      ).withOpacity(0.2),
                      _getDemandColor(
                        trendData.isNotEmpty 
                          ? trendData.reduce((a, b) => a + b) / trendData.length 
                          : 0
                      ).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getCropIcon(cropName),
                  size: 14, // Reduced size
                  color: _getDemandColor(
                    trendData.isNotEmpty 
                      ? trendData.reduce((a, b) => a + b) / trendData.length 
                      : 0
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cropName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2D3748),
                        fontSize: 14, // Reduced font size
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '4-Week Forecast',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                        fontSize: 10, // Reduced font size
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12), // Reduced spacing
          // Chart with proper constraints
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 25,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey[200]!,
                          strokeWidth: 0.8,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30, // Reduced reserved size
                          interval: 25,
                          getTitlesWidget: (value, meta) {
                            if (value == 0) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Text(
                                '${value.toInt()}%',
                                style: const TextStyle(
                                  color: Color(0xFF02C697),
                                  fontSize: 9, // Reduced font size
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 25, // Reduced reserved size
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final weeks = ['W1', 'W2', 'W3', 'W4'];
                            if (value >= 0 && value < weeks.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  weeks[value.toInt()],
                                  style: const TextStyle(
                                    color: Color(0xFF02C697),
                                    fontSize: 9, // Reduced font size
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: 3,
                    minY: 0,
                    maxY: 100,
                    lineBarsData: [
                      LineChartBarData(
                        spots: trendData.asMap().entries.map((entry) {
                          return FlSpot(entry.key.toDouble(), entry.value.toDouble());
                        }).toList(),
                        isCurved: true,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF02C697),
                            const Color(0xFF02C697).withOpacity(0.6),
                          ],
                        ),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 3, // Reduced dot size
                              color: Colors.white,
                              strokeWidth: 2,
                              strokeColor: const Color(0xFF02C697),
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(0xFF02C697).withOpacity(0.3),
                              const Color(0xFF02C697).withOpacity(0.05),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getDemandColor(double averageDemand) {
    if (averageDemand >= 75) {
      return Colors.green;
    } else if (averageDemand >= 50) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  IconData _getCropIcon(String cropName) {
    switch (cropName.toLowerCase()) {
      case 'tomato':
        return Icons.local_florist;
      case 'carrot':
        return Icons.agriculture;
      case 'brinjal':
        return Icons.eco;
      default:
        return Icons.grass;
    }
  }
  // END DUPLICATE METHODS

  Future<List<Map<String, dynamic>>> _fetchTransactions() async {
    // Implementation for fetching transactions
    return [];
  }

  String _getHarvestStatus(Map<String, dynamic> item) {
    final crop = item['crop']?.toString().toLowerCase() ?? '';
    
    // Simple hardcoded logic for harvest status
    final quantity = double.tryParse(item['quantity'].toString()) ?? 0;
    final price = double.tryParse(item['price'].toString()) ?? 0;
    
    if (price > 150 && quantity > 50) {
      return 'Good';
    } else if (crop.contains('tomato') && price > 100) {
      return 'Good';
    } else if (crop.contains('carrot') && price > 80) {
      return 'Good';
    } else if (crop.contains('brinjal') && price > 90) {
      return 'Good';
    } else {
      return 'Bad';
    }
  }

  bool _evaluateWeatherForCrop(String crop, List<Map<String, dynamic>> forecast) {
    int badWeatherDays = 0;
    
    for (final day in forecast) {
      final condition = day['condition']?.toString().toLowerCase() ?? '';
      final temp = day['temp'] as double? ?? 25.0;
      
      // Crop-specific weather evaluation
      bool isDayBad = false;
      
      switch (crop) {
        case 'tomato':
          // Tomatoes are sensitive to excessive rain and extreme temperatures
          if (condition.contains('rain') || condition.contains('thunderstorm')) {
            isDayBad = true;
          }
          if (temp > 35 || temp < 10) {
            isDayBad = true;
          }
          break;
          
        case 'carrot':
          // Carrots can handle cooler weather but not excessive moisture
          if (condition.contains('thunderstorm') || condition.contains('snow')) {
            isDayBad = true;
          }
          if (temp > 30 || temp < 5) {
            isDayBad = true;
          }
          break;
          
        case 'brinjal':
          // Brinjals (eggplants) need warm weather and don't like cold or heavy rain
          if (condition.contains('rain') || condition.contains('thunderstorm')) {
            isDayBad = true;
          }
          if (temp > 40 || temp < 15) {
            isDayBad = true;
          }
          break;
          
        default:
          // General crop evaluation
          if (condition.contains('thunderstorm') || condition.contains('snow')) {
            isDayBad = true;
          }
          if (temp > 38 || temp < 8) {
            isDayBad = true;
          }
      }
      
      if (isDayBad) {
        badWeatherDays++;
      }
    }
    
    // If more than 2 days have bad weather conditions, mark as 'Bad'
    return badWeatherDays <= 2;
  }

  Color _getHarvestStatusColor(Map<String, dynamic> item) {
    return _getHarvestStatus(item) == 'Good' ? Colors.green : Colors.red;
  }

  String _getHarvestPrecautions(Map<String, dynamic> item) {
    final status = _getHarvestStatus(item);
    final crop = item['crop']?.toString().toLowerCase() ?? '';
    
    if (status == 'Good') {
      return _getGoodWeatherPrecautions(crop);
    } else {
      return _getBadWeatherPrecautions(crop);
    }
  }

  String _getGoodWeatherPrecautions(String crop) {
    String weatherInfo = _getWeatherSummary();
    
    switch (crop) {
      case 'tomato':
        return '''$weatherInfo

🍅 TOMATO STORAGE - FAVORABLE CONDITIONS:
• Store in cool, dry place (55-70°F)
• Keep away from direct sunlight
• Good weather ahead - extend shelf life
• Separate ripe from unripe tomatoes
• Check regularly for overripening
• Handle gently to avoid bruising''';
      case 'carrot':
        return '''$weatherInfo

🥕 CARROT STORAGE - OPTIMAL CONDITIONS:
• Remove green tops before storage
• Cool weather helps preserve quality
• Store in refrigerator crisper drawer
• Keep in perforated plastic bags
• Can last 3-4 weeks in good conditions
• Wash only before consumption''';
      case 'brinjal':
        return '''$weatherInfo

🍆 BRINJAL STORAGE - SUITABLE CONDITIONS:
• Moderate weather supports quality
• Store at room temperature if using within 2 days
• For longer storage, keep in refrigerator
• Avoid storing below 50°F
• Use within 5-7 days for best quality
• Handle carefully as they bruise easily''';
      default:
        return '''$weatherInfo

🌱 GENERAL STORAGE - GOOD CONDITIONS:
• Favorable weather for crop preservation
• Store in appropriate temperature conditions
• Maintain proper humidity levels
• Regular quality checks recommended
• Handle with care during transport''';
    }
  }

  String _getBadWeatherPrecautions(String crop) {
    String weatherWarning = _getWeatherWarning();
    
    switch (crop) {
      case 'tomato':
        return '''$weatherWarning

⚠️ TOMATO URGENT ACTION NEEDED:
• Unfavorable weather detected ahead
• Move to covered, dry storage immediately
• Separate any damaged fruits NOW
• Consider processing into sauces/pastes
• Increase ventilation to prevent moisture
• Sell quickly before weather worsens''';
      case 'carrot':
        return '''$weatherWarning

⚠️ CARROT PROTECTION REQUIRED:
• Poor weather conditions forecast
• Ensure completely dry before storage
• Extra protection from moisture needed
• Consider immediate local market sales
• Store in well-ventilated, dry area
• Monitor closely for quality changes''';
      case 'brinjal':
        return '''$weatherWarning

⚠️ BRINJAL IMMEDIATE ACTION:
• Weather unsuitable for crop storage
• Move to controlled environment quickly
• Check for any existing damage
• Consider processing/cooking options
• Avoid exposure to excess humidity
• Implement emergency preservation methods''';
      default:
        return '''$weatherWarning

⚠️ GENERAL CROP PROTECTION:
• Adverse weather conditions ahead
• Implement immediate protective measures
• Review and upgrade storage facilities
• Consider alternative preservation methods
• Monitor crop quality frequently''';
    }
  }

  String _getWeatherSummary() {
    // Hardcoded weather info: 28°C, 2.3mm rainfall
    return "🌤️ WEATHER STATUS: 28°C, 2.3mm rainfall - Good conditions for storage";
  }

  String _getWeatherWarning() {
    // Hardcoded weather warning
    return "🌧️ WEATHER ALERT: Poor conditions - Take immediate protective action";
  }
  void _showHarvestDetails(BuildContext context, Map<String, dynamic> item) {
    final status = _getHarvestStatus(item);
    final statusColor = _getHarvestStatusColor(item);
    final precautions = _getHarvestPrecautions(item);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  statusColor.withOpacity(0.02),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            statusColor.withOpacity(0.2),
                            statusColor.withOpacity(0.1),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        status == 'Good' ? Icons.check_circle : Icons.warning,
                        color: statusColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['crop'] ?? 'Unknown Crop',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$status Quality',
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close,
                        color: Colors.grey[400],
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Quick Details
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '${item['quantity']} kg',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2D3748),
                              ),
                            ),
                            Text(
                              'Quantity',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: Colors.grey[300],
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'LKR ${item['price']}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2D3748),
                              ),
                            ),
                            Text(
                              'Per kg',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Precautions Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        statusColor.withOpacity(0.05),
                        statusColor.withOpacity(0.02),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: statusColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: statusColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            status == 'Good' ? 'Storage & Handling Tips' : 'Quality Improvement Tips',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        precautions,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: Color(0xFF2D3748),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: statusColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Got It!',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /*
  Widget _buildHarvestListingsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Harvest Listings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            child: const Center(
              child: Text(
                'Harvest listings will be displayed here',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  */
}