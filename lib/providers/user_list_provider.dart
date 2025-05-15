// lib/providers/user_list_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserListProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // List to hold the fetched user documents
  List<DocumentSnapshot> _users = [];
  List<DocumentSnapshot> get users => _users;

  // To keep track of the last document fetched for pagination
  DocumentSnapshot? _lastDocument;

  // Loading state for the initial fetch
  bool _isLoadingInitial = true;
  bool get isLoadingInitial => _isLoadingInitial;

  // Loading state for fetching more users
  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  // Flag to indicate if there are more users to fetch
  bool _hasMoreUsers = true;
  bool get hasMoreUsers => _hasMoreUsers;

  // Number of documents to fetch per page
  final int _documentsPerPage = 10; // You can adjust this value

  UserListProvider() {
    // Fetch the initial batch of users when the provider is created
    fetchInitialUsers();
  }

  // Fetches the first batch of users
  Future<void> fetchInitialUsers() async {
   
    _isLoadingInitial = true;
    _users = []; // Reset users list
    _lastDocument = null; // Reset last document
    _hasMoreUsers = true; // Assume there are more users initially
    notifyListeners();

    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .orderBy('createdAt', descending: true) // Ensure consistent ordering
          .limit(_documentsPerPage)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        _users.addAll(querySnapshot.docs);
        _lastDocument = querySnapshot.docs.last;
      }

      // Check if there are more users
      _hasMoreUsers = querySnapshot.docs.length == _documentsPerPage;

    } catch (e) {
      // Handle error appropriately, maybe set an error message state
    }

    _isLoadingInitial = false;
    notifyListeners();
  }

  // Fetches the next batch of users
  Future<void> fetchMoreUsers() async {
    if (_isLoadingMore || !_hasMoreUsers || _lastDocument == null) {
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .orderBy('createdAt', descending: true) // Ensure consistent ordering
          .startAfterDocument(_lastDocument!) // Start after the last fetched document
          .limit(_documentsPerPage)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        _users.addAll(querySnapshot.docs);
        _lastDocument = querySnapshot.docs.last;
      }

      // Update if there are more users
      _hasMoreUsers = querySnapshot.docs.length == _documentsPerPage;

    } catch (e) {
      // Handle error appropriately
    }

    _isLoadingMore = false;
    notifyListeners();
  }

  // Helper to reset and refetch, e.g., for pull-to-refresh
  Future<void> refreshUsers() async {
    await fetchInitialUsers();
  }
}
