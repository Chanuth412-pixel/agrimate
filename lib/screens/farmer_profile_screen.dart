import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:weather_icons/weather_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'farmer_detail_screen.dart';
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
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Farmer Dashboard',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF02C697),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, size: 20),
            ),
            tooltip: 'View Profile',
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              final doc = await FirebaseFirestore.instance
                  .collection('farmers')
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
          const SizedBox(width: 8),
        ],
      ),
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
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.18, // low opacity background image
              child: Image.asset(
                'assets/images/Background.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned.fill(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top curved container
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF02C697),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Container(
                margin: const EdgeInsets.only(top: 10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Crop Demand Trends Section
                      Row(
                        children: [
                          const Icon(Icons.trending_up, color: Color(0xFF02C697)),
                          const SizedBox(width: 8),
                          Text(
                            'Crop Demand Trends',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2D3748),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 220,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
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
                            // Scroll indicators
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
                    ],
                  ),
                ),
              ),
            ),

            // Ongoing Transactions Section
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.receipt_long, color: Color(0xFF02C697)),
                      const SizedBox(width: 8),
                      Text(
                        'Ongoing Transactions',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2D3748),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 335, // or 300
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
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
                                    height: 315,
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
                                              final deliveryMethod = tx['deliveryMethod'];
                                              final deliveryStatus = tx['Status'] ?? 'pending';
                                              final deliverStatus = tx['deliver_status'] ?? '';
                                              final deliveryGuyName = tx['delivery_guy_name'];
                                              final deliveryGuyPhone = tx['delivery_guy_phone'];
                                              return Padding(
                                                padding: const EdgeInsets.only(right: 16),
                                                child: Container(
                                                  width: 250,
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
                                                      Text('Deliver On:  ${deliveredOn.day}/${deliveredOn.month}/${deliveredOn.year}', style: Theme.of(context).textTheme.bodySmall),
                                                      if (deliveryMethod != null) ...[
                                                        const SizedBox(height: 8),
                                                        Row(
                                                          children: [
                                                            const Icon(Icons.local_shipping, size: 16, color: Color(0xFF02C697)),
                                                            const SizedBox(width: 4),
                                                            Text(
                                                              deliveryMethod == 'self' ? 'Self Delivery' : 'Delivery Guy',
                                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF02C697)),
                                                            ),
                                                          ],
                                                        ),
                                                        if (deliveryMethod == 'delivery_guy' && deliverStatus == 'assigned' && deliveryGuyName != null) ...[
                                                          const SizedBox(height: 6),
                                                          Row(
                                                            children: [
                                                              const Icon(Icons.person, size: 16, color: Colors.blueAccent),
                                                              const SizedBox(width: 4),
                                                              Text('Delivery Guy: $deliveryGuyName', style: const TextStyle(fontSize: 13, color: Colors.blueAccent)),
                                                              if (tx['delivery_guy_id'] != null)
                                                                FutureBuilder<double?>(
                                                                  future: _fetchDriverRating(tx['delivery_guy_id']),
                                                                  builder: (context, snapshot) {
                                                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                                                      return const Padding(
                                                                        padding: EdgeInsets.only(left: 8.0),
                                                                        child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                                                                      );
                                                                    }
                                                                    if (!snapshot.hasData || snapshot.data == null) {
                                                                      return const Padding(
                                                                        padding: EdgeInsets.only(left: 8.0),
                                                                        child: Text('No rating', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                                                      );
                                                                    }
                                                                    return Padding(
                                                                      padding: const EdgeInsets.only(left: 8.0),
                                                                      child: Row(
                                                                        children: [
                                                                          const Icon(Icons.star, color: Colors.amber, size: 15),
                                                                          Text(snapshot.data!.toStringAsFixed(1), style: const TextStyle(fontSize: 13)),
                                                                        ],
                                                                      ),
                                                                    );
                                                                  },
                                                                ),
                                                            ],
                                                          ),
                                                          if (deliveryGuyPhone != null)
                                                            Padding(
                                                              padding: const EdgeInsets.only(left: 20, top: 2),
                                                              child: Text('Phone: $deliveryGuyPhone', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                                            ),
                                                         if (status.toLowerCase() == 'pending')
                                                           Padding(
                                                             padding: const EdgeInsets.only(top: 8.0),
                                                             child: ElevatedButton.icon(
                                                               icon: const Icon(Icons.assignment_turned_in, size: 16),
                                                               label: const Text('Assign to Driver', style: TextStyle(fontSize: 13)),
                                                               style: ElevatedButton.styleFrom(
                                                                 backgroundColor: Colors.blueAccent,
                                                                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                                 textStyle: const TextStyle(fontSize: 13),
                                                               ),
                                                               onPressed: () => _markAsAssignedToDriver(userId, tx, transactions),
                                                             ),
                                                           ),
                                                        ],
                                                      ] else ...[
                                                        const SizedBox(height: 8),
                                                        ElevatedButton.icon(
                                                          icon: const Icon(Icons.local_shipping, size: 16),
                                                          label: const Text('Choose Delivery Method', style: TextStyle(fontSize: 13)),
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: const Color(0xFF02C697),
                                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                            textStyle: const TextStyle(fontSize: 13),
                                                          ),
                                                          onPressed: () => _showDeliveryMethodDialog(context, tx, userId, transactions),
                                                        ),
                                                      ],
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
                        // Scroll indicators
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
                ],
              ),
            ),

            // My Harvest Listings Section (glassy green weather-style)
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0E5F3A), // dark green
                    Color(0xFF7FE9B5), // mint green
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.eco, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'My Harvest Listings',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('Harvests')
                          .doc(userId)
                          .get(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: CircularProgressIndicator(color: Colors.white),
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
                          itemCount: harvests.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = harvests[index];
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: BackdropFilter(
                                filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                child: InkWell(
                                  onTap: () => _showHarvestDetails(context, item),
                                  borderRadius: BorderRadius.circular(18),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(color: Colors.white.withOpacity(0.18), width: 1),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          blurRadius: 12,
                                          offset: const Offset(0, 6),
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
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white.withOpacity(0.14),
                                                    shape: BoxShape.circle,
                                                    border: Border.all(color: Colors.white.withOpacity(0.22)),
                                                  ),
                                                  child: const Icon(Icons.eco, color: Colors.white),
                                                ),
                                                const SizedBox(width: 12),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item['crop'] ?? 'Unknown Crop',
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.w700,
                                                        fontSize: 16,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'Quantity: ${item['quantity']} kg',
                                                      style: TextStyle(
                                                        color: Colors.white.withOpacity(0.85),
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                    Text(
                                                      'Price: LKR ${item['price']}/kg',
                                                      style: TextStyle(
                                                        color: Colors.white.withOpacity(0.85),
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.12),
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(color: Colors.white.withOpacity(0.22)),
                                              ),
                                              child: const Text(
                                                'Active',
                                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              '7-Day Weather Forecast',
                                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                                            ),
                                            const SizedBox(height: 12),
                                            SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              child: Row(
                                                children: List.generate(7, (index) {
                                                  final date = DateTime.now().add(Duration(days: index));
                                                  final weatherList = _weatherData[item['crop']] ?? [];
                                                  final dayData = index < weatherList.length ? weatherList[index] : null;

                                                  return Container(
                                                    margin: const EdgeInsets.only(right: 8),
                                                    child: Column(
                                                      children: [
                                                        ClipRRect(
                                                          borderRadius: BorderRadius.circular(12),
                                                          child: BackdropFilter(
                                                            filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                                            child: Container(
                                                              width: 44,
                                                              height: 44,
                                                              decoration: BoxDecoration(
                                                                color: (dayData != null ? Colors.greenAccent : Colors.white).withOpacity(0.16),
                                                                borderRadius: BorderRadius.circular(12),
                                                                border: Border.all(color: Colors.white.withOpacity(0.22)),
                                                              ),
                                                              child: Icon(
                                                                dayData != null ? _getWeatherIcon(dayData) : WeatherIcons.na,
                                                                size: 20,
                                                                color: Colors.white,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(height: 6),
                                                        Text(
                                                          _getShortDayName(date.weekday),
                                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.9)),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }),
                                              ),
                                            ),
                                            const SizedBox(height: 12),
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
                                                final bannerColor = (hasNonIdealDay ? Colors.orangeAccent : Colors.lightGreenAccent).withOpacity(0.16);
                                                return ClipRRect(
                                                  borderRadius: BorderRadius.circular(10),
                                                  child: BackdropFilter(
                                                    filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                      decoration: BoxDecoration(
                                                        color: bannerColor,
                                                        borderRadius: BorderRadius.circular(10),
                                                        border: Border.all(color: Colors.white.withOpacity(0.22)),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          Icon(hasNonIdealDay ? Icons.warning_amber : Icons.check_circle, size: 16, color: Colors.white),
                                                          const SizedBox(width: 8),
                                                          Text(
                                                            hasNonIdealDay ? "Check updated precautions" : "Perfect farming conditions",
                                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.95)),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
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
            const SizedBox(height: 24),
          ],
        ),
      ), // end SingleChildScrollView
          ), // end Positioned.fill (content)
        ],
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
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 400,
            maxHeight: 600, // Set a reasonable max height
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with crop name and icon
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF02C697).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.eco,
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
                              harvest['crop'] ?? 'Unknown Crop',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3748),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF02C697).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Active',
                                style: TextStyle(
                                  color: Color(0xFF02C697),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Details section
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
                    child: Column(
                      children: [
                        _buildDetailRow(
                          'Quantity',
                          '${harvest['quantity']} kg',
                          Icons.scale,
                        ),
                        const Divider(height: 16),
                        _buildDetailRow(
                          'Price',
                          'LKR ${harvest['price']}/kg',
                          Icons.attach_money,
                        ),
                        const Divider(height: 16),
                        _buildDetailRow(
                          'Planting Date',
                          harvest['plantingDate'] ?? 'Not set',
                          Icons.calendar_today,
                        ),
                        const Divider(height: 16),
                        _buildDetailRow(
                          'Harvest Date',
                          harvest['harvestDate'] ?? 'Not set',
                          Icons.event,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Weather forecast section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Weather Forecast',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 100, // Fixed height for weather section
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: 7,
                          itemBuilder: (context, index) {
                            final date = DateTime.now().add(Duration(days: index));
                            final weatherList = _weatherData[harvest['crop']] ?? [];
                            final dayData = index < weatherList.length ? weatherList[index] : null;
                            
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: Column(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
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
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      dayData != null 
                                        ? _getWeatherIcon(dayData)
                                        : WeatherIcons.na,
                                      size: 24,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getShortDayName(date.weekday),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF4A5568),
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
                  const SizedBox(height: 24),

                  // Precautions Section
                  if (harvest['precautions'] != null && harvest['precautions'].toString().isNotEmpty) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.warning_amber,
                                size: 20,
                                color: Colors.orange[700],
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Precautions',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3748),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.orange[200]!,
                            ),
                          ),
                          child: Text(
                            harvest['precautions'].toString(),
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: Colors.orange[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Disease Detection Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();
                        try {
                          final XFile? image = await picker.pickImage(
                            source: ImageSource.camera,
                            imageQuality: 80,
                          );
                          
                          if (image != null) {
                            // Here you would typically:
                            // 1. Upload the image
                            // 2. Call disease detection API
                            // 3. Show results
                            
                            // For now, show a placeholder message
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Image uploaded for disease detection. Analysis in progress...'),
                                  backgroundColor: Color(0xFF02C697),
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error capturing image: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF02C697),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(
                        Icons.camera_alt,
                        size: 20,
                      ),
                      label: const Text(
                        'Detect Disease',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF02C697).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 16,
            color: const Color(0xFF02C697),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF4A5568),
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF2D3748),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
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

  void _showDeliveryMethodDialog(BuildContext context, Map<String, dynamic> tx, String? userId, List<Map<String, dynamic>> transactions) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choose Delivery Method'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.person, size: 18),
                label: const Text('Deliver Myself'),
                onPressed: () async {
                  await _updateDeliveryMethod(userId, tx, transactions, 'self');
                  if (mounted) Navigator.pop(context);
                },
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.delivery_dining, size: 18),
                label: const Text('Assign to Delivery Guy'),
                onPressed: () async {
                  await _updateDeliveryMethod(userId, tx, transactions, 'delivery_guy');
                  if (mounted) Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateDeliveryMethod(String? userId, Map<String, dynamic> tx, List<Map<String, dynamic>> transactions, String method) async {
    if (userId == null) return;
    // Update the deliveryMethod in the selected transaction
    final updatedTx = Map<String, dynamic>.from(tx);
    updatedTx['deliveryMethod'] = method;
    // Replace the transaction in the array
    final updatedTransactions = transactions.map((t) => t == tx ? updatedTx : t).toList();
    await FirebaseFirestore.instance
        .collection('Ongoing_Trans_Farm')
        .doc(userId)
        .update({'transactions': updatedTransactions});
    setState(() {}); // Refresh UI
  }

  Future<void> _markAsAssigned(String? userId, Map<String, dynamic> tx, List<Map<String, dynamic>> transactions) async {
    if (userId == null) return;
    final updatedTx = Map<String, dynamic>.from(tx);
    updatedTx['Status'] = 'assigned';
    final updatedTransactions = transactions.map((t) => t == tx ? updatedTx : t).toList();
    await FirebaseFirestore.instance
        .collection('Ongoing_Trans_Farm')
        .doc(userId)
        .update({'transactions': updatedTransactions});
    setState(() {});
  }

  Future<void> _markAsAssignedToDriver(String? userId, Map<String, dynamic> tx, List<Map<String, dynamic>> transactions) async {
    if (userId == null) return;
    final updatedTxs = transactions.map((t) {
      if (t['Date'] == tx['Date'] && t['Customer ID'] == tx['Customer ID']) {
        final updated = Map<String, dynamic>.from(t);
        updated['Status'] = 'assigned';
        return updated;
      }
      return t;
    }).toList();
    await FirebaseFirestore.instance
        .collection('Ongoing_Trans_Farm')
        .doc(userId)
        .update({'transactions': updatedTxs});
    setState(() {});
  }

  Future<double?> _fetchDriverRating(String driverId) async {
    final doc = await FirebaseFirestore.instance.collection('DriverReviews').doc(driverId).get();
    if (!doc.exists || doc.data() == null || !(doc.data()!.containsKey('ratings'))) {
      return null;
    }
    final List<dynamic> ratings = doc['ratings'] ?? [];
    if (ratings.isEmpty) return null;
    double avg = ratings.map((r) => (r['rating'] ?? 0).toDouble()).fold(0.0, (a, b) => a + b) / ratings.length;
    return avg;
  }
}