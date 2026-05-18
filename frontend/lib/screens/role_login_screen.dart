import 'package:flutter/material.dart';

import '../auth_service.dart';
import '../ia/ia_chat_sheet.dart';
import '../perfil_usuario.dart';
import 'cadastro_screen.dart';

/// Login com validação na API (matrícula/identificador + senha).
class RoleLoginScreen extends StatefulWidget {
  const RoleLoginScreen({super.key});

  @override
  State<RoleLoginScreen> createState() => _RoleLoginScreenState();
}

class _RoleLoginScreenState extends State<RoleLoginScreen> {
  PerfilUsuario _perfil = PerfilUsuario.aluno;
  final _idController = TextEditingController();
  final _senhaController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscureSenha = true;
  bool _loading = false;

  @override
  void dispose() {
    _idController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);
    try {
      await AuthService.instance.login(
        perfil: _perfil,
        identificador: _idController.text,
        senha: _senhaController.text,
      );
      if (!mounted) return;
      final route = _perfil == PerfilUsuario.motorista ? '/motorista' : '/aluno';
      Navigator.of(context).pushReplacementNamed(route);
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de conexão: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final idLabel = _perfil == PerfilUsuario.aluno ? 'Matrícula' : 'Identificador (motorista)';
    final idHint = _perfil == PerfilUsuario.aluno ? 'Ex.: 2024001234' : 'Ex.: CNH ou código interno';

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(Icons.directions_bus_filled_rounded, size: 56, color: scheme.primary),
                        const SizedBox(height: 16),
                        Text(
                          'Chamada',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Entre como aluno ou motorista',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 32),
                        Text('Perfil', style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 8),
                        SegmentedButton<PerfilUsuario>(
                          segments: const [
                            ButtonSegment(value: PerfilUsuario.aluno, label: Text('Aluno'), icon: Icon(Icons.school_outlined)),
                            ButtonSegment(
                              value: PerfilUsuario.motorista,
                              label: Text('Motorista'),
                              icon: Icon(Icons.badge_outlined),
                            ),
                          ],
                          selected: {_perfil},
                          onSelectionChanged: (s) {
                            setState(() => _perfil = s.first);
                          },
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _idController,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: idLabel,
                            hintText: idHint,
                            border: const OutlineInputBorder(),
                            prefixIcon: Icon(_perfil == PerfilUsuario.aluno ? Icons.person_outline : Icons.drive_eta_outlined),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Informe o $idLabel';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _senhaController,
                          obscureText: _obscureSenha,
                          onFieldSubmitted: (_) => _entrar(),
                          decoration: InputDecoration(
                            labelText: 'Senha',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: _obscureSenha ? 'Mostrar senha' : 'Ocultar senha',
                              onPressed: () => setState(() => _obscureSenha = !_obscureSenha),
                              icon: Icon(
                                _obscureSenha ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Informe a senha';
                            return null;
                          },
                        ),
                        const SizedBox(height: 28),
                        FilledButton(
                          onPressed: _loading ? null : _entrar,
                          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                          child: _loading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Entrar'),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Primeiro acesso?',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 4),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push<void>(
                              MaterialPageRoute<void>(
                                builder: (_) => CadastroScreen(perfilInicial: _perfil),
                              ),
                            );
                          },
                          child: const Text('Cadastrar aluno ou motorista'),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Use a matrícula ou identificador cadastrados. Senha incorreta não entra no app.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 4,
              child: IconButton.filledTonal(
                tooltip: 'Ajuda / suporte (IA)',
                onPressed: () {
                  showIaChatSheet(
                    context,
                    title: 'Ajuda e suporte',
                    dataContext: '''
App Chamada — tela de login.
- Perfil Aluno: matrícula + senha cadastradas.
- Perfil Motorista: identificador/CNH + senha cadastradas.
- Primeiro acesso: use "Cadastrar aluno ou motorista".
- Credenciais inválidas são rejeitadas pela API.
''',
                    draftMessage: 'Sou novo no app. O que cada perfil faz e como acesso a lista de chamada?',
                  );
                },
                icon: const Icon(Icons.smart_toy_outlined),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
