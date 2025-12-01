import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider extends ChangeNotifier {
  FirebaseAuth? _auth;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? _user;
  User? get user => _user;

  bool get isLoggedIn => _user != null;

  AuthProvider() {
    _initializeAuth();
  }

  void _initializeAuth() {
    try {
      _auth = FirebaseAuth.instance;
      _auth?.authStateChanges().listen((User? user) {
        _user = user;
        notifyListeners();
      });
    } catch (e) {
      debugPrint("AuthProvider: Firebase not initialized: $e");
    }
  }

  Future<User?> signInWithGoogle() async {
    if (_auth == null) {
      debugPrint("Firebase Auth not initialized");
      return null;
    }
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User canceled

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth!.signInWithCredential(
        credential,
      );
      return userCredential.user;
    } catch (e) {
      debugPrint("Error signing in with Google: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth?.signOut();
  }
}
