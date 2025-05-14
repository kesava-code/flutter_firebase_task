// This file defines the AuthProvider class, which manages user authentication
// (registration, login, logout) using Firebase Auth. It also handles storing
// user details in Cloud Firestore and profile image uploads to Firebase Storage.
// It utilizes ChangeNotifier to update the UI based on authentication state,
// loading status, and error messages.
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class AuthProvider extends ChangeNotifier {
  // Firebase User object.
  User? _user;
  // Getter for the user object.
  User? get user => _user;

  // Stores error messages.
  String? _errorMessage;
  // Getter for error messages.
  String? get errorMessage => _errorMessage;

  // Tracks loading state for async operations.
  bool _isLoading = false;
  // Getter for loading state.
  bool get isLoading => _isLoading;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Connectivity _connectivity = Connectivity();

  // Constructor: Listens for authentication state changes.
  AuthProvider() {
    _auth.authStateChanges().listen((User? newUser) {
      _user = newUser; // Update user state.
      _errorMessage = null; // Clear errors on auth change.
      notifyListeners(); // Notify listeners.
    });
  }
  // Helper method to check network connectivity
  Future<bool> _checkInternetConnectivity() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    // The result can be a list if multiple connectivity types are active.
    // We consider connected if at least one result is not none.
    if (connectivityResult.contains(ConnectivityResult.none)) {
      _errorMessage =
          "No internet connection. Please check your network and try again.";
      return false;
    }
    return true;
  }

  // Registers a new user.
  Future<bool> register(
    String name,
    String email,
    String password,
    XFile? profileImage,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Check for internet connectivity first
    if (!await _checkInternetConnectivity()) {
      _isLoading = false;
      notifyListeners(); // Notify for error message and loading state
      return false;
    }

    if (profileImage == null) {
      _isLoading = false;
      _errorMessage = "Please Select Profile Photo";
      return false;
    }

    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      _user = userCredential.user;

      String? profileImageUrl;
      // If a profile image is provided, upload it.
      if (_user != null) {
        final Reference storageRef = _storage.ref().child(
          'users/${_user!.uid}/profile.jpg',
        );
        await storageRef.putFile(File(profileImage.path));
        profileImageUrl = await storageRef.getDownloadURL();
      }

      // Store additional user info in Firestore.
      if (_user != null) {
        await _firestore.collection('users').doc(_user!.uid).set({
          'uid': _user!.uid,
          'name': name,
          'email': email,
          'profileImageUrl': profileImageUrl, // Null if no image.
          'createdAt': FieldValue.serverTimestamp(), // Timestamp of creation.
        });
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      // Handle Firebase authentication errors.
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      // Handle other errors.
      _errorMessage = "An unexpected error occurred: ${e.toString()}";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logs in an existing user.
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Check for internet connectivity first
    if (!await _checkInternetConnectivity()) {
      _isLoading = false;
      notifyListeners(); // Notify for error message and loading state
      return false;
    }

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      // authStateChanges listener updates _user.
      _isLoading = false;
      notifyListeners(); // Notify for isLoading state change.
      return true;
    } on FirebaseAuthException catch (e) {
      // Handle Firebase authentication errors.
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      // Handle other errors.
      _errorMessage = "An unexpected error occurred: ${e.toString()}";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logs out the current user.
  Future<void> logout() async {
    _isLoading = true; // Optional: show loading during logout.
    notifyListeners();
    await _auth.signOut();
    // authStateChanges listener will update _user to null.
    _user = null; // Explicitly set for immediate UI effect if needed.
    _isLoading = false;
    _errorMessage = null; // Clear errors on logout.
    notifyListeners(); // Update UI.
  }

  // Helper to clear error messages.
  void clearErrorMessage() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }
}
