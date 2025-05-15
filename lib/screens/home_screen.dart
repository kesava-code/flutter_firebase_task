// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart'; // For navigation after logout

class HomeScreen extends StatelessWidget {
  static const routeName = '/home';
  const HomeScreen({super.key});

  String capitalizeFirstLetter(String text) {
    if (text.isEmpty) {
      return text;
    }
    return '${text[0].toUpperCase()}${text.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    // Access AuthProvider, listen: false because we only need it for the logout action.
    // User data for the current user can be fetched directly if needed, or passed.
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user; // Get the currently logged-in user

    return Scaffold(
      appBar: AppBar(
        title: const Text('USERS'),
        actions: [
          IconButton(
            iconSize: 30,
            color: Theme.of(context).colorScheme.primary,
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () async {
              await authProvider.logout();
              // The AuthCheck widget will handle navigation to LoginScreen
            },
          ),
          SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          // Optional: Display current user's info at the top
          if (currentUser != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: StreamBuilder<DocumentSnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(currentUser.uid)
                        .snapshots(),
                builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                  if (snapshot.hasError)
                    return Text('Error: ${snapshot.error}');
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return const CircularProgressIndicator();
                  if (!snapshot.hasData || !snapshot.data!.exists)
                    return const Text('Current user data not found.');

                  final userData =
                      snapshot.data!.data() as Map<String, dynamic>;
                  return Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundImage:
                            userData['profileImageUrl'] != null
                                ? CachedNetworkImageProvider(
                                  userData['profileImageUrl'],
                                )
                                : null,
                        child:
                            userData['profileImageUrl'] == null
                                ? const Icon(Icons.person_outline, size: 25)
                                : null,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Welcome, ${userData['name'] ?? 'User'}!"
                                .toUpperCase(),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            userData['email'] ?? 'No email',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          if (currentUser != null) const Divider(),

          // List of all users
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Stream to listen to changes in the 'users' collection.
              stream:
                  FirebaseFirestore.instance
                      .collection('users')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
              builder: (
                BuildContext context,
                AsyncSnapshot<QuerySnapshot> snapshot,
              ) {
                // Handle errors.
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Something went wrong. Please try again.'),
                  );
                }

                // Show a loading indicator while data is being fetched.
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // If there's no data or no documents, show a message.
                if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No users found.'));
                }

                // If data is available, build the ListView.
                return ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  children:
                      snapshot.data!.docs.map((DocumentSnapshot document) {
                        // Cast the document data to a Map.
                        Map<String, dynamic> data =
                            document.data()! as Map<String, dynamic>;
                        // Skip displaying the current user in the list of other users (optional)
                        // if (currentUser != null && data['uid'] == currentUser.uid) {
                        //   return const SizedBox.shrink(); // Or some other widget
                        // }

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 6.0,
                          ),
                          elevation: 2.0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 25,
                              // Use CachedNetworkImageProvider for efficient image loading and caching.
                              backgroundImage:
                                  data['profileImageUrl'] != null
                                      ? CachedNetworkImageProvider(
                                        data['profileImageUrl'],
                                      )
                                      : null,
                              backgroundColor:
                                  Colors
                                      .grey[200], // Explicitly null if no image
                              // Show a placeholder icon if no image URL is available.
                              child:
                                  data['profileImageUrl'] == null
                                      ? const Icon(
                                        Icons.person_outline,
                                        size: 25,
                                      )
                                      : null, // Background for the avatar
                            ),
                            title: Text(
                              capitalizeFirstLetter(data['name']),
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
