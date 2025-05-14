// lib/screens/register_screen.dart
// This file defines the RegisterScreen widget, a StatefulWidget that provides
// the UI for new user registration. It includes fields for name, email, password,
// profile image selection, and uses AuthProvider for registration logic.
// Handles form validation, displays loading/error states, and navigates
// to HomeScreen on success or allows navigation back to the LoginScreen.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // For File type
import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  static const routeName = '/register'; // Route name for navigation.
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controllers for text input fields.
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController =
      TextEditingController(); // For password confirmation.
  final _formKey = GlobalKey<FormState>(); // Key for form validation.

  // Holds the selected profile image file.
  XFile? _profileImage;
  final ImagePicker _picker = ImagePicker(); // Instance for picking images.

  // Opens image gallery to pick a profile image.
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50, // Optional: Compress image.
        maxWidth: 800, // Optional: Resize image.
      );
      if (image != null) {
        setState(() {
          _profileImage = image;
        });
      }
    } catch (e) {
      // Handle errors during image picking (e.g., permissions).
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: ${e.toString()}')),
        );
      }
    }
  }

  // Handles the user registration process.
  void _register(BuildContext context) async {
    // Clear any previous error messages from AuthProvider.
    Provider.of<AuthProvider>(context, listen: false).clearErrorMessage();

    // Validate the form. If invalid, do not proceed.
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // Trim whitespace from input values.
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    bool success = await authProvider.register(
      name,
      email,
      password,
      _profileImage,
    );

    if (success) {
      // Navigate to HomeScreen on successful registration.
      if (mounted) {
        Navigator.pushReplacementNamed(context, HomeScreen.routeName);
      }
    } else {
      // Show error message if registration fails.
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
    // Dispose controllers to free resources.
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Center(
        // Center the form content.
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0), // Add padding around the form.
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment
                      .stretch, // Make buttons stretch to full width.
              children: [
                Text(
                  'Create Account',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Profile Image Picker UI.
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[300],
                      backgroundImage:
                          _profileImage != null
                              ? FileImage(File(_profileImage!.path))
                              : null,
                      child:
                          _profileImage == null
                              ? Icon(
                                Icons.camera_alt,
                                size: 40,
                                color: Colors.grey[700],
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
                  controller: _nameController,
                  decoration: InputDecoration(
                    prefixIconColor: Theme.of(context).primaryColor,
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
                ),
                const SizedBox(height: 16),
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
                    // More sophisticated email validation could be added here.
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
                      return 'Please enter a password.';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters long.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    prefixIconColor: Theme.of(context).primaryColor,
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
                              color: Theme.of(context).colorScheme.onPrimary,
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
                            // Navigate back to the LoginScreen.
                            Navigator.pushReplacementNamed(
                              context,
                              LoginScreen.routeName,
                            );
                          },
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account?',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(' Login'),
                    ],
                  ),
                ),
                // Display error message from AuthProvider, if any, and not loading.
                // if (authProvider.errorMessage != null &&
                //     `!authProvider.isLoading)
                //   Padding(
                //     padding: const EdgeInsets.only(top: 16.0),
                //     child: Text(
                //       authProvider.errorMessage!,
                //       style: const TextStyle(
                //         color: Colors.red,
                //         fontWeight: FontWeight.bold,
                //       ),
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
