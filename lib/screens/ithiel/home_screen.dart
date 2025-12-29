import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../services/session_manager.dart';
import '../../services/database_service.dart';
import '../../services/health_service.dart';
import '../../services/health_simulator.dart';
import '../../models/health_status.dart';
import '../../models/health_record.dart';
import '../../models/user.dart' as user_model;
import '../../services/ai_advisor_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  String? _currentActivity;  // Pour suivre l'activité actuelle
  String? _userName = 'Utilisateur';
  bool _isLoading = true;
  String _aiAdvice = 'Analyse en cours...';
  Timer? _adviceTimer;
  
  // Suivi des enregistrements de santé
  List<HealthRecord> _healthHistory = [];
  Timer? _recordTimer;
  static const int _maxRecords = 100; // Nombre maximum d'enregistrements à conserver
  
  // Données des indicateurs de santé
  late final HealthService _healthService;
  late final HealthSimulator _healthSimulator;
  Map<String, HealthIndicatorData> _healthIndicators = {};
  StreamSubscription<Map<String, HealthIndicatorData>>? _healthSubscription;
  Timer? _simulationTimer;
  
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _alertLevel = 0;
  int _selectedTabIndex = 0;
  
  @override
  void initState() {
    super.initState();
    _healthSimulator = HealthSimulator();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    
    // Initialiser l'animation avec des valeurs par défaut
    _animation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _updateAnimation(72.0, 98.0); // Valeurs par défaut
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

  // Formatage de l'heure pour l'affichage des horodatages
  String _formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  // Construction d'un élément de statistique dans la section de suivi quotidien
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

  // Détermine la couleur du score de santé global
  Color _getHealthScoreColor(double score) {
    if (score >= 75) return Colors.green;
    if (score >= 50) return Colors.orange;
    if (score >= 25) return Colors.orange[800]!;
    return Colors.red;
  }

  // Calcule la tendance du score de santé par rapport au dernier enregistrement
  String _calculateTrend() {
    if (_healthHistory.length < 2) return '→ Stable';

    final last = _healthHistory.last.healthScore;
    final previous = _healthHistory[_healthHistory.length - 2].healthScore;
    final difference = last - previous;

    if (difference > 2) return '↑ En hausse';
    if (difference < -2) return '↓ En baisse';
    return '→ Stable';
  }

  // Couleur associée à la tendance
  Color _getTrendColor() {
    final trend = _calculateTrend();
    if (trend.contains('hausse')) return Colors.green;
    if (trend.contains('baisse')) return Colors.red;
    return Colors.blue;
  }

  // Boîte de dialogue pour sélectionner une autre activité
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

  // Section d'affichage des conseils de l'assistant IA
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
    // Mettre à jour les conseils immédiatement
    _updateAIAdvice();
    
    // Puis toutes les 1 minute
    _adviceTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateAIAdvice();
    });
    
    // Démarrer l'enregistrement périodique des données
    _startHealthRecording();
  }
  
  void _startHealthRecording() {
    // Enregistrer périodiquement toutes les 5 minutes (la première donnée
    // est déjà enregistrée lors de la première mise à jour _updateHealthData)
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
      
      // Convertir les indicateurs en format sérialisable
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
      
      // Ajouter à l'historique (sans setState ici pour éviter les setState imbriqués).
      // Les appels qui ont besoin de rafraîchir l'UI entourent cette méthode avec setState.
      _healthHistory.add(record);
      
      // Limiter la taille de l'historique
      if (_healthHistory.length > _maxRecords) {
        _healthHistory.removeAt(0);
      }
      
      // Sauvegarder dans Firestore (optionnel)
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

      // Récupérer les données utilisateur depuis Firestore directement
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
      print('Erreur lors du chargement des données utilisateur: $e');
    }
  }

  void _startSimulation() async {
    try {
      final userId = SessionManager.getUserId();
      if (userId != null) {
        _healthService = HealthService(userId);
      } else {
        print("⚠️ Aucun utilisateur connecté, utilisation uniquement des données simulées");
      }

      // Initialiser avec des données de simulation (toujours, même sans utilisateur)
      _updateHealthData(_healthSimulator.generateInitialData());
      
      if (mounted) {
        setState(() {
          _isLoading = false; // Arrêter le chargement après l'initialisation
        });
      }
      
      // Démarrer la simulation locale
      _simulationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (mounted) {
          setState(() {
            _updateHealthData(_healthSimulator.generateNextData());
          });
        }
      });
      
      // Si un utilisateur est connecté, essayer de se connecter à Firebase pour des données réelles
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
              print("⚠️ Erreur de connexion Firebase: $error");
              // Continuer avec les données simulées en cas d'erreur
            },
            cancelOnError: true,
          );
        } catch (e) {
          print("⚠️ Erreur lors de l'écoute des mises à jour Firebase: $e");
          // Continuer avec les données simulées
        }
      }
    } catch (e) {
      print("❌ Erreur dans _startSimulation: $e");
      if (mounted) {
        setState(() {
          _isLoading = false; // S'assurer que le chargement s'arrête en cas d'erreur
        });
      }
    }
  }
  
  void _updateAnimation(double heartRate, double spo2) {
    // Ajuster la vitesse en fonction de la fréquence cardiaque
    // Plus la fréquence est élevée, plus l'animation est rapide
    double speedFactor = (heartRate / 60).clamp(0.5, 2.0);
    
    // Ajuster l'amplitude en fonction de la saturation en oxygène
    // Moins il y a d'oxygène, plus l'amplitude est grande
    double spo2Factor = (100 - spo2) / 10; // 0 à 1.5 (pour 85-100% SpO2)
    double amplitude = 0.1 + (spo2Factor * 0.05); // 0.1 à 0.175
    
    // Mettre à jour la durée de l'animation
    _animationController.duration = Duration(milliseconds: (2000 / speedFactor).round());
    
    // Mettre à jour l'échelle de l'animation
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
      
      // Mettre à jour l'animation en fonction des nouvelles données
      final heartRate = double.tryParse(
            (newData['bpm']?.value ?? newData['heart_rate']?.value ?? '0').toString(),
          ) ?? 0;
      final spo2 = double.tryParse(newData['spo2']?.value.toString() ?? '0') ?? 0;
      _updateAnimation(heartRate, spo2);
      
      // Mettre à jour le niveau d'alerte
      _updateAlertLevel();
      
      // Mettre à jour l'activité en fonction des données
      _updateActivityBasedOnData(newData);
      
      // Enregistrer les données de santé à chaque mise à jour pour alimenter la courbe
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
        _alertLevel = maxAlertLevel;
      });
    }
  }

  void _updateActivityBasedOnData(Map<String, HealthIndicatorData> data) {
    // Mettre à jour l'activité en fonction des données
    // Exemple : si la fréquence cardiaque est élevée, considérer que l'utilisateur est en train de faire du sport
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
        color: indicatorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: indicatorColor.withOpacity(0.3)),
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
                  gridData: FlGridData(show: true),
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
                  borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey[300]!)),
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
                        color: Colors.blue.withOpacity(0.1),
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
      onPressed: () {
        // Logique pour associer un médecin
      },
      icon: Icon(Icons.medical_services),
      label: Text('Associer un médecin'),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }

  // Méthode pour construire un bouton d'activité
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
    // Vérifier si les indicateurs sont chargés
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

    // Initialiser l'animation si ce n'est pas déjà fait
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
          // Animation des poumons
          Container(
            width: 200,
            height: 200,
            margin: const EdgeInsets.only(top: 20, bottom: 40, left: 40),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[100],
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.2),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _healthIndicators.isEmpty
              ? Center(
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
                )
              : SingleChildScrollView(
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
                ),
    );
  }
}