import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../models/connexion.dart';

class ConnexionService {
  static final ConnexionService _instance = ConnexionService._internal();
  factory ConnexionService() => _instance;
  ConnexionService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Scanner un QR code et trouver l'utilisateur correspondant
  Future<User?> findUserByMatricule(String matricule) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('matricule', isEqualTo: matricule)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return User.fromMap(snapshot.docs.first.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Erreur lors de la recherche de l\'utilisateur: $e');
      return null;
    }
  }

  // Créer une connexion entre deux utilisateurs
  Future<bool> creerConnexion(String utilisateurSourceId, User utilisateurCible) async {
    try {
      // Vérifier si la connexion existe déjà
      QuerySnapshot existingConnexion = await _firestore
          .collection('connexions')
          .where('utilisateurSourceId', isEqualTo: utilisateurSourceId)
          .where('utilisateurCibleId', isEqualTo: utilisateurCible.id)
          .where('estActif', isEqualTo: 1)
          .get();

      if (existingConnexion.docs.isNotEmpty) {
        return false; // La connexion existe déjà
      }

      // Créer la nouvelle connexion
      Connexion nouvelleConnexion = Connexion(
        id: Connexion.generateConnexionId(),
        utilisateurSourceId: utilisateurSourceId,
        utilisateurCibleId: utilisateurCible.id!,
        utilisateurCibleMatricule: utilisateurCible.matricule,
        utilisateurCibleNom: '${utilisateurCible.prenom} ${utilisateurCible.nom}',
        utilisateurCibleEmail: utilisateurCible.email,
        dateConnexion: DateTime.now(),
      );

      await _firestore
          .collection('connexions')
          .doc(nouvelleConnexion.id)
          .set(nouvelleConnexion.toMap());

      return true;
    } catch (e) {
      print('Erreur lors de la création de la connexion: $e');
      return false;
    }
  }

  // Récupérer les connexions actuelles d'un utilisateur
  Future<List<Connexion>> getConnexionsActuelles(String utilisateurId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('connexions')
          .where('utilisateurSourceId', isEqualTo: utilisateurId)
          .where('estActif', isEqualTo: 1)
          .orderBy('dateConnexion', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Connexion.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des connexions: $e');
      return [];
    }
  }

  // Supprimer une connexion
  Future<bool> supprimerConnexion(String connexionId) async {
    try {
      await _firestore
          .collection('connexions')
          .doc(connexionId)
          .update({'estActif': 0});

      return true;
    } catch (e) {
      print('Erreur lors de la suppression de la connexion: $e');
      return false;
    }
  }

  // Formater la date de connexion
  String formaterDateConnexion(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
