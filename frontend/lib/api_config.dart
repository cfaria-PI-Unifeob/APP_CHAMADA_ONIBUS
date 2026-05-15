import 'package:flutter/foundation.dart';

/// API Node em produção (Render).
const String kApiProductionBase = 'https://app-chamada-onibus.onrender.com';

/// Retorna a URL base da API (sem barra no final).
///
/// **Web no Render (ou qualquer host que não seja localhost):** usa sempre
/// [kApiProductionBase], assim um `--dart-define=API_BASE_URL=http://localhost:3000`
/// errado no CI não quebra o app publicado.
///
/// **Web em localhost:** usa `API_BASE_URL` se definido, senão `http://localhost:3000`.
///
/// **Mobile/desktop:** `API_BASE_URL` se definido; em **release** usa produção;
/// em **debug**, Android emulador → `10.0.2.2`, demais → `localhost`.
String apiBaseUrl() {
  if (kIsWeb) {
    final host = Uri.base.host.toLowerCase();
    final isLocalHost =
        host == 'localhost' || host == '127.0.0.1' || host == '0.0.0.0';
    if (!isLocalHost) {
      return kApiProductionBase;
    }
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    return 'http://localhost:3000';
  }

  const fromEnv = String.fromEnvironment('API_BASE_URL');
  if (fromEnv.isNotEmpty) return fromEnv;
  if (kReleaseMode) return kApiProductionBase;
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:3000';
  }
  return 'http://localhost:3000';
}

/// Base URL para **somente** rotas de IA (`/api/ia/chat`).
///
/// Sempre usa [kApiProductionBase], para o chat funcionar mesmo em **debug**
/// (Android/iOS/desktop chamar `localhost` quebraria a IA).
///
/// Dev local da IA: `flutter run ... --dart-define=IA_API_BASE_URL=http://localhost:3000`
String iaApiBaseUrl() {
  const fromEnv = String.fromEnvironment('IA_API_BASE_URL');
  if (fromEnv.isNotEmpty) return fromEnv;
  return kApiProductionBase;
}
