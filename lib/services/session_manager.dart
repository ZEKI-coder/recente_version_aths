import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart' as user_model;
import 'database_service.dart';

class SessionManager {
  static const String _keyRememberMe = 'remember_me';
  static const String _keyRememberedEmail = 'remembered_email';

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sauvegarder la session complète (Firebase Auth gère automatiquement la session)
  static Future<void> saveSession({
    required String email,
    bool rememberMe = false, required String userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRememberMe, rememberMe);

    if (rememberMe) {
      await prefs.setString(_keyRememberedEmail, email);
    } else {
      await prefs.remove(_keyRememberedEmail);
    }
  }

  // Récupérer l'ID utilisateur (depuis Firebase Auth)
  static String? getUserId() {
    return _auth.currentUser?.uid;
  }

  // Récupérer l'email (depuis Firebase Auth)
  static String? getUserEmail() {
    return _auth.currentUser?.email;
  }

  // Récupérer l'email mémorisé
  static Future<String?> getRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRememberedEmail);
  }

  // Vérifier si connecté (Firebase Auth gère automatiquement la persistance)
  static bool isLoggedIn() {
    return _auth.currentUser != null;
  }

  // Vérifier "Se souvenir de moi"
  static Future<bool> isRememberMeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyRememberMe) ?? false;
  }

  // Déconnexion complète
  static Future<void> logout() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Déconnexion partielle (garde l'email si "Se souvenir")
  static Future<void> logoutButKeepEmail() async {
    await _auth.signOut();

    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_keyRememberedEmail);
    final rememberMe = prefs.getBool(_keyRememberMe) ?? false;

    await prefs.clear();

    if (rememberMe && email != null) {
      await prefs.setString(_keyRememberedEmail, email);
      await prefs.setBool(_keyRememberMe, true);
    }
  }

  // Stream pour écouter les changements d'état d'authentification
  static Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  // Obtenir l'utilisateur actuel (notre modèle personnalisé)
  static Future<user_model.User?> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    try {
      // Récupérer notre utilisateur depuis la base de données locale
      return await DatabaseService.instance.getUserById(firebaseUser.uid);
    } catch (e) {
      print('Erreur lors de la récupération de l\'utilisateur: $e');
      return null;
    }
  }

  // Obtenir l'utilisateur Firebase Auth
  static User? getFirebaseUser() {
    return _auth.currentUser;
  }

  // Vérifier si l'email est vérifié
  static bool isEmailVerified() {
    return _auth.currentUser?.emailVerified ?? false;
  }

  // Envoyer un email de vérification
  static Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  // Réinitialiser le mot de passe
  static Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}