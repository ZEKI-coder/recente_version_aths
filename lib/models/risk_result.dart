// ============================================
// models/risk_result.dart
// ============================================
import 'health_data.dart';

class RiskResult {
  final String emoji;
  final String percentage;
  final int color;
  final RiskLevel level;

  RiskResult({
    required this.emoji,
    required this.percentage,
    required this.color,
    required this.level,
  });
}