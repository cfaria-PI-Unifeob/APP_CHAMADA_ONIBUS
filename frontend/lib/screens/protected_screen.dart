import 'package:flutter/material.dart';

import '../auth_service.dart';
import '../perfil_usuario.dart';

/// Bloqueia acesso se não houver login válido ou perfil incorreto.
class ProtectedScreen extends StatefulWidget {
  const ProtectedScreen({
    super.key,
    required this.requiredPerfil,
    required this.child,
  });

  final PerfilUsuario requiredPerfil;
  final Widget child;

  @override
  State<ProtectedScreen> createState() => _ProtectedScreenState();
}

class _ProtectedScreenState extends State<ProtectedScreen> {
  bool _checking = true;
  bool _allowed = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    try {
      final session = await AuthService.instance.restore();
      if (!mounted) return;

      final ok = session != null && session.user.perfil == widget.requiredPerfil;
      if (!ok) {
        await AuthService.instance.logout();
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
        return;
      }

      setState(() {
        _checking = false;
        _allowed = true;
      });
    } catch (_) {
      await AuthService.instance.logout();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_allowed) {
      return const SizedBox.shrink();
    }
    return widget.child;
  }
}
