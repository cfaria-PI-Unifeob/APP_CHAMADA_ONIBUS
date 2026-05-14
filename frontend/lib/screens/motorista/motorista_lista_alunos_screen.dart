import 'package:flutter/material.dart';

import '../../motorista_memoria.dart';
import 'aluno_foto_preview.dart';
import 'motorista_app_bar.dart';

/// Lista somente leitura de todos os alunos em [motoristaMemoria].
class MotoristaListaAlunosScreen extends StatelessWidget {
  const MotoristaListaAlunosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lista = motoristaMemoria.alunos;

    return Scaffold(
      appBar: appBarMotoristaComVoltar(context, 'Alunos cadastrados'),
      body: lista.isEmpty
          ? const Center(child: Text('Nenhum aluno cadastrado.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: lista.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
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
                    subtitle: Text(
                      'Mat.: ${a.matricula} · ${a.telefone}\n${a.transporte}\n${a.faculdade}',
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}
