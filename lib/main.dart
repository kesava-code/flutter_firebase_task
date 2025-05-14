import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_firebase_task/providers/auth_provider.dart';
import 'package:flutter_firebase_task/screens/home_screen.dart';
import 'package:flutter_firebase_task/screens/login_screen.dart';
import 'package:flutter_firebase_task/screens/register_screen.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],

      child: MaterialApp(
        routes: {
          LoginScreen.routeName: (ctx) => const LoginScreen(),
          RegisterScreen.routeName: (ctx) => const RegisterScreen(),
          HomeScreen.routeName: (ctx) => const HomeScreen(),
        },
        debugShowCheckedModeBanner: false,
        title: 'Flutter Sample Task',
        theme: ThemeData(
          // This is the theme of your application.
          //
          // TRY THIS: Try running your application with "flutter run". You'll see
          // the application has a purple toolbar. Then, without quitting the app,
          // try changing the seedColor in the colorScheme below to Colors.green
          // and then invoke "hot reload" (save your changes or press the "hot
          // reload" button in a Flutter-supported IDE, or press "r" if you used
          // the command line to start the app).
          //
          // Notice that the counter didn't reset back to zero; the application
          // state is not lost during the reload. To reset the state, use hot
          // restart instead.
          //
          // This works for code too, not just values: Most code changes can be
          // tested with just a hot reload.
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
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
    // Listen to AuthProvider to get the current user state.
    // No need for `listen: false` here as this widget *should* rebuild when auth state changes.
    final authProvider = Provider.of<AuthProvider>(context);

    // If a user is logged in, show the HomeScreen.
    if (authProvider.user != null) {
      return const HomeScreen();
    } else {
      // Otherwise, show the LoginScreen.
      return const LoginScreen();
    }
  }
}
