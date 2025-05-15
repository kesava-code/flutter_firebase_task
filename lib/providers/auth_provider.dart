// lib/providers/auth_provider.dart
// This file defines the AuthProvider class, which manages user authentication
// (registration, login, logout) using Firebase Auth. It also handles storing
// user details in Cloud Firestore and profile image uploads to Firebase Storage.
// It utilizes ChangeNotifier to update the UI based on authentication state,
// loading status, and error messages. The _auth.authStateChanges stream is the
// primary source of truth for the user's authentication state (_user).

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // Required for File type
import 'package:firebase_storage/firebase_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // Import for connectivity check

class AuthProvider extends ChangeNotifier {
  // Firebase User object. Updated primarily by the authStateChanges listener.
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
  final Connectivity _connectivity =
      Connectivity(); // Instance for connectivity checks

  // Constructor: Listens for authentication state changes from Firebase.
  AuthProvider() {
    _auth.authStateChanges().listen((User? firebaseUser) {
      log("triggered");
      // This listener is the single source of truth for _user state.
      // It fires when Firebase's auth state changes (login, logout, token refresh, app start).
      if (_user != firebaseUser) {
        // Only update and notify if there's an actual change.
        _user = firebaseUser;
        _errorMessage = null; // Clear any previous error on auth state change.
        // isLoading is managed by individual methods (login, register, logout).
        // We don't reset isLoading here to avoid interfering with ongoing operations.
        notifyListeners(); // Notify listening widgets (like AuthCheck) about the change in user state.
      }
    });
  }

  // Helper method to check network connectivity.
  Future<bool> _checkInternetConnectivity() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      _errorMessage =
          "No internet connection. Please check your network and try again.";
      // No notifyListeners() here; calling method will handle it.
      return false;
    }
    return true;
  }

  // Registers a new user.
  // Creates the user in Firebase Auth, stores details in Firestore, uploads image,
  // and then signs the user out to enforce manual login.
  Future<bool> register(
    String name,
    String email,
    String password,
    XFile? profileImage,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners(); // Notify for isLoading and initial error clear.

    if (!await _checkInternetConnectivity()) {
      _isLoading = false;
      // _errorMessage is set by _checkInternetConnectivity.
      notifyListeners(); // Notify for error message and loading state.
      return false;
    }

    if (profileImage == null) {
      _isLoading = false;
      _errorMessage = "Please select a profile photo.";
      notifyListeners();
      return false;
    }

    try {
      // Create user with email and password.
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      User? createdFirebaseUser = userCredential.user; // Get the created user.

      if (createdFirebaseUser != null) {
        // Upload profile image.
        final Reference storageRef = _storage.ref().child(
          'user_profiles/${createdFirebaseUser.uid}/profile.jpg',
        );
        await storageRef.putFile(File(profileImage.path));
        final String profileImageUrl = await storageRef.getDownloadURL();

        // Store additional user info in Firestore.
        await _firestore.collection('users').doc(createdFirebaseUser.uid).set({
          'uid': createdFirebaseUser.uid,
          'name': name,
          'email': email,
          'profileImageUrl': profileImageUrl,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // IMPORTANT: Sign out the user immediately after registration.
        // This ensures they are not automatically "logged into the app state"
        // and will be redirected to LoginScreen by AuthCheck (as _user becomes null via authStateChanges).
        await _auth.signOut();
      } else {
        // This case should ideally not be reached if createUserWithEmailAndPassword succeeds.
        _errorMessage =
            "User creation succeeded but Firebase user data is null.";
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _isLoading = false;
      // The authStateChanges listener will handle _user becoming null and notifying.
      // We notify here mainly for isLoading.
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? "An unknown authentication error occurred.";
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage =
          "An unexpected error occurred during registration: ${e.toString()}";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logs in an existing user.
  // Relies on authStateChanges listener to update _user state.
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners(); // Notify for isLoading and initial error clear.

    if (!await _checkInternetConnectivity()) {
      _isLoading = false;
      // _errorMessage is set by _checkInternetConnectivity.
      notifyListeners();
      return false;
    }

    try {
      // Perform sign-in. DO NOT set _user directly here.
      // The authStateChanges listener will be triggered by Firebase
      // and will update _user and call notifyListeners.
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      // If signInWithEmailAndPassword is successful, the authStateChanges listener
      // will update _user to the new Firebase user and notify.
      // We just need to manage isLoading here.
      _isLoading = false;
      _errorMessage = null; // Ensure error is cleared on success.
      notifyListeners(); // Notify for isLoading and potential error clear.
      return true;
    } on FirebaseAuthException catch (e) {
      // _user state will be handled by authStateChanges (likely remains null or previous state).
      _errorMessage = e.message ?? "An unknown authentication error occurred.";
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage =
          "An unexpected error occurred during login: ${e.toString()}";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logs out the current user.
  // Relies on authStateChanges listener to update _user state to null.
  Future<void> logout() async {
    _isLoading = true;
    _errorMessage = null; // Clear any errors before attempting logout.
    notifyListeners(); // Notify for isLoading and error clear.

    await _auth.signOut();
    // The authStateChanges listener will detect the sign-out,
    // set _user to null, and call notifyListeners.

    _isLoading = false;
    // _errorMessage should already be null or handled by listener.
    notifyListeners(); // Notify for isLoading state change.
  }

  // Helper to clear error messages manually if needed from UI.
  void clearErrorMessage() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }
}
