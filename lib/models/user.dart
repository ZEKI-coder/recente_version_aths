import 'dart:math';

class User {
  final String? id;
  final String matricule; // Matricule unique pour QR code
  final String email;
  final String password;
  final String nom;
  final String prenom;
  final int age;
  final bool hasConditions;
  final DateTime createdAt;

  User({
    this.id,
    required this.matricule,
    required this.email,
    required this.password,
    required this.nom,
    required this.prenom,
    required this.age,
    this.hasConditions = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Générer un matricule unique
  static String generateMatricule() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(6);
    final randomPart = random.nextInt(9999).toString().padLeft(4, '0');
    return 'ZEKI$timestamp$randomPart';
  }

  // Convertir en Map pour la base de données
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'matricule': matricule,
      'email': email,
      'password': password,
      'nom': nom,
      'prenom': prenom,
      'age': age,
      'hasconditions': hasConditions,
      'createdat': createdAt.toIso8601String(),
    };
  }

  // Créer un User depuis un Map
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String?,
      matricule: map['matricule'] as String? ?? User.generateMatricule(),
      email: map['email'] as String,
      password: map['password'] as String? ?? '',
      nom: map['nom'] as String,
      prenom: map['prenom'] as String,
      age: map['age'] as int,
      hasConditions: map['hasconditions'] is bool
          ? map['hasconditions'] as bool
          : (map['hasconditions'] as int? ?? 0) == 1,
      createdAt: map['createdat'] is String
          ? DateTime.parse(map['createdat'] as String)
          : DateTime.now(),
    );
  }

  // Copier avec modifications
  User copyWith({
    String? id,
    String? matricule,
    String? email,
    String? password,
    String? nom,
    String? prenom,
    int? age,
    bool? hasConditions,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      matricule: matricule ?? this.matricule,
      email: email ?? this.email,
      password: password ?? this.password,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      age: age ?? this.age,
      hasConditions: hasConditions ?? this.hasConditions,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, matricule: $matricule, email: $email, nom: $nom, prenom: $prenom, age: $age, hasConditions: $hasConditions)';
  }
}