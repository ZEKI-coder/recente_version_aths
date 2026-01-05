import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({Key? key}) : super(key: key);

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  // Controllers pour les champs de texte
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _numeroTelController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _adresseController = TextEditingController();

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  // Données de santé
  bool _grippe = false;
  bool _fumeur = false;
  bool _rhume = false;
  bool _allergies = false;

  // Liste des maladies
  List<Map<String, dynamic>> _maladies = [];

  // Mode édition pour chaque champ
  bool _editingNom = false;
  bool _editingPrenom = false;
  bool _editingAge = false;
  bool _editingTel = false;
  bool _editingEmail = false;
  bool _editingAdresse = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Charger les données de l'utilisateur
  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _nomController.text = prefs.getString('nom') ?? '';
      _prenomController.text = prefs.getString('prenom') ?? '';
      _ageController.text = prefs.getString('age') ?? '';
      _numeroTelController.text = prefs.getString('numero_tel') ?? '';
      _emailController.text = prefs.getString('email') ?? '';
      _adresseController.text = prefs.getString('adresse') ?? '';

      // Données de santé
      _grippe = prefs.getBool('symptomes') ?? false;
      _fumeur = prefs.getBool('fumeur') ?? false;
      _rhume = prefs.getBool('rhume') ?? false;
      _allergies = prefs.getBool('allergies') ?? false;

      // TODO: Charger les maladies depuis la base de données
      _maladies = [
        {'nom': 'Asthme', 'date': '15/01/2024'},
        {'nom': 'Bronchite chronique', 'date': '20/03/2023'},
      ];
    });
  }

  // Sauvegarder un champ spécifique
  Future<void> _saveField(String key, String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
    // TODO: Envoyer au serveur
    _showSuccessSnackBar('$key mis à jour');
  }

  // Sélectionner une image
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 500,
      maxHeight: 500,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      _showSuccessSnackBar('Photo mise à jour !');
    }
  }

  // Prendre une photo avec la caméra
  Future<void> _takePhoto() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 500,
      maxHeight: 500,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      _showSuccessSnackBar('Photo mise à jour !');
    }
  }

  // Afficher le choix entre galerie et caméra
  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choisir une photo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF667EEA)),
                title: const Text('Galerie'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF667EEA)),
                title: const Text('Appareil photo'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Afficher un message de succès
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Mon Profil'),
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
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
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
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 70,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 65,
                            backgroundImage: _imageFile != null
                                ? FileImage(_imageFile!)
                                : null,
                            child: _imageFile == null
                                ? const Icon(Icons.person, size: 70, color: Color(0xFF667EEA))
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _showImageSourceDialog,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Color(0xFF667EEA),
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '${_prenomController.text} ${_nomController.text}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _emailController.text,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Informations personnelles avec crayons
            _buildSectionCard(
              title: '📝 Informations personnelles',
              subtitle: '',
              child: Column(
                children: [
                  _buildEditableField(
                    controller: _nomController,
                    label: 'Nom',
                    icon: Icons.person_outline,
                    isEditing: _editingNom,
                    onEdit: () {
                      setState(() => _editingNom = !_editingNom);
                      if (!_editingNom) {
                        _saveField('nom', _nomController.text);
                      }
                    },
                  ),
                  const SizedBox(height: 15),
                  _buildEditableField(
                    controller: _prenomController,
                    label: 'Prénom',
                    icon: Icons.person,
                    isEditing: _editingPrenom,
                    onEdit: () {
                      setState(() => _editingPrenom = !_editingPrenom);
                      if (!_editingPrenom) {
                        _saveField('prenom', _prenomController.text);
                      }
                    },
                  ),
                  const SizedBox(height: 15),
                  _buildEditableField(
                    controller: _ageController,
                    label: 'Âge',
                    icon: Icons.cake,
                    isEditing: _editingAge,
                    keyboardType: TextInputType.number,
                    onEdit: () {
                      setState(() => _editingAge = !_editingAge);
                      if (!_editingAge) {
                        _saveField('age', _ageController.text);
                      }
                    },
                  ),
                  const SizedBox(height: 15),
                  _buildEditableField(
                    controller: _numeroTelController,
                    label: 'Numéro de téléphone',
                    icon: Icons.phone,
                    isEditing: _editingTel,
                    keyboardType: TextInputType.phone,
                    onEdit: () {
                      setState(() => _editingTel = !_editingTel);
                      if (!_editingTel) {
                        _saveField('numero_tel', _numeroTelController.text);
                      }
                    },
                  ),
                  const SizedBox(height: 15),
                  _buildEditableField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email,
                    isEditing: _editingEmail,
                    keyboardType: TextInputType.emailAddress,
                    onEdit: () {
                      setState(() => _editingEmail = !_editingEmail);
                      if (!_editingEmail) {
                        _saveField('email', _emailController.text);
                      }
                    },
                  ),
                  const SizedBox(height: 15),
                  _buildEditableField(
                    controller: _adresseController,
                    label: 'Adresse',
                    icon: Icons.location_on,
                    isEditing: _editingAdresse,
                    maxLines: 3,
                    onEdit: () {
                      setState(() => _editingAdresse = !_editingAdresse);
                      if (!_editingAdresse) {
                        _saveField('adresse', _adresseController.text);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  // Bouton Mot de passe oublié
                  TextButton.icon(
                    onPressed: () {
                      // TODO: Navigation vers page mot de passe oublié
                      _showForgotPasswordDialog();
                    },
                    icon: const Icon(Icons.lock_reset, color: Color(0xFF667EEA)),
                    label: const Text(
                      '🔒 Mot de passe oublié ?',
                      style: TextStyle(
                        color: Color(0xFF667EEA),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Facteurs de maladie et Maladies côte à côte
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Facteurs de maladie (gauche)
                  Expanded(
                    child: _buildSmallCard(
                      title: '⚠️ Facteurs',
                      child: Column(
                        children: [
                          _buildCompactSwitch(
                            title: 'Grippe',
                            value: _grippe,
                            onChanged: (value) => setState(() => _grippe = value),
                          ),
                          _buildCompactSwitch(
                            title: 'Fumeur',
                            value: _fumeur,
                            onChanged: (value) => setState(() => _fumeur = value),
                          ),
                          _buildCompactSwitch(
                            title: 'Rhume',
                            value: _rhume,
                            onChanged: (value) => setState(() => _rhume = value),
                          ),
                          _buildCompactSwitch(
                            title: 'Allergies',
                            value: _allergies,
                            onChanged: (value) => setState(() => _allergies = value),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  // Maladies (droite)
                  Expanded(
                    child: _buildSmallCard(
                      title: '🩺 Maladies',
                      child: _maladies.isEmpty
                          ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(15.0),
                          child: Text(
                            'Aucune',
                            style: TextStyle(
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                          : Column(
                        children: _maladies.map((maladie) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border(
                                left: BorderSide(
                                  color: const Color(0xFF667EEA),
                                  width: 3,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  maladie['nom'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${maladie['date']}',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
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

  // Widget pour créer une carte de section
  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  // Widget pour petite carte (facteurs et maladies)
  Widget _buildSmallCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
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
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }

  // Widget pour champ éditable avec crayon
  Widget _buildEditableField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isEditing,
    required VoidCallback onEdit,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            enabled: isEditing,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: TextStyle(
              color: isEditing ? Colors.black : Colors.grey[700],
            ),
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(icon, color: const Color(0xFF667EEA)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
              ),
              filled: true,
              fillColor: isEditing ? Colors.white : Colors.grey[100],
            ),
          ),
        ),
        const SizedBox(width: 10),
        IconButton(
          onPressed: onEdit,
          icon: Icon(
            isEditing ? Icons.check : Icons.edit,
            color: isEditing ? Colors.green : const Color(0xFF667EEA),
          ),
          style: IconButton.styleFrom(
            backgroundColor: Colors.grey[100],
          ),
        ),
      ],
    );
  }

  // Widget pour switch compact
  Widget _buildCompactSwitch({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF667EEA),
          ),
        ],
      ),
    );
  }

  // Dialog pour mot de passe oublié
  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final emailController = TextEditingController();
        return AlertDialog(
          title: const Text('Mot de passe oublié'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Entrez votre email pour recevoir un lien de réinitialisation',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Envoyer email de réinitialisation
                Navigator.pop(context);
                _showSuccessSnackBar('Email envoyé !');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
              ),
              child: const Text('Envoyer'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _ageController.dispose();
    _numeroTelController.dispose();
    _emailController.dispose();
    _adresseController.dispose();
    super.dispose();
  }
}