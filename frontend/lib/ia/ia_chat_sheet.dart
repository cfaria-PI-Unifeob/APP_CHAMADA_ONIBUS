import 'package:flutter/material.dart';

import 'ia_client.dart';

/// Abre o painel de chat com a API (`/api/ia/chat`).
Future<void> showIaChatSheet(
  BuildContext context, {
  required String title,
  required String dataContext,
  String hintText = 'Escreva sua pergunta…',
  String? draftMessage,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return _IaChatSheetBody(
        title: title,
        dataContext: dataContext,
        hintText: hintText,
        draftMessage: draftMessage,
      );
    },
  );
}

class _IaChatSheetBody extends StatefulWidget {
  const _IaChatSheetBody({
    required this.title,
    required this.dataContext,
    required this.hintText,
    this.draftMessage,
  });

  final String title;
  final String dataContext;
  final String hintText;
  final String? draftMessage;

  @override
  State<_IaChatSheetBody> createState() => _IaChatSheetBodyState();
}

class _IaChatSheetBodyState extends State<_IaChatSheetBody> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _msgs = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.draftMessage != null && widget.draftMessage!.trim().isNotEmpty) {
      _controller.text = widget.draftMessage!.trim();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading) return;
    setState(() {
      _msgs.add(_Msg.user(text));
      _controller.clear();
      _loading = true;
    });
    _scrollParaFim();

    try {
      final apiMessages = _msgs
          .where((m) => m.role == 'user' || m.role == 'assistant')
          .map((m) => {'role': m.role, 'content': m.content})
          .toList();
      final reply = await iaChat(messages: apiMessages, context: widget.dataContext);
      if (!mounted) return;
      setState(() {
        _msgs.add(_Msg.assistant(reply));
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _msgs.add(_Msg.assistant('Erro: $e'));
        _loading = false;
      });
    }
    _scrollParaFim();
  }

  void _scrollParaFim() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final h = MediaQuery.sizeOf(context).height * 0.86;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SizedBox(
        height: h,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 12, 8),
              child: Row(
                children: [
                  Icon(Icons.smart_toy_outlined, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _msgs.length + (_loading ? 1 : 0),
                itemBuilder: (context, i) {
                  if (_loading && i == _msgs.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final m = _msgs[i];
                  final isUser = m.role == 'user';
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.88),
                      child: Card(
                        color: isUser
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: SelectableText(
                            m.content,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _enviar(),
                      decoration: InputDecoration(
                        hintText: widget.hintText,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _loading ? null : _enviar,
                    child: const Icon(Icons.send),
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

class _Msg {
  _Msg.user(this.content) : role = 'user';
  _Msg.assistant(this.content) : role = 'assistant';

  final String role;
  final String content;
}
