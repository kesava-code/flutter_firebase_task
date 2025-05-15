// lib/screens/register_screen.dart
// This file defines the RegisterScreen widget, a StatefulWidget that provides
// the UI for new user registration. It includes fields for name, email, password,
// profile image selection, and uses AuthProvider for registration logic.
// Handles form validation, displays loading/error states.
// AuthCheck handles navigation to LoginScreen after successful registration
// (because AuthProvider signs out the user and sets emailForLogin state).
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // For File type
import '../providers/auth_provider.dart';
// LoginScreen import is still needed for "Already have an account?" navigation.
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  static const routeName = '/register';
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controllers for text input fields
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  // GlobalKey for form validation
  final _formKey = GlobalKey<FormState>();

  // Holds the selected profile image file
  XFile? _profileImage;
  // Instance for picking images
  final ImagePicker _picker = ImagePicker();

  // Opens image gallery to pick a profile image
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _profileImage = image;
        });
      }
    } catch (e) {
      // Handle errors during image picking
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: ${e.toString()}')),
        );
      }
    }
  }

  // Handles the user registration process
  void _register(BuildContext context) async {
    // Clear any previous error messages from AuthProvider
    Provider.of<AuthProvider>(context, listen: false).clearErrorMessage();

    // Validate the form fields
    if (!(_formKey.currentState?.validate() ?? false)) {
      return; // If form is not valid, do not proceed.
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // Trim whitespace from inputs
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Attempt to register the user
    bool success = await authProvider.register(
      name,
      email,
      password,
      _profileImage,
    );

    if (success) {
      // If registration is successful
      if (mounted) {
        Navigator.popUntil(context, ModalRoute.withName('/'));
        // NO EXPLICIT NAVIGATION TO LOGIN SCREEN HERE.
        // AuthProvider.register() now signs out the user and sets _emailAfterRegistration.
        // AuthCheck will see the user is null and show LoginScreen.
        // LoginScreen will then read _emailAfterRegistration from AuthProvider.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please log in.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } else {
      // If registration fails, show an error message.
      if (mounted && authProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.errorMessage ??
                  'Registration failed. Please try again.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    // Dispose controllers to free resources
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Access AuthProvider to listen for state changes for UI (isLoading, errorMessage)
    final authProvider = Provider.of<AuthProvider>(context);

    // Using the UI structure from user's previous RegisterScreen example
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
                  'Create Account',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      backgroundImage:
                          _profileImage != null
                              ? FileImage(File(_profileImage!.path))
                              : null,
                      child:
                          _profileImage == null
                              ? Icon(
                                Icons.camera_alt,
                                size: 40,
                                color:
                                    Theme.of(context).colorScheme.onSecondary,
                              )
                              : null,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    _profileImage == null
                        ? 'Tap to add profile photo'
                        : 'Change photo',
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  textCapitalization: TextCapitalization.words,
                  controller: _nameController,
                  focusNode: _nameFocusNode,
                  decoration: InputDecoration(
                    prefixIconColor: Theme.of(context).colorScheme.primary,
                    labelText: 'Full Name',
                    hintText: 'Enter your full name',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name.';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) {
                    FocusScope.of(context).requestFocus(_emailFocusNode);
                  },
                ),
                const SizedBox(height: 16),
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
                  onFieldSubmitted: (value) {
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
                      return 'Please enter a password.';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters long.';
                    }
                    return null;
                  },
                  onFieldSubmitted: (value) {
                    FocusScope.of(
                      context,
                    ).requestFocus(_confirmPasswordFocusNode);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  focusNode: _confirmPasswordFocusNode,
                  obscureText: true,
                  decoration: InputDecoration(
                    prefixIconColor: Theme.of(context).colorScheme.primary,
                    labelText: 'Confirm Password',
                    hintText: 'Re-enter your password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please confirm your password.';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match.';
                    }
                    return null;
                  },
                  onFieldSubmitted: (value) {
                    authProvider.isLoading ? null : _register(context);
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
                      authProvider.isLoading ? null : () => _register(context),
                  child:
                      authProvider.isLoading
                          ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            ),
                          )
                          : Text(
                            'Register',
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
                            // Explicit navigation to LoginScreen is fine here for this button.
                            Navigator.pushNamed(context, LoginScreen.routeName);
                          },
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account?',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const Text(' Login'),
                    ],
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
