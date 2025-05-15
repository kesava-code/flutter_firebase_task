// lib/screens/register_screen.dart
// This file defines the RegisterScreen widget, a StatefulWidget that provides
// the UI for new user registration. It includes fields for name, email, password,
// profile image selection, and uses AuthProvider for registration logic.
// Handles form validation, displays loading/error states, and navigates
// to LoginScreen on success (passing the email) or allows navigation back to LoginScreen.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // For File type
import '../providers/auth_provider.dart';
// HomeScreen import is no longer needed as navigation goes to LoginScreen.
import 'login_screen.dart'; // For navigation to LoginScreen.

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
  // GlobalKey for form validation.
  final _formKey = GlobalKey<FormState>();

  // Holds the selected profile image file.
  XFile? _profileImage;
  // Instance for picking images.
  final ImagePicker _picker = ImagePicker();

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
    final email = _emailController.text.trim(); // Get email to pass to LoginScreen.
    final password = _passwordController.text.trim();

    // Attempt to register the user using AuthProvider.
    bool success = await authProvider.register(
      name,
      email,
      password,
      _profileImage,
    );

    if (success) {
      // If registration is successful:
      if (mounted) {
        // Navigate to LoginScreen, replacing the current screen.
        // Pass the registered email as an argument to LoginScreen.
        Navigator.pushReplacementNamed(
          context,
          LoginScreen.routeName,
          arguments: email, // Pass the email.
        );
        // Show a success message to the user.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please log in.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
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
    // Access AuthProvider to listen for state changes (isLoading, errorMessage).
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      // No AppBar as per user's provided structure.
      body: Center(
        // Center the form content.
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0), // Add padding around the form.
          child: Form(
            key: _formKey, // Assign the GlobalKey to the Form.
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // Center content vertically.
              crossAxisAlignment:
                  CrossAxisAlignment.stretch, // Make buttons stretch to full width.
              children: [
                // Title.
                Text(
                  'Create Account',
                  style: Theme.of(context).textTheme.titleLarge, // Style from user's code.
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24), // Spacing.
                // Profile Image Picker UI.
                Center(
                  child: GestureDetector(
                    onTap: _pickImage, // Call _pickImage when tapped.
                    child: CircleAvatar(
                      radius: 50, // Size of the avatar.
                      backgroundColor: Theme.of(context).colorScheme.secondary, // From user's code.
                      backgroundImage:
                          _profileImage != null
                              ? FileImage(File(_profileImage!.path))
                              : null, // Display selected image.
                      child:
                          _profileImage == null
                              ? Icon( // Show camera icon if no image.
                                  Icons.camera_alt,
                                  size: 40,
                                  color:
                                      Theme.of(context).colorScheme.onSecondary, // From user's code.
                                )
                              : null,
                    ),
                  ),
                ),
                const SizedBox(height: 8), // Spacing.
                // Text instruction for image picker.
                Center(
                  child: Text(
                    _profileImage == null
                        ? 'Tap to add profile photo'
                        : 'Change photo',
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                ),
                const SizedBox(height: 24), // Spacing.
                // Name Text Field.
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    prefixIconColor: Theme.of(context).colorScheme.primary, // From user's code.
                    labelText: 'Full Name',
                    hintText: 'Enter your full name',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  validator: (value) { // Name validation.
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16), // Spacing.
                // Email Text Field.
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    prefixIconColor: Theme.of(context).colorScheme.primary, // From user's code.
                    labelText: 'Email',
                    hintText: 'Enter your email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  validator: (value) { // Email validation.
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
                  obscureText: true, // Hide password text.
                  decoration: InputDecoration(
                    prefixIconColor: Theme.of(context).colorScheme.primary, // From user's code.
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  validator: (value) { // Password validation.
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a password.';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters long.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16), // Spacing.
                // Confirm Password Text Field.
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true, // Hide password text.
                  decoration: InputDecoration(
                    prefixIconColor: Theme.of(context).colorScheme.primary, // From user's code.
                    labelText: 'Confirm Password',
                    hintText: 'Re-enter your password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  validator: (value) { // Confirm password validation.
                    if (value == null || value.trim().isEmpty) {
                      return 'Please confirm your password.';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24), // Spacing.
                // Register Button.
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary, // From user's code.
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  onPressed:
                      authProvider.isLoading ? null : () => _register(context), // Disable if loading.
                  child:
                      authProvider.isLoading
                          ? SizedBox( // Show progress indicator when loading.
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.onPrimary, // From user's code.
                              ),
                            )
                          : Text( // Show "Register" text.
                              'Register',
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.onPrimary, // From user's code.
                              ),
                            ),
                ),
                const SizedBox(height: 16), // Spacing.
                // Navigation to Login Screen.
                TextButton(
                  onPressed:
                      authProvider.isLoading
                          ? null // Disable if loading.
                          : () {
                              // Navigate back to the LoginScreen, replacing current screen.
                              Navigator.pushReplacementNamed(
                                context,
                                LoginScreen.routeName,
                              );
                            },
                  child: Row( // Structure from user's code.
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account?',
                        style: Theme.of(context).textTheme.titleSmall, // Style from user's code.
                      ),
                      const Text(' Login'), // Added space for better visual.
                    ],
                  ),
                ),
                // Display error message (commented out as per user's code).
                // if (authProvider.errorMessage != null &&
                //     !authProvider.isLoading)
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
