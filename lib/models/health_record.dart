import 'package:cloud_firestore/cloud_firestore.dart';
import 'health_status.dart';

class HealthRecord {
  final DateTime timestamp;
  final Map<String, dynamic> indicators;
  final double healthScore;

  HealthRecord({
    required this.timestamp,
    required this.indicators,
    required this.healthScore,
  });

  Map<String, dynamic> toMap() {
    return {
      'timestamp': Timestamp.fromDate(timestamp),
      'indicators': indicators,
      'healthScore': healthScore,
    };
  }

  factory HealthRecord.fromMap(Map<String, dynamic> map) {
    return HealthRecord(
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      indicators: Map<String, dynamic>.from(map['indicators']),
      healthScore: (map['healthScore'] as num).toDouble(),
    );
  }

  // Calcule un score de santé global basé sur tous les indicateurs
  // Utilise un Map non typé pour pouvoir accepter
  // Map<String, HealthIndicatorData>, Map<String, dynamic>, etc.
  static double calculateHealthScore(Map indicators) {
    // Poids pour chaque indicateur (ajustez selon l'importance)
    const weights = {
      'spo2': 0.4,    // Très important pour la santé respiratoire
      'iqa': 0.3,     // Important pour la qualité de l'air
      'bpm': 0.2,     // Important pour l'effort respiratoire
      'pressure': 0.1 // Moins directement lié mais pertinent
    };

    // Normalise chaque indicateur entre 0 et 1
    final normalized = {
      // SpO2 en %
      'spo2': _normalize(
        _getNumericIndicatorValue(indicators['spo2']),
        70,
        100,
      ),
      // IQA de 0 à 200+
      'iqa': _normalize(
        _getNumericIndicatorValue(indicators['iqa']),
        0,
        200,
      ),
      // BPM inverse (plus bas = mieux) – on accepte 'bpm' ou 'heart_rate'
      'bpm': 1.0 - _normalize(
        _getNumericIndicatorValue(
          indicators['bpm'] ?? indicators['heart_rate'],
        ),
        50,
        150,
      ),
      // Pression artérielle – on accepte 'blood_pressure' ou 'pressure'
      'pressure': _calculatePressureScore(
        _getPressureValue(
          indicators['blood_pressure'] ?? indicators['pressure'],
        ),
      ),
    };

    // Calcule le score global pondéré
    double score = 0.0;
    weights.forEach((key, weight) {
      score += (normalized[key] ?? 0) * weight;
    });

    return score.clamp(0.0, 1.0) * 100; // Retourne un pourcentage
  }

  static double _normalize(double value, double min, double max) {
    return ((value - min) / (max - min)).clamp(0.0, 1.0);
  }

  /// Récupère une valeur numérique à partir d'un indicateur pouvant être de
  /// différents types (HealthIndicatorData, Map, String, etc.).
  static double _getNumericIndicatorValue(dynamic indicator) {
    if (indicator == null) return 0.0;

    if (indicator is HealthIndicatorData) {
      return double.tryParse(indicator.value.toString()) ?? 0.0;
    }

    if (indicator is Map<String, dynamic>) {
      return double.tryParse(indicator['value']?.toString() ?? '0') ?? 0.0;
    }

    // Dernier recours : tenter de parser directement
    return double.tryParse(indicator.toString()) ?? 0.0;
  }

  /// Récupère la valeur de pression sous forme de chaîne "systolique/diastolique".
  static String _getPressureValue(dynamic indicator) {
    if (indicator == null) return '120/80';

    if (indicator is HealthIndicatorData) {
      return indicator.value.toString();
    }

    if (indicator is Map<String, dynamic>) {
      return indicator['value']?.toString() ?? '120/80';
    }

    return indicator.toString();
  }

  static double _calculatePressureScore(String pressure) {
    try {
      final parts = pressure.split('/');
      if (parts.length != 2) return 0.5;
      
      final systolic = double.tryParse(parts[0]) ?? 120;
      final diastolic = double.tryParse(parts[1]) ?? 80;
      
      // Score basé sur la pression artérielle (meilleur pour des valeurs normales)
      if (systolic < 90 || diastolic < 60) return 0.6; // Hypotension
      if (systolic < 120 && diastolic < 80) return 1.0; // Normal
      if (systolic < 140 && diastolic < 90) return 0.8; // Préhypertension
      if (systolic < 160 || diastolic < 100) return 0.5; // Hypertension stade 1
      return 0.3; // Hypertension stade 2 ou plus
    } catch (e) {
      return 0.5; // Valeur par défaut en cas d'erreur
    }
  }
}
