// auth_service.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _currentUser;
  bool _isAdmin = false;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isAdmin => _isAdmin;
  bool get isLoading => _isLoading;

  AuthService() {
    // Listen to auth state changes
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(User? user) async {
    _currentUser = user;

    if (user != null) {
      try {
        // Check if user is admin with proper field validation
        final userDoc =
            await _firestore.collection('admins').doc(user.uid).get();

        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>?;
          _isAdmin = data?['is_admin'] == true && data?['is_active'] == true;
        } else {
          _isAdmin = false;
        }
      } catch (e) {
        print('Error checking admin status: $e');
        _isAdmin = false;
      }
    } else {
      _isAdmin = false;
    }

    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    try {
      _setLoading(true); // This was missing

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Verify admin role with field validation
      final userDoc = await _firestore
          .collection('admins')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        await _auth.signOut();
        throw Exception('User is not an admin');
      }

      final data = userDoc.data() as Map<String, dynamic>?;
      if (data?['is_admin'] != true || data?['is_active'] != true) {
        await _auth.signOut();
        throw Exception(
            'User does not have admin privileges or account is inactive');
      }

      return true;
    } catch (e) {
      print('Login error: $e');
      rethrow;
    } finally {
      _setLoading(false); // This was missing
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  // Add this missing method
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
