import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// API Node em produção (Render). Ajuste se o domínio da API mudar.
const String kApiProductionBase = 'https://app-chamada-onibus.onrender.com';

/// URL da API Node.
///
/// Ordem: `API_BASE_URL` via `--dart-define` (CI/local) → produção em release/web → localhost em **debug** não-web.
///
/// **Web:** sempre produção por padrão (evita `localhost` no app publicado). Dev local com API no PC:
/// `flutter run -d chrome --dart-define=API_BASE_URL=https://app-chamada-onibus-front.onrender.com`
String apiBaseUrl() {
  const fromEnv = String.fromEnvironment('API_BASE_URL');
  if (fromEnv.isNotEmpty) return fromEnv;
  if (kIsWeb) return kApiProductionBase;
  if (kReleaseMode) return kApiProductionBase;
  if (Platform.isAndroid) return 'http://10.0.2.2:3000';
  return 'https://app-chamada-onibus-front.onrender.com';
}