import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../services/session_manager.dart';
import '../../models/user.dart' as user_model;
import 'login_screen.dart';
import '../screens/cadrant_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  user_model.User? _currentUser;
  bool _isLoading = true;
  bool _hasAsthma = false;
  bool _hasAllergies = false;
  bool _hasDiabetes = false;
  bool _hasHeartDisease = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final userId = SessionManager.getUserId();
      if (userId != null) {
        final user = await DatabaseService.instance.getUserById(userId);
        if (mounted) {
          setState(() {
            _currentUser = user;
            _isLoading = false;
            // Initialiser les conditions de santé si nécessaire
            if (user != null && user.hasConditions) {
              _hasAsthma = true;
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

    try {
      if (_currentUser != null) {
        // Mettre à jour le statut des conditions
        final updatedUser = user_model.User(
          id: _currentUser!.id,
          email: _currentUser!.email,
          password: _currentUser!.password,
          nom: _currentUser!.nom,
          prenom: _currentUser!.prenom,
          age: _currentUser!.age,
          hasConditions: (_hasAsthma || _hasAllergies || _hasDiabetes || _hasHeartDisease),
          createdAt: _currentUser!.createdAt,
        );

        await DatabaseService.instance.updateUser(updatedUser);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil enregistré avec succès !'),
              backgroundColor: Colors.green,
            ),
          );

          // Naviguer vers le tableau de bord
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const CadrantScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _logout() async {
    await SessionManager.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF3730A3).withOpacity(0.1),
              const Color(0xFF818CF8).withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
            child: Column(
              children: [
                // En-tête avec bouton déconnexion
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Mon Profil',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Color(0xFF3730A3)),
                      onPressed: _logout,
                      tooltip: 'Déconnexion',
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Carte principale du profil
                Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      children: [
                        // Avatar
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3730A3).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 50,
                            color: Color(0xFF3730A3),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Nom complet
                        Text(
                          '${_currentUser?.prenom ?? ''} ${_currentUser?.nom ?? ''}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Email
                        Text(
                          _currentUser?.email ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF3730A3),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Âge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_currentUser?.age ?? 0} ans',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Carte des conditions de santé
                Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3730A3).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.health_and_safety,
                                color: Color(0xFF3730A3),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Conditions de santé',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Sélectionnez vos conditions médicales',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Asthme
                        _buildConditionTile(
                          icon: Icons.air,
                          title: 'Asthme',
                          value: _hasAsthma,
                          onChanged: (value) {
                            setState(() => _hasAsthma = value);
                          },
                        ),
                        const SizedBox(height: 12),

                        // Allergies
                        _buildConditionTile(
                          icon: Icons.coronavirus,
                          title: 'Allergies respiratoires',
                          value: _hasAllergies,
                          onChanged: (value) {
                            setState(() => _hasAllergies = value);
                          },
                        ),
                        const SizedBox(height: 12),

                        // Diabète
                        _buildConditionTile(
                          icon: Icons.water_drop,
                          title: 'Diabète',
                          value: _hasDiabetes,
                          onChanged: (value) {
                            setState(() => _hasDiabetes = value);
                          },
                        ),
                        const SizedBox(height: 12),

                        // Maladie cardiaque
                        _buildConditionTile(
                          icon: Icons.favorite,
                          title: 'Maladie cardiaque',
                          value: _hasHeartDisease,
                          onChanged: (value) {
                            setState(() => _hasHeartDisease = value);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Bouton Enregistrer
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3730A3),
                      foregroundColor: Colors.white,
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Text(
                      'Enregistrer et continuer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Bouton Ignorer
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const CadrantScreen()),
                    );
                  },
                  child: const Text(
                    'Ignorer pour le moment',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConditionTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? const Color(0xFF3730A3) : Colors.grey[300]!,
          width: 2,
        ),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: (val) => onChanged(val ?? false),
        activeColor: const Color(0xFF3730A3),
        title: Row(
          children: [
            Icon(
              icon,
              color: value ? const Color(0xFF3730A3) : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: value ? FontWeight.w600 : FontWeight.normal,
                color: value ? Colors.black : Colors.grey[700],
              ),
            ),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        controlAffinity: ListTileControlAffinity.trailing,
      ),
    );
  }
}