import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider extends ChangeNotifier {
  bool _isSuperAdmin = false;
  String _userId = '';
  bool _isLoading = true;

  bool get isSuperAdmin => _isSuperAdmin;
  String get userId => _userId;
  bool get isLoading => _isLoading;

  UserProvider() {
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Get the stored user ID from SharedPreferences instead of Firebase Auth
      final prefs = await SharedPreferences.getInstance();
      final userType = prefs.getString('user_type');
      final userId = prefs.getString('user_id');

      if (userType == 'admin' && userId != null) {
        _userId = userId;

        // Check if user is a super admin
        final adminDoc = await FirebaseFirestore.instance
            .collection('admins')
            .doc(_userId)
            .get();

        if (adminDoc.exists) {
          _isSuperAdmin = adminDoc.data()?['isSuperAdmin'] ?? false;
        }
      }
    } catch (e) {
      print('Error initializing user: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Method to manually set super admin status (for testing or other purposes)
  void setSuperAdmin(bool value) {
    _isSuperAdmin = value;
    notifyListeners();
  }
}
