import 'package:flutter/material.dart';

import '../../ia/ia_chat_sheet.dart';
import '../../ia/motorista_ia_context.dart';
import '../../motorista_memoria.dart';
import 'motorista_app_bar.dart';
import 'motorista_cadastro_aluno_screen.dart';
import 'motorista_cadastro_transporte_screen.dart';
import 'motorista_lista_alunos_screen.dart';
import 'motorista_lista_chamada_screen.dart';
import 'motorista_remover_aluno_screen.dart';
import 'motorista_remover_transporte_screen.dart';

class MotoristaMenuScreen extends StatelessWidget {
  const MotoristaMenuScreen({super.key});

  void _sair(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final items = <_MenuItem>[
      _MenuItem(
        title: 'Cadastrar aluno',
        subtitle: 'Incluir novo aluno na rota',
        icon: Icons.person_add_outlined,
        builder: (_) => const MotoristaCadastroAlunoScreen(),
      ),
      _MenuItem(
        title: 'Lista de alunos',
        subtitle: 'Ver todos os alunos cadastrados',
        icon: Icons.groups_outlined,
        builder: (_) => const MotoristaListaAlunosScreen(),
      ),
      _MenuItem(
        title: 'Remover aluno',
        subtitle: 'Retirar aluno da lista',
        icon: Icons.person_remove_outlined,
        builder: (_) => const MotoristaRemoverAlunoScreen(),
      ),
      _MenuItem(
        title: 'Cadastrar transporte',
        subtitle: 'Novo veículo ou linha',
        icon: Icons.add_road_outlined,
        builder: (_) => const MotoristaCadastroTransporteScreen(),
      ),
      _MenuItem(
        title: 'Remover transporte',
        subtitle: 'Excluir cadastro de transporte',
        icon: Icons.delete_outline,
        builder: (_) => const MotoristaRemoverTransporteScreen(),
      ),
      _MenuItem(
        title: 'Lista de chamada',
        subtitle: 'Presença dos alunos',
        icon: Icons.fact_check_outlined,
        builder: (_) => const MotoristaListaChamadaScreen(),
      ),
    ];

    return Scaffold(
      appBar: appBarMotoristaMenu(
        context,
        onVoltar: () => _sair(context),
        actions: [
          IconButton(
            tooltip: 'Sair',
            onPressed: () => _sair(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length + 2,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          if (i == 0) {
            return Card(
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                  child: Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.onTertiaryContainer),
                ),
                title: const Text('Resumo do dia (IA)'),
                subtitle: const Text('Alunos, transportes e chamada atual'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  motoristaMemoria.sincronizarChamadaComAlunos();
                  showIaChatSheet(
                    context,
                    title: 'Resumo do dia',
                    dataContext: motoristaContextoDiaCompleto(),
                    draftMessage:
                        'Faça um resumo bem curto do dia com base nos dados (totais, alertas, próximo passo).',
                  );
                },
              ),
            );
          }
          if (i == 1) {
            return Card(
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                  child: Icon(Icons.groups, color: Theme.of(context).colorScheme.onSecondaryContainer),
                ),
                title: const Text('IA — quem subiu?'),
                subtitle: const Text('Entrada, saída e quem falta na saída'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  motoristaMemoria.sincronizarChamadaComAlunos();
                  showIaChatSheet(
                    context,
                    title: 'Quem subiu?',
                    dataContext: motoristaContextoDiaCompleto(),
                    draftMessage:
                        'Quem já embarcou na entrada? Quem na saída? Quem falta na saída? Liste os nomes.',
                  );
                },
              ),
            );
          }
          final it = items[i - 2];
          return Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: CircleAvatar(
                child: Icon(it.icon),
              ),
              title: Text(it.title),
              subtitle: Text(it.subtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(builder: it.builder),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _MenuItem {
  _MenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.builder,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final WidgetBuilder builder;
}
