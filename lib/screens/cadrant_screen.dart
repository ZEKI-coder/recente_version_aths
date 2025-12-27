import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/session_manager.dart';
import '../models/user.dart' hide HealthData;
import '../models/health_data.dart';
import '../utils/risk_calculator.dart';
import 'login_screen.dart';

class CadrantScreen extends StatefulWidget {
  const CadrantScreen({Key? key}) : super(key: key);

  @override
  State<CadrantScreen> createState() => _CadrantScreenState();
}

class _CadrantScreenState extends State<CadrantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _heartRateController = TextEditingController();
  final _spo2Controller = TextEditingController();
  final _aqiController = TextEditingController();
  final _bloodPressureController = TextEditingController();

  User? _currentUser;
  bool _isAsthmatic = false;
  String _riskEmoji = '';
  String _riskPercentage = '';
  Color _riskColor = Colors.grey;
  bool _showResult = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userId = await SessionManager.getUserId();
      if (userId == null) {
        _navigateToLogin();
        return;
      }

      final user = await DatabaseService.instance.getUserById(userId);
      if (user != null) {
        setState(() {
          _currentUser = user as User?;
          _isAsthmatic = user.hasConditions;
        });
      }
    } catch (e) {
      print('Erreur de chargement: $e');
    }
  }

  Future<void> _calculateRisk() async {
    if (!_formKey.currentState!.validate()) return;

    final heartRate = int.tryParse(_heartRateController.text);
    final spo2 = int.tryParse(_spo2Controller.text);
    final aqi = int.tryParse(_aqiController.text);

    if (heartRate == null || spo2 == null || aqi == null) {
      setState(() {
        _riskEmoji = '⚠️';
        _riskPercentage = 'Données incomplètes';
        _riskColor = Colors.orange;
        _showResult = true;
      });
      return;
    }

    // Calcul du risque
    final result = RiskCalculator.calculate(
      heartRate: heartRate,
      spo2: spo2,
      aqi: aqi,
      age: _currentUser?.age,
      hasConditions: _isAsthmatic,
    );

    setState(() {
      _riskEmoji = result.emoji;
      _riskPercentage = result.percentage;
      _riskColor = Color(result.color);
      _showResult = true;
    });

    // Sauvegarder dans la base de données
    await _saveHealthData(heartRate, spo2, aqi, result, _currentUser);

    // Animation de feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Données enregistrées avec succès'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveHealthData(
      int heartRate,
      int spo2,
      int aqi,
      dynamic result,
      dynamic user,
      ) async {
    try {
      final userId = await SessionManager.getUserId();
      if (userId == null) return;

      final healthData = HealthData(
        userId: user.id,
        heartRate: heartRate,
        spo2: spo2,
        aqi: aqi,
        riskScore: double.parse(result.percentage.replaceAll('%', '')),
        riskLevel: result.level,
      );

      await DatabaseService.instance.insertHealthData(healthData);
    } catch (e) {
      print('Erreur de sauvegarde: $e');
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await SessionManager.logout();
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3730A3),
        elevation: 0,
        title: Text(
          _currentUser != null
              ? 'Bonjour ${_currentUser!.prenom}'
              : 'ASTHMATIC',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Historique - À venir')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Carte principale
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      // Icône coeur
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3730A3).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: Color(0xFF3730A3),
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Titre
                      const Text(
                        'ASTHMATIC',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Sous-titre
                      const Text(
                        'Suivi respiratoire intelligent',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFF3730A3),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Toggle Asthmatique
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Personne asthmatique ?',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Switch(
                              value: _isAsthmatic,
                              onChanged: (value) {
                                setState(() => _isAsthmatic = value);
                              },
                              activeColor: const Color(0xFF3730A3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Fréquence cardiaque
                      _buildInputField(
                        controller: _heartRateController,
                        label: 'Fréquence cardiaque (BPM)',
                        hint: 'Ex: 70',
                        icon: Icons.favorite,
                      ),
                      const SizedBox(height: 24),

                      // SpO2
                      _buildInputField(
                        controller: _spo2Controller,
                        label: 'SpO₂ (%)',
                        hint: 'Ex: 98',
                        icon: Icons.air,
                      ),
                      const SizedBox(height: 24),

                      // Pression artérielle
                      _buildInputField(
                        controller: _bloodPressureController,
                        label: 'Pression artérielle',
                        hint: 'Ex: 120/80',
                        icon: Icons.water_drop,
                        isRequired: false,
                      ),
                      const SizedBox(height: 24),

                      // IQA
                      _buildInputField(
                        controller: _aqiController,
                        label: 'IQA (Indice Qualité Air)',
                        hint: 'Ex: 22',
                        icon: Icons.cloud,
                      ),
                      const SizedBox(height: 32),

                      // Bouton Calculer
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _calculateRisk,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3730A3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Calculer le risque',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      // Résultat
                      if (_showResult) ...[
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Risque:',
                                      style: TextStyle(
                                        fontSize: 24,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _riskEmoji,
                                    style: const TextStyle(fontSize: 48),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _riskPercentage,
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: _riskColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isRequired = true,
  }) {
    return Row(
      children: [
        // Icône
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF3730A3),
            size: 32,
          ),
        ),
        const SizedBox(width: 20),

        // Champ de texte
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  fontSize: 18,
                  color: Color(0xFF3730A3),
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(
                    color: const Color(0xFF3730A3).withOpacity(0.5),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                validator: isRequired
                    ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ce champ est requis';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Valeur invalide';
                  }
                  return null;
                }
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _heartRateController.dispose();
    _spo2Controller.dispose();
    _aqiController.dispose();
    _bloodPressureController.dispose();
    super.dispose();
  }
}