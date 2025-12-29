import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/session_manager.dart';
import '../../services/health_service.dart';
import '../../services/health_simulator.dart';
import '../../models/health_status.dart';
import '../../models/health_record.dart';
import '../../services/ai_advisor_service.dart';
import 'map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  String? _currentActivity;  
  String? _userName = 'Utilisateur';
  bool _isLoading = true;
  String _aiAdvice = 'Analyse en cours...';
  Timer? _adviceTimer;
  
  // Suivi des enregistrements de santé
  List<HealthRecord> _healthHistory = [];
  Timer? _recordTimer;
  static const int _maxRecords = 100; 
  
  // Données des indicateurs de santé
  late final HealthService _healthService;
  late final HealthSimulator _healthSimulator;
  Map<String, HealthIndicatorData> _healthIndicators = {};
  StreamSubscription<Map<String, HealthIndicatorData>>? _healthSubscription;
  Timer? _simulationTimer;
  
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _selectedTabIndex = 0;
  
  @override
  void initState() {
    super.initState();
    _healthSimulator = HealthSimulator();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    
    _animation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _updateAnimation(72.0, 98.0); 
    _animationController.repeat(reverse: true);
    
    _loadUserData().then((_) {
      _startSimulation();
      _startAdviceUpdates();
    });
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    _healthSubscription?.cancel();
    _adviceTimer?.cancel();
    _recordTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getHealthScoreColor(double score) {
    if (score >= 75) return Colors.green;
    if (score >= 50) return Colors.orange;
    if (score >= 25) return Colors.orange[800]!;
    return Colors.red;
  }

  String _calculateTrend() {
    if (_healthHistory.length < 2) return '→ Stable';

    final last = _healthHistory.last.healthScore;
    final previous = _healthHistory[_healthHistory.length - 2].healthScore;
    final difference = last - previous;

    if (difference > 2) return '↑ En hausse';
    if (difference < -2) return '↓ En baisse';
    return '→ Stable';
  }

  Color _getTrendColor() {
    final trend = _calculateTrend();
    if (trend.contains('hausse')) return Colors.green;
    if (trend.contains('baisse')) return Colors.red;
    return Colors.blue;
  }

  void _showOtherActivityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Autre activité'),
        content: const Text('Fonctionnalité à implémenter'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildAssistantAdviceSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Conseils de l\'assistant',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _aiAdvice,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateAIAdvice() async {
    if (!mounted) return;
    
    try {
      final advice = await AIAdvisorService.getHealthAdvice(
        healthIndicators: _healthIndicators,
        userName: _userName ?? 'Utilisateur',
        currentActivity: _currentActivity,
      );
      
      if (mounted) {
        setState(() {
          _aiAdvice = advice;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour des conseils IA: $e');
      if (mounted) {
        setState(() {
          _aiAdvice = 'Conseils non disponibles pour le moment.';
        });
      }
    }
  }

  void _startAdviceUpdates() {
    _updateAIAdvice();
    
    _adviceTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateAIAdvice();
    });
    
    _startHealthRecording();
  }
  
  void _startHealthRecording() {
    _recordTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (!mounted) return;
      setState(() {
        _recordHealthData();
      });
    });
  }
  
  void _recordHealthData() {
    if (_healthIndicators.isEmpty) return;

    try {
      final healthScore = HealthRecord.calculateHealthScore(_healthIndicators);
      
      final indicatorsMap = {
        for (var entry in _healthIndicators.entries)
          entry.key: {
            'value': entry.value.value,
            'unit': entry.value.unit,
            'status': entry.value.status.toString(),
          }
      };
      
      final record = HealthRecord(
        timestamp: DateTime.now(),
        indicators: indicatorsMap,
        healthScore: healthScore,
      );
      
      _healthHistory.add(record);
      
      if (_healthHistory.length > _maxRecords) {
        _healthHistory.removeAt(0);
      }
      
      _saveHealthRecordToFirestore(record);
    } catch (e) {
      debugPrint('Erreur lors de l\'enregistrement des données de santé: $e');
    }
  }
  
  Future<void> _saveHealthRecordToFirestore(HealthRecord record) async {
    try {
      final userId = SessionManager.getUserId();
      if (userId == null) return;
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('health_records')
          .add(record.toMap());
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde des données de santé: $e');
    }
  }

  Future<void> _loadUserData() async {
    try {
      final userId = SessionManager.getUserId();
      if (userId == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
          
      if (userDoc.exists && mounted) {
        setState(() {
          final data = userDoc.data() as Map<String, dynamic>;
          _userName = data['prenom'] ?? data['name'] ?? 'Utilisateur';
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des données utilisateur: $e');
    }
  }

  void _startSimulation() async {
    try {
      final userId = SessionManager.getUserId();
      if (userId != null) {
        _healthService = HealthService(userId);
      } else {
        debugPrint("⚠️ Aucun utilisateur connecté, utilisation uniquement des données simulées");
      }

      _updateHealthData(_healthSimulator.generateInitialData());
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      
      _simulationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (mounted) {
          setState(() {
            _updateHealthData(_healthSimulator.generateNextData());
          });
        }
      });
      
      if (userId != null) {
        try {
          _healthSubscription = _healthService.getHealthIndicatorsStream().listen(
            (indicators) {
              if (mounted) {
                setState(() {
                  indicators.forEach((key, value) {
                    _healthIndicators[key] = value;
                  });
                  _updateAlertLevel();
                });
              }
            },
            onError: (error) {
              debugPrint("⚠️ Erreur de connexion Firebase: $error");
            },
            cancelOnError: true,
          );
        } catch (e) {
          debugPrint("⚠️ Erreur lors de l'écoute des mises à jour Firebase: $e");
        }
      }
    } catch (e) {
      debugPrint("❌ Erreur dans _startSimulation: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _updateAnimation(double heartRate, double spo2) {
    double speedFactor = (heartRate / 60).clamp(0.5, 2.0);
    
    double spo2Factor = (100 - spo2) / 10; 
    double amplitude = 0.1 + (spo2Factor * 0.05); 
    
    _animationController.duration = Duration(milliseconds: (2000 / speedFactor).round());
    
    _animation = Tween<double>(
      begin: 1.0 - amplitude,
      end: 1.0 + amplitude,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  void _updateHealthData(Map<String, HealthIndicatorData> newData) {
    if (!mounted) return;
    
    setState(() {
      _healthIndicators = newData;
      _isLoading = false;
      
      final heartRate = double.tryParse(
            (newData['bpm']?.value ?? newData['heart_rate']?.value ?? '0').toString(),
          ) ?? 0;
      final spo2 = double.tryParse(newData['spo2']?.value.toString() ?? '0') ?? 0;
      _updateAnimation(heartRate, spo2);
      
      _updateAlertLevel();
      
      _updateActivityBasedOnData(newData);
      
      _recordHealthData();
    });
  }

  void _updateAlertLevel() {
    int maxAlertLevel = 0;
    
    _healthIndicators.forEach((key, indicator) {
      switch (indicator.status) {
        case HealthStatus.critical:
          maxAlertLevel = max(maxAlertLevel, 3);
          break;
        case HealthStatus.danger:
          maxAlertLevel = max(maxAlertLevel, 2);
          break;
        case HealthStatus.warning:
          maxAlertLevel = max(maxAlertLevel, 1);
          break;
        case HealthStatus.good:
          break;
      }
    });
    
    if (mounted) {
      setState(() {
        // _alertLevel = maxAlertLevel; 
      });
    }
  }

  void _updateActivityBasedOnData(Map<String, HealthIndicatorData> data) {
    final heartRate = double.tryParse(
          (data['bpm']?.value ?? data['heart_rate']?.value ?? '0').toString(),
        ) ?? 0;
    if (heartRate > 120) {
      _setActivityFromData('En course');
    } else {
      _setActivityFromData(null);
    }
  }

  void _setActivityFromUser(String label) {
    setState(() {
      _currentActivity = _currentActivity == label ? null : label;
    });
  }

  void _setActivityFromData(String? activity) {
    if (_currentActivity != null) return;
    setState(() {
      _currentActivity = activity;
    });
  }

  Widget _buildHealthIndicators() {
    if (_healthIndicators.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: _healthIndicators.entries.map((entry) {
        return _buildHealthIndicator(entry.key, entry.value);
      }).toList(),
    );
  }

  Widget _buildHealthIndicator(String title, HealthIndicatorData data, {Color? color}) {
    final indicatorColor = color ?? data.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: indicatorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: indicatorColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            '${data.value}${data.unit.isNotEmpty ? ' ${data.unit}' : ''}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: indicatorColor,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: indicatorColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyTrackingSection() {
    if (_healthHistory.isEmpty) {
      return Card(
        margin: const EdgeInsets.all(16),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text('Collecte des données en cours...'),
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Évolution de votre santé respiratoire',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Dernière mise à jour: ${_formatTime(_healthHistory.last.timestamp)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < _healthHistory.length && index % 6 == 0) {
                            return Text(_formatTime(_healthHistory[index].timestamp));
                          }
                          return const Text('');
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value % 25 == 0) {
                            return Text('${value.toInt()}%');
                          }
                          return const Text('');
                        },
                        reservedSize: 40,
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.withValues(alpha: 0.3)!)),
                  minX: 0,
                  maxX: _healthHistory.isNotEmpty ? _healthHistory.length - 1 : 1,
                  minY: 0,
                  maxY: 100,
                  lineBarsData: [
                    LineChartBarData(
                      spots: _healthHistory.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          entry.value.healthScore,
                        );
                      }).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem('Score actuel', '${_healthHistory.last.healthScore.toStringAsFixed(0)}%',
                    _getHealthScoreColor(_healthHistory.last.healthScore)),
                _buildStatItem('Tendance', _calculateTrend(), _getTrendColor()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssociateDoctorButton() {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.medical_services),
      label: const Text('Associer un médecin'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }

  Widget _buildActivityButton(String label, IconData icon) {
    final isActive = _currentActivity == label;
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: isActive ? Colors.blue[100] : Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, color: isActive ? Colors.blue : Colors.grey[700]),
            onPressed: () => _setActivityFromUser(label),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.blue : Colors.grey[700],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildLungAnimation() {
    final spo2Data = _healthIndicators['spo2'] ?? 
        HealthIndicatorData(
          value: '98',
          status: HealthStatus.good,
          label: 'SpO2',
          unit: '%',
          timestamp: DateTime.now(),
        );

    final bpmData = _healthIndicators['bpm'] ??
        _healthIndicators['heart_rate'] ??
        HealthIndicatorData(
          value: '72',
          status: HealthStatus.good,
          label: 'BPM',
          unit: '',
          timestamp: DateTime.now(),
        );

    final pressureData = _healthIndicators['blood_pressure'] ??
        HealthIndicatorData(
          value: '120/80',
          status: HealthStatus.good,
          label: 'Pression',
          unit: 'mmHg',
          timestamp: DateTime.now(),
        );

    final iqaData = _healthIndicators['iqa'] ??
        HealthIndicatorData(
          value: '75',
          status: HealthStatus.good,
          label: 'IQA',
          unit: '',
          timestamp: DateTime.now(),
        );

    if (!_animationController.isAnimating) {
      _animation = Tween<double>(
        begin: 0.95,
        end: 1.05,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ));
      _animationController.repeat(reverse: true);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(right: 40),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            margin: const EdgeInsets.only(top: 20, bottom: 40, left: 40),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.withValues(alpha: 0.1),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.2),
                  blurRadius: 15,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: ScaleTransition(
                scale: _animation,
                child: Image.asset(
                  'assets/animations/Poumons.gif',
                  width: 160,
                  height: 160,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          
          // Indicateur SpO2 en haut
          Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: Center(
              child: _buildHealthIndicator('SpO2', spo2Data, color: Colors.green),
            ),
          ),
          
          // Indicateur BPM à droite
          Positioned(
            right: 10,
            top: 0,
            bottom: 0,
            child: Center(
              child: _buildHealthIndicator('BPM', bpmData, color: Colors.red),
            ),
          ),
          
          // Indicateur Pression à gauche
          Positioned(
            left: 10,
            top: 0,
            bottom: 0,
            child: Center(
              child: _buildHealthIndicator('Pression', pressureData, color: Colors.purple),
            ),
          ),
          
          // Indicateur IQA en bas
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Center(
              child: _buildHealthIndicator('IQA', iqaData, color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Onglet "Carte"
    if (_selectedTabIndex == 1) {
      return MapScreen(healthIndicators: _healthIndicators);
    }

    // Onglet "Connexion" (placeholder pour le moment)
    if (_selectedTabIndex == 2) {
      return const Center(
        child: Text('Espace connexion à venir'),
      );
    }

    // Onglet "Accueil" (comportement existant)
    if (_healthIndicators.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              'Impossible de charger les données de santé',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Utilisation des données simulées',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _startSimulation,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Animation des poumons
          _buildLungAnimation(),
          
          const SizedBox(height: 20),
          
          // Section des activités
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Votre activité actuelle ?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildActivityButton(
                        'Dormir',
                        Icons.nightlight_round,
                      ),
                      _buildActivityButton(
                        'Marche',
                        Icons.directions_walk,
                      ),
                      _buildActivityButton(
                        'Course',
                        Icons.directions_run,
                      ),
                      _buildActivityButton(
                        'Autre',
                        Icons.add_circle_outline,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Section des conseils de l'assistant
          _buildAssistantAdviceSection(),
          
          const SizedBox(height: 20),
          
          // Section de suivi quotidien
          _buildDailyTrackingSection(),
          
          const SizedBox(height: 20),
          
          // Bouton pour associer un médecin
          Center(child: _buildAssociateDoctorButton()),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.person),
        title: Text('Bonjour, ${_userName ?? 'Utilisateur'}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              // Menu latéral ou options à venir
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTabIndex,
        onTap: (index) {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Carte',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services),
            label: 'Connexion',
          ),
        ],
      ),
      body: _buildCurrentBody(),
    );
  }
}