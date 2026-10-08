import 'package:flutter/material.dart';

import '../models/local.dart';

Future<bool> confirmDelete(BuildContext context, Local local) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Excluir local?'),
          content: Text(
            '“${local.nome}” será removido da lista e dos favoritos.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir'),
            ),
          ],
        ),
      ) ??
      false;
}
