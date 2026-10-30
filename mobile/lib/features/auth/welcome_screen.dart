import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/widgets.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    super.key,
    required this.onStart,
    required this.onGoogleSignIn,
    required this.isSigningIn,
    this.errorMessage,
  });

  final VoidCallback onStart;
  final VoidCallback onGoogleSignIn;
  final bool isSigningIn;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = math.min(constraints.maxWidth, 480.0);
          final heroHeight = math
              .min(width - 32, constraints.maxHeight * 0.43)
              .clamp(210.0, 370.0);
          return SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const BrandMark(compact: true),
                      const SizedBox(height: 16),
                      _WelcomePhoto(height: heroHeight),
                      const SizedBox(height: 20),
                      Text(
                        'Tu mejor versión\nempieza hoy',
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(
                              fontSize: width < 350 ? 30 : 34,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.8,
                              height: 1.04,
                            ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Entrená a tu ritmo, seguí tu progreso y alcanzá tus objetivos.',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 20),
                      LimeButton(
                        label: 'Comenzar',
                        height: 52,
                        onPressed: isSigningIn ? null : onStart,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton(
                          onPressed: isSigningIn ? null : onGoogleSignIn,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: AppColors.surfaceRaised,
                            side: const BorderSide(color: AppColors.line),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(17),
                            ),
                            textStyle: const TextStyle(
                          fontFamily: 'Roboto',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: Text(
                            isSigningIn
                                ? 'Conectando…'
                                : 'Continuar con Google',
                          ),
                        ),
                      ),
                      if (errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          errorMessage!,
                          style: const TextStyle(color: Color(0xFFFFB3BA)),
                        ),
                      ],
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: isSigningIn ? null : onGoogleSignIn,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          foregroundColor: AppColors.muted,
                          alignment: Alignment.centerLeft,
                        ),
                        child: const Text(
                          '¿Ya tenés cuenta?  Iniciá sesión',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

class _WelcomePhoto extends StatelessWidget {
  const _WelcomePhoto({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/welcome_gym.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            semanticLabel: 'Dos atletas en un gimnasio',
            errorBuilder: (context, error, stackTrace) => Container(
              color: AppColors.surface,
              alignment: Alignment.center,
              child: Image.asset('assets/images/entrenaya_logo.png', width: 160),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.center,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0x8C090F11)],
              ),
            ),
          ),
          Positioned(
            left: 14,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_fire_department_outlined,
                    color: AppColors.lime,
                    size: 19,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Tu ritmo. Tu meta.',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
