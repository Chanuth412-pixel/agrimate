import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:weather_icons/weather_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'farmer_detail_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class FarmerProfileScreen extends StatefulWidget {
  const FarmerProfileScreen({super.key});

  @override
  State<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen> {
  final Map<String, List<Map<String, dynamic>>> _weatherData = {};
  static const String apiKey = '9fb4df22ed842a6a5b04febf271c4b1c'; // Hardcoded OpenWeather API key
  final ScrollController _trendsScrollController = ScrollController();
  final ScrollController _transactionsScrollController = ScrollController();

  // Constants for scroll distances
  static const double _trendScrollDistance = 300.0; // Distance for one trend tile
  static const double _transactionScrollDistance = 500.0; // Distance for two transaction tiles

  @override
  void initState() {
    super.initState();
    _loadWeatherData();
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

  bool _isIdealTemperature(String crop, double temp, bool isDay) {
    switch (crop.toLowerCase()) {
      case 'brinjal':
        return isDay ? (temp >= 25 && temp <= 30) : (temp >= 20 && temp <= 24);
      case 'carrot':
        return isDay ? (temp >= 18 && temp <= 24) : (temp >= 10 && temp <= 15);
      case 'tomato':
        return isDay ? (temp >= 21 && temp <= 29) : (temp >= 15 && temp <= 20);
      default:
        return false;
    }
  }

  bool _isIdealRainfall(String crop, double weeklyRainfall) {
    switch (crop.toLowerCase()) {
      case 'brinjal':
        return weeklyRainfall >= 20 && weeklyRainfall <= 30;
      case 'carrot':
        return weeklyRainfall >= 15 && weeklyRainfall <= 20;
      case 'tomato':
        return weeklyRainfall >= 15 && weeklyRainfall <= 25;
      default:
        return false;
    }
  }

  Future<void> _loadWeatherData() async {
    try {
      // Use Colombo's coordinates
      final lat = 6.9271;
      final lon = 79.8612;
      
      final response = await http.get(
        Uri.parse('https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&appid=$apiKey&units=metric')
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> forecasts = data['list'];
        
        // Process forecasts for each crop type
        for (String crop in ['Brinjal', 'Carrot', 'Tomato']) {
          List<Map<String, dynamic>> processedData = [];
          var processedDays = 0;
          var currentDate = '';
          double weeklyRainfall = 0;
          
          // Process first 5 days
          for (var forecast in forecasts) {
            var date = DateTime.fromMillisecondsSinceEpoch(forecast['dt'] * 1000);
            var dateStr = '${date.year}-${date.month}-${date.day}';
            var hour = date.hour;
            var isDay = hour >= 6 && hour <= 18;
            
            if (dateStr != currentDate && processedDays < 5) {
              currentDate = dateStr;
              processedDays++;
              
              final temp = forecast['main']['temp'] as double;
              final rain = forecast['rain']?['3h'] ?? 0;
              weeklyRainfall += rain;
              
              processedData.add({
                'date': date,
                'temp': temp,
                'isDay': isDay,
                'isIdealTemp': _isIdealTemperature(crop, temp, isDay),
                'isIdealRain': _isIdealRainfall(crop, weeklyRainfall),
              });
            }
          }

          // Extend to 7 days using last day's data
          if (processedData.isNotEmpty) {
            final lastDay = processedData.last;
            processedData.addAll([
              {...lastDay, 'date': DateTime.now().add(Duration(days: 5))},
              {...lastDay, 'date': DateTime.now().add(Duration(days: 6))},
            ]);
          }

          setState(() {
            _weatherData[crop] = processedData;
          });
        }
      }
    } catch (e) {
      print('Error fetching weather: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmer Dashboard'),
        backgroundColor: const Color(0xFF02C697),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'View Profile',
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;

              final doc = await FirebaseFirestore.instance
                  .collection('farmers') // <-- Change this to your Farmer collection name
                  .doc(user?.uid)
                  .get();

              final farmerData = doc.data() ?? {
                "email": user?.email ?? '',
                "uid": user?.uid ?? '',
                "phone": "Not Provided",
                "name": "Not Provided",
              };

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FarmerDetailScreen(farmerData: farmerData),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/addHarvest');
        },
        backgroundColor: const Color(0xFF02C697),
        icon: const Icon(Icons.add),
        label: const Text("Add Harvest"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Crop Demand Trends',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.white,
                            Colors.white.withOpacity(0.0),
                            Colors.white.withOpacity(0.0),
                            Colors.white,
                          ],
                          stops: const [0.0, 0.1, 0.9, 1.0],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.dstOut,
                      child: SingleChildScrollView(
                        controller: _trendsScrollController,
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                          child: Row(
                            children: [
                              const SizedBox(width: 24),
                              SizedBox(
                                height: 200,
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
                                    
                                    return Row(
                                      children: List.generate(
                                        crops.length,
                                        (index) {
                                          final cropKey = crops[index];
                                          final cropName = cropNames[index];
                                          final trendData = List<int>.from(data[cropKey] ?? [0, 0, 0, 0]);
                                          
                                          // Calculate average demand for overall score
                                          final avgDemand = trendData.isNotEmpty 
                                              ? trendData.reduce((a, b) => a + b) / trendData.length 
                                              : 0;
                                          
                                          return Padding(
                                            padding: const EdgeInsets.only(right: 16),
                                            child: Container(
                                              width: 200,
                                              height: 180, // Fixed height for the container
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(16),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.green.withOpacity(0.08),
                                                    blurRadius: 12,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              padding: const EdgeInsets.all(12),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    cropName,
                                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '4-Week Demand Forecast',
                                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                      color: Colors.grey[600],
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Expanded(
                                                    child: LineChart(
                                                      LineChartData(
                                                        gridData: FlGridData(show: false),
                                                        titlesData: FlTitlesData(
                                                          leftTitles: AxisTitles(
                                                            sideTitles: SideTitles(
                                                              showTitles: true,
                                                              reservedSize: 28,
                                                              interval: 25, // Changed from 20 to 25 for better spacing
                                                              getTitlesWidget: (value, meta) {
                                                                if (value == 0) return const Text('');
                                                                return Text(
                                                                  '${value.toInt()}%',
                                                                  style: TextStyle(
                                                                    color: Colors.grey[600],
                                                                    fontSize: 10,
                                                                  ),
                                                                );
                                                              },
                                                            ),
                                                          ),
                                                          rightTitles: AxisTitles(
                                                            sideTitles: SideTitles(showTitles: false),
                                                          ),
                                                          topTitles: AxisTitles(
                                                            sideTitles: SideTitles(showTitles: false),
                                                          ),
                                                          bottomTitles: AxisTitles(
                                                            sideTitles: SideTitles(
                                                              showTitles: true,
                                                              reservedSize: 20,
                                                              interval: 1,
                                                              getTitlesWidget: (value, meta) {
                                                                final weeks = ['W1', 'W2', 'W3', 'W4'];
                                                                if (value >= 0 && value < weeks.length) {
                                                                  return Padding(
                                                                    padding: const EdgeInsets.only(top: 5),
                                                                    child: Text(
                                                                      weeks[value.toInt()],
                                                                      style: TextStyle(
                                                                        color: Colors.grey[600],
                                                                        fontSize: 10,
                                                                      ),
                                                                    ),
                                                                  );
                                                                }
                                                                return const Text('');
                                                              },
                                                            ),
                                                          ),
                                                        ),
                                                        borderData: FlBorderData(show: false),
                                                        minX: 0,
                                                        maxX: 3,
                                                        minY: 0,
                                                        maxY: 100,
                                                        lineBarsData: [
                                                          LineChartBarData(
                                                            spots: List.generate(
                                                              trendData.length,
                                                              (i) => FlSpot(i.toDouble(), trendData[i].toDouble()),
                                                            ),
                                                            isCurved: true,
                                                            color: _getDemandColor(
                                                              trendData.isNotEmpty 
                                                                ? trendData.reduce((a, b) => a + b) / trendData.length 
                                                                : 0
                                                            ),
                                                            barWidth: 2.5, // Slightly reduced from 3
                                                            isStrokeCapRound: true,
                                                            dotData: FlDotData(
                                                              show: true,
                                                              getDotPainter: (spot, percent, barData, index) {
                                                                return FlDotCirclePainter(
                                                                  radius: 3, // Reduced from 4
                                                                  color: Colors.white,
                                                                  strokeWidth: 1.5, // Reduced from 2
                                                                  strokeColor: barData.color ?? Colors.green,
                                                                );
                                                              },
                                                            ),
                                                            belowBarData: BarAreaData(
                                                              show: true,
                                                              color: _getDemandColor(
                                                                trendData.isNotEmpty 
                                                                  ? trendData.reduce((a, b) => a + b) / trendData.length 
                                                                  : 0
                                                              ).withOpacity(0.1),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.end,
                                                    children: [
                                                      Text(
                                                        'Avg: ${(trendData.isNotEmpty ? trendData.reduce((a, b) => a + b) / trendData.length : 0).round()}%',
                                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                          color: _getDemandColor(
                                                            trendData.isNotEmpty 
                                                              ? trendData.reduce((a, b) => a + b) / trendData.length 
                                                              : 0
                                                          ),
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 24),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Left scroll indicator
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: () => _scrollTrends(false),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.chevron_left,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Right scroll indicator
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: () => _scrollTrends(true),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.chevron_right,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Ongoing Transactions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 240,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.white,
                            Colors.white.withOpacity(0.0),
                            Colors.white.withOpacity(0.0),
                            Colors.white,
                          ],
                          stops: const [0.0, 0.1, 0.9, 1.0],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.dstOut,
                      child: SingleChildScrollView(
                        controller: _transactionsScrollController,
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                          child: Row(
                            children: [
                              const SizedBox(width: 24),
                              SizedBox(
                                height: 220,
                                child: FutureBuilder<DocumentSnapshot>(
                                  future: FirebaseFirestore.instance
                                      .collection('Ongoing_Trans_Farm')
                                      .doc(userId)
                                      .get(),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) {
                                      return const Center(child: CircularProgressIndicator());
                                    }
                                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                                    if (data == null || !data.containsKey('transactions')) {
                                      return _buildEmptyState('No transactions found.');
                                    }
                                    final transactions = List<Map<String, dynamic>>.from(data['transactions']);
                                    if (transactions.isEmpty) {
                                      return _buildEmptyState('No transactions available.');
                                    }
                                    return Row(
                                      children: List.generate(
                                        transactions.length,
                                        (index) {
                                          final tx = transactions[index];
                                          final crop = tx['Crop'] ?? 'Unknown';
                                          final quantity = tx['Quantity Sold (1kg)'] ?? 0;
                                          final price = tx['Sale Price Per kg'] ?? 0;
                                          final status = tx['Status'] ?? 'Pending';
                                          final customerName = tx['Farmer Name'] ?? 'N/A';
                                          final phoneNO = tx['Phone_NO'] ?? 'N/A';
                                          final deliveredOn = (tx['Date'] as Timestamp?)?.toDate() ?? DateTime.now();
                                          return Padding(
                                            padding: const EdgeInsets.only(right: 16),
                                            child: Container(
                                              width: 220,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(16),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.green.withOpacity(0.08),
                                                    blurRadius: 12,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              padding: const EdgeInsets.all(16),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text(
                                                        crop,
                                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      _buildStatusChip(status),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text('Customer: $customerName', style: Theme.of(context).textTheme.bodySmall),
                                                  Text('Contact: $phoneNO', style: Theme.of(context).textTheme.bodySmall),
                                                  Text('Deliver On: ${deliveredOn.day}/${deliveredOn.month}/${deliveredOn.year}', style: Theme.of(context).textTheme.bodySmall),
                                                  const Divider(height: 20),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      _buildDetailBox('Quantity', '${quantity}kg', const Color(0xFFF3F4F6)),
                                                      _buildDetailBox('Unit Price', 'LKR$price', const Color(0xFFF3F4F6)),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 24),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Left scroll indicator
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: () => _scrollTransactions(false),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.chevron_left,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Right scroll indicator
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: () => _scrollTransactions(true),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.chevron_right,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'My Harvest Listings',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('Harvests')
                    .doc(userId)
                    .get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
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
                    itemCount: harvests.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = harvests[index];
                      return GestureDetector(
                        onTap: () => _showHarvestDetails(context, item),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${item['crop']} - ${item['quantity']}kg',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  // Weather indicator dots
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: List.generate(7, (index) {
                                          final date = DateTime.now().add(Duration(days: index));
                                          final weatherList = _weatherData[item['crop']] ?? [];
                                          final dayData = index < weatherList.length ? weatherList[index] : null;
                                          
                                          return Container(
                                            width: 32,
                                            height: 32,
                                            margin: const EdgeInsets.symmetric(horizontal: 6),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: dayData != null ? [
                                                  _getWeatherGradientStart(dayData),
                                                  _getWeatherGradientEnd(dayData),
                                                ] : [
                                                  Colors.grey[300]!,
                                                  Colors.grey[400]!,
                                                ],
                                              ),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              dayData != null 
                                                ? _getWeatherIcon(dayData)
                                                : WeatherIcons.na,
                                              size: 18,
                                              color: Colors.white,
                                            ),
                                          );
                                        }),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: List.generate(7, (index) {
                                          final date = DateTime.now().add(Duration(days: index));
                                          final dayName = _getShortDayName(date.weekday);
                                          return Container(
                                            width: 44,
                                            margin: const EdgeInsets.symmetric(horizontal: 0),
                                            child: Text(
                                              dayName,
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          );
                                        }),
                                      ),
                                      const SizedBox(height: 8),
                                      // Weather status message
                                      Builder(
                                        builder: (context) {
                                          final weatherList = _weatherData[item['crop']] ?? [];
                                          bool hasNonIdealDay = false;
                                          
                                          for (var dayData in weatherList) {
                                            if (!(dayData['isIdealTemp'] && dayData['isIdealRain'])) {
                                              hasNonIdealDay = true;
                                              break;
                                            }
                                          }
                                          
                                          return Text(
                                            hasNonIdealDay 
                                              ? "⚠️ Heads up! Check the updated precautions."
                                              : "🌱 All good! Perfect conditions for farming.",
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: hasNonIdealDay ? Colors.orange[700] : Colors.green[700],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Planting: ${item['plantingDate']}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                'Harvest: ${item['harvestDate']}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                'Price: LKR${item['expectedPrice']} per kg',
                                style: Theme.of(context).textTheme.bodySmall,
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
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.info_outline,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
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

  Widget _buildDetailBox(String label, String value, Color bgColor) {
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
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekDemand(BuildContext context, String week, int demand) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          week,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        Text(
          '$demand%',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: _getDemandColor(demand.toDouble()),
          ),
        ),
      ],
    );
  }

  Color _getDemandColor(double demand) {
    if (demand >= 80) {
      return Colors.green[700]!;
    } else if (demand >= 60) {
      return Colors.orange[600]!;
    } else if (demand >= 40) {
      return Colors.amber[600]!;
    } else {
      return Colors.red[600]!;
    }
  }

  void _showHarvestDetails(BuildContext context, Map<String, dynamic> harvest) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 600),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Harvest Details',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF02C697),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey[100],
                          shape: const CircleBorder(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Crop and Quantity
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF02C697).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${harvest['crop']?.toString().toUpperCase()}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF02C697),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Quantity: ${harvest['quantity']} kg',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Basic Details
                  _buildDetailRow('Planting Date', harvest['plantingDate'] ?? 'N/A'),
                  _buildDetailRow('Harvest Date', harvest['harvestDate'] ?? 'N/A'),
                  _buildDetailRow('Expected Price', 'LKR ${harvest['expectedPrice']} per kg'),
                  _buildDetailRow('Available Quantity', '${harvest['available']} kg'),
                  const SizedBox(height: 20),
                  
                  // Precautions Section
                  if (harvest['precautions'] != null && harvest['precautions'].toString().isNotEmpty) ...[
                    Text(
                      'Crop Care Precautions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Text(
                        harvest['precautions'].toString(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                          color: Colors.orange[800],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  
                  // Close Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF02C697),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getShortDayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Mon';
      case DateTime.tuesday:
        return 'Tue';
      case DateTime.wednesday:
        return 'Wed';
      case DateTime.thursday:
        return 'Thu';
      case DateTime.friday:
        return 'Fri';
      case DateTime.saturday:
        return 'Sat';
      case DateTime.sunday:
        return 'Sun';
      default:
        return '';
    }
  }

  IconData _getWeatherIcon(Map<String, dynamic> dayData) {
    // First check if conditions are ideal
    bool isIdeal = dayData['isIdealTemp'] && dayData['isIdealRain'];
    bool isDay = dayData['isDay'] ?? true;

    if (isIdeal) {
      if (isDay) {
        return WeatherIcons.day_sunny; // Ideal daytime
      }
      return WeatherIcons.night_clear; // Ideal nighttime
    }

    // Non-ideal conditions
    double temp = (dayData['temp'] is num) ? (dayData['temp'] as num).toDouble() : 20.0;
    double rain = (dayData['rain'] is num) ? (dayData['rain'] as num).toDouble() : 0.0;

    if (temp <= 15.0) {
      return WeatherIcons.snowflake_cold; // Too cold
    }
    if (temp >= 30.0) {
      return WeatherIcons.hot; // Too hot
    }
    if (rain >= 30.0) {
      return WeatherIcons.rain; // Too much rain
    }
    return WeatherIcons.rain_mix; // Other non-ideal conditions
  }

  Color _getWeatherGradientStart(Map<String, dynamic> dayData) {
    bool isIdeal = dayData['isIdealTemp'] && dayData['isIdealRain'];
    bool isDay = dayData['isDay'] ?? true;

    if (isIdeal) {
      return Colors.lightGreen[300] ?? Colors.lightGreen; // Ideal conditions - light green
    }

    // Non-ideal conditions - yellow
    return Colors.yellow[300] ?? Colors.yellow;
  }

  Color _getWeatherGradientEnd(Map<String, dynamic> dayData) {
    bool isIdeal = dayData['isIdealTemp'] && dayData['isIdealRain'];
    bool isDay = dayData['isDay'] ?? true;

    if (isIdeal) {
      return Colors.lightGreen[500] ?? Colors.lightGreen; // Ideal conditions - darker light green
    }

    // Non-ideal conditions - darker yellow
    return Colors.yellow[500] ?? Colors.yellow;
  }
}