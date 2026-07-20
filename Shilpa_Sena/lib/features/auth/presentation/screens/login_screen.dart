import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../../../../core/theme/design_constants.dart';
import '../../../../core/presentation/widgets/custom_background.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/images/app_icon.png',
                          height: 80,
                          width: 80,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Shilpa Sena',
                      style: GoogleFonts.grandHotel(
                        fontSize: 48,
                        color: Colors.white,
                        fontWeight: FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Login to continue your learning journey',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    TextFormField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        fillColor: Colors.white.withOpacity(0.15),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        fillColor: Colors.white.withOpacity(0.15),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 48),
                    ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          try {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );

                            await context.read<AuthProvider>().signInWithEmail(
                              _emailController.text.trim(),
                              _passwordController.text.trim(),
                            );

                            if (context.mounted) Navigator.pop(context);
                            if (context.mounted) context.go('/home');
                          } catch (e) {
                            if (context.mounted) Navigator.pop(context);
                            if (context.mounted) {
                              final errorMessage = AuthProvider.mapAuthException(e);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(errorMessage),
                                  backgroundColor: Theme.of(context).colorScheme.error,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent[700] ?? DesignConstants.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('LOGIN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () async {
                        try {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );

                          await context.read<AuthProvider>().signInWithGoogle();

                          if (context.mounted) Navigator.pop(context);
                          if (context.mounted) context.go('/home');
                        } catch (e) {
                          if (context.mounted) Navigator.pop(context);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Google Sign-In failed: $e'),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/google.png',
                            height: 24,
                            width: 24,
                          ),
                          const SizedBox(width: 8),
                          RichText(
                            text: const TextSpan(
                              text: 'Continue ',
                              style: TextStyle(color: Color(0xFF00305B), fontWeight: FontWeight.bold, fontSize: 14),
                              children: [
                                TextSpan(
                                  text: 'with ',
                                  style: TextStyle(fontWeight: FontWeight.normal),
                                ),
                                TextSpan(
                                  text: 'Google',
                                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Dont have an account? ',
                          style: TextStyle(color: Color(0xFF00305B), fontSize: 14),
                        ),
                        GestureDetector(
                          onTap: () => context.push('/signup'),
                          child: Text(
                            'Sign Up',
                            style: TextStyle(
                              color: Colors.blueAccent[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
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
        ),
      ),
    );
  }
}
