import 'dart:math';
import '../models/health_status.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

class HealthSimulator {
  static const double minBPM = 60.0;
  static const double maxBPM = 120.0;
  static const double minSpO2 = 85.0;
  static const double maxSpO2 = 100.0;
  static const double minTemp = 35.0;
  static const double maxTemp = 39.5;
  static const double minSystolic = 90.0;
  static const double maxSystolic = 180.0;
  static const double minDiastolic = 60.0;
  static const double maxDiastolic = 120.0;

  final Random _random = Random();
  Map<String, HealthIndicatorData>? _lastData;

  HealthSimulator() {
    // Générer des données initiales
    _lastData = generateInitialData();
  }

  Map<String, HealthIndicatorData> generateInitialData() {
    // Générer des données réalistes mais aléatoires
    return {
      'bpm': _createIndicator(
        value: 70.0 + _random.nextDouble() * 20.0, // 70-90 BPM
        min: minBPM,
        max: maxBPM,
        label: 'BPM',
        unit: '',
      ),
      'spo2': _createIndicator(
        value: 96.0 + _random.nextDouble() * 3.0, // 96-99%
        min: minSpO2,
        max: maxSpO2,
        label: 'SpO2',
        unit: '%',
      ),
      'temperature': _createIndicator(
        value: 36.5 + _random.nextDouble() * 0.8, // 36.5-37.3°C
        min: minTemp,
        max: maxTemp,
        label: 'Temp',
        unit: '°C',
      ),
      'blood_pressure': _createBloodPressureIndicator(
        systolic: 115.0 + _random.nextDouble() * 10.0, // 115-125
        diastolic: 75.0 + _random.nextDouble() * 5.0, // 75-80
      ),
      'iqa': _createIndicator(
        value: 50.0 + _random.nextDouble() * 80.0, // 50-130 IQA
        min: 0,
        max: 200,
        label: 'IQA',
        unit: '',
      ),
    };
  }

  Map<String, HealthIndicatorData> generateNextData() {
    if (_lastData == null) return generateInitialData();

    final newData = <String, HealthIndicatorData>{};
    
    // Générer de nouvelles valeurs basées sur les précédentes
    newData['bpm'] = _updateIndicator(
      _lastData!['bpm']!,
      min: minBPM,
      max: maxBPM,
      maxChange: 5.0,
    );
    
    newData['spo2'] = _updateIndicator(
      _lastData!['spo2']!,
      min: minSpO2,
      max: maxSpO2,
      maxChange: 0.5,
    );
    
    newData['temperature'] = _updateIndicator(
      _lastData!['temperature']!,
      min: minTemp,
      max: maxTemp,
      maxChange: 0.1,
    );
    
    newData['iqa'] = _updateIndicator(
      _lastData!['iqa']!,
      min: 0,
      max: 200,
      maxChange: 5.0,
    );
    
    // Traitement spécial pour la tension artérielle
    final lastBP = _lastData!['blood_pressure']!;
    final lastSystolic = double.tryParse(lastBP.value.split('/')[0]) ?? 120.0;
    final lastDiastolic = double.tryParse(lastBP.value.split('/')[1]) ?? 80.0;
    
    final newSystolic = _getNewValue(
      lastSystolic,
      minSystolic,
      maxSystolic,
      maxChange: 3.0,
    );
    
    final newDiastolic = _getNewValue(
      lastDiastolic,
      minDiastolic,
      maxDiastolic,
      maxChange: 2.0,
    );
    
    newData['blood_pressure'] = _createBloodPressureIndicator(
      systolic: newSystolic,
      diastolic: newDiastolic,
    );
    
    _lastData = newData;
    return newData;
  }

  HealthIndicatorData _createIndicator({
    required double value,
    required double min,
    required double max,
    required String label,
    required String unit,
  }) {
    final clampedValue = value.clamp(min, max);
    return HealthIndicatorData(
      value: clampedValue.toStringAsFixed(unit == '' ? 0 : 1),
      status: _determineStatus(label, clampedValue),
      label: label,
      unit: unit,
      timestamp: DateTime.now(),
    );
  }

  HealthIndicatorData _createBloodPressureIndicator({
    required double systolic,
    required double diastolic,
  }) {
    final status = _determineBloodPressureStatus(systolic, diastolic);
    return HealthIndicatorData(
      value: '${systolic.toStringAsFixed(0)}/${diastolic.toStringAsFixed(0)}',
      status: status,
      label: 'Pression',
      unit: 'mmHg',
      timestamp: DateTime.now(),
    );
  }

  HealthIndicatorData _updateIndicator(
    HealthIndicatorData last, {
    required double min,
    required double max,
    required double maxChange,
  }) {
    final lastValue = double.tryParse(last.value) ?? min;
    final newValue = _getNewValue(lastValue, min, max, maxChange: maxChange);
    
    return last.copyWith(
      value: newValue.toStringAsFixed(last.unit == '' ? 0 : 1),
      status: _determineStatus(last.label, newValue, lastValue: lastValue),
      timestamp: DateTime.now(),
    );
  }

  double _getNewValue(
    double lastValue, 
    double min, 
    double max, {
    required double maxChange,
  }) {
    double change = (_random.nextDouble() * 2 - 1) * maxChange;
    return (lastValue + change).clamp(min, max);
  }

  HealthStatus _determineBloodPressureStatus(double systolic, double diastolic) {
    if (systolic >= 180 || diastolic >= 120) {
      return HealthStatus.critical;
    } else if (systolic >= 140 || diastolic >= 90) {
      return HealthStatus.danger;
    } else if (systolic >= 130 || diastolic >= 85) {
      return HealthStatus.warning;
    } else {
      return HealthStatus.good;
    }
  }

  HealthStatus _determineStatus(String label, double value, {double? lastValue}) {
    // Si une valeur précédente est fournie, limiter les changements brusques
    if (lastValue != null) {
      double change = (value - lastValue).abs();
      if (change > 5.0 && label == 'BPM') {
        value = lastValue + (value > lastValue ? 5.0 : -5.0);
      } else if (change > 1.0 && label == 'SpO2') {
        value = lastValue + (value > lastValue ? 1.0 : -1.0);
      } else if (change > 0.3 && label == 'Temp') {
        value = lastValue + (value > lastValue ? 0.3 : -0.3);
      }
    }

    // Déterminer le statut en fonction de la valeur
    switch (label) {
      case 'BPM':
        if (value < 50 || value > 120) return HealthStatus.critical;
        if (value < 60 || value > 100) return HealthStatus.danger;
        if (value < 65 || value > 90) return HealthStatus.warning;
        return HealthStatus.good;
        
      case 'SpO2':
        if (value < 85) return HealthStatus.critical;
        if (value < 90) return HealthStatus.danger;
        if (value < 95) return HealthStatus.warning;
        return HealthStatus.good;
        
      case 'Temp':
        if (value <= 35.0 || value >= 39.0) return HealthStatus.critical;
        if (value <= 35.5 || value >= 38.5) return HealthStatus.danger;
        if (value <= 36.0 || value >= 38.0) return HealthStatus.warning;
        return HealthStatus.good;
        
      case 'IQA':
        // 0-50: bon, 50-100: moyen, 100-150: mauvais, >150: très mauvais
        if (value >= 150) return HealthStatus.critical;
        if (value >= 100) return HealthStatus.danger;
        if (value >= 50) return HealthStatus.warning;
        return HealthStatus.good;
        
      default:
        return HealthStatus.good;
    }
  }
}
