import 'package:flutter/material.dart';

/// AppBar com seta voltar sempre visível (subtelas abertas a partir do menu).
AppBar appBarMotoristaComVoltar(
  BuildContext context,
  String title, {
  List<Widget>? actions,
}) {
  return AppBar(
    title: Text(title),
    automaticallyImplyLeading: false,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back),
      tooltip: 'Voltar',
      onPressed: () => Navigator.of(context).maybePop(),
    ),
    actions: actions,
  );
}

/// AppBar do menu principal (volta ao login).
AppBar appBarMotoristaMenu(
  BuildContext context, {
  required VoidCallback onVoltar,
  List<Widget>? actions,
}) {
  return AppBar(
    title: const Text('Menu do motorista'),
    automaticallyImplyLeading: false,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back),
      tooltip: 'Voltar',
      onPressed: onVoltar,
    ),
    actions: actions,
  );
}
