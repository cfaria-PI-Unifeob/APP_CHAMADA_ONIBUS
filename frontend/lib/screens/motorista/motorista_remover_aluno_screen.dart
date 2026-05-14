import 'package:flutter/material.dart';

import '../../motorista_memoria.dart';
import 'aluno_foto_preview.dart';
import 'motorista_app_bar.dart';

class MotoristaRemoverAlunoScreen extends StatefulWidget {
  const MotoristaRemoverAlunoScreen({super.key});

  @override
  State<MotoristaRemoverAlunoScreen> createState() => _MotoristaRemoverAlunoScreenState();
}

class _MotoristaRemoverAlunoScreenState extends State<MotoristaRemoverAlunoScreen> {
  void _atualizar() => setState(() {});

  Future<void> _confirmarRemover(AlunoMemoria a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover aluno'),
        content: Text('Remover ${a.nome}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remover')),
        ],
      ),
    );
    if (ok == true && mounted) {
      motoristaMemoria.removerAluno(a.id);
      _atualizar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${a.nome} removido.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lista = motoristaMemoria.alunos;

    return Scaffold(
      appBar: appBarMotoristaComVoltar(context, 'Remover aluno'),
      body: lista.isEmpty
          ? const Center(child: Text('Nenhum aluno cadastrado.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: lista.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final a = lista[i];
                return Card(
                  child: ListTile(
                    leading: Material(
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => mostrarPreviewFotoAluno(context, a),
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: a.foto != null && a.foto!.isNotEmpty
                              ? Image.memory(a.foto!, fit: BoxFit.cover)
                              : Icon(Icons.person, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ),
                    title: Text(a.nome),
                    subtitle: Text('${a.transporte}\n${a.faculdade}'),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _confirmarRemover(a),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
