import 'dart:convert';

import 'package:http/http.dart' as http;

import '../api_config.dart';

class IaApiException implements Exception {
  IaApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Chama `POST /api/ia/chat` na API Node (usa `OPENAI_API_KEY` no servidor, se existir).
Future<String> iaChat({
  required List<Map<String, String>> messages,
  String? context,
}) async {
  final uri = Uri.parse('${apiBaseUrl()}/api/ia/chat');
  final res = await http.post(
    uri,
    headers: {'Content-Type': 'application/json; charset=utf-8'},
    body: jsonEncode({
      'messages': messages,
      if (context != null && context.trim().isNotEmpty) 'context': context.trim(),
    }),
  );
  final bodyRaw = utf8.decode(res.bodyBytes);
  if (res.statusCode != 200) {
    throw IaApiException('HTTP ${res.statusCode}: $bodyRaw');
  }
  final body = jsonDecode(bodyRaw) as Map<String, dynamic>;
  final reply = body['reply']?.toString();
  if (reply == null || reply.isEmpty) {
    throw IaApiException('Resposta vazia da API.');
  }
  return reply;
}
