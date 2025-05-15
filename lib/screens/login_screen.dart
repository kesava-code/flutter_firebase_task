// lib/screens/login_screen.dart
// This file defines the LoginScreen widget, a StatefulWidget providing the UI
// for user login. It includes email and password fields, utilizes AuthProvider
// for authentication, and handles form validation. Displays loading states and
// error messages. Navigation to HomeScreen is handled by AuthCheck based on
// AuthProvider's state. Can pre-fill email and focus password if navigated
// from registration.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'register_screen.dart';
// HomeScreen import is not needed here as AuthCheck handles navigation to it.

class LoginScreen extends StatefulWidget {
  static const routeName = '/login'; // Route name for navigation.
  final String?
  emailFromRegistration; // Optional: To accept email if passed via constructor

  const LoginScreen({super.key, this.emailFromRegistration});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers for text input fields.
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  // GlobalKey for form validation.
  final _formKey = GlobalKey<FormState>();
  // FocusNode to programmatically focus the password field.
  final _passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Check if email was passed from registration screen via constructor argument.
    if (widget.emailFromRegistration != null &&
        widget.emailFromRegistration!.isNotEmpty) {
      _emailController.text = widget.emailFromRegistration!;
      // Request focus on password field after the first frame renders.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Ensure the widget is still in the tree.
          FocusScope.of(context).requestFocus(_passwordFocusNode);
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if arguments were passed via Navigator.pushNamed's arguments parameter
    // and if the email controller is still empty (e.g., not set by constructor).
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is String &&
        arguments.isNotEmpty &&
        _emailController.text.isEmpty) {
      _emailController.text = arguments;
      // Request focus on password field after the first frame renders.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Ensure the widget is still in the tree.
          FocusScope.of(context).requestFocus(_passwordFocusNode);
        }
      });
    }
  }

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

    // Attempt to log in using AuthProvider.
    bool success = await authProvider.login(email, password);

    if (success) {
      // Navigation to HomeScreen is handled by AuthCheck widget
      // based on AuthProvider's user state. No explicit navigation here.
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
    // Dispose controllers and FocusNode to free resources.
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Access AuthProvider to listen for state changes (isLoading, errorMessage).
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      // No AppBar as per user's provided structure.
      // If an AppBar were added, automaticallyImplyLeading: false would be recommended
      // because AuthCheck handles the primary navigation flow.
      body: Center(
        // Center the form content.
        child: SingleChildScrollView(
          // Allow scrolling for smaller screens.
          padding: const EdgeInsets.all(24.0), // Add padding around the form.
          child: Form(
            key: _formKey, // Assign the GlobalKey to the Form.
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center, // Center content vertically.
              crossAxisAlignment:
                  CrossAxisAlignment.stretch, // Make buttons stretch.
              children: [
                // Welcome message.
                Text(
                  'Welcome Back!',
                  style:
                      Theme.of(context)
                          .textTheme
                          .titleLarge, // Using titleLarge from user's code.
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24), // Spacing.
                // Email Text Field.
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    prefixIconColor:
                        Theme.of(
                          context,
                        ).colorScheme.primary, // From user's code.
                    labelText: 'Email',
                    hintText: 'Enter your email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  validator: (value) {
                    // Email validation.
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email.';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Please enter a valid email address.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16), // Spacing.
                // Password Text Field.
                TextFormField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode, // Assign the FocusNode.
                  obscureText: true, // Hide password text.
                  decoration: InputDecoration(
                    prefixIconColor:
                        Theme.of(
                          context,
                        ).colorScheme.primary, // From user's code.
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  validator: (value) {
                    // Password validation.
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your password.';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters long.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24), // Spacing.
                // Login Button.
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(
                          context,
                        ).colorScheme.primary, // From user's code.
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
                            // Show progress indicator when loading.
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onPrimary, // From user's code.
                            ),
                          )
                          : Text(
                            // Show "Login" text.
                            'Login',
                            style: TextStyle(
                              fontSize: 16,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onPrimary, // From user's code.
                            ),
                          ),
                ),
                const SizedBox(height: 16), // Spacing.
                // Navigation to Register Screen.
                TextButton(
                  onPressed:
                      authProvider.isLoading
                          ? null // Disable if loading.
                          : () {
                            // Navigate to the RegisterScreen.
                            // Using pushReplacementNamed to replace LoginScreen in the stack,
                            // which is often cleaner for auth flows.
                            Navigator.pushReplacementNamed(
                              context,
                              RegisterScreen.routeName,
                            );
                          },
                  child: Text(
                    "CREATE ACCOUNT", // Text from user's code.
                    style:
                        Theme.of(
                          context,
                        ).textTheme.titleSmall, // Style from user's code.
                  ),
                ),
                // Display error message directly on screen (commented out as per user's code).
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
