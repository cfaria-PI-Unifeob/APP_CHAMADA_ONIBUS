import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../motorista_memoria.dart';

/// Diálogo com foto (se houver) e nome do aluno.
void mostrarPreviewFotoAluno(BuildContext context, AlunoMemoria aluno) {
  final bytes = aluno.foto;
  final bytesCopy = (bytes != null && bytes.isNotEmpty) ? Uint8List.fromList(bytes) : null;

  showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      final w = (MediaQuery.sizeOf(ctx).width - 72).clamp(220.0, 360.0);
      final imgH = (w * 1.05).clamp(200.0, 340.0);

      Widget imagemOuPlaceholder() {
        if (bytesCopy == null) {
          return SizedBox(
            width: w,
            height: 200,
            child: ColoredBox(
              color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
              child: Icon(
                Icons.person,
                size: 88,
                color: Theme.of(ctx).colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: w,
            height: imgH,
            child: Image(
              image: MemoryImage(bytesCopy),
              fit: BoxFit.contain,
              gaplessPlayback: true,
              filterQuality: FilterQuality.medium,
              errorBuilder: (c, err, st) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.broken_image_outlined, size: 48, color: Theme.of(c).colorScheme.error),
                        const SizedBox(height: 8),
                        Text(
                          'Não foi possível exibir a imagem.',
                          textAlign: TextAlign.center,
                          style: Theme.of(c).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }

      return AlertDialog(
        title: const Text('Aluno'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            imagemOuPlaceholder(),
            const SizedBox(height: 16),
            Text(
              aluno.nome,
              textAlign: TextAlign.center,
              style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Fechar')),
        ],
      );
    },
  );
}
