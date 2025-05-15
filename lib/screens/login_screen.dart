// lib/screens/login_screen.dart
// This file defines the LoginScreen widget, a StatefulWidget providing the UI
// for user login. It includes email and password fields, utilizes AuthProvider
// for authentication, and handles form validation. Displays loading states and
// error messages. Navigation to HomeScreen is handled by AuthCheck based on
// AuthProvider's state. Can pre-fill email (from AuthProvider state) and
// focus password if navigated from registration.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'register_screen.dart'; // For "CREATE ACCOUNT" button navigation

class LoginScreen extends StatefulWidget {
  static const routeName = '/login';
  // Constructor no longer needs emailFromRegistration, will get from Provider.
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers for text input fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  // GlobalKey for form validation
  final _formKey = GlobalKey<FormState>();
  // FocusNode to programmatically focus the password field
  final _passwordFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Try to pre-fill email after the first frame has been built.
    // This ensures that context is available and AuthProvider can be accessed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybePrefillEmailAndFocus();
    });
  }

  void _maybePrefillEmailAndFocus() {
    if (!mounted) return; // Ensure widget is still in the tree.

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final emailToPrefill = authProvider.emailAfterRegistration;

    print(
      "[LoginScreen] _maybePrefillEmailAndFocus called. Email from provider: $emailToPrefill",
    );

    if (emailToPrefill != null && emailToPrefill.isNotEmpty) {
      _emailController.text = emailToPrefill;
      // Important: Clear the email from AuthProvider state after consuming it.
      authProvider.clearEmailAfterRegistration();
      // Request focus on the password field.
      if (mounted) {
        // Check mounted again before requesting focus
        FocusScope.of(context).requestFocus(_passwordFocusNode);
      }
    }
    // Fallback: Check for route arguments (can be removed if only using AuthProvider state for this)
    // For now, this provides a secondary way if LoginScreen is pushed with arguments directly.
    else {
      final arguments = ModalRoute.of(context)?.settings.arguments;
      if (arguments is String &&
          arguments.isNotEmpty &&
          _emailController.text.isEmpty) {
        _emailController.text = arguments;
        if (mounted) {
          FocusScope.of(context).requestFocus(_passwordFocusNode);
        }
      } else if (mounted) {
        // If no pre-fill, focus the email field initially.
        FocusScope.of(context).requestFocus(_emailFocusNode);
      }
    }
  }

  // Handles the user login process
  void _login(BuildContext context) async {
    // Clear any previous error messages from AuthProvider
    Provider.of<AuthProvider>(context, listen: false).clearErrorMessage();

    // Validate the form fields
    if (!(_formKey.currentState?.validate() ?? false)) {
      return; // If form is not valid, do not proceed.
    }
    FocusScope.of(context).unfocus();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // Trim whitespace from inputs.
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Attempt to log in
    bool success = await authProvider.login(email, password);

    if (success) {
      Navigator.popUntil(context, ModalRoute.withName('/'));
      // Navigation to HomeScreen is handled by AuthCheck widget
      // based on AuthProvider's user state. No explicit navigation here.
    } else {
      // If login fails, show an error message using SnackBar.
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
    // Dispose controllers and focus node to free up resources
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Access AuthProvider to listen for changes in isLoading or errorMessage for the UI.
    final authProvider = Provider.of<AuthProvider>(context);

    // Using the UI structure from user's previous LoginScreen example
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Welcome Back!',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _emailController,

                  focusNode: _emailFocusNode,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    prefixIconColor: Theme.of(context).colorScheme.primary,
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
                  onFieldSubmitted: (_) {
                    // When "next" is pressed
                    FocusScope.of(context).requestFocus(_passwordFocusNode);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  obscureText: true,
                  decoration: InputDecoration(
                    prefixIconColor: Theme.of(context).colorScheme.primary,
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
                  onFieldSubmitted: (_) {
                    authProvider.isLoading ? null : _login(context);
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
                  onPressed:
                      authProvider.isLoading ? null : () => _login(context),
                  child:
                      authProvider.isLoading
                          ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                          ? null
                          : () {
                            // Explicit navigation to RegisterScreen is fine here.
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
                // Optional: Inline error message display
                // if (authProvider.errorMessage != null && !authProvider.isLoading)
                //   Padding(
                //     padding: const EdgeInsets.only(top: 16.0),
                //     child: Text(
                //       authProvider.errorMessage!,
                //       style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
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
