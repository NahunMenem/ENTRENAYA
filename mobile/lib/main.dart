import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_theme.dart';
import 'core/models.dart';
import 'features/auth/auth_service.dart';
import 'features/auth/welcome_screen.dart';
import 'features/home/home_shell.dart';
import 'features/onboarding/onboarding_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EntrenaYaApp());
}

class EntrenaYaApp extends StatelessWidget {
  const EntrenaYaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EntrenaYa',
      locale: const Locale('es', 'AR'),
      supportedLocales: const [Locale('es', 'AR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const AppFlow(),
    );
  }
}

class AppFlow extends StatefulWidget {
  const AppFlow({super.key});

  @override
  State<AppFlow> createState() => _AppFlowState();
}

class _AppFlowState extends State<AppFlow> {
  static const _demoMode = bool.fromEnvironment(
    'DEMO_MODE',
    defaultValue: true,
  );
  final AuthService _authService = AuthService();
  AthleteProfile? _profile;
  String? _signedInName;
  String? _authError;
  bool _isSigningIn = false;

  void _enterPreview() {
    setState(
      () => _profile = const AthleteProfile(
        name: 'Atleta',
        goal: 'Ganar fuerza',
        level: 'Principiante',
        trainingPlace: 'Gimnasio',
        daysPerWeek: 4,
        sessionMinutes: 60,
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isSigningIn = true;
      _authError = null;
    });
    try {
      final session = await _authService.signInWithGoogle();
      if (!mounted) return;
      setState(() {
        _signedInName = session.name;
        _isSigningIn = false;
      });
      _openOnboarding(initialName: session.name);
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _authError = error.message;
        _isSigningIn = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _authError = 'No pudimos iniciar sesión. Probá de nuevo.';
        _isSigningIn = false;
      });
    }
  }

  void _openOnboarding({String? initialName}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OnboardingScreen(
          initialName: initialName,
          onComplete: (profile) {
            Navigator.of(context).pop();
            setState(() => _profile = profile);
          },
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    if (!_demoMode) await _authService.signOut();
    if (!mounted) return;
    setState(() {
      _profile = null;
      _signedInName = null;
      _authError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    if (profile != null) {
      return HomeShell(profile: profile, onSignOut: _signOut);
    }
    return WelcomeScreen(
      isSigningIn: _isSigningIn,
      errorMessage: _authError,
      onStart: _demoMode
          ? _enterPreview
          : () => _openOnboarding(initialName: _signedInName),
      onGoogleSignIn: _demoMode ? _enterPreview : _signInWithGoogle,
    );
  }
}
