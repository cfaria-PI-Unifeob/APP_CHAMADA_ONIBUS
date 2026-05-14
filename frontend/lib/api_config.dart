import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// URL da API Node (Render, etc.).
///
/// **Produção (Flutter web):** build com
/// `flutter build web --dart-define=API_BASE_URL=https://SEU-SERVICO.onrender.com`
///
/// Sem define, web usa `localhost:3000` (só útil em dev com API local).
String apiBaseUrl() {
  const fromEnv = String.fromEnvironment('API_BASE_URL');
  if (fromEnv.isNotEmpty) return fromEnv;
  if (kIsWeb) return 'http://localhost:3000';
  if (!kIsWeb && Platform.isAndroid) {
    return 'http://10.0.2.2:3000';
  }
  return 'http://localhost:3000';
}
