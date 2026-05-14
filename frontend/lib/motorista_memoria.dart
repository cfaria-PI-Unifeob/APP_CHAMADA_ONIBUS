import 'dart:typed_data';

/// Dados em memória só para o protótipo do app (sem API ainda).
final motoristaMemoria = MotoristaMemoria._();

class AlunoMemoria {
  AlunoMemoria({
    required this.id,
    required this.nome,
    required this.matricula,
    required this.telefone,
    required this.transporte,
    required this.faculdade,
    this.foto,
  });

  final String id;
  final String nome;
  final String matricula;
  final String telefone;
  /// Texto livre ou resumo do transporte (ex.: placa — rota).
  final String transporte;
  final String faculdade;
  /// JPEG/PNG em memória (protótipo).
  final Uint8List? foto;
}

class TransporteMemoria {
  TransporteMemoria({
    required this.id,
    required this.empresa,
    required this.placa,
    required this.rota,
    required this.vagas,
  });

  final String id;
  /// Nome da empresa do ônibus.
  final String empresa;
  final String placa;
  final String rota;
  final int vagas;

  String get resumo => '$empresa · $placa — $rota';
}

class MotoristaMemoria {
  MotoristaMemoria._() {
    _transportes.add(
      TransporteMemoria(
        id: 't1',
        empresa: 'Viação Exemplo',
        placa: 'ABC1D23',
        rota: 'Campus → Centro',
        vagas: 44,
      ),
    );
    _alunos.addAll([
      AlunoMemoria(
        id: 'a1',
        nome: 'Ana Costa',
        matricula: '20241001',
        telefone: '(11) 98888-1111',
        transporte: _transportes.first.resumo,
        faculdade: 'Faculdade Projeto — ADS',
      ),
      AlunoMemoria(
        id: 'a2',
        nome: 'Bruno Lima',
        matricula: '20241002',
        telefone: '(11) 97777-2222',
        transporte: _transportes.first.resumo,
        faculdade: 'Faculdade Projeto — SI',
      ),
    ]);
    _syncChamadaMaps();
  }

  final List<AlunoMemoria> _alunos = [];
  final List<TransporteMemoria> _transportes = [];
  final Map<String, bool> _embarqueEntradaDia = {};
  final Map<String, bool> _embarqueSaidaDia = {};
  int _nextAluno = 100;
  int _nextTransporte = 100;

  List<AlunoMemoria> get alunos => List.unmodifiable(_alunos);
  List<TransporteMemoria> get transportes => List.unmodifiable(_transportes);

  void _syncChamadaMaps() {
    for (final a in _alunos) {
      _embarqueEntradaDia.putIfAbsent(a.id, () => false);
      _embarqueSaidaDia.putIfAbsent(a.id, () => false);
    }
    bool existe(String id) => _alunos.any((e) => e.id == id);
    _embarqueEntradaDia.removeWhere((id, _) => !existe(id));
    _embarqueSaidaDia.removeWhere((id, _) => !existe(id));
  }

  /// Expõe sincronização para telas (ex.: lista de chamada ao montar/atualizar).
  void sincronizarChamadaComAlunos() => _syncChamadaMaps();

  bool embarqueEntrada(String alunoId) => _embarqueEntradaDia[alunoId] ?? false;

  bool embarqueSaida(String alunoId) => _embarqueSaidaDia[alunoId] ?? false;

  void setEmbarqueEntrada(String alunoId, bool value) {
    _embarqueEntradaDia[alunoId] = value;
  }

  void setEmbarqueSaida(String alunoId, bool value) {
    _embarqueSaidaDia[alunoId] = value;
  }

  void limparChamadaDia() {
    for (final a in _alunos) {
      _embarqueEntradaDia[a.id] = false;
      _embarqueSaidaDia[a.id] = false;
    }
  }

  void cadastrarAluno({
    required String nome,
    required String matricula,
    required String telefone,
    required String transporte,
    required String faculdade,
    Uint8List? foto,
  }) {
    _alunos.add(
      AlunoMemoria(
        id: 'a$_nextAluno',
        nome: nome.trim(),
        matricula: matricula.trim(),
        telefone: telefone.trim(),
        transporte: transporte.trim(),
        faculdade: faculdade.trim(),
        foto: foto == null ? null : Uint8List.fromList(foto),
      ),
    );
    _nextAluno++;
    _syncChamadaMaps();
  }

  void removerAluno(String id) {
    _alunos.removeWhere((e) => e.id == id);
    _syncChamadaMaps();
  }

  void cadastrarTransporte({
    required String empresa,
    required String placa,
    required String rota,
    required int vagas,
  }) {
    _transportes.add(
      TransporteMemoria(
        id: 't$_nextTransporte',
        empresa: empresa.trim(),
        placa: placa.trim().toUpperCase(),
        rota: rota.trim(),
        vagas: vagas,
      ),
    );
    _nextTransporte++;
  }

  void removerTransporte(String id) {
    _transportes.removeWhere((e) => e.id == id);
  }
}
