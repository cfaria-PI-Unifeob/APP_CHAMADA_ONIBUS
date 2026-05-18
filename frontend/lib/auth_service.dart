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

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  AuthSession? _session;

  AuthSession? get session => _session;

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
    final res = await http.post(
      Uri.parse('${apiBaseUrl()}/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'perfil': perfil == PerfilUsuario.motorista ? 'motorista' : 'aluno',
        'identificador': identificador.trim(),
        'senha': senha,
      }),
    );

    final body = _decodeBody(res);
    if (res.statusCode != 200) {
      throw AuthException(body['error']?.toString() ?? 'Falha no login (${res.statusCode})');
    }

    return _saveSessionFromResponse(body);
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

    final res = await http.post(
      Uri.parse('${apiBaseUrl()}/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    final body = _decodeBody(res);
    if (res.statusCode != 201) {
      throw AuthException(body['error']?.toString() ?? 'Falha no cadastro (${res.statusCode})');
    }

    return _saveSessionFromResponse(body);
  }

  Future<AuthSession?> restore() async {
    if (_session != null) return _session;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_kTokenKey);
    final userJson = prefs.getString(_kUserKey);
    if (token == null || userJson == null) return null;

    try {
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      _session = AuthSession(token: token, user: AuthUser.fromJson(userMap));
    } catch (_) {
      await logout();
      return null;
    }

    final res = await http.get(
      Uri.parse('${apiBaseUrl()}/api/auth/me'),
      headers: {
        ...authHeaders,
        'Content-Type': 'application/json',
      },
    );

    if (res.statusCode != 200) {
      await logout();
      return null;
    }

    return _session;
  }

  Future<void> logout() async {
    _session = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kTokenKey);
    await prefs.remove(_kUserKey);
  }

  Future<AuthSession> _saveSessionFromResponse(Map<String, dynamic> body) async {
    final token = body['token']?.toString();
    final userJson = body['user'];
    if (token == null || token.isEmpty || userJson is! Map) {
      throw AuthException('resposta inválida do servidor');
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
