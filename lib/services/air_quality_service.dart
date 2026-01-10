import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AirQualityData {
  final double latitude;
  final double longitude;
  final int aqiIndex; // 1 (bon) à 5 (très mauvais) selon OpenWeatherMap
  final Map<String, dynamic> components; // Polluants détaillés

  AirQualityData({
    required this.latitude,
    required this.longitude,
    required this.aqiIndex,
    required this.components,
  });
}

class AirQualityService {
  // Clé fournie par l'utilisateur
  static const String _apiKey = 'b42604511ecc58d76bb8a2a284fb1012';
  static const String _baseUrl = 'http://api.openweathermap.org/data/2.5/air_pollution';

  static Future<AirQualityData?> fetchAirQuality({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl?lat=$latitude&lon=$longitude&appid=$_apiKey',
    );

    debugPrint('🌤️ Appel API: ${uri.toString()}');

    try {
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'AsthmaticApp/1.0',
        },
      ).timeout(const Duration(seconds: 15));
      
      debugPrint('🌤️ Status code: ${response.statusCode}');
      
      if (response.statusCode != 200) {
        debugPrint('🌤️ Erreur HTTP: ${response.statusCode}');
        debugPrint('🌤️ Response body: ${response.body}');
        return null;
      }

      final body = response.body;
      debugPrint('🌤️ Body: ${body.substring(0, body.length > 200 ? 200 : body.length)}...');

      final data = jsonDecode(body) as Map<String, dynamic>;
      final list = data['list'] as List<dynamic>?;
      if (list == null || list.isEmpty) {
        debugPrint('🌤️ Pas de données dans la réponse');
        return null;
      }

      final first = list.first as Map<String, dynamic>;
      final main = first['main'] as Map<String, dynamic>? ?? {};
      final components = first['components'] as Map<String, dynamic>? ?? {};

      final aqiIndex = (main['aqi'] as num?)?.toInt() ?? 1;
      
      debugPrint('🌤️ AQI reçu: $aqiIndex');
      debugPrint('🌤️ Composants: $components');

      return AirQualityData(
        latitude: latitude,
        longitude: longitude,
        aqiIndex: aqiIndex,
        components: components,
      );
    } on SocketException catch (e) {
      debugPrint('🌤️ Erreur réseau: ${e.message}');
      debugPrint('🌤️ Vérifie ta connexion internet ou essaie avec un VPN si nécessaire');
      return null;
    } on TimeoutException catch (e) {
      debugPrint('🌤️ Timeout: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('🌤️ Exception API: $e');
      debugPrint('🌤️ Type: ${e.runtimeType}');
      return null;
    }
  }
}
