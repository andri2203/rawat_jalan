import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isLogin = true;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child:
            isLoading
                ? Center(child: CircularProgressIndicator())
                : Column(
                  children: [
                    // Header with logo
                    Container(
                      height: 250,
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.medical_services,
                          size: 100,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Column(
                        children: [
                          Text(
                            isLogin ? 'Selamat Datang' : 'Daftar Akun',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[800],
                            ),
                          ),
                          const SizedBox(height: 30),
                          isLogin
                              ? _buildLoginForm(context)
                              : _buildRegisterForm(context),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isLogin
                                    ? 'Belum punya akun?'
                                    : 'Sudah punya akun?',
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    isLogin = !isLogin;
                                  });
                                },
                                child: Text(
                                  isLogin ? 'Register' : 'Login',
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    return Column(
      children: [
        TextFormField(
          controller: emailController,
          decoration: InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email, color: Colors.green[700]),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.green[700]!),
            ),
          ),
        ),
        const SizedBox(height: 15),
        TextFormField(
          controller: passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: Icon(Icons.lock, color: Colors.green[700]),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.green[700]!),
            ),
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () async {
              setState(() {
                isLoading = true;
              });
              try {
                // Handle login
                final auth = FirebaseAuth.instance;
                String email = emailController.text;
                String password = passwordController.text;
                // Add your login logic here
                await auth.signInWithEmailAndPassword(
                  email: email,
                  password: password,
                );
                if (!context.mounted) return;
                setState(() {
                  isLoading = false;
                });
              } catch (e) {
                if (!context.mounted) return;
                setState(() {
                  isLoading = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Login Gagal ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Login',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();

    return Column(
      children: [
        TextFormField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Full Name',
            prefixIcon: Icon(Icons.person, color: Colors.green[700]),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.green[700]!),
            ),
          ),
        ),
        const SizedBox(height: 15),
        TextFormField(
          controller: emailController,
          decoration: InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email, color: Colors.green[700]),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.green[700]!),
            ),
          ),
        ),
        const SizedBox(height: 15),
        TextFormField(
          controller: passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: Icon(Icons.lock, color: Colors.green[700]),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.green[700]!),
            ),
          ),
        ),
        const SizedBox(height: 15),
        TextFormField(
          controller: confirmPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Confirm Password',
            prefixIcon: Icon(Icons.lock, color: Colors.green[700]),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.green[700]!),
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () async {
              // Handle registration
              final auth = FirebaseAuth.instance;
              String name = nameController.text;
              String email = emailController.text;
              String password = passwordController.text;
              String confirmPassword = confirmPasswordController.text;
              // Add your registration logic here
              if (password == confirmPassword) {
                final UserCredential cred = await auth
                    .createUserWithEmailAndPassword(
                      email: email,
                      password: password,
                    );

                final user = cred.user;

                if (user != null) {
                  user.updateProfile(displayName: name);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Register',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
