import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class AuthService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream de l'utilisateur actuel
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => currentUser != null;
  bool get isEmailVerified => currentUser?.emailVerified ?? false;

  // Inscription
  Future<UserCredential?> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> userData,
  }) async {
    try {
      // Créer le compte
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Envoyer email de vérification
        await credential.user!.sendEmailVerification();

        // Sauvegarder les données utilisateur
        await _saveMerchantData(credential.user!.uid, userData);

        return credential;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Connexion
  Future<UserCredential?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw 'Erreur lors de la déconnexion: $e';
    }
  }

  // Réinitialisation mot de passe
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Mise à jour mot de passe
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = currentUser;
      if (user == null) throw 'Utilisateur non connecté';

      // Ré-authentification
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Mise à jour du mot de passe
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Renvoyer email de vérification
  Future<void> sendEmailVerification() async {
    try {
      await currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Recharger les données utilisateur
  Future<void> reloadUser() async {
    await currentUser?.reload();
  }

  // Sauvegarder les données marchand
  Future<void> _saveMerchantData(
      String uid, Map<String, dynamic> userData) async {
    final encryptedKeys = _encryptApiKeys(userData);

    await _firestore.collection('merchants').doc(uid).set({
      'name': userData['name'],
      'email': userData['email'],
      'phone': userData['phone'],
      'supportPhone': userData['supportPhone'] ?? userData['phone'],
      'freemopayKeys': encryptedKeys,
      'callbackUrl': userData['callbackUrl'],
      'isEmailVerified': false,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Chiffrement des clés API
  Map<String, String> _encryptApiKeys(Map<String, dynamic> userData) {
    final key = utf8.encode(currentUser?.uid ?? 'default_key');

    return {
      'appKey': _encrypt(userData['appKey'], key),
      'secretKey': _encrypt(userData['secretKey'], key),
    };
  }

  String _encrypt(String text, List<int> key) {
    // Implémentation simple - en production, utilisez un vrai chiffrement
    final bytes = utf8.encode(text);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);
    return '${base64.encode(bytes)}.$digest';
  }

  // Gestion des erreurs Firebase
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Aucun compte trouvé avec cet email.';
      case 'wrong-password':
        return 'Mot de passe incorrect.';
      case 'email-already-in-use':
        return 'Un compte existe déjà avec cet email.';
      case 'weak-password':
        return 'Le mot de passe est trop faible.';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard.';
      case 'network-request-failed':
        return 'Problème de connexion internet.';
      case 'invalid-email':
        return 'Format d\'email invalide.';
      case 'user-disabled':
        return 'Ce compte a été désactivé.';
      default:
        return 'Erreur d\'authentification: ${e.message}';
    }
  }
}
