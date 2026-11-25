import 'package:flutter/material.dart';

import '../models/forum_post.dart';
import '../theme/app_theme.dart';

/// Présente un message, son auteur et ses actions dans une carte Material cliquable.
class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.replyCount,
    required this.isExpanded,
    required this.onTap,
    required this.onReply,
    this.isReply = false,
    this.onEdit,
  });

  final ForumPost post;
  final int replyCount;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback onReply;
  final bool isReply;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final radius = isReply ? 18.0 : 22.0;
    final avatarSize = isReply ? 17.0 : 21.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: replyCount == 0 ? null : onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Ink(
          padding: EdgeInsets.all(isReply ? 14 : 18),
          decoration: BoxDecoration(
            color: isReply ? AppColors.surfaceRaised : AppColors.surface,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: AppColors.border.withValues(alpha: isReply ? 0.65 : 0.9),
            ),
            boxShadow: isReply
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Le liseré coloré donne un repère visuel aux avatars du fil.
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [post.avatarColor, AppColors.violet],
                      ),
                    ),
                    child: CircleAvatar(
                      radius: avatarSize,
                      backgroundColor: AppColors.surface,
                      child: Text(
                        post.initials,
                        style: TextStyle(
                          color: post.avatarColor,
                          fontSize: isReply ? 10 : 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.ink,
                            fontSize: isReply ? 12 : 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          post.time,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onEdit != null)
                    IconButton(
                      tooltip: 'Modifier mon message',
                      visualDensity: VisualDensity.compact,
                      onPressed: onEdit,
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: AppColors.violet,
                        size: 19,
                      ),
                    ),
                ],
              ),
              if (post.title.isNotEmpty) ...[
                SizedBox(height: isReply ? 12 : 16),
                Text(
                  post.title,
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: isReply ? 14 : 16,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                    letterSpacing: -0.2,
                  ),
                ),
              ] else
                SizedBox(height: isReply ? 8 : 10),
              Text(
                post.body,
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: isReply ? 13 : 14,
                  height: 1.55,
                ),
              ),
              SizedBox(height: isReply ? 12 : 16),
              Divider(
                height: 1,
                color: AppColors.border.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (replyCount > 0)
                    TextButton.icon(
                      onPressed: onTap,
                      icon: Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.mode_comment_outlined,
                        size: 18,
                      ),
                      label: Text(
                        isExpanded
                            ? 'Masquer les réponses'
                            : '$replyCount ${replyCount == 1 ? 'réponse' : 'réponses'}',
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.violet,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                      ),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                      child: Text(
                        'Aucune réponse',
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                    ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: onReply,
                    icon: const Icon(Icons.reply_rounded, size: 18),
                    label: const Text('Répondre'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.ink,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
