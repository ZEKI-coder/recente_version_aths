import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

enum HealthStatus {
  good,      // Vert
  warning,   // Orange
  danger,    // Rouge
  critical,  // Rouge foncé
}

class HealthIndicatorData {
  final String value;
  final HealthStatus status;
  final String label;
  final String unit;
  final DateTime timestamp;

  HealthIndicatorData({
    required this.value,
    required this.status,
    required this.label,
    required this.unit,
    required this.timestamp,
  });

  // Méthode pour obtenir la couleur en fonction du statut
  Color get color {
    switch (status) {
      case HealthStatus.good:
        return Colors.green;
      case HealthStatus.warning:
        return Colors.orange;
      case HealthStatus.danger:
        return Colors.red[400]!;
      case HealthStatus.critical:
        return Colors.red[900]!;
    }
  }

  // Convertir depuis une Map (pour Firebase)
  factory HealthIndicatorData.fromMap(Map<String, dynamic> map, String indicatorId) {
    return HealthIndicatorData(
      value: map['value']?.toString() ?? 'N/A',
      status: HealthStatus.values[map['status'] is int ? map['status'] : 0],
      label: (map['label'] ?? indicatorId).toString(),
      unit: (map['unit'] ?? '').toString(),
      timestamp: (map['timestamp'] as firestore.Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Créer une copie avec des valeurs modifiées
  HealthIndicatorData copyWith({
    String? value,
    HealthStatus? status,
    String? label,
    String? unit,
    DateTime? timestamp,
  }) {
    return HealthIndicatorData(
      value: value ?? this.value,
      status: status ?? this.status,
      label: label ?? this.label,
      unit: unit ?? this.unit,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
