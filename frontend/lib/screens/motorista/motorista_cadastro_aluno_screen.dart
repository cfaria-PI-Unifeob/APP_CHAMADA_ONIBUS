import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../ia/ia_chat_sheet.dart';
import '../../ia/motorista_ia_context.dart';
import '../../motorista_memoria.dart';
import 'motorista_app_bar.dart';

class MotoristaCadastroAlunoScreen extends StatefulWidget {
  const MotoristaCadastroAlunoScreen({super.key});

  @override
  State<MotoristaCadastroAlunoScreen> createState() => _MotoristaCadastroAlunoScreenState();
}

class _MotoristaCadastroAlunoScreenState extends State<MotoristaCadastroAlunoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _matricula = TextEditingController();
  final _telefone = TextEditingController();
  final _transporteLivre = TextEditingController();
  final _faculdade = TextEditingController();
  String? _transporteIdSelecionado;
  Uint8List? _fotoBytes;

  @override
  void initState() {
    super.initState();
    final lista = motoristaMemoria.transportes;
    if (lista.isNotEmpty) {
      _transporteIdSelecionado = lista.first.id;
    }
  }

  @override
  void dispose() {
    _nome.dispose();
    _matricula.dispose();
    _telefone.dispose();
    _transporteLivre.dispose();
    _faculdade.dispose();
    super.dispose();
  }

  String _transporteParaSalvar() {
    final lista = motoristaMemoria.transportes;
    if (lista.isEmpty) return _transporteLivre.text.trim();
    final id = _transporteIdSelecionado ?? lista.first.id;
    final t = lista.firstWhere((e) => e.id == id, orElse: () => lista.first);
    return t.resumo;
  }

  Future<void> _escolherFoto(ImageSource source) async {
    try {
      final arquivo = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 82,
      );
      if (!mounted || arquivo == null) return;
      final bytes = await arquivo.readAsBytes();
      if (!mounted) return;
      setState(() => _fotoBytes = bytes);
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Câmera/galeria: ${e.message ?? e.code}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível obter a imagem: $e')),
      );
    }
  }

  void _removerFoto() => setState(() => _fotoBytes = null);

  void _salvar() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final lista = motoristaMemoria.transportes;
    if (lista.isNotEmpty && _transporteIdSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione o transporte.')),
      );
      return;
    }
    if (lista.isEmpty && _transporteLivre.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastre um transporte ou informe o transporte manualmente.')),
      );
      return;
    }
    motoristaMemoria.cadastrarAluno(
      nome: _nome.text,
      matricula: _matricula.text,
      telefone: _telefone.text,
      transporte: _transporteParaSalvar(),
      faculdade: _faculdade.text,
      foto: _fotoBytes,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Aluno cadastrado (memória local).')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final transportes = motoristaMemoria.transportes;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: appBarMotoristaComVoltar(context, 'Cadastrar aluno'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Foto do aluno', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 100,
                        height: 100,
                        child: _fotoBytes != null
                            ? Image.memory(_fotoBytes!, fit: BoxFit.cover)
                            : ColoredBox(
                                color: scheme.surfaceContainerHighest,
                                child: Icon(
                                  Icons.add_a_photo_outlined,
                                  size: 40,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _escolherFoto(ImageSource.camera),
                            icon: const Icon(Icons.photo_camera_outlined),
                            label: const Text('Tirar foto'),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () => _escolherFoto(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Escolher da galeria'),
                          ),
                          if (_fotoBytes != null) ...[
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: _removerFoto,
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Remover foto'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nome,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nome completo',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().length < 3) ? 'Informe o nome' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _matricula,
                  decoration: const InputDecoration(
                    labelText: 'Matrícula',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.numbers),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Informe a matrícula' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _telefone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Telefone',
                    hintText: '(11) 98765-4321',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length < 8) return 'Informe um telefone válido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                if (transportes.isNotEmpty) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Transporte',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.directions_bus_outlined),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _transporteIdSelecionado,
                              hint: const Text('Selecione'),
                              items: transportes
                                  .map(
                                    (t) => DropdownMenuItem<String>(
                                      value: t.id,
                                      child: Text(t.resumo, overflow: TextOverflow.ellipsis),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => setState(() => _transporteIdSelecionado = v),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'IA · dúvidas sobre transportes',
                        onPressed: () {
                          showIaChatSheet(
                            context,
                            title: 'Transportes',
                            dataContext: motoristaContextoTransportesCadastro(),
                            draftMessage:
                                'Qual transporte devo escolher se moro perto do campus? Explique as opções da lista.',
                          );
                        },
                        icon: const Icon(Icons.smart_toy_outlined),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _transporteLivre,
                          decoration: const InputDecoration(
                            labelText: 'Transporte',
                            hintText: 'Placa, linha ou descrição',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.directions_bus_outlined),
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Informe o transporte' : null,
                        ),
                      ),
                      IconButton(
                        tooltip: 'IA · dúvidas sobre transportes',
                        onPressed: () {
                          showIaChatSheet(
                            context,
                            title: 'Transportes',
                            dataContext: motoristaContextoTransportesCadastro(),
                            draftMessage:
                                'Não há transportes no cadastro. O que devo escrever no campo transporte?',
                          );
                        },
                        icon: const Icon(Icons.smart_toy_outlined),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _faculdade,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Faculdade',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().length < 2) ? 'Informe a faculdade' : null,
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: _salvar,
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('Salvar aluno'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
