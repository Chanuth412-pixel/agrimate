import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WeatherService {
  String get apiKey => dotenv.env['OPENWEATHER_API_KEY'] ?? '';
  final String baseUrl = 'https://api.openweathermap.org/data/2.5';

  Future<Map<String, dynamic>> get5DayForecast(double lat, double lon) async {
    if (apiKey.isEmpty) {
      throw Exception('OpenWeather API key not found in .env file');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/forecast?lat=$lat&lon=$lon&appid=$apiKey&units=metric'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load weather data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching weather data: $e');
    }
  }

  // Helper method to get weather icon based on condition
  String getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return 'wb_sunny'; // Clear sky
      case 'clouds':
        return 'cloud'; // Cloudy
      case 'rain':
        return 'umbrella'; // Rain
      case 'thunderstorm':
        return 'flash_on'; // Thunderstorm
      case 'snow':
        return 'ac_unit'; // Snow
      case 'mist':
      case 'fog':
        return 'cloud_queue'; // Mist/Fog
      default:
        return 'help_outline'; // Unknown
    }
  }

  // Helper method to determine weather suitability
  String getWeatherSuitability(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
      case 'clouds':
        return 'Ideal';
      case 'rain':
      case 'thunderstorm':
      case 'snow':
        return 'Non-Ideal';
      default:
        return 'Moderate';
    }
  }

  // Process 5-day forecast into 7-day forecast by extending last day's data
  List<Map<String, dynamic>> process7DayForecast(Map<String, dynamic> data) {
    List<Map<String, dynamic>> processedData = [];
    var list = data['list'] as List;
    
    // Get one forecast per day (at noon)
    var currentDate = DateTime.now();
    for (int day = 0; day < 7; day++) {
      var targetDate = currentDate.add(Duration(days: day));
      
      if (day < 5) {
        // For first 5 days, find the forecast closest to noon
        var dayForecasts = list.where((item) {
          var itemDate = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
          return itemDate.year == targetDate.year && 
                 itemDate.month == targetDate.month && 
                 itemDate.day == targetDate.day;
        }).toList();

        if (dayForecasts.isNotEmpty) {
          // Find forecast closest to noon
          var noonForecast = dayForecasts.reduce((a, b) {
            var aTime = DateTime.fromMillisecondsSinceEpoch(a['dt'] * 1000);
            var bTime = DateTime.fromMillisecondsSinceEpoch(b['dt'] * 1000);
            var noonDiff = (aTime.hour - 12).abs().compareTo((bTime.hour - 12).abs());
            return noonDiff <= 0 ? a : b;
          });

          processedData.add({
            'date': targetDate,
            'temp': noonForecast['main']['temp'],
            'condition': noonForecast['weather'][0]['main'],
            'description': noonForecast['weather'][0]['description'],
          });
        }
      } else {
        // For days 6 and 7, extend the last day's forecast
        var lastDayData = processedData.last;
        processedData.add({
          'date': targetDate,
          'temp': lastDayData['temp'],
          'condition': lastDayData['condition'],
          'description': lastDayData['description'],
        });
      }
    }

    return processedData;
  }
} 