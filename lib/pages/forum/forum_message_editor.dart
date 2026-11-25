import 'package:flutter/material.dart';

import '../../models/forum_post.dart';

/// Contient les données temporaires saisies dans le dialogue du forum.
class ForumMessageDraft {
  const ForumMessageDraft({required this.title, required this.content});

  final String title;
  final String content;
}

/// Ouvre le dialogue de réponse ou de modification d’un message.
abstract final class ForumMessageEditor {
  static Future<ForumMessageDraft?> open({
    required BuildContext context,
    required ForumPost post,
    required bool isReply,
  }) async {
    final titleController = TextEditingController(
      text: isReply ? '' : post.title,
    );
    final contentController = TextEditingController(
      text: isReply ? '' : post.body,
    );
    String? validationError;

    final draft = await showDialog<ForumMessageDraft>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isReply ? 'Répondre au message' : 'Modifier mon message'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isReply) ...[
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Titre'),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: contentController,
                  minLines: 3,
                  maxLines: 7,
                  decoration: InputDecoration(
                    labelText: isReply ? 'Votre réponse' : 'Contenu',
                    errorText: validationError,
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                if (contentController.text.trim().isEmpty) {
                  setDialogState(
                    () => validationError = 'Le contenu ne peut pas être vide.',
                  );
                  return;
                }
                Navigator.pop(
                  dialogContext,
                  ForumMessageDraft(
                    title: titleController.text,
                    content: contentController.text,
                  ),
                );
              },
              child: Text(isReply ? 'Envoyer' : 'Enregistrer'),
            ),
          ],
        ),
      ),
    );

    titleController.dispose();
    contentController.dispose();
    return draft;
  }
}
