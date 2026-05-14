import 'package:flutter/material.dart';

import 'perfil_usuario.dart';
import 'screens/home_screen.dart';
import 'screens/motorista/motorista_menu_screen.dart';
import 'screens/role_login_screen.dart';
void main() {
  runApp(const ChamadaApp());
}

class ChamadaApp extends StatelessWidget {
  const ChamadaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chamada',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const RoleLoginScreen(),
        '/motorista': (_) => const MotoristaMenuScreen(),
        '/aluno': (_) => const HomeScreen(perfil: PerfilUsuario.aluno),
      },
    );
  }
}
