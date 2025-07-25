import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatelessWidget {
  final AuthService _authService = AuthService();

  LoginScreen({super.key});

  void _signIn(BuildContext context) async {
    final user = await _authService.signInWithGoogle();
    if (user != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully logged in')),
      );
      await Future.delayed(const Duration(milliseconds: 500));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign in failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF23232F),
              Color(0xFF181A20),
              Color(0xFF3A3F47),
            ],
          ),
        ),
        child: Center(
        child: SingleChildScrollView(
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: size.width < 400 ? size.width : 400,
                ),
            child: Card(
                  color: Colors.white.withOpacity(0.95),
              shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
              ),
                  elevation: 12,
              child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/logo.png',
                          width: 80,
                          height: 80,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                          'To-Do App',
                      style: TextStyle(
                            fontSize: 28,
                        fontWeight: FontWeight.bold,
                            color: Color(0xFF23232F),
                            letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                          'Organize your tasks efficiently',
                      style: TextStyle(
                        fontSize: 16,
                            color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                        const SizedBox(height: 36),
                    SizedBox(
                      width: double.infinity,
                          height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                              elevation: 6,
                              padding: EdgeInsets.zero,
                        ),
                        onPressed: () => _signIn(context),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                          children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: Image.network(
                              'https://upload.wikimedia.org/wikipedia/commons/4/4a/Logo_2013_Google.png',
                              width: 28,
                              height: 28,
                            ),
                                ),
                                const SizedBox(width: 14),
                                const Flexible(
                                  child: Text(
                              'Sign in with Google',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
