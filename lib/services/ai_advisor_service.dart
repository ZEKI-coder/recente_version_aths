import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../models/health_status.dart';

class AIAdvisorService {
  static const String _apiKey = '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';
  static const String _apiUrl = 'https://openrouter.ai/api/v1/chat/completions';

  static Future<String> getEnvironmentalAdvice({
    required Map<String, HealthIndicatorData> airQualityIndicators,
    required int aqiIndex,
    required String userName,
  }) async {
    final prompt = '''
Tu es un assistant environnemental spécialisé dans la qualité de l'air et ses effets sur la santé respiratoire.
Fournis des conseils très concis et pratiques en 2 phrases courtes maximum. Sois informatif mais prudent.

DONNÉES ENVIRONNEMENTALES ACTUELLES:
- Indice AQI: $aqiIndex (${_getAQIDescription(aqiIndex)})
- Polluants dans l'air:
${airQualityIndicators.entries.map((entry) => '- ${entry.value.label}: ${entry.value.value} ${entry.value.unit}').join('\n')}

CONSEILS SPÉCIFIQUES:
- Si AQI ≥ 4 (rouge) : Évitez les activités extérieures, portez un masque
- Si AQI = 3 (orange) : Limitez les activités intenses, personnes sensibles restez à l'intérieur
- Si AQI ≤ 2 (vert) : Air de bonne qualité, activités normales possibles

Adapte tes conseils aux niveaux de polluants spécifiques (PM2.5, O3, NO2, CO) et à l'indice AQI global.
''';

    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'openai/gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'Tu es un assistant environnemental attentionné qui fournit des conseils sur la qualité de l\'air.',
            },
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.7,
          'max_tokens': 80,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].trim();
      } else {
        debugPrint('Erreur API: ${response.statusCode}');
        return 'Conseils environnementaux non disponibles.';
      }
    } catch (e) {
      debugPrint('Exception: $e');
      return 'Conseils environnementaux non disponibles.';
    }
  }

  static String _getAQIDescription(int aqi) {
    switch (aqi) {
      case 1:
        return 'Bonne';
      case 2:
        return 'Correcte';
      case 3:
        return 'Modérée';
      case 4:
        return 'Mauvaise';
      case 5:
        return 'Très mauvaise';
      default:
        return 'Inconnue';
    }
  }

  static Future<String> getHealthAdvice({
    required Map<String, HealthIndicatorData> healthIndicators,
    required String userName,
    String? currentActivity,
  }) async {
    try {
      final headers = {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      };

      String activityText = '';
      if (currentActivity != null && currentActivity.trim().isNotEmpty) {
        activityText = "\nActivité actuelle de l'utilisateur : $currentActivity.";
      }

      final prompt = '''
Tu es un assistant médical spécialisé dans les maladies respiratoires. 
Fournis des conseils personnalisés pour l'utilisateur $userName en fonction des indicateurs de santé suivants :

- IQA (Indice de Qualité de l'Air) : ${healthIndicators['iqa']?.value} (${_getStatusText(healthIndicators['iqa']?.status)})
- SpO2 (Saturation en oxygène) : ${healthIndicators['spo2']?.value}% (${_getStatusText(healthIndicators['spo2']?.status)})
- Pression artérielle : ${healthIndicators['blood_pressure']?.value} (${_getStatusText(healthIndicators['blood_pressure']?.status)})
- Fréquence cardiaque : ${healthIndicators['heart_rate']?.value ?? healthIndicators['bpm']?.value} BPM (${_getStatusText((healthIndicators['heart_rate'] ?? healthIndicators['bpm'])?.status)})
$activityText

Donne des conseils très concis et pratiques en 2 phrases courtes maximum. Sois rassurant mais précis. Si un indicateur est critique, mentionne-le clairement. Adapte les conseils à l'activité en cours si elle est fournie.

Conseils :''';

      final body = {
        'model': 'openai/gpt-3.5-turbo',
        'messages': [
          {
            'role': 'system',
            'content': 'Tu es un assistant médical attentionné et professionnel qui fournit des conseils de santé respiratoire.',
          },
          {'role': 'user', 'content': prompt}
        ],
        'temperature': 0.7,
        'max_tokens': 80,
      };

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].toString().trim();
      } else {
        debugPrint('Erreur API: ${response.statusCode} - ${response.body}');
        return 'Impossible de récupérer les conseils pour le moment. Veuillez réessayer plus tard.';
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'appel à l\'API: $e');
      return 'Erreur de connexion au service de conseils. Vérifiez votre connexion Internet.';
    }
  }

  static String _getStatusText(HealthStatus? status) {
    switch (status) {
      case HealthStatus.good:
        return 'Normal';
      case HealthStatus.warning:
        return 'Attention';
      case HealthStatus.danger:
        return 'Dangereux';
      case HealthStatus.critical:
        return 'Critique';
      default:
        return 'Inconnu';
    }
  }
}
