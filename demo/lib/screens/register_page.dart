import 'dart:io';
import 'package:demo/services/notification_service.dart';
import 'package:demo/widgets/loading_animation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _bioController = TextEditingController();

  // Add focus nodes to control focus
  final _usernameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  // Add error message state variables
  String? _usernameError;
  String? _emailError;
  String? _passwordError;

  File? _profileImage; // Store the selected image file
  bool isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path); // Convert to File
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register *'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Picture Field
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey[200],
                      child: _profileImage == null
                          ? const Icon(Icons.camera_alt,
                              size: 40, color: Colors.grey)
                          : ClipOval(
                              child: Image.file(
                                _profileImage!,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Username field with error handling
                TextFormField(
                  controller: _usernameController,
                  focusNode: _usernameFocusNode,
                  decoration: InputDecoration(
                    labelText: 'Username *',
                    errorText: _usernameError,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.person),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.red, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a username';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    // Clear error when user starts typing
                    if (_usernameError != null) {
                      setState(() {
                        _usernameError = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Email field with error handling
                TextFormField(
                  controller: _emailController,
                  focusNode: _emailFocusNode,
                  decoration: InputDecoration(
                    labelText: 'Email *',
                    errorText: _emailError,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.email),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.red, width: 2),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an email';
                    }
                    // Simple email validation
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    // Clear error when user starts typing
                    if (_emailError != null) {
                      setState(() {
                        _emailError = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Password field with error handling
                TextFormField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  decoration: InputDecoration(
                    labelText: 'Password *',
                    errorText: _passwordError,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.lock),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.red, width: 2),
                    ),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    // Clear error when user starts typing
                    if (_passwordError != null) {
                      setState(() {
                        _passwordError = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Bio field
                TextFormField(
                  controller: _bioController,
                  decoration: InputDecoration(
                    labelText: 'Bio (Optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.info_outline),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                // Register button
                isLoading
                    ? const Center(child: LoadingAnimation())
                    : ElevatedButton(
                        onPressed: _registerUser,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Register',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),

                const SizedBox(height: 16),

                // Link to login page
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account?"),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: const Text("Log In"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _registerUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
        _usernameError = null;
        _emailError = null;
        _passwordError = null;
      });

      try {
        final response = await ApiService.registerAUser(
          username: _usernameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          bio: _bioController.text,
          profileImagePath: _profileImage?.path,
        );

        setState(() {
          isLoading = false;
        });

        if (response != null && response["access_token"] != null) {
          await ApiService().saveToken(response["access_token"]);

          // Ensure user is authenticated before registering FCM token
          String? fcmToken = await FirebaseMessaging.instance.getToken();
          if (fcmToken != null) {
            final authToken = await ApiService().getAccessToken();
            if (authToken != null) {
              await NotificationService().registerDeviceToken(fcmToken);
            } else {
              print(
                  '⚠️ Skipping FCM registration, user not authenticated yet.');
            }
          }

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration successful! Logging in...'),
              backgroundColor: Colors.green,
            ),
          );

          await Navigator.pushNamedAndRemoveUntil(
              context, "/feed", (route) => false);
        } else if (response != null && response["error"] != null) {
          // Handle specific error format from the API
          final errors = response["error"];

          if (errors is Map<String, dynamic>) {
            // Check for username errors
            if (errors.containsKey('username')) {
              final usernameErrors = errors['username'];
              if (usernameErrors is List && usernameErrors.isNotEmpty) {
                setState(() {
                  _usernameError = usernameErrors.first.toString();
                });
                _usernameFocusNode.requestFocus();
              }
            }

            // Check for email errors
            if (errors.containsKey('email')) {
              final emailErrors = errors['email'];
              if (emailErrors is List && emailErrors.isNotEmpty) {
                setState(() {
                  _emailError = emailErrors.first.toString();
                });

                // Only focus on email if username doesn't have errors
                if (_usernameError == null) {
                  _emailFocusNode.requestFocus();
                }
              }
            }

            // Check for password errors
            if (errors.containsKey('password')) {
              final passwordErrors = errors['password'];
              if (passwordErrors is List && passwordErrors.isNotEmpty) {
                setState(() {
                  _passwordError = passwordErrors.first.toString();
                });

                // Only focus on password if no other fields have errors
                if (_usernameError == null && _emailError == null) {
                  _passwordFocusNode.requestFocus();
                }
              }
            }

            // If there are errors but none of the specific fields were caught
            if (_usernameError == null &&
                _emailError == null &&
                _passwordError == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Registration failed: ${errors.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } else {
            // Handle generic error string
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errors.toString()),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Unknown error occurred"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        setState(() {
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _bioController.dispose();
    _usernameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }
}
