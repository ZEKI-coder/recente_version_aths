class User {
  final String? id;
  final String email;
  final String password;
  final String nom;
  final String prenom;
  final int age;
  final bool hasConditions;
  final DateTime createdAt;

  User({
    this.id,
    required this.email,
    required this.password,
    required this.nom,
    required this.prenom,
    required this.age,
    this.hasConditions = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convertir en Map pour la base de données
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      // password should NOT be stored in Firestore; Auth handles passwords
      'nom': nom,
      'prenom': prenom,
      'age': age,
      'hasConditions': hasConditions,
      'createdAt': createdAt,
    };
  }

  // Créer un User depuis un Map
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String?,
      email: map['email'] as String,
      password: map['password'] as String? ?? '',
      nom: map['nom'] as String,
      prenom: map['prenom'] as String,
      age: map['age'] as int,
        hasConditions: (map['hasConditions'] ?? map['hasconditions']) is bool
          ? (map['hasConditions'] ?? map['hasconditions']) as bool
          : ((map['hasConditions'] ?? map['hasconditions']) as int? ?? 0) == 1,
          createdAt: map['createdAt'] is String
            ? DateTime.parse(map['createdAt'] as String)
            : map['createdAt'] is int
              ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
              : map['createdAt'] is DateTime
                ? map['createdAt'] as DateTime
                : DateTime.now(),
    );
  }

  // Copier avec modifications
  User copyWith({
    String? id,
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
    return 'User(id: $id, email: $email, nom: $nom, prenom: $prenom, age: $age, hasConditions: $hasConditions)';
  }
}