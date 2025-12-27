import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/user.dart' as user_model;
import '../models/health_data.dart' as health_model;

class DatabaseService {
  // Singleton
  static final DatabaseService instance = DatabaseService._init();
  DatabaseService._init();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  // Collections
  static const String usersCollection = 'users';
  static const String healthDataCollection = 'health_data';

  // helper removed; use explicit Db methods

  // ===================== USERS =====================

  Future<String> createUser(user_model.User user) async {
    try {
      // Créer l'utilisateur dans Firebase Auth
      auth.UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: user.email,
        password: user.password,
      );

      String uid = userCredential.user!.uid;

      // Stocker les données utilisateur dans Firestore
      await _firestore.collection(usersCollection).doc(uid).set({
        'email': user.email,
        'nom': user.nom,
        'prenom': user.prenom,
        'age': user.age,
        'hasConditions': user.hasConditions,
        'createdAt': user.createdAt,
      });

      print("✅ Utilisateur créé avec succès: $uid");
      return uid;
    } catch (e) {
      print("❌ Erreur création utilisateur: $e");
      rethrow;
    }
  }

  Future<user_model.User?> login(String email, String password) async {
    try {
      // Connexion via Firebase Auth
      auth.UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = userCredential.user!.uid;

      // Récupérer les données depuis Firestore
      DocumentSnapshot doc = await _firestore.collection(usersCollection).doc(uid).get();

      if (!doc.exists) return null;

      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data['id'] = uid;
      data['password'] = password; // Optionnel, généralement on ne stocke pas le mot de passe

      return user_model.User.fromMap(data);
    } catch (e) {
      print("❌ Erreur login: $e");
      return null;
    }
  }

  Future<user_model.User?> getUserByEmail(String email) async {
    try {
      QuerySnapshot query = await _firestore
          .collection(usersCollection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;

      Map<String, dynamic> data = query.docs.first.data() as Map<String, dynamic>;
      data['id'] = query.docs.first.id;

      return user_model.User.fromMap(data);
    } catch (e) {
      print("❌ Erreur getUserByEmail: $e");
      return null;
    }
  }

  Future<user_model.User?> getUserById(String id) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(usersCollection).doc(id).get();

      if (!doc.exists) return null;

      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data['id'] = id;

      return user_model.User.fromMap(data);
    } catch (e) {
      print("❌ Erreur getUserById: $e");
      return null;
    }
  }

  Future<bool> updateUser(user_model.User user) async {
    try {
      await _firestore.collection(usersCollection).doc(user.id.toString()).update({
        'email': user.email,
        'nom': user.nom,
        'prenom': user.prenom,
        'age': user.age,
        'hasConditions': user.hasConditions,
      });

      // Mettre à jour l'email dans Firebase Auth si nécessaire
      if (_auth.currentUser != null && _auth.currentUser!.email != user.email) {
        await _auth.currentUser!.updateEmail(user.email);
      }

      return true;
    } catch (e) {
      print("❌ Erreur updateUser: $e");
      return false;
    }
  }

  Future<bool> deleteUser(String id) async {
    try {
      // Supprimer les données de santé
      await deleteUserHealthData(id);

      // Supprimer le document Firestore
      await _firestore.collection(usersCollection).doc(id).delete();

      // Supprimer l'utilisateur de Firebase Auth
      if (_auth.currentUser?.uid == id) {
        await _auth.currentUser!.delete();
      }

      return true;
    } catch (e) {
      print("❌ Erreur deleteUser: $e");
      return false;
    }
  }

  // ===================== HEALTH DATA =====================

  Future<String> insertHealthData(health_model.HealthData data) async {
    try {
      DocumentReference docRef = await _firestore.collection(healthDataCollection).add({
        'userId': data.userId,
        'heartRate': data.heartRate,
        'spo2': data.spo2,
        'aqi': data.aqi,
        'riskScore': data.riskScore,
        'riskLevel': data.riskLevel.name,
        'timestamp': data.timestamp,
      });

      return docRef.id;
    } catch (e) {
      print("❌ Erreur insertHealthData: $e");
      rethrow;
    }
  }

  Future<List<health_model.HealthData>> getHealthDataByUser(String userId) async {
    try {
      QuerySnapshot query = await _firestore
          .collection(healthDataCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      return query.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return health_model.HealthData.fromMap(data);
      }).toList();
    } catch (e) {
      print("❌ Erreur getHealthDataByUser: $e");
      return [];
    }
  }

  Future<health_model.HealthData?> getLastHealthData(String userId) async {
    try {
      QuerySnapshot query = await _firestore
          .collection(healthDataCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;

      Map<String, dynamic> data = query.docs.first.data() as Map<String, dynamic>;
      data['id'] = query.docs.first.id;

      return health_model.HealthData.fromMap(data);
    } catch (e) {
      print("❌ Erreur getLastHealthData: $e");
      return null;
    }
  }

  Future<double?> getAverageRiskScore(String userId) async {
    try {
      QuerySnapshot query = await _firestore
          .collection(healthDataCollection)
          .where('userId', isEqualTo: userId)
          .get();

      if (query.docs.isEmpty) return null;

      double total = 0;
      for (var doc in query.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        total += (data['riskScore'] as num).toDouble();
      }

      return total / query.docs.length;
    } catch (e) {
      print("❌ Erreur getAverageRiskScore: $e");
      return null;
    }
  }

  Future<bool> deleteUserHealthData(String userId) async {
    try {
        QuerySnapshot query = await _firestore
          .collection(healthDataCollection)
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in query.docs) {
        await doc.reference.delete();
      }

      return true;
    } catch (e) {
      print("❌ Erreur deleteUserHealthData: $e");
      return false;
    }
  }

  // -------- AUTH HELPERS --------

  Future<void> logout() async {
    await _auth.signOut();
  }

  auth.User? getCurrentUser() {
    return _auth.currentUser;
  }

  Stream<auth.User?> authStateChanges() {
    return _auth.authStateChanges();
  }
}