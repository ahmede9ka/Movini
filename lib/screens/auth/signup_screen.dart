import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../home/home_screen.dart';

class SignupScreen extends StatefulWidget {
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  File? image;
  final picker = ImagePicker();

  final firstCtrl = TextEditingController();
  final lastCtrl = TextEditingController();
  final ageCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        image = File(picked.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Create Account")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: image != null ? FileImage(image!) : null,
                child: image == null ? Icon(Icons.camera_alt, size: 30) : null,
              ),
            ),
            SizedBox(height: 20),
            TextField(
                controller: firstCtrl,
                decoration: InputDecoration(labelText: "First Name")),
            TextField(
                controller: lastCtrl,
                decoration: InputDecoration(labelText: "Last Name")),
            TextField(
                controller: ageCtrl,
                decoration: InputDecoration(labelText: "Age")),
            TextField(
                controller: emailCtrl,
                decoration: InputDecoration(labelText: "Email")),
            TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: InputDecoration(labelText: "Password")),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // TEMP navigation
                Navigator.push(
                    context, MaterialPageRoute(builder: (_) => HomeScreen()));
              },
              child: Text("Sign Up"),
              style:
              ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
            )
          ],
        ),
      ),
    );
  }
}
