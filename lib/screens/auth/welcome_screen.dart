import 'package:flutter/material.dart';

import '../../widgets/custom_button.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, this.firebaseAvailable = true});

  final bool firebaseAvailable;

  void showFirebaseRequirement(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Firebase sign-in is available in the Android, iOS, macOS, and web builds.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.sizeOf(context).width > MediaQuery.sizeOf(context).height;

    return Scaffold(
      backgroundColor: const Color(0xFF003D32),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SizedBox.expand(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/welcome_background.png',
                  fit: isLandscape ? BoxFit.contain : BoxFit.cover,
                  alignment: Alignment.center,
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x1600241D),
                        Color(0x0000241D),
                        Color(0x2600241D),
                      ],
                      stops: [0, 0.55, 1],
                    ),
                  ),
                ),
                SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            SizedBox(
                              height: constraints.maxHeight *
                                  (isLandscape ? 0.08 : 0.17),
                            ),
                            const Text(
                              'Community\nMarketplace',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                height: 1.12,
                                fontWeight: FontWeight.w700,
                                shadows: [
                                  Shadow(
                                    color: Color(0x66000000),
                                    blurRadius: 12,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Buy, Sell & Support your Local Community',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                height: 1.4,
                                shadows: [
                                  Shadow(
                                    color: Color(0x66000000),
                                    blurRadius: 10,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            CustomButton(
                              text: 'Get Started',
                              onPressed: () {
                                if (!firebaseAvailable) {
                                  showFirebaseRequirement(context);
                                  return;
                                }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              height: 44,
                              child: TextButton(
                                onPressed: () {
                                  if (!firebaseAvailable) {
                                    showFirebaseRequirement(context);
                                    return;
                                  }
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const LoginScreen(),
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  textStyle: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                child: const Text(
                                  'I already have an account',
                                ),
                              ),
                            ),
                            SizedBox(height: constraints.maxHeight * 0.07),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
