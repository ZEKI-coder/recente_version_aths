import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'zeki_page_detail.dart';

class GestionUsersPagePr extends StatefulWidget {
  const GestionUsersPagePr({Key? key}) : super(key: key);

  @override
  State<GestionUsersPagePr> createState() => _GestionUsersPageState();
}

class _GestionUsersPageState extends State<GestionUsersPagePr> {
  // Code QR unique du PROTÉGÉ
  final String _qrCode = "USER_ID_12345"; // Généré dynamiquement

  // Liste des RESPONSABLES connectés (qui surveillent le protégé)
  final List<Map<String, dynamic>> _responsablesConnectes = [
    {
      'id': 1,
      'nom': 'Papa Kouassi',
      'email': 'papa.kouassi@example.com',
      'date': '28/12/2024 14:30',
      'role': 'Responsable',
      'photo': null,
    },
    {
      'id': 2,
      'nom': 'Maman Yao',
      'email': 'maman.yao@example.com',
      'date': '27/12/2024 10:15',
      'role': 'Responsable',
      'photo': null,
    },
    {
      'id': 3,
      'nom': 'Tante Marie',
      'email': 'marie@example.com',
      'date': '26/12/2024 16:45',
      'role': 'Responsable',
      'photo': null,
    },
  ];

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
                _showPartagerQRDialog();
              } else if (value == 'ajouter') {
                _showAjouterResponsableDialog();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'partager',
                child: Row(
                  children: [
                    Icon(Icons.qr_code, color: Color(0xFF667EEA)),
                    SizedBox(width: 10),
                    Text('Voir mon QR Code'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'ajouter',
                child: Row(
                  children: [
                    Icon(Icons.person_add, color: Color(0xFF2ECC71)),
                    SizedBox(width: 10),
                    Text('Ajouter un responsable'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Section Mon QR Code (pour que les responsables scannent)
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
                    'Partagez ce code avec vos responsables',
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
                      data: _qrCode,
                      version: QrVersions.auto,
                      size: 200.0,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Bouton Partager
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

            // Section Mes Responsables Connectés
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
                        'Mes Responsables',
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
                          '${_responsablesConnectes.length} connecté(s)',
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
                    'Personnes qui peuvent me surveiller',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Liste des responsables
                  if (_responsablesConnectes.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(30.0),
                        child: Column(
                          children: [
                            Icon(Icons.supervisor_account_outlined, size: 60, color: Colors.grey),
                            SizedBox(height: 15),
                            Text(
                              'Aucun responsable connecté',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Partagez votre QR code pour ajouter des responsables',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Column(
                      children: _responsablesConnectes.map((responsable) {
                        return _buildResponsableCard(responsable);
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

  // Widget pour une carte de responsable
  Widget _buildResponsableCard(Map<String, dynamic> responsable) {
    return InkWell(
      onTap: () => _showResponsableDetails(responsable),
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
              radius: 28,
              backgroundColor: const Color(0xFF667EEA),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(width: 15),
            // Informations
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    responsable['nom'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2ECC71).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          responsable['role'],
                          style: const TextStyle(
                            color: Color(0xFF2ECC71),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.check_circle, size: 16, color: Colors.green),
                      const SizedBox(width: 4),
                      const Text(
                        'Actif',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 5),
                      Text(
                        'Depuis le ${responsable['date']}',
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

  // Afficher détails du responsable
  void _showResponsableDetails(Map<String, dynamic> responsable) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConnexionDetailPage(connexion: responsable),
      ),
    );
  }

  // Fonction pour scanner un QR Code
  void _scanQRCode() {
    // TODO: Implémenter la fonctionnalité de scan QR Code
    // Vous pouvez utiliser le package 'mobile_scanner' ou 'qr_code_scanner'
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.qr_code_scanner, color: Color(0xFFFF6B6B)),
              SizedBox(width: 10),
              Text('Scanner un QR Code'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.qr_code_scanner,
                size: 80,
                color: Color(0xFFFF6B6B),
              ),
              const SizedBox(height: 20),
              const Text(
                'Scannez le QR Code d\'un autre utilisateur pour l\'ajouter à votre liste de responsables ou de protégés.',
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFFFF6B6B)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Assurez-vous d\'avoir les permissions nécessaires',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // Ici vous pouvez ouvrir le scanner de QR Code
                _showSuccessSnackBar('Ouverture du scanner...');
                // TODO: Lancer le scanner QR Code
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Ouvrir caméra'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B6B),
              ),
            ),
          ],
        );
      },
    );
  }

  // Dialog partager QR code
  void _showPartagerQRDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Mon QR Code'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Partagez ce code avec vos responsables pour qu\'ils puissent vous surveiller',
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF667EEA), width: 2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: QrImageView(
                  data: _qrCode,
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showSuccessSnackBar('QR Code partagé !');
              },
              icon: const Icon(Icons.share),
              label: const Text('Partager'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
              ),
            ),
          ],
        );
      },
    );
  }

  // Dialog ajouter un responsable
  void _showAjouterResponsableDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.person_add, color: Color(0xFF2ECC71)),
              SizedBox(width: 10),
              Text('Ajouter un responsable'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pour ajouter un responsable, partagez-lui votre QR code afin qu\'il puisse le scanner.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFF667EEA).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF667EEA)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Votre responsable verra vos informations de santé',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showPartagerQRDialog();
              },
              icon: const Icon(Icons.qr_code),
              label: const Text('Voir mon QR'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2ECC71),
              ),
            ),
          ],
        );
      },
    );
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
}