
// ============================================
// models/health_data.dart
// ============================================
enum RiskLevel {
  faible,
  modere,
  eleve,
  tresEleve;

  String get displayName {
    switch (this) {
      case RiskLevel.faible:
        return 'Faible';
      case RiskLevel.modere:
        return 'Modéré';
      case RiskLevel.eleve:
        return 'Élevé';
      case RiskLevel.tresEleve:
        return 'Très Élevé';
    }
  }
}

class HealthData {
  final String? id;
  final String userId;
  final int heartRate;
  final int spo2;
  final int aqi;
  final double riskScore;
  final RiskLevel riskLevel;
  final int timestamp;

  HealthData({
    this.id,
    required this.userId,
    required this.heartRate,
    required this.spo2,
    required this.aqi,
    required this.riskScore,
    required this.riskLevel,
    int? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'heartRate': heartRate,
      'spo2': spo2,
      'aqi': aqi,
      'riskScore': riskScore,
      'riskLevel': riskLevel.name,
      'timestamp': timestamp,
    };
  }

  factory HealthData.fromMap(Map<String, dynamic> map) {
    return HealthData(
      id: map['id'] as String?,
      userId: map['userId'] as String,
      heartRate: map['heartRate'] as int,
      spo2: map['spo2'] as int,
      aqi: map['aqi'] as int,
      riskScore: (map['riskScore'] as num).toDouble(),
      riskLevel: RiskLevel.values.firstWhere(
            (e) => e.name == map['riskLevel'],
        orElse: () => RiskLevel.faible,
      ),
      timestamp: map['timestamp'] as int,
    );
  }

  DateTime get date => DateTime.fromMillisecondsSinceEpoch(timestamp);
}