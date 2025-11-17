import 'package:flutter/material.dart';
import 'package:self_develpoment_app/presentation/screens/auth/login/login.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  bool showpassword = false;
  bool confirmshowpass = false;
  final emailcontroller = TextEditingController();
  final namecontroller = TextEditingController();
  final passcontroller = TextEditingController();
  final conformpasscontroller = TextEditingController();

  bool loading = false;

  Future<void> _signup() async {
    final supabase = Supabase.instance.client;

    final name = namecontroller.text.trim();
    final email = emailcontroller.text.trim();
    final password = passcontroller.text.trim();
    final confirm = conformpasscontroller.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
      _showMessage('Please fill all fields');
      return;
    }

    if (password.length < 6) {
      _showMessage('Password must contain at least 6 characters');
      return;
    }

    if (password != confirm) {
      _showMessage('Passwords do not match');
      return;
    }

    try {
      setState(() => loading = true);

      final response = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) {
        _showMessage('Signup failed. Try again.');
        return;
      }

      final userId = response.user!.id;

      await supabase.from('profiles').insert({
        'id': userId,
        'name': name,
        'email': email,
        'role': 'user',
      });

      _showMessage('Signup successful!');
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      _showMessage("Error: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                // Icon / Branding
                const Icon(
                  Icons.self_improvement_rounded,
                  size: 70,
                  color: Color(0xFF6A5AE0),
                ),
                const SizedBox(height: 20),

                Text(
                  "Create Account",
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Start your growth journey today",
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),

                // NAME
                TextField(
                  controller: namecontroller,
                  cursorColor: Colors.black,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.person_outline_rounded,
                      color: Colors.black,
                    ),
                    labelText: "Full Name",
                    labelStyle: const TextStyle(color: Colors.black),

                    filled: true,
                    fillColor: Colors.white,

                    // 🔳 DEFAULT BORDER
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Colors.black,
                        width: 1.2,
                      ),
                    ),

                    // 🔳 WHEN NOT FOCUSED
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Colors.black,
                        width: 1.2,
                      ),
                    ),

                    // 🔳 WHEN FOCUSED
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Colors.black,
                        width: 1.6,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // EMAIL
                TextField(
                  controller: emailcontroller,
                  cursorColor: Colors.black,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: Colors.black,
                    ),
                    labelText: "Email",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Colors.black,
                        width: 1.2,
                      ),
                    ),

                    // 🔳 WHEN NOT FOCUSED
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Colors.black,
                        width: 1.2,
                      ),
                    ),

                    // 🔳 WHEN FOCUSED
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Colors.black,
                        width: 1.6,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // PASSWORD
                TextField(
                  cursorColor: Colors.black,
                  controller: passcontroller,
                  obscureText: !showpassword,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      color: Colors.black,
                    ),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          showpassword = !showpassword;
                        });
                      },
                      icon: Icon(
                        showpassword ? Icons.visibility : Icons.visibility_off,
                        color: Colors.black,
                      ),
                    ),
                    labelText: "Password",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Colors.black,
                        width: 1.2,
                      ),
                    ),

                    // 🔳 WHEN NOT FOCUSED
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Colors.black,
                        width: 1.2,
                      ),
                    ),

                    // 🔳 WHEN FOCUSED
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Colors.black,
                        width: 1.6,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // CONFIRM PASSWORD
                TextField(
                  cursorColor: Colors.black,
                  controller: conformpasscontroller,
                  obscureText: !confirmshowpass,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.lock_reset_rounded,
                      color: Colors.black,
                    ),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          confirmshowpass = !confirmshowpass;
                        });
                      },
                      icon: Icon(
                        confirmshowpass
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.black,
                      ),
                    ),
                    labelText: "Confirm Password",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Colors.black,
                        width: 1.2,
                      ),
                    ),

                    // 🔳 WHEN NOT FOCUSED
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Colors.black,
                        width: 1.2,
                      ),
                    ),

                    // 🔳 WHEN FOCUSED
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Colors.black,
                        width: 1.6,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                // SIGNUP BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading ? null : _signup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A5AE0),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Sign Up",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                // LOGIN REDIRECT
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already have an account? ",
                      style: TextStyle(color: Colors.black),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Login()),
                      ),
                      child: const Text(
                        "Login",
                        style: TextStyle(
                          color: Color(0xFF6A5AE0),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
}
