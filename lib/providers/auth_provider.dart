// This file defines the AuthProvider class, which manages user authentication
// (registration, login, logout) using Firebase Auth. It also handles storing
// user details in Cloud Firestore and profile image uploads to Firebase Storage.
// It utilizes ChangeNotifier to update the UI based on authentication state,
// loading status, and error messages. The _auth.authStateChanges stream is the
// primary source of truth for the user's authentication state (_user).

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // Required for File type
import 'package:firebase_storage/firebase_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // Import for connectivity check

class AuthProvider extends ChangeNotifier {
  User? _user;
  User? get user => _user;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // New property to hold email after registration for LoginScreen pre-fill
  String? _emailAfterRegistration;
  String? get emailAfterRegistration => _emailAfterRegistration;


  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Connectivity _connectivity = Connectivity();

  AuthProvider() {
   
    _auth.authStateChanges().listen((User? firebaseUser) {
     
      if (_user != firebaseUser) {
        _user = firebaseUser;
        // Don't clear _errorMessage here if firebaseUser is null,
        // as it might be a network error during an operation.
        // Let individual methods handle their specific errors.
        // Only clear general auth error if user successfully logs in.
        if (firebaseUser != null) {
            _errorMessage = null;
        }
       
        notifyListeners();
      } 
    });
  }

  Future<bool> _checkInternetConnectivity() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      _errorMessage = "No internet connection. Please check your network and try again.";
      return false;
    }
    return true;
  }

  Future<bool> register(
    String name,
    String email,
    String password,
    XFile? profileImage,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    _emailAfterRegistration = null; // Clear any previous
    notifyListeners();

    if (!await _checkInternetConnectivity()) {
      _isLoading = false;
      notifyListeners();
      return false;
    }

    if (profileImage == null) {
      _isLoading = false;
      _errorMessage = "Please select a profile photo.";
      notifyListeners();
      return false;
    }

    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      
      User? createdFirebaseUser = userCredential.user;

      if (createdFirebaseUser != null) {
        final Reference storageRef = _storage.ref().child(
              'user_profiles/${createdFirebaseUser.uid}/profile.jpg',
            );
        await storageRef.putFile(File(profileImage.path));
        final String profileImageUrl = await storageRef.getDownloadURL();

        await _firestore.collection('users').doc(createdFirebaseUser.uid).set({
          'uid': createdFirebaseUser.uid,
          'name': name,
          'email': email,
          'profileImageUrl': profileImageUrl,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Set the email for LoginScreen to pick up
        _emailAfterRegistration = email;
       

        await _auth.signOut(); // This will trigger authStateChanges
      } else {
        _errorMessage = "User creation succeeded but Firebase user data is null.";
         _isLoading = false;
        notifyListeners();
        return false;
      }
      
      _isLoading = false;
      // Notify for isLoading and for _emailAfterRegistration being set.
      // The user becoming null will be handled by authStateChanges.
      notifyListeners();
      return true; 
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? "An unknown authentication error occurred.";
      _isLoading = false;
      notifyListeners();
      return false; 
    } catch (e) {
       _errorMessage = "An unexpected error occurred during registration: ${e.toString()}";
      _isLoading = false;
      notifyListeners();
      return false; 
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    _emailAfterRegistration = null; // Clear it on login attempt
    notifyListeners();

    if (!await _checkInternetConnectivity()) {
      _isLoading = false;
      notifyListeners(); 
      return false;
    }

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      // authStateChanges listener will update _user and notify.
      _isLoading = false;
      // _errorMessage = null; // Already set above, and listener clears it if user becomes non-null
      notifyListeners(); 
      return true; 
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? "An unknown authentication error occurred.";
      _isLoading = false;
      notifyListeners();
      return false; 
    } catch (e) {
      _errorMessage = "An unexpected error occurred during login: ${e.toString()}";
      _isLoading = false;
      notifyListeners();
      return false; 
    }
  }

  // Method for LoginScreen to call after consuming the email.
  void clearEmailAfterRegistration() {
    if (_emailAfterRegistration != null) {
     
      _emailAfterRegistration = null;
      // Optionally notify listeners if any UI specifically depends on _emailAfterRegistration,
      // but for pre-filling, it's usually a one-time read.
      // notifyListeners(); 
    }
  }

  Future<void> logout() async {
    _isLoading = true; 
    _errorMessage = null;
    _emailAfterRegistration = null; // Clear this on logout too
    notifyListeners();

    await _auth.signOut();
    // authStateChanges listener will set _user to null and notify.
    _isLoading = false;
    notifyListeners();
  }

  void clearErrorMessage() {
    if (_errorMessage != null) {
      _errorMessage = null;
      _emailAfterRegistration = null; // Also clear this when errors are cleared
      notifyListeners();
    }
  }
}
