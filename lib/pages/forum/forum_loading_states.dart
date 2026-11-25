import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Construit les erreurs bloquantes ou compactes du fil.
abstract final class ForumLoadingStates {
  /// Affiche une erreur qui remplace toute la liste.
  static Widget error({
    required Object? error,
    required Future<void> Function() onRetry,
  }) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppColors.muted, size: 38),
          const SizedBox(height: 12),
          const Text(
            'Impossible de charger les messages.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            '$error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  /// Affiche une erreur lors d’un rafraîchissement sans masquer les messages.
  static Widget inlineError({
    required Object? error,
    required Future<void> Function() onRetry,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppColors.muted, size: 18),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Actualisation impossible : $error',
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}
