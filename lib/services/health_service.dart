import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/health_status.dart';

class HealthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;

  HealthService(this.userId);

  // Référence à la collection des indicateurs de santé de l'utilisateur
  CollectionReference get _healthIndicatorsRef =>
      _firestore.collection('users').doc(userId).collection('health_indicators');

  // Récupérer les données d'un indicateur en temps réel
  Stream<Map<String, HealthIndicatorData>> getHealthIndicatorsStream() {
    return _healthIndicatorsRef.snapshots().map((snapshot) {
      final indicators = <String, HealthIndicatorData>{};
      for (var doc in snapshot.docs) {
        indicators[doc.id] = HealthIndicatorData.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return indicators;
    });
  }

  // Mettre à jour un indicateur de santé
  Future<void> updateHealthIndicator(
    String indicatorId, {
    required String value,
    required HealthStatus status,
    String? label,
    String? unit,
  }) async {
    await _healthIndicatorsRef.doc(indicatorId).set({
      'value': value,
      'status': status.index,
      'label': label ?? indicatorId,
      'unit': unit ?? '',
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Méthode pour simuler des données de test
  static Map<String, HealthIndicatorData> getMockData() {
    return {
      'spo2': HealthIndicatorData(
        value: '92',  // Valeur légèrement basse pour montrer un avertissement (orange)
        status: HealthStatus.warning,
        label: 'SpO2',
        unit: '%',
        timestamp: DateTime.now(),
      ),
      'heart_rate': HealthIndicatorData(
        value: '112',  // Valeur élevée pour montrer un danger (rouge)
        status: HealthStatus.danger,
        label: 'BPM',
        unit: '',
        timestamp: DateTime.now(),
      ),
      'blood_pressure': HealthIndicatorData(
        value: '140/90',  // Valeur critique (rouge foncé)
        status: HealthStatus.critical,
        label: 'Pression',
        unit: 'mmHg',
        timestamp: DateTime.now(),
      ),
      'temperature': HealthIndicatorData(
        value: '36.8',  // Valeur normale (vert)
        status: HealthStatus.good,
        label: 'Temp',
        unit: '°C',
        timestamp: DateTime.now(),
      ),
      'iqa': HealthIndicatorData(
        value: 'Bonne',
        status: HealthStatus.good,
        label: 'IQA',
        unit: '',
        timestamp: DateTime.now(),
      ),
      'blood_pressure': HealthIndicatorData(
        value: '120/80',
        status: HealthStatus.good,
        label: 'Pression',
        unit: 'mmHg',
        timestamp: DateTime.now(),
      ),
    };
  }
}
