import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'widgets/auth_providers.dart';
import '../../navigation/bottom_nav_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isSignIn = true;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Controllers
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  // Error messages
  String fullNameError = '';
  String phoneError = '';
  String emailError = '';
  String passwordError = '';
  String confirmPasswordError = '';

  void toggleMode() {
    setState(() {
      isSignIn = !isSignIn;
      fullNameError = '';
      phoneError = '';
      emailError = '';
      passwordError = '';
      confirmPasswordError = '';
    });
  }

  bool _validateInputs() {
    bool valid = true;

    setState(() {
      fullNameError = '';
      phoneError = '';
      emailError = '';
      passwordError = '';
      confirmPasswordError = '';

      if (!isSignIn && fullNameController.text.isEmpty) {
        fullNameError = '* Full Name required';
        valid = false;
      }

      if (!isSignIn) {
        if (phoneController.text.isEmpty) {
          phoneError = '* Phone required';
          valid = false;
        } else if (!RegExp(r'^(09|07)\d{8}$')
            .hasMatch(phoneController.text)) {
          phoneError = '* Phone must start with 09 or 07 and be 10 digits';
          valid = false;
        }
      }

      if (emailController.text.isEmpty) {
        emailError = '* Email required';
        valid = false;
      } else if (!emailController.text.contains('@') ||
          !emailController.text.contains('.')) {
        emailError = '* Invalid email address';
        valid = false;
      }

      if (passwordController.text.isEmpty) {
        passwordError = '* Password required';
        valid = false;
      }

      if (!isSignIn) {
        if (confirmPasswordController.text.isEmpty) {
          confirmPasswordError = '* Confirm password required';
          valid = false;
        } else if (passwordController.text !=
            confirmPasswordController.text) {
          confirmPasswordError = '* Passwords do not match';
          valid = false;
        }
      }
    });

    return valid;
  }

  Future<void> _submit() async {
    if (!_validateInputs()) return;

    setState(() => isLoading = true);

    try {
      UserCredential userCredential;

      if (isSignIn) {
        // LOGIN
        userCredential = await _auth.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
      } else {
        // REGISTER
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        // Update display name
        await userCredential.user!
            .updateDisplayName(fullNameController.text.trim());

        // Create Firestore user
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'username': fullNameController.text.trim(),
          'email': emailController.text.trim(),
          'phone': phoneController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const BottomNavScreen(initialIndex: 0),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'Account does not exist';
          break;
        case 'wrong-password':
          message = 'Wrong password';
          break;
        case 'email-already-in-use':
          message = 'Email already in use';
          break;
        default:
          message = e.message ?? 'Authentication failed';
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.blue.shade600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Toggle
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (!isSignIn) toggleMode();
                      },
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color:
                              isSignIn ? primaryColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Text(
                          'Log In',
                          style: TextStyle(
                            color: isSignIn
                                ? Colors.white
                                : Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (isSignIn) toggleMode();
                      },
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color:
                              !isSignIn ? primaryColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Text(
                          'Register',
                          style: TextStyle(
                            color: !isSignIn
                                ? Colors.white
                                : Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Full Name
            if (!isSignIn)
              _inputBlock(
                label: 'Full Name',
                controller: fullNameController,
                error: fullNameError,
                hint: 'full name',
              ),

            // Phone
            if (!isSignIn)
              _inputBlock(
                label: 'Phone',
                controller: phoneController,
                error: phoneError,
                hint: '09........',
                keyboard: TextInputType.phone,
              ),

            // Email
            _inputBlock(
              label: 'Email Address',
              controller: emailController,
              error: emailError,
              hint: 'name@example.com',
            ),

            // Password
            _passwordBlock(
              label: 'Password',
              controller: passwordController,
              error: passwordError,
              obscure: _obscurePassword,
              toggle: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),

            // Confirm Password
            if (!isSignIn)
              _passwordBlock(
                label: 'Confirm Password',
                controller: confirmPasswordController,
                error: confirmPasswordError,
                obscure: _obscureConfirm,
                toggle: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),

            ElevatedButton(
              onPressed: isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                isSignIn ? 'Enter LuckyEta' : 'Create Account',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey.shade400)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('OR CONTINUE WITH',
                      style: TextStyle(color: Colors.grey)),
                ),
                Expanded(child: Divider(color: Colors.grey.shade400)),
              ],
            ),

            const SizedBox(height: 16),

            AuthProviders(
              onGoogleTap: () {},
              onAppleTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputBlock({
    required String label,
    required TextEditingController controller,
    required String error,
    required String hint,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboard,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        if (error.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child:
                Text(error, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _passwordBlock({
    required String label,
    required TextEditingController controller,
    required String error,
    required bool obscure,
    required VoidCallback toggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: '••••••••',
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            suffixIcon: IconButton(
              icon:
                  Icon(obscure ? Icons.visibility_off : Icons.visibility),
              onPressed: toggle,
            ),
          ),
        ),
        if (error.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child:
                Text(error, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}
