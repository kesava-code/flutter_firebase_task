// This file defines the LoginScreen widget, a StatefulWidget providing the UI
// for user login. It includes email and password fields, utilizes AuthProvider
// for authentication, and handles form validation. Displays loading states and
// error messages (via SnackBar and inline text), navigates to HomeScreen on
// successful login, or to RegisterScreen for new users.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  static const routeName = '/login'; // Route name for navigation.
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers for text input fields.
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // Key for form validation.

  // Handles the user login process.
  void _login(BuildContext context) async {
    // Clear any previous error messages.
    Provider.of<AuthProvider>(context, listen: false).clearErrorMessage();

    // Validate the form. If invalid, do not proceed.
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // Trim whitespace from input values.
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    bool success = await authProvider.login(email, password);

    if (success) {
      // Navigate to HomeScreen on successful login, replacing the current screen.
      if (mounted) {
        // Check if the widget is still in the tree.
        Navigator.pushReplacementNamed(context, HomeScreen.routeName);
      }
    } else {
      // Show error message via SnackBar if login fails.
      if (mounted && authProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.errorMessage ?? 'Login failed. Please try again.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    // Dispose controllers to free resources.
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Access AuthProvider to listen for state changes (isLoading, errorMessage).
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Center(
        // Center the form content.
        child: SingleChildScrollView(
          // Allow scrolling for smaller screens.
          padding: const EdgeInsets.all(24.0), // Add padding around the form.
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.stretch, // Make buttons stretch.
              children: [
                // Optional: App Logo or Title
                // const SizedBox(height: 24),
                Text(
                  'Welcome Back!',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    prefixIconColor: Theme.of(context).primaryColor,
                    labelText: 'Email',
                    hintText: 'Enter your email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email.';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Please enter a valid email address.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    prefixIconColor: Theme.of(context).primaryColor,
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your password.';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters long.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  // Disable button while loading, otherwise call _login.
                  onPressed:
                      authProvider.isLoading ? null : () => _login(context),
                  child:
                      authProvider.isLoading
                          ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          )
                          : Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed:
                      authProvider.isLoading
                          ? null // Disable if loading.
                          : () {
                            // Navigate to the RegisterScreen.
                            Navigator.pushNamed(
                              context,
                              RegisterScreen.routeName,
                            );
                          },
                  child: Text(
                    "CREATE ACCOUNT",
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                // Display error message directly on screen (alternative/addition to SnackBar).
                // if (authProvider.errorMessage != null &&
                //     `!authProvider.isLoading)
                //   Padding(
                //     padding: const EdgeInsets.only(top: 16.0),
                //     child: Text(
                //       authProvider.errorMessage!,
                //       style: const TextStyle(
                //           color: Colors.red, fontWeight: FontWeight.bold),
                //       textAlign: TextAlign.center,
                //     ),
                //   ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
