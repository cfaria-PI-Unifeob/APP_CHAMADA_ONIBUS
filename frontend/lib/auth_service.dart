import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';
import 'perfil_usuario.dart';

const _kTokenKey = 'auth_token';
const _kUserKey = 'auth_user';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.perfil,
    required this.identificador,
    required this.nome,
    this.email,
    this.telefone,
  });

  final String id;
  final PerfilUsuario perfil;
  final String identificador;
  final String nome;
  final String? email;
  final String? telefone;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id']?.toString() ?? '',
      perfil: json['perfil'] == 'motorista' ? PerfilUsuario.motorista : PerfilUsuario.aluno,
      identificador: json['identificador']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      email: json['email']?.toString(),
      telefone: json['telefone']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'perfil': perfil == PerfilUsuario.motorista ? 'motorista' : 'aluno',
        'identificador': identificador,
        'nome': nome,
        if (email != null) 'email': email,
        if (telefone != null) 'telefone': telefone,
      };
}

class AuthSession {
  const AuthSession({required this.token, required this.user});

  final String token;
  final AuthUser user;
}

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

const _kRequestTimeout = Duration(seconds: 20);

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  AuthSession? _session;

  AuthSession? get session => _session;

  /// Confirma se a API de login está acessível (health).
  Future<bool> checkApiReachable() async {
    try {
      final res = await http
          .get(Uri.parse('${apiBaseUrl()}/health'))
          .timeout(_kRequestTimeout);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Map<String, String> get authHeaders {
    final token = _session?.token;
    if (token == null || token.isEmpty) return {};
    return {'Authorization': 'Bearer $token'};
  }

  Future<AuthSession> login({
    required PerfilUsuario perfil,
    required String identificador,
    required String senha,
  }) async {
    final res = await http
        .post(
          Uri.parse('${apiBaseUrl()}/api/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'perfil': perfil == PerfilUsuario.motorista ? 'motorista' : 'aluno',
            'identificador': identificador.trim(),
            'senha': senha,
          }),
        )
        .timeout(_kRequestTimeout);

    final body = _decodeBody(res);
    if (res.statusCode != 200) {
      throw AuthException(body['error']?.toString() ?? 'Falha no login (${res.statusCode})');
    }

    return _saveAndValidateSession(body);
  }

  Future<AuthSession> register({
    required PerfilUsuario perfil,
    required String identificador,
    required String senha,
    required String nome,
    required String email,
    String? telefone,
  }) async {
    final payload = <String, dynamic>{
      'perfil': perfil == PerfilUsuario.motorista ? 'motorista' : 'aluno',
      'identificador': identificador.trim(),
      'senha': senha,
      'nome': nome.trim(),
      'email': email.trim(),
    };
    if (telefone != null && telefone.trim().isNotEmpty) {
      payload['telefone'] = telefone.trim();
    }

    final res = await http
        .post(
          Uri.parse('${apiBaseUrl()}/api/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(_kRequestTimeout);

    final body = _decodeBody(res);
    if (res.statusCode != 201) {
      throw AuthException(body['error']?.toString() ?? 'Falha no cadastro (${res.statusCode})');
    }

    return _saveAndValidateSession(body);
  }

  Future<AuthSession?> restore() async {
    if (_session != null) {
      final valid = await _validateToken(_session!.token);
      if (valid) return _session;
      await logout();
      return null;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_kTokenKey);
    final userJson = prefs.getString(_kUserKey);
    if (token == null || userJson == null) return null;

    try {
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      final user = AuthUser.fromJson(userMap);
      final valid = await _validateToken(token);
      if (!valid) {
        await logout();
        return null;
      }
      _session = AuthSession(token: token, user: user);
      return _session;
    } catch (_) {
      await logout();
      return null;
    }
  }

  Future<bool> _validateToken(String token) async {
    if (token.length < 20) return false;
    try {
      final res = await http
          .get(
            Uri.parse('${apiBaseUrl()}/api/auth/me'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(_kRequestTimeout);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    _session = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kTokenKey);
    await prefs.remove(_kUserKey);
  }

  Future<AuthSession> _saveAndValidateSession(Map<String, dynamic> body) async {
    final token = body['token']?.toString();
    final userJson = body['user'];
    if (token == null || token.length < 20 || userJson is! Map) {
      throw AuthException('resposta inválida do servidor');
    }

    final valid = await _validateToken(token);
    if (!valid) {
      throw AuthException('servidor não confirmou o login. Verifique a API.');
    }

    final user = AuthUser.fromJson(Map<String, dynamic>.from(userJson));
    final session = AuthSession(token: token, user: user);
    _session = session;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTokenKey, token);
    await prefs.setString(_kUserKey, jsonEncode(user.toJson()));

    return session;
  }

  Map<String, dynamic> _decodeBody(http.Response res) {
    try {
      return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
    } catch (_) {
      return {'error': res.body.isNotEmpty ? res.body : 'resposta inválida'};
    }
  }
}
