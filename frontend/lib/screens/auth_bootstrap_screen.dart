import 'package:flutter/material.dart';

import '../auth_service.dart';
import '../perfil_usuario.dart';
/// Verifica sessão salva antes de mostrar login ou área logada.
class AuthBootstrapScreen extends StatefulWidget {
  const AuthBootstrapScreen({super.key});

  @override
  State<AuthBootstrapScreen> createState() => _AuthBootstrapScreenState();
}

class _AuthBootstrapScreenState extends State<AuthBootstrapScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final session = await AuthService.instance.restore();
      if (!mounted) return;

      if (session != null) {
        final route =
            session.user.perfil == PerfilUsuario.motorista ? '/motorista' : '/aluno';
        Navigator.of(context).pushReplacementNamed(route);
        return;
      }
    } catch (_) {
      await AuthService.instance.logout();
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
