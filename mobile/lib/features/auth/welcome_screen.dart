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
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Image.asset(
                      'assets/images/entrenaya_logo.png',
                      width: 148,
                      height: 148,
                      fit: BoxFit.contain,
                      semanticLabel: 'Logo de EntrenaYa',
                    ),
                  ),
                  const SizedBox(height: 2),
                  _WelcomeHero(),
                  const SizedBox(height: 24),
                  Text(
                    'Tu mejor versión\nempieza hoy',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 35),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Entrená a tu ritmo, seguí tu progreso y alcanzá tus objetivos.',
                    style: TextStyle(color: AppColors.muted, fontSize: 15, height: 1.5),
                  ),
                  const SizedBox(height: 22),
                  LimeButton(label: 'Comenzar', onPressed: isSigningIn ? null : onStart),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: OutlinedButton.icon(
                      onPressed: isSigningIn ? null : onGoogleSignIn,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: AppColors.surfaceRaised,
                        side: const BorderSide(color: AppColors.line),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
                        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      icon: isSigningIn
                          ? const SizedBox.square(
                              dimension: 19,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const _GoogleGlyph(),
                      label: Text(isSigningIn ? 'Conectando…' : 'Continuar con Google'),
                    ),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: const Color(0xFF351F24),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded, color: Color(0xFFFF8D96), size: 19),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: const TextStyle(color: Color(0xFFFFC0C5), fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Center(
                    child: TextButton(
                      onPressed: onGoogleSignIn,
                      child: const Text(
                        '¿Ya tenés cuenta?  Iniciá sesión',
                        style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 232,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF29331E), Color(0xFF182027), Color(0xFF11151A)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -34,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.lime.withValues(alpha: 0.13), width: 24),
              ),
            ),
          ),
          Positioned(
            right: 36,
            top: 36,
            child: Icon(Icons.fitness_center_rounded, size: 90, color: AppColors.lime.withValues(alpha: 0.92)),
          ),
          Positioned(
            left: 18,
            bottom: 17,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.86),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.local_fire_department_rounded, color: AppColors.lime, size: 20),
                  SizedBox(width: 8),
                  Text('Tu ritmo. Tu meta.', style: TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          Positioned(
            left: 22,
            top: 22,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.lime.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'ENTRENÁ A TU MANERA',
                style: TextStyle(color: AppColors.lime, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'G',
      style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Color(0xFF8AB4F8)),
    );
  }
}
