import 'package:flutter/material.dart';

class WeatherForecastTile extends StatelessWidget {
  final String cropName;
  final List<String> weatherIcons;
  final List<String> weatherConditions;
  final List<String> temperatures;
  final String harvestDate;
  final String quantity;

  const WeatherForecastTile({
    Key? key,
    required this.cropName,
    required this.weatherIcons,
    required this.weatherConditions,
    required this.temperatures,
    required this.harvestDate,
    required this.quantity,
  }) : super(key: key);

  Color getWeatherColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
      case 'clouds':
        return Colors.green; // Ideal weather
      case 'rain':
      case 'thunderstorm':
      case 'snow':
        return Colors.red; // Non-ideal weather
      default:
        return Colors.yellow; // Moderate weather
    }
  }

  IconData getWeatherIconData(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'wb_sunny':
        return Icons.wb_sunny;
      case 'cloud':
        return Icons.cloud;
      case 'umbrella':
        return Icons.umbrella;
      case 'flash_on':
        return Icons.flash_on;
      case 'ac_unit':
        return Icons.ac_unit;
      case 'cloud_queue':
        return Icons.cloud_queue;
      case 'help_outline':
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Crop Info Section
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cropName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Harvest Date: $harvestDate',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                Text(
                  'Quantity: $quantity kg',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          
          // Weather Forecast Section
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '7-Day Weather Forecast',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(7, (index) {
                      // Safely get weather data or use defaults
                      final iconName = index < weatherIcons.length ? weatherIcons[index] : 'help_outline';
                      final condition = index < weatherConditions.length ? weatherConditions[index] : 'Unknown';
                      final temp = index < temperatures.length ? temperatures[index] : 'N/A';

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          children: [
                            Icon(
                              getWeatherIconData(iconName),
                              color: getWeatherColor(condition),
                              size: 32,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Day ${index + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              condition,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${temp}°C',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 