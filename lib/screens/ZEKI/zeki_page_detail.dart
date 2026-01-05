import 'package:flutter/material.dart';

class ConnexionDetailPage extends StatefulWidget {
  final Map<String, dynamic> connexion;

  const ConnexionDetailPage({Key? key, required this.connexion}) : super(key: key);

  @override
  State<ConnexionDetailPage> createState() => _ConnexionDetailPageState();
}

class _ConnexionDetailPageState extends State<ConnexionDetailPage> {
  // Exemple de données (à remplacer par les vraies données)
  String etatActuel = 'Bon';
  bool alerte = false;

  // Données de santé
  Map<String, String> rapportSante = {
    'SPL': 'Normal',
    'Battement': '75 bpm',
    'IQA': 'Bon',
    'Temp': '37.2°C',
  };

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
          'Connexion',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF667EEA),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // En-tête avec dégradé
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  children: [
                    // Photo de profil
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 55,
                        backgroundColor: const Color(0xFF667EEA),
                        child: Text(
                          widget.connexion['nom'][0],
                          style: const TextStyle(
                            fontSize: 50,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Nom des personnes connecté
                    Text(
                      'Nom et Prenom',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.connexion['nom'],
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Informations principales
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Carte État Actuel (sans "En ligne")
                  _buildInfoCard(
                    title: 'État Actuel',
                    children: [
                      _buildInfoRow('État', etatActuel,
                          valueColor: etatActuel == 'Bon' ? Colors.green : Colors.orange),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Bouton Alerte
                  Container(
                    width: double.infinity,
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
                      children: [
                        const Text(
                          'Alerte',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 15),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() => alerte = !alerte);
                              _showAlertDialog();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: alerte ? Colors.red[700] : const Color(0xFFE74C3C),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              alerte ? 'ALERTE ACTIVÉE' : 'Alerte',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Carte Télécharger rapport de santé
                  _buildInfoCard(
                    title: 'Télécharger rapport de santé',
                    children: [
                      Column(
                        children: rapportSante.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF2C3E50),
                                  ),
                                ),
                                Text(
                                  entry.value,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF667EEA),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _showSuccessSnackBar('Rapport téléchargé !');
                          },
                          icon: const Icon(Icons.download),
                          label: const Text(
                            'Télécharger le rapport',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2ECC71),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget pour carte d'information
  Widget _buildInfoCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  // Widget pour ligne d'information
  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF2C3E50),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor ?? const Color(0xFF667EEA),
          ),
        ),
      ],
    );
  }

  // Dialog d'alerte
  void _showAlertDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                alerte ? Icons.warning : Icons.info,
                color: alerte ? Colors.red : const Color(0xFF667EEA),
              ),
              const SizedBox(width: 10),
              Text(alerte ? 'Alerte activée' : 'Alerte désactivée'),
            ],
          ),
          content: Text(
            alerte
                ? 'Une alerte a été envoyée pour ${widget.connexion['nom']}'
                : 'Alerte désactivée pour ${widget.connexion['nom']}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
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