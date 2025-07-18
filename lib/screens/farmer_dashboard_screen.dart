import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/weather_service.dart';
import '../widgets/weather_forecast_tile.dart';

class FarmerDashboardScreen extends StatefulWidget {
  const FarmerDashboardScreen({super.key});

  @override
  State<FarmerDashboardScreen> createState() => _FarmerDashboardScreenState();
}

class _FarmerDashboardScreenState extends State<FarmerDashboardScreen> {
  final WeatherService _weatherService = WeatherService();
  final Map<String, List<Map<String, dynamic>>> _weatherData = {};

  @override
  void initState() {
    super.initState();
    _loadHarvestsAndWeather();
  }

  Future<void> _loadHarvestsAndWeather() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final harvests = await FirebaseFirestore.instance
          .collection('Ongoing_Trans_Far')
          .doc(userId)
          .get();

      if (!harvests.exists) return;

      final harvestData = harvests.data()?['transactions'] as List<dynamic>?;
      if (harvestData == null) return;

      for (var harvest in harvestData) {
        // Get weather data for each harvest
        try {
          final weatherForecast = await _weatherService.get5DayForecast(
            harvest['Location']['latitude'] ?? 0.0,
            harvest['Location']['longitude'] ?? 0.0,
          );

          final processedForecast = _weatherService.process7DayForecast(weatherForecast);
          
          setState(() {
            _weatherData[harvest['Transaction ID']] = processedForecast;
          });
        } catch (e) {
          print('Error fetching weather for harvest: $e');
        }
      }
    } catch (e) {
      print('Error loading harvests: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Harvests'),
        backgroundColor: const Color(0xFF02C697),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Ongoing_Trans_Far')
            .doc(userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.data() as Map<String, dynamic>?;
          if (data == null || !data.containsKey('transactions')) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.eco, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No harvests yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your first harvest to get started',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          final transactions = List<Map<String, dynamic>>.from(data['transactions']);

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final harvest = transactions[index];
              final weatherForHarvest = _weatherData[harvest['Transaction ID']] ?? [];

              if (weatherForHarvest.isEmpty) {
                return const SizedBox.shrink(); // Skip if no weather data
              }

              return WeatherForecastTile(
                cropName: harvest['Crop'] ?? 'Unknown Crop',
                harvestDate: harvest['Date'] != null
                    ? (harvest['Date'] as Timestamp).toDate().toString().split(' ')[0]
                    : 'No date',
                quantity: (harvest['Quantity Sold (1kg)'] ?? 0).toString(),
                weatherIcons: weatherForHarvest.map((day) => 
                  _weatherService.getWeatherIcon(day['condition'] as String)
                ).toList(),
                weatherConditions: weatherForHarvest.map((day) => 
                  day['condition'] as String
                ).toList(),
                temperatures: weatherForHarvest.map((day) => 
                  '${(day['temp'] as num).toStringAsFixed(1)}'
                ).toList(),
              );
            },
          );
        },
      ),
    );
  }
}
