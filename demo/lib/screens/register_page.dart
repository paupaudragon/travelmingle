import 'dart:io';
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
      body: Padding(
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
                              width: 80, // diameter = 2 * radius
                              height: 80,
                              fit: BoxFit
                                  .cover, // This ensures the image covers the circle properly
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username *'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a username';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email *'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password *'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(labelText: 'Bio (Optional)'),
              ),
              const SizedBox(height: 16),

              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _registerUser,
                      child: const Text('Register'),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  void _registerUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      try {
        final errorMessage = await ApiService.registerAUser(
          username: _usernameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          bio: _bioController.text,
          profileImagePath: _profileImage?.path,
        );

        setState(() {
          isLoading = false;
        });

        if (errorMessage == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration successful!')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      } catch (e) {
        setState(() {
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred: $e')),
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
    super.dispose();
  }
}
