import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
// Assuming your project structure might be 'providers/auth_provider.dart'
// If it's directly under lib, then 'auth_provider.dart' is fine.
// For this example, I'll use the path from your import.
import 'package:flutter_firebase_task/providers/auth_provider.dart';
import 'package:flutter_firebase_task/screens/home_screen.dart';
import 'package:flutter_firebase_task/screens/login_screen.dart';
import 'package:flutter_firebase_task/screens/register_screen.dart';
import 'package:provider/provider.dart';

void main() async {
  // Ensure Flutter bindings are initialized before Firebase.
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase.
  await Firebase.initializeApp();
  // Run the application.
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // MultiProvider makes AuthProvider available to the widget tree.
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: MaterialApp(
        // Theme settings from your provided code.
        darkTheme: ThemeData.dark(),
        routes: {
          LoginScreen.routeName: (ctx) => const LoginScreen(),
          RegisterScreen.routeName: (ctx) => const RegisterScreen(),
          HomeScreen.routeName: (ctx) => const HomeScreen(),
        },
        debugShowCheckedModeBanner: false,
        title: 'Flutter Sample Task', // Title from your provided code.
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blueAccent,
          ), // Theme from your code.
          // useMaterial3: true, // Consider adding useMaterial3 if you are using Material 3 features.
        ),
        // The AuthCheck widget determines the initial screen based on auth state.
        home: const AuthCheck(),
      ),
    );
  }
}

// AuthCheck widget listens to the authentication state and navigates accordingly.
class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    // Add a print statement here to see when AuthCheck rebuilds.
    print("[AuthCheck] build() called.");

    // Listen to AuthProvider to get the current user state.
    // Provider.of<AuthProvider>(context) without listen: false ensures this widget rebuilds on notifyListeners().
    final authProvider = Provider.of<AuthProvider>(context);
    print("[AuthCheck] authProvider.user: ${authProvider.user?.uid}");

    // If a user is logged in, show the HomeScreen.
    if (authProvider.user != null) {
      print("[AuthCheck] User is authenticated. Showing HomeScreen.");
      // Using a ValueKey ensures HomeScreen is treated as a new widget if it needs to be rebuilt.
      return const HomeScreen(key: ValueKey('HomeScreen'));
    } else {
      // Otherwise, show the LoginScreen.
      print("[AuthCheck] User is not authenticated. Showing LoginScreen.");
      // Using a ValueKey ensures LoginScreen is treated as a new widget if it needs to be rebuilt.
      return const LoginScreen(key: ValueKey('LoginScreen'));
    }
  }
}
