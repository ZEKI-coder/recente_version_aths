import 'dart:ui';
import '../models/health_data.dart';
import '../models/risk_result.dart';

class RiskCalculator {
  static RiskResult calculate({
    required int heartRate,
    required int spo2,
    required int aqi,
    int? age,
    bool hasConditions = false,
  }) {
    double riskScore = 0.0;

    // 1. Évaluation de la fréquence cardiaque (0-30 points)
    riskScore += _evaluateHeartRate(heartRate);

    // 2. Évaluation de la saturation en oxygène (0-35 points)
    riskScore += _evaluateSpo2(spo2);

    // 3. Évaluation de la qualité de l'air (0-25 points)
    riskScore += _evaluateAqi(aqi);

    // 4. Facteurs supplémentaires (0-10 points)
    if (age != null) {
      riskScore += _evaluateAge(age);
    }
    if (hasConditions) {
      riskScore += 5;
    }

    // Normaliser le score sur 100
    final normalizedScore = (riskScore * 100 / 100).clamp(0.0, 100.0);

    return _createResult(normalizedScore);
  }

  static double _evaluateHeartRate(int heartRate) {
    if (heartRate < 60) return 15.0; // Bradycardie
    if (heartRate >= 60 && heartRate <= 100) return 0.0; // Normal
    if (heartRate >= 101 && heartRate <= 120) return 10.0; // Tachycardie légère
    if (heartRate >= 121 && heartRate <= 150) return 20.0; // Tachycardie modérée
    return 30.0; // Tachycardie sévère
  }

  static double _evaluateSpo2(int spo2) {
    if (spo2 >= 95) return 0.0; // Normal
    if (spo2 >= 90 && spo2 <= 94) return 15.0; // Hypoxémie légère
    if (spo2 >= 85 && spo2 <= 89) return 25.0; // Hypoxémie modérée
    return 35.0; // Hypoxémie sévère
  }

  static double _evaluateAqi(int aqi) {
    if (aqi <= 50) return 0.0; // Bon
    if (aqi >= 51 && aqi <= 100) return 5.0; // Modéré
    if (aqi >= 101 && aqi <= 150) return 10.0; // Mauvais pour groupes sensibles
    if (aqi >= 151 && aqi <= 200) return 15.0; // Mauvais
    if (aqi >= 201 && aqi <= 300) return 20.0; // Très mauvais
    return 25.0; // Dangereux
  }

  static double _evaluateAge(int age) {
    if (age < 40) return 0.0;
    if (age >= 40 && age <= 60) return 2.0;
    if (age >= 61 && age <= 75) return 4.0;
    return 5.0;
  }

  static RiskResult _createResult(double score) {
    if (score < 25) {
      return RiskResult(
        emoji: '✅',
        percentage: '${score.toInt()}%',
        color: 0xFF4CAF50, // Vert
        level: RiskLevel.faible,
      );
    } else if (score < 50) {
      return RiskResult(
        emoji: '⚠️',
        percentage: '${score.toInt()}%',
        color: 0xFFFF9800, // Orange
        level: RiskLevel.modere,
      );
    } else if (score < 75) {
      return RiskResult(
        emoji: '🔴',
        percentage: '${score.toInt()}%',
        color: 0xFFFF5722, // Rouge-orange
        level: RiskLevel.eleve,
      );
    } else {
      return RiskResult(
        emoji: '🚨',
        percentage: '${score.toInt()}%',
        color: 0xFFD32F2F, // Rouge foncé
        level: RiskLevel.tresEleve,
      );
    }
  }
}