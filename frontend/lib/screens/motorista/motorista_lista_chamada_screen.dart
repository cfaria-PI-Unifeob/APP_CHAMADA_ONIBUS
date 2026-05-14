import 'package:flutter/material.dart';

import '../../ia/ia_chat_sheet.dart';
import '../../ia/motorista_ia_context.dart';
import '../../motorista_memoria.dart';
import 'aluno_foto_preview.dart';
import 'motorista_app_bar.dart';

class MotoristaListaChamadaScreen extends StatefulWidget {
  const MotoristaListaChamadaScreen({super.key});

  @override
  State<MotoristaListaChamadaScreen> createState() => _MotoristaListaChamadaScreenState();
}

class _MotoristaListaChamadaScreenState extends State<MotoristaListaChamadaScreen> {
  void _sincronizarIds() {
    motoristaMemoria.sincronizarChamadaComAlunos();
  }

  int _contarEntrada(List<AlunoMemoria> lista) {
    var n = 0;
    for (final a in lista) {
      if (motoristaMemoria.embarqueEntrada(a.id)) n++;
    }
    return n;
  }

  int _contarSaida(List<AlunoMemoria> lista) {
    var n = 0;
    for (final a in lista) {
      if (motoristaMemoria.embarqueSaida(a.id)) n++;
    }
    return n;
  }

  /// Quem embarcou na entrada e ainda não foi marcado na saída.
  int _faltamNaSaida(List<AlunoMemoria> lista) {
    var n = 0;
    for (final a in lista) {
      if (motoristaMemoria.embarqueEntrada(a.id) && !motoristaMemoria.embarqueSaida(a.id)) n++;
    }
    return n;
  }

  void _salvarChamada() {
    final lista = motoristaMemoria.alunos;
    final total = lista.length;
    final naEntrada = _contarEntrada(lista);
    final naSaida = _contarSaida(lista);
    final faltamSaida = _faltamNaSaida(lista);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Chamada (protótipo): entrada $naEntrada · saída $naSaida · '
          'faltam na saída $faltamSaida (de $total alunos).',
        ),
      ),
    );
  }

  Future<void> _confirmarLimparChamada() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpar chamada do dia'),
        content: const Text(
          'Todas as marcações de embarque (entrada e saída) serão apagadas. '
          'Use no começo de um novo dia para fazer a chamada outra vez, com a lista de alunos atual.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Limpar')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    motoristaMemoria.limparChamadaDia();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chamada zerada. Marque entrada e saída de novo.')),
    );
  }

  Widget _avatarAluno(AlunoMemoria a) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => mostrarPreviewFotoAluno(context, a),
        child: SizedBox(
          width: 52,
          height: 52,
          child: a.foto != null && a.foto!.isNotEmpty
              ? Image.memory(
                  a.foto!,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.person, color: scheme.onSurfaceVariant),
                )
              : Icon(Icons.person, color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _sincronizarIds();
    final lista = motoristaMemoria.alunos;
    final naEntrada = _contarEntrada(lista);
    final naSaida = _contarSaida(lista);
    final faltamSaida = _faltamNaSaida(lista);
    final hoje = DateTime.now();
    final dataStr =
        '${hoje.day.toString().padLeft(2, '0')}/${hoje.month.toString().padLeft(2, '0')}/${hoje.year}';

    return Scaffold(
      appBar: appBarMotoristaComVoltar(
        context,
        'Lista de chamada',
        actions: lista.isEmpty
            ? null
            : [
                IconButton(
                  tooltip: 'Limpar chamada (novo dia)',
                  onPressed: _confirmarLimparChamada,
                  icon: const Icon(Icons.event_repeat_outlined),
                ),
              ],
      ),
      floatingActionButton: lista.isEmpty
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton.small(
                  heroTag: 'ia_onibus',
                  tooltip: 'IA — lista e alunos',
                  onPressed: () {
                    motoristaMemoria.sincronizarChamadaComAlunos();
                    showIaChatSheet(
                      context,
                      title: 'IA no ônibus',
                      dataContext: motoristaContextoDiaCompleto(),
                      hintText: 'Pergunte sobre a lista, quem faltou…',
                      draftMessage:
                          'Com os dados atuais: quantos embarcaram na entrada, quantos na saída, quem falta na saída? Liste nomes quando couber.',
                    );
                  },
                  child: const Icon(Icons.smart_toy_outlined),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.extended(
                  heroTag: 'salvar_chamada',
                  onPressed: _salvarChamada,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Salvar'),
                ),
              ],
            ),
      body: lista.isEmpty
          ? const Center(child: Text('Cadastre alunos para montar a chamada.'))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Material(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Data: $dataStr — toque na foto para ver maior. '
                          'Marque embarque na entrada e na saída.',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            _ResumoChip(
                              label: 'Embarcaram na entrada',
                              valor: naEntrada,
                              icon: Icons.login,
                            ),
                            _ResumoChip(
                              label: 'Embarcaram na saída',
                              valor: naSaida,
                              icon: Icons.logout,
                            ),
                            _ResumoChip(
                              label: 'Faltam na saída',
                              valor: faltamSaida,
                              icon: Icons.pending_actions_outlined,
                              destaque: faltamSaida > 0,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _confirmarLimparChamada,
                          icon: const Icon(Icons.event_repeat_outlined),
                          label: const Text('Limpar chamada (novo dia)'),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 130),
                    itemCount: lista.length,
                    itemBuilder: (context, i) {
                      final a = lista[i];
                      final e = motoristaMemoria.embarqueEntrada(a.id);
                      final s = motoristaMemoria.embarqueSaida(a.id);
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _avatarAluno(a),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      a.nome,
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${a.transporte}\n${a.faculdade}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Tooltip(
                                message: 'Embarque na entrada (ida)',
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Entrada',
                                      style: Theme.of(context).textTheme.labelSmall,
                                    ),
                                    Checkbox(
                                      value: e,
                                      onChanged: (v) {
                                        motoristaMemoria.setEmbarqueEntrada(a.id, v ?? false);
                                        setState(() {});
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              Tooltip(
                                message: 'Embarque na saída (volta)',
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Saída',
                                      style: Theme.of(context).textTheme.labelSmall,
                                    ),
                                    Checkbox(
                                      value: s,
                                      onChanged: (v) {
                                        motoristaMemoria.setEmbarqueSaida(a.id, v ?? false);
                                        setState(() {});
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _ResumoChip extends StatelessWidget {
  const _ResumoChip({
    required this.label,
    required this.valor,
    required this.icon,
    this.destaque = false,
  });

  final String label;
  final int valor;
  final IconData icon;
  final bool destaque;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = destaque ? scheme.errorContainer : scheme.secondaryContainer;
    final fg = destaque ? scheme.onErrorContainer : scheme.onSecondaryContainer;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: fg),
            const SizedBox(width: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
                  ),
                  Text(
                    '$valor',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
