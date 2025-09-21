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
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        // Glassy card effect
        color: Colors.white.withOpacity(0.18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          // Crop Info Section
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF66E6BE), Color(0xFF19A37C)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
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
                      style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Harvest Date: $harvestDate',
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.95)),
                    ),
                  ],
                ),
                Text(
                  'Quantity: $quantity kg',
                  style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          
          // Weather Forecast Section
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '7-Day Weather Forecast',
                  style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
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

                      final color = getWeatherColor(condition);
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        child: _ForecastPill(
                          dayLabel: 'Day ${index + 1}',
                          icon: getWeatherIconData(iconName),
                          accent: color,
                          condition: condition,
                          temp: temp,
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

class _ForecastPill extends StatelessWidget {
  final String dayLabel;
  final String condition;
  final String temp;
  final IconData icon;
  final Color accent;

  const _ForecastPill({
    required this.dayLabel,
    required this.condition,
    required this.temp,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.35)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            dayLabel,
            style: theme.textTheme.labelMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 2),
          Text(
            condition,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 2),
          Text(
            '$temp°C',
            style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}