import 'package:flutter/material.dart';

import '../../motorista_memoria.dart';
import 'motorista_app_bar.dart';

class MotoristaCadastroTransporteScreen extends StatefulWidget {
  const MotoristaCadastroTransporteScreen({super.key});

  @override
  State<MotoristaCadastroTransporteScreen> createState() => _MotoristaCadastroTransporteScreenState();
}

class _MotoristaCadastroTransporteScreenState extends State<MotoristaCadastroTransporteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _empresa = TextEditingController();
  final _placa = TextEditingController();
  final _rota = TextEditingController();
  final _vagas = TextEditingController();

  @override
  void dispose() {
    _empresa.dispose();
    _placa.dispose();
    _rota.dispose();
    _vagas.dispose();
    super.dispose();
  }

  void _salvar() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final v = int.tryParse(_vagas.text.trim());
    if (v == null || v < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um número válido de vagas.')),
      );
      return;
    }
    motoristaMemoria.cadastrarTransporte(
      empresa: _empresa.text,
      placa: _placa.text,
      rota: _rota.text,
      vagas: v,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transporte cadastrado (memória local).')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarMotoristaComVoltar(context, 'Cadastrar transporte'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _empresa,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Empresa do ônibus',
                    hintText: 'Nome da empresa de transporte',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business_outlined),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().length < 2) ? 'Informe o nome da empresa' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _placa,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Placa',
                    hintText: 'ABC1D23',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.directions_car_outlined),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().length < 5) ? 'Informe a placa' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _rota,
                  decoration: const InputDecoration(
                    labelText: 'Rota / linha',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.route_outlined),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Descreva a rota' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _vagas,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Vagas',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.event_seat_outlined),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Informe as vagas' : null,
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: _salvar,
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('Salvar transporte'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
