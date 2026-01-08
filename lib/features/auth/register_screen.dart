import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();

  String fullNameError = '';
  String phoneError = '';
  String emailError = '';
  String passwordError = '';
  String confirmError = '';
  String firebaseError = '';

  bool _validateInputs() {
    bool valid = true;

    setState(() {
      fullNameError = '';
      phoneError = '';
      emailError = '';
      passwordError = '';
      confirmError = '';
      firebaseError = '';

      if (fullNameController.text.isEmpty) {
        fullNameError = '* Full Name required';
        valid = false;
      }

      if (phoneController.text.isEmpty) {
        phoneError = '* Phone required';
        valid = false;
      } else if (!RegExp(r'^\d+$').hasMatch(phoneController.text)) {
        phoneError = '* Invalid phone number';
        valid = false;
      }

      if (emailController.text.isEmpty) {
        emailError = '* Email required';
        valid = false;
      } else if (!emailController.text.contains('@') || !emailController.text.contains('.com')) {
        emailError = '* Invalid email address';
        valid = false;
      }

      if (passwordController.text.isEmpty) {
        passwordError = '* Password required';
        valid = false;
      }

      if (confirmController.text.isEmpty) {
        confirmError = '* Confirm password required';
        valid = false;
      } else if (passwordController.text != confirmController.text) {
        confirmError = '* Passwords do not match';
        valid = false;
      }
    });

    return valid;
  }

  Future<void> _register() async {
    if (!_validateInputs()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      await FirebaseAuth.instance.currentUser!.updateDisplayName(fullNameController.text.trim());

      // Navigate back to login
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      setState(() => firebaseError = e.message ?? 'An error occurred');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.blue.shade600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            const Text('Register', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),

            // Full Name
            TextField(
              controller: fullNameController,
              decoration: InputDecoration(
                hintText: 'Full Name',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            if (fullNameError.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(fullNameError, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ),
            const SizedBox(height: 16),

            // Phone
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: '09........',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            if (phoneError.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(phoneError, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ),
            const SizedBox(height: 16),

            // Email
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                hintText: 'name@example.com',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            if (emailError.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(emailError, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ),
            const SizedBox(height: 16),

            // Password
            TextField(
              controller: passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: '••••••••',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            if (passwordError.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(passwordError, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ),
            const SizedBox(height: 16),

            // Confirm Password
            TextField(
              controller: confirmController,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                hintText: 'Confirm Password',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
            ),
            if (confirmError.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(confirmError, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ),
            const SizedBox(height: 16),

            // Firebase error
            if (firebaseError.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(firebaseError, style: const TextStyle(color: Colors.red)),
              ),

            // Register button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Create Account', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
