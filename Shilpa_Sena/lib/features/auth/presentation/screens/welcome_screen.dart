import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/presentation/widgets/custom_background.dart';
import '../../../../core/theme/design_constants.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/app_icon.png',
                      height: 100,
                      width: 100,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Welcome to Shilpa Sena',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: GoogleFonts.grandHotel(
                    fontSize: 36,
                    fontWeight: FontWeight.normal,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Unlock your creative potential with our\npremium courses and study materials.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    context.push('/signup');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent[700] ?? DesignConstants.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Get Started', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.push('/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent[700] ?? DesignConstants.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('I already have an account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
