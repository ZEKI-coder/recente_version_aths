import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'zeki_page_detail.dart';
import 'qr_scanner_page.dart';
import '../../models/user.dart' as user_model;
import '../../models/connexion.dart';
import '../../services/connexion_service.dart';
import '../../services/session_manager.dart';

class GestionUsersPage extends StatefulWidget {
  const GestionUsersPage({Key? key}) : super(key: key);

  @override
  State<GestionUsersPage> createState() => _GestionUsersPageState();
}

class _GestionUsersPageState extends State<GestionUsersPage> {
  final ConnexionService _connexionService = ConnexionService();
  user_model.User? _currentUser;
  String _userMatricule = "";
  List<Connexion> _connexionsActuelles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // Récupérer l'utilisateur actuel depuis la session
      user_model.User? user = await SessionManager.getCurrentUser();

      if (user != null) {
        setState(() {
          _currentUser = user;
          _userMatricule = user.matricule;
        });

        // Charger les connexions actuelles
        await _loadConnexions();
      } else {
        // Créer un utilisateur par défaut pour le développement
        user_model.User defaultUser = user_model.User(
          id: 'default_user',
          matricule: user_model.User.generateMatricule(),
          email: 'user@example.com',
          password: 'password',
          nom: 'Utilisateur',
          prenom: 'Test',
          age: 25,
        );

        setState(() {
          _currentUser = defaultUser;
          _userMatricule = defaultUser.matricule;
        });

        await _loadConnexions();
      }
    } catch (e) {
      print('Erreur lors du chargement des données utilisateur: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadConnexions() async {
    if (_currentUser?.id != null) {
      List<Connexion> connexions = await _connexionService.getConnexionsActuelles(_currentUser!.id!);
      setState(() {
        _connexionsActuelles = connexions;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Bonjour Users',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF667EEA),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'partager') {
                _showPartagerCompteDialog();
              } else if (value == 'scanner') {
                _scanQRCode();
              } else if (value == 'creer') {
                _showCreerCompteDialog();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'partager',
                child: Row(
                  children: [
                    Icon(Icons.share, color: Color(0xFF667EEA)),
                    SizedBox(width: 10),
                    Text('Partager mon compte'),
                  ],
                ),
              ),

              const PopupMenuItem(
                value: 'creer',
                child: Row(
                  children: [
                    Icon(Icons.add_circle, color: Color(0xFF2ECC71)),
                    SizedBox(width: 10),
                    Text('Créer un nouveau'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Section Code QR
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Mon Code QR',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Partagez ce code pour vous connecter',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Code QR
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: const Color(0xFF667EEA), width: 3),
                          ),
                          child: QrImageView(
                            data: _userMatricule,
                            version: QrVersions.auto,
                            size: 200.0,
                            backgroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Bouton Partager centré
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _showSuccessSnackBar('Code QR partagé !');
                            },
                            icon: const Icon(Icons.share),
                            label: const Text('Partager'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF667EEA),
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        // Bouton Scanner QR Code
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _scanQRCode();
                            },
                            icon: const Icon(Icons.qr_code_scanner, size: 24),
                            label: const Text(
                              'Scanner un QR Code',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF667EEA),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Section Connexions actuelles
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Connexions actuelles',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF667EEA).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_connexionsActuelles.length} connecté(s)',
                                style: const TextStyle(
                                  color: Color(0xFF667EEA),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Nom + Prenom du protégé',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Liste des connexions
                        if (_connexionsActuelles.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(30.0),
                              child: Column(
                                children: [
                                  Icon(Icons.link_off, size: 60, color: Colors.grey),
                                  SizedBox(height: 15),
                                  Text(
                                    'Aucune connexion active',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Column(
                            children: _connexionsActuelles.map((connexion) {
                              return _buildConnexionCard(connexion);
                            }).toList(),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
      }

      // Widget pour une carte de connexion
      Widget _buildConnexionCard(Connexion connexion) {
        return InkWell(
          onTap: () => _showConnexionDetails(connexion),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                // Photo/Avatar
                CircleAvatar(
                  radius: 25,
                  backgroundColor: const Color(0xFF667EEA),
                  child: Text(
                    connexion.utilisateurCibleNom.isNotEmpty
                        ? connexion.utilisateurCibleNom[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                // Informations
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        connexion.utilisateurCibleNom,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        connexion.utilisateurCibleEmail,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 5),
                          Text(
                            _connexionService.formaterDateConnexion(connexion.dateConnexion),
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Flèche
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
              ],
            ),
          ),
        );
      }

      // Afficher détails connexion
      void _showConnexionDetails(Connexion connexion) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConnexionDetailPage(
              connexion: {
                'id': connexion.id,
                'nom': connexion.utilisateurCibleNom,
                'email': connexion.utilisateurCibleEmail,
                'date': _connexionService.formaterDateConnexion(connexion.dateConnexion),
                'matricule': connexion.utilisateurCibleMatricule,
                'photo': null,
              },
            ),
          ),
        );
      }

      // Fonction pour scanner un QR Code
      Future<void> _scanQRCode() async {
        if (_currentUser?.id == null) {
          _showErrorSnackBar('Utilisateur non connecté');
          return;
        }

        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QRScannerPage(currentUserId: _currentUser!.id!),
          ),
        );

        if (result == true) {
          // Le scan a réussi, recharger les connexions
          await _loadConnexions();
          _showSuccessSnackBar('Connexion ajoutée avec succès !');
        }
      }

      // Dialog partager compte
      void _showPartagerCompteDialog() {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Partager mon QR Code'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Partagez votre QR code pour permettre à d\'autres personnes de se connecter',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  QrImageView(
                    data: _userMatricule,
                    version: QrVersions.auto,
                    size: 200.0,
                    backgroundColor: Colors.white,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fermer'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showSuccessSnackBar('QR Code partagé !');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF667EEA),
                  ),
                  child: const Text('Partager'),
                ),
              ],
            );
          },
        );
      }

      void _showCreerCompteDialog() {
        // TODO: Implement dialog for creating a new account
      }

      // Afficher message de succès
      void _showSuccessSnackBar(String message) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // Afficher message d'erreur
      void _showErrorSnackBar(String message) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

// Page Scanner QR (placeholder)
class ScannerQRPage extends StatelessWidget {
  const ScannerQRPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner QR Code'),
        backgroundColor: const Color(0xFF667EEA),
      ),
      body: const Center(
        child: Text(
          'Scanner QR Code\n(à développer)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}