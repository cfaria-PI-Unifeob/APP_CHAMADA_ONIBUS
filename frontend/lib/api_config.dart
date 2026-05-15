import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// URL da API Node (Render, etc.).
///
/// **Web:** por padrão usa a API em produção; para dev local com API no PC:
/// `flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000`
///
/// Outro ambiente: `--dart-define=API_BASE_URL=https://outro-host.com`
String apiBaseUrl() {
  const fromEnv = String.fromEnvironment('API_BASE_URL');
  if (fromEnv.isNotEmpty) return fromEnv;
  if (kIsWeb) return 'https://app-chamada-onibus.onrender.com';
  if (!kIsWeb && Platform.isAndroid) {
    return 'http://10.0.2.2:3000';
  }
  return 'http://localhost:3000';
}
