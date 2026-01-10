import '../models/user.dart';

class Connexion {
  final String id;
  final String utilisateurSourceId;
  final String utilisateurCibleId;
  final String utilisateurCibleMatricule;
  final String utilisateurCibleNom;
  final String utilisateurCibleEmail;
  final DateTime dateConnexion;
  final bool estActif;

  Connexion({
    required this.id,
    required this.utilisateurSourceId,
    required this.utilisateurCibleId,
    required this.utilisateurCibleMatricule,
    required this.utilisateurCibleNom,
    required this.utilisateurCibleEmail,
    required this.dateConnexion,
    this.estActif = true,
  });

  // Convertir en Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'utilisateurSourceId': utilisateurSourceId,
      'utilisateurCibleId': utilisateurCibleId,
      'utilisateurCibleMatricule': utilisateurCibleMatricule,
      'utilisateurCibleNom': utilisateurCibleNom,
      'utilisateurCibleEmail': utilisateurCibleEmail,
      'dateConnexion': dateConnexion.toIso8601String(),
      'estActif': estActif ? 1 : 0,
    };
  }

  // Créer depuis un Map
  factory Connexion.fromMap(Map<String, dynamic> map) {
    return Connexion(
      id: map['id'] as String,
      utilisateurSourceId: map['utilisateurSourceId'] as String,
      utilisateurCibleId: map['utilisateurCibleId'] as String,
      utilisateurCibleMatricule: map['utilisateurCibleMatricule'] as String,
      utilisateurCibleNom: map['utilisateurCibleNom'] as String,
      utilisateurCibleEmail: map['utilisateurCibleEmail'] as String,
      dateConnexion: map['dateConnexion'] is String
          ? DateTime.parse(map['dateConnexion'] as String)
          : DateTime.now(),
      estActif: map['estActif'] is bool
          ? map['estActif'] as bool
          : (map['estActif'] as int? ?? 0) == 1,
    );
  }

  // Générer un ID de connexion
  static String generateConnexionId() {
    return 'CONN_${DateTime.now().millisecondsSinceEpoch}';
  }
}
