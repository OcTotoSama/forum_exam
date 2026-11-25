import 'package:flutter/material.dart';

import '../../models/forum_post.dart';
import '../../models/forum_user.dart';
import '../../theme/app_theme.dart';
import '../../widgets/post_card.dart';

/// Affiche récursivement un message et ses réponses imbriquées.
class ForumMessageTree extends StatelessWidget {
  const ForumMessageTree({
    super.key,
    required this.post,
    required this.depth,
    required this.ancestors,
    required this.repliesByParent,
    required this.expandedMessages,
    required this.session,
    required this.onToggleReplies,
    required this.onReply,
    required this.onEdit,
  });

  final ForumPost post;
  final int depth;
  final Set<int> ancestors;
  final Map<int, List<ForumPost>> repliesByParent;
  final Set<int> expandedMessages;
  final ValueNotifier<ForumUser?> session;
  final ValueChanged<int> onToggleReplies;
  final ValueChanged<ForumPost> onReply;
  final ValueChanged<ForumPost> onEdit;

  @override
  Widget build(BuildContext context) {
    if (ancestors.contains(post.id)) return const SizedBox.shrink();

    final path = {...ancestors, post.id};
    final children = repliesByParent[post.id] ?? const <ForumPost>[];
    final userId = session.value?.id;
    final canEdit = userId != null && userId == post.userId;
    final isExpanded = expandedMessages.contains(post.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PostCard(
            post: post,
            replyCount: children.length,
            isExpanded: isExpanded,
            isReply: depth > 0,
            onTap: children.isEmpty ? () {} : () => onToggleReplies(post.id),
            onReply: () => onReply(post),
            onEdit: canEdit ? () => onEdit(post) : null,
          ),
          if (isExpanded && children.isNotEmpty)
            Container(
              margin: EdgeInsets.only(left: depth == 0 ? 22 : 16, top: 12),
              padding: const EdgeInsets.only(left: 14),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: AppColors.violet.withValues(alpha: 0.38),
                    width: 2,
                  ),
                ),
              ),
              child: Column(
                children: [
                  for (final reply in children)
                    ForumMessageTree(
                      post: reply,
                      depth: depth + 1,
                      ancestors: path,
                      repliesByParent: repliesByParent,
                      expandedMessages: expandedMessages,
                      session: session,
                      onToggleReplies: onToggleReplies,
                      onReply: onReply,
                      onEdit: onEdit,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
