import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../home/home_screen.dart';
import 'authService.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  File? image;
  XFile? webImage; // For web compatibility
  final picker = ImagePicker();
  bool isLoading = false;

  final _formKey = GlobalKey<FormState>();
  final firstCtrl = TextEditingController();
  final lastCtrl = TextEditingController();
  final ageCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  final AuthService _authService = AuthService();
  bool obscurePassword = true;

  @override
  void dispose() {
    firstCtrl.dispose();
    lastCtrl.dispose();
    ageCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    try {
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (picked != null) {
        setState(() {
          if (kIsWeb) {
            webImage = picked;
            image = null;
          } else {
            image = File(picked.path);
            webImage = null;
          }
        });
      }
    } catch (e) {
      _showSnackBar('Error picking image: $e', isError: true);
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (image == null && webImage == null) {
      _showSnackBar('Please select a profile photo', isError: true);
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // For web, convert XFile to File
      File? imageFile = image;
      if (kIsWeb && webImage != null) {
        imageFile = File(webImage!.path);
      }

      final result = await _authService.signUp(
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
        firstName: firstCtrl.text.trim(),
        lastName: lastCtrl.text.trim(),
        age: int.parse(ageCtrl.text.trim()),
        image: imageFile,
      );

      if (!mounted) return;

      if (result['success']) {
        _showSnackBar(result['message']);

        // Navigate to Home Screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen()),
        );
      } else {
        _showSnackBar(result['message'], isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('An unexpected error occurred', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Widget to display image (compatible with web and mobile)
  Widget _buildProfileImage() {
    ImageProvider? imageProvider;

    if (kIsWeb && webImage != null) {
      imageProvider = NetworkImage(webImage!.path);
    } else if (image != null) {
      imageProvider = FileImage(image!);
    }

    return CircleAvatar(
      radius: 60,
      backgroundColor: Colors.grey[300],
      backgroundImage: imageProvider,
      child: imageProvider == null
          ? Icon(Icons.person, size: 60, color: Colors.grey[600])
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Account"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Photo Picker
              GestureDetector(
                onTap: pickImage,
                child: Stack(
                  children: [
                    _buildProfileImage(),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor,
                        radius: 20,
                        child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tap to select photo',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 30),

              // First Name Field
              TextFormField(
                controller: firstCtrl,
                decoration: InputDecoration(
                  labelText: "First Name",
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your first name';
                  }
                  if (value.trim().length < 2) {
                    return 'First name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // Last Name Field
              TextFormField(
                controller: lastCtrl,
                decoration: InputDecoration(
                  labelText: "Last Name",
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your last name';
                  }
                  if (value.trim().length < 2) {
                    return 'Last name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // Age Field
              TextFormField(
                controller: ageCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Age",
                  prefixIcon: const Icon(Icons.cake),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your age';
                  }
                  final age = int.tryParse(value.trim());
                  if (age == null) {
                    return 'Please enter a valid number';
                  }
                  if (age < 13 || age > 120) {
                    return 'Age must be between 13 and 120';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // Email Field
              TextFormField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email",
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(value.trim())) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // Password Field
              TextFormField(
                controller: passCtrl,
                obscureText: obscurePassword,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // Sign Up Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _signUp,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    "Sign Up",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Login Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account? "),
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () {
                      Navigator.pop(context);
                    },
                    child: const Text("Login"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}