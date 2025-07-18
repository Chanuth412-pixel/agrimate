import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

Future<List<LatLng>> fetchORSRoute(LatLng start, LatLng end, String apiKey) async {
  final url = Uri.parse('https://api.openrouteservice.org/v2/directions/driving-car');
  final body = jsonEncode({
    "coordinates": [
      [start.longitude, start.latitude],
      [end.longitude, end.latitude]
    ]
  });

  final response = await http.post(
    url,
    headers: {
      'Authorization': apiKey,
      'Content-Type': 'application/json',
    },
    body: body,
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final List<dynamic> coords = data['features'][0]['geometry']['coordinates'];
    return coords.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
  } else {
    throw Exception('Failed to fetch route: {response.body}');
  }
}
