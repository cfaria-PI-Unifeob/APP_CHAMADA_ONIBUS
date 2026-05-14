import 'package:flutter/material.dart';

import '../perfil_usuario.dart';

/// Cadastro de aluno ou motorista (protótipo; persistência virá da API).
class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key, this.perfilInicial = PerfilUsuario.aluno});

  final PerfilUsuario perfilInicial;

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  late PerfilUsuario _perfil = widget.perfilInicial;
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _identificador = TextEditingController();
  final _telefone = TextEditingController();
  final _senha = TextEditingController();
  final _senhaConfirm = TextEditingController();
  bool _obscureSenha = true;
  bool _obscureSenhaConfirm = true;

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _identificador.dispose();
    _telefone.dispose();
    _senha.dispose();
    _senhaConfirm.dispose();
    super.dispose();
  }

  String get _campoIdLabel =>
      _perfil == PerfilUsuario.aluno ? 'Matrícula' : 'CNH ou identificador';

  String get _campoIdHint =>
      _perfil == PerfilUsuario.aluno ? 'Ex.: 2024001234' : 'Ex.: número da CNH';

  void _cadastrar() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _perfil == PerfilUsuario.aluno
              ? 'Cadastro de aluno registrado (protótipo). Faça login quando a API estiver pronta.'
              : 'Cadastro de motorista registrado (protótipo). Faça login quando a API estiver pronta.',
        ),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Primeiro acesso'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Cadastro',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Crie sua conta como aluno ou motorista.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 24),
                    Text('Perfil', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    SegmentedButton<PerfilUsuario>(
                      segments: const [
                        ButtonSegment(
                          value: PerfilUsuario.aluno,
                          label: Text('Aluno'),
                          icon: Icon(Icons.school_outlined),
                        ),
                        ButtonSegment(
                          value: PerfilUsuario.motorista,
                          label: Text('Motorista'),
                          icon: Icon(Icons.badge_outlined),
                        ),
                      ],
                      selected: {_perfil},
                      onSelectionChanged: (s) => setState(() => _perfil = s.first),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nome,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nome completo',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().length < 3) return 'Informe o nome completo';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Informe o e-mail';
                        if (!v.contains('@')) return 'E-mail inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _identificador,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: _campoIdLabel,
                        hintText: _campoIdHint,
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(
                          _perfil == PerfilUsuario.aluno ? Icons.numbers : Icons.credit_card_outlined,
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Informe $_campoIdLabel';
                        return null;
                      },
                    ),
                    if (_perfil == PerfilUsuario.motorista) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _telefone,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Telefone',
                          hintText: 'Ex.: (11) 98765-4321',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().length < 8) return 'Informe um telefone válido';
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _senha,
                      obscureText: _obscureSenha,
                      textInputAction: TextInputAction.next,
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
                        if (v == null || v.length < 6) return 'Mínimo de 6 caracteres';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _senhaConfirm,
                      obscureText: _obscureSenhaConfirm,
                      onFieldSubmitted: (_) => _cadastrar(),
                      decoration: InputDecoration(
                        labelText: 'Confirmar senha',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _obscureSenhaConfirm ? 'Mostrar senha' : 'Ocultar senha',
                          onPressed: () => setState(() => _obscureSenhaConfirm = !_obscureSenhaConfirm),
                          icon: Icon(
                            _obscureSenhaConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (v) {
                        if (v != _senha.text) return 'As senhas não coincidem';
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),
                    FilledButton(
                      onPressed: _cadastrar,
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text('Cadastrar'),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Os dados ainda não são enviados ao servidor neste protótipo.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
