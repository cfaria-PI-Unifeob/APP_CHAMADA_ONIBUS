import '../motorista_memoria.dart';

/// Texto enviado à IA com o estado atual do protótipo (memória local).
String motoristaContextoDiaCompleto() {
  final hoje = DateTime.now().toIso8601String().split('T').first;
  final b = StringBuffer('Data de referência: $hoje\n\n');
  b.writeln('TRANSPORTES:');
  if (motoristaMemoria.transportes.isEmpty) {
    b.writeln('(nenhum cadastrado)');
  } else {
    for (final t in motoristaMemoria.transportes) {
      b.writeln('- ${t.resumo} (vagas: ${t.vagas})');
    }
  }
  b.writeln('\nALUNOS E CHAMADA (entrada = ida, saída = volta):');
  if (motoristaMemoria.alunos.isEmpty) {
    b.writeln('(nenhum cadastrado)');
  } else {
    for (final a in motoristaMemoria.alunos) {
      final e = motoristaMemoria.embarqueEntrada(a.id);
      final s = motoristaMemoria.embarqueSaida(a.id);
      b.writeln('- ${a.nome} | mat. ${a.matricula} | ${a.faculdade} | transporte: ${a.transporte} | entrada=$e saída=$s');
    }
  }
  return b.toString();
}

/// Só transportes (tela de cadastro de aluno).
String motoristaContextoTransportesCadastro() {
  final b = StringBuffer('Cadastro de aluno: escolha de transporte.\n\n');
  final t = motoristaMemoria.transportes;
  if (t.isEmpty) {
    b.writeln('Não há transportes cadastrados; o motorista pode preencher o campo livre.');
  } else {
    b.writeln('Opções no dropdown:');
    for (final x in t) {
      b.writeln('- ${x.resumo} (vagas: ${x.vagas})');
    }
  }
  return b.toString();
}
