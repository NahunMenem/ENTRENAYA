import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;
}

class AuthSession {
  const AuthSession({required this.accessToken, required this.name, required this.email});

  final String accessToken;
  final String? name;
  final String email;
}

class AuthService {
  static const _apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://entrenaya-production.up.railway.app',
  );
  static const _webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  static const _iosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');

  Future<void>? _initialization;

  bool get isGoogleConfigured =>
      !kIsWeb && _webClientId.isNotEmpty &&
      (defaultTargetPlatform != TargetPlatform.iOS || _iosClientId.isNotEmpty);

  Future<void> _initializeGoogle() {
    return _initialization ??= GoogleSignIn.instance.initialize(
      clientId: !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS ? _iosClientId : null,
      serverClientId: _webClientId,
    );
  }

  Future<AuthSession> signInWithGoogle() async {
    if (!isGoogleConfigured) {
      throw const AuthException(
        'Falta configurar los identificadores de Google para esta plataforma.',
      );
    }

    try {
      await _initializeGoogle();
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const AuthException('Google no devolvió el token de identidad.');
      }

      final response = await http
          .post(
            Uri.parse('$_apiBaseUrl/api/v1/auth/google'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'id_token': idToken}),
          )
          .timeout(const Duration(seconds: 20));

      final body = jsonDecode(response.body);
      if (response.statusCode != 200) {
        final detail = body is Map<String, dynamic> ? body['detail'] : null;
        throw AuthException(
          detail is String ? detail : 'No pudimos validar tu cuenta con EntrenaYa.',
        );
      }

      final data = body as Map<String, dynamic>;
      final user = data['user'] as Map<String, dynamic>;
      return AuthSession(
        accessToken: data['access_token'] as String,
        name: user['name'] as String?,
        email: user['email'] as String,
      );
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthException('Cancelaste el inicio de sesión.');
      }
      throw const AuthException(
        'No pudimos conectarnos con Google. Revisá la configuración de la app.',
      );
    } on AuthException {
      rethrow;
    } on http.ClientException {
      throw const AuthException('No pudimos conectar con el servidor.');
    } on FormatException {
      throw const AuthException('El servidor devolvió una respuesta inesperada.');
    } on Exception {
      throw const AuthException('La conexión tardó demasiado. Intentá de nuevo.');
    }
  }

  Future<void> signOut() async {
    if (!isGoogleConfigured) return;
    try {
      await _initializeGoogle();
      await GoogleSignIn.instance.signOut();
    } on Exception {
      // The EntrenaYa session still ends if Google sign-out fails.
    }
  }
}
