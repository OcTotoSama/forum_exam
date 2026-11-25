import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Affiche l’en-tête du forum avec son bouton d’actualisation.
class ForumHeader extends StatelessWidget {
  const ForumHeader({
    super.key,
    required this.isLoading,
    required this.onRefresh,
  });

  final bool isLoading;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.violet, Color(0xFF7867E8)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.violet.withValues(alpha: 0.22),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.forum_rounded,
            color: AppColors.background,
            size: 24,
          ),
        ),
        const SizedBox(width: 13),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Le Forum',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'La communauté, en conversation',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: isLoading ? null : onRefresh,
          tooltip: 'Actualiser les messages',
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.ink,
            fixedSize: const Size(44, 44),
          ),
          icon: const Icon(Icons.refresh_rounded, size: 20),
        ),
      ],
    );
  }
}

/// Affiche le titre du fil et le nombre de messages chargés.
class ForumSectionTitle extends StatelessWidget {
  const ForumSectionTitle({super.key, required this.postCount});

  final int postCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Le fil de discussion',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Les dernières conversations de la communauté',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.forum_outlined,
                color: AppColors.violet,
                size: 15,
              ),
              const SizedBox(width: 6),
              Text(
                '$postCount',
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
