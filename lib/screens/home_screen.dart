// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/auth_provider.dart';
import '../providers/user_list_provider.dart'; // Import the UserListProvider

class HomeScreen extends StatefulWidget { // Changed to StatefulWidget for ScrollController
  static const routeName = '/home';
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Optionally, fetch initial users here if not done in provider's constructor,
    // or if you need to pass arguments. For this setup, provider's constructor handles it.
    // final userListProvider = Provider.of<UserListProvider>(context, listen: false);
    // if (userListProvider.users.isEmpty && !userListProvider.isLoadingInitial) {
    //   userListProvider.fetchInitialUsers();
    // }

    // Add listener to scroll controller
    _scrollController.addListener(() {
      // Check if the current scroll position is past 70% of the max scroll extent
      // and if there are more users to fetch and not currently loading more.
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.7) {
        final userListProvider = Provider.of<UserListProvider>(context, listen: false);
        // Check if not already loading more and if there are more users
        if (userListProvider.hasMoreUsers && !userListProvider.isLoadingMore) {
          userListProvider.fetchMoreUsers();
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String capitalizeFirstLetter(String text) {
    if (text.isEmpty) {
      return text;
    }
    return '${text[0].toUpperCase()}${text.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;

    // Use Consumer for UserListProvider to react to its changes
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
              // AuthCheck will handle navigation
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          // Current user info section (remains the same)
          if (currentUser != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUser.uid)
                    .snapshots(),
                builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                  if (snapshot.hasError) return Text('Error: ${snapshot.error}');
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                  }
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Text('Current user data not found.');
                  }
                  final userData = snapshot.data!.data() as Map<String, dynamic>;
                  return Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundImage: userData['profileImageUrl'] != null
                            ? CachedNetworkImageProvider(userData['profileImageUrl'])
                            : null,
                        child: userData['profileImageUrl'] == null
                            ? const Icon(Icons.person_outline, size: 25)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded( // Use Expanded to prevent overflow if text is long
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Welcome, ${userData['name'] ?? 'User'}!".toUpperCase(),
                              style: Theme.of(context).textTheme.titleMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              userData['email'] ?? 'No email',
                              style: Theme.of(context).textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          if (currentUser != null) const Divider(),

          // Paginated list of all users
          Expanded(
            child: Consumer<UserListProvider>(
              builder: (context, userListProvider, child) {
                if (userListProvider.isLoadingInitial) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (userListProvider.users.isEmpty && !userListProvider.hasMoreUsers) {
                  return const Center(child: Text('No users found.'));
                }

                return RefreshIndicator(
                  onRefresh: () => userListProvider.refreshUsers(),
                  child: ListView.builder(
                    controller: _scrollController, // Attach scroll controller
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    itemCount: userListProvider.users.length +
                        (userListProvider.hasMoreUsers ? 1 : 0), // Add 1 for loader/button
                    itemBuilder: (BuildContext context, int index) {
                      // Check if this is the last item (loader/button)
                      if (index == userListProvider.users.length) {
                        if (userListProvider.isLoadingMore) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0), // Increased padding for visibility
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        } else if (userListProvider.hasMoreUsers) {
                          // This space is reserved for the loader. If not loading and has more,
                          // it means the scroll listener will trigger the fetch.
                          // You could put a small SizedBox here or a subtle indicator if preferred.
                          return const SizedBox(height: 40); // Placeholder for when not loading but more available
                        } else {
                          // No more users and not loading more
                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Center(child: Text(userListProvider.users.isEmpty ? "" : "No more users.")),
                          );
                        }
                      }

                      // Display user data
                      final DocumentSnapshot document = userListProvider.users[index];
                      final Map<String, dynamic> data = document.data()! as Map<String, dynamic>;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 6.0),
                        elevation: 2.0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0)),
                        child: ListTile(
                          leading: CircleAvatar(
                            radius: 25,
                            backgroundImage: data['profileImageUrl'] != null
                                ? CachedNetworkImageProvider(data['profileImageUrl'])
                                : null,
                            backgroundColor: Colors.grey[200],
                            child: data['profileImageUrl'] == null
                                ? const Icon(Icons.person_outline, size: 25)
                                : null,
                          ),
                          title: Text(
                            capitalizeFirstLetter(data['name'] ?? 'No Name'),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(data['email'] ?? 'No Email'),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
