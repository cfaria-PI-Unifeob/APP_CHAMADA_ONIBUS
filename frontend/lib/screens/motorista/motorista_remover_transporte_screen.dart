import 'package:flutter/material.dart';

import '../../motorista_memoria.dart';
import 'motorista_app_bar.dart';

class MotoristaRemoverTransporteScreen extends StatefulWidget {
  const MotoristaRemoverTransporteScreen({super.key});

  @override
  State<MotoristaRemoverTransporteScreen> createState() => _MotoristaRemoverTransporteScreenState();
}

class _MotoristaRemoverTransporteScreenState extends State<MotoristaRemoverTransporteScreen> {
  void _atualizar() => setState(() {});

  Future<void> _confirmarRemover(TransporteMemoria t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover transporte'),
        content: Text('Remover ${t.empresa}\n${t.placa} — ${t.rota}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remover')),
        ],
      ),
    );
    if (ok == true && mounted) {
      motoristaMemoria.removerTransporte(t.id);
      _atualizar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transporte ${t.placa} removido.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lista = motoristaMemoria.transportes;

    return Scaffold(
      appBar: appBarMotoristaComVoltar(context, 'Remover transporte'),
      body: lista.isEmpty
          ? const Center(child: Text('Nenhum transporte cadastrado.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: lista.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final t = lista[i];
                return Card(
                  child: ListTile(
                    title: Text(t.placa),
                    subtitle: Text('${t.empresa}\n${t.rota} · ${t.vagas} vagas'),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _confirmarRemover(t),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
