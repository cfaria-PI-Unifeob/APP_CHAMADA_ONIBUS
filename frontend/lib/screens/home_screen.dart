import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../auth_service.dart';
import '../perfil_usuario.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.perfil});

  final PerfilUsuario perfil;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _healthText;
  List<Map<String, dynamic>> _chamadas = [];
  String? _error;
  bool _loading = false;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final base = apiBaseUrl();
    try {
      final headers = AuthService.instance.authHeaders;
      final health = await http.get(Uri.parse('$base/health'));
      final list = await http.get(Uri.parse('$base/api/chamadas'), headers: headers);
      if (health.statusCode != 200 || list.statusCode != 200) {
        throw Exception('HTTP ${health.statusCode} / ${list.statusCode}');
      }
      final listBody = jsonDecode(list.body) as Map<String, dynamic>;
      final items = (listBody['items'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      setState(() {
        _healthText = utf8.decode(health.bodyBytes);
        _chamadas = items;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _healthText = null;
        _chamadas = [];
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  String get _perfilLabel =>
      widget.perfil == PerfilUsuario.aluno ? 'Aluno' : 'Motorista';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chamada'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Chip(
                label: Text(
                  AuthService.instance.session?.user.nome ?? _perfilLabel,
                ),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Sair',
            onPressed: () async {
              await AuthService.instance.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
            },
            icon: const Icon(Icons.logout),
          ),
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _loading ? null : _load,
            icon: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('API: ${apiBaseUrl()}', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          if (_error != null)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)),
              ),
            ),
          if (_healthText != null) ...[
            Text('Health', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SelectableText(_healthText!),
            const SizedBox(height: 16),
          ],
          Text('Chamadas', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_chamadas.isEmpty && _error == null && !_loading)
            const Text('Nenhum item.'),
          ..._chamadas.map(
            (c) => Card(
              child: ListTile(
                title: Text(c['turma']?.toString() ?? ''),
                subtitle: Text('${c['data'] ?? ''} · presentes: ${c['presentes'] ?? ''}'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
