import 'package:flutter/material.dart';
import 'auth_screen.dart'; // The login/auth screen

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool isRegister = true;

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();

  bool passwordVisible = false;
  bool confirmVisible = false;

  void toggleMode() {
    setState(() {
      isRegister = !isRegister;
    });
    if (!isRegister) {
      // Go back to AuthScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    passwordVisible = false;
    confirmVisible = false;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.blue.shade600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),

            // Toggle Sign In / Register at the very top
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
                      onTap: toggleMode,
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: !isRegister ? primaryColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Text(
                          'Log In',
                          style: TextStyle(
                            color: !isRegister ? Colors.white : Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isRegister ? primaryColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Text(
                        'Register',
                        style: TextStyle(
                          color: isRegister ? Colors.white : Colors.grey.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Title and subtitle
            const Text(
              "Create Account",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Fill in the details to continue",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // Full Name
            const Text("Full Name", style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _field(fullNameController, "Your full name"),

            const SizedBox(height: 16),

            // Email
            const Text("Email", style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _field(emailController, "name@example.com"),

            const SizedBox(height: 16),

            // Phone
            const Text("Phone Number", style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _field(phoneController, "+123 456 7890"),

            const SizedBox(height: 16),

            // Password
            const Text("Password", style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _field(passwordController, "Enter password", obscure: true, toggle: true, visible: passwordVisible, onToggle: () {
              setState(() {
                passwordVisible = !passwordVisible;
              });
            }),

            const SizedBox(height: 16),

            // Confirm Password
            const Text("Confirm Password", style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _field(confirmController, "Confirm password", obscure: true, toggle: true, visible: confirmVisible, onToggle: () {
              setState(() {
                confirmVisible = !confirmVisible;
              });
            }),

            const SizedBox(height: 30),

            // Register button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  backgroundColor: primaryColor,
                ),
                child: const Text("Register"),
              ),
            ),

            const SizedBox(height: 25),

            // OR divider
            Row(
              children: const [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text("OR CONTINUE WITH"),
                ),
                Expanded(child: Divider()),
              ],
            ),

            const SizedBox(height: 25),

            // Social login buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: Image.asset('assets/icons/apple.png', height: 20, width: 20),
                    label: const Text('Apple', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: Image.asset('assets/icons/google.png', height: 20, width: 20),
                    label: const Text('Google', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Bottom secure text
            Column(
              children: const [
                Text(
                  '256-BIT SECURE CONNECTION',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text('Terms of Service • Privacy Policy',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  TextField _field(TextEditingController controller, String hint,
      {bool obscure = false, bool toggle = false, bool visible = false, VoidCallback? onToggle}) {
    return TextField(
      controller: controller,
      obscureText: toggle ? !visible : obscure,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        suffixIcon: toggle
            ? IconButton(
                icon: Icon(visible ? Icons.visibility : Icons.visibility_off, color: Colors.grey.shade400),
                onPressed: onToggle,
              )
            : null,
      ),
    );
  }
}
