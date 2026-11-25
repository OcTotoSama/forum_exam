import 'package:flutter/material.dart';

import 'api_resource_id.dart';
import 'forum_user.dart';

/// Message de discussion et données d’affichage dérivées de sa réponse API.
class ForumPost {
  const ForumPost({
    required this.id,
    required this.author,
    required this.initials,
    required this.datePosted,
    required this.title,
    required this.body,
    required this.avatarColor,
    this.parentId,
    this.userId,
  });

  final int id;
  final String author;
  final String initials;
  final DateTime datePosted;
  final String title;
  final String body;
  final Color avatarColor;
  final int? parentId;
  final int? userId;

  /// Formate la date en durée courte, puis en date calendrier pour les anciens messages.
  String get time {
    final difference = DateTime.now().difference(datePosted);
    if (difference.isNegative || difference.inMinutes == 0) {
      return 'à l’instant';
    }
    if (difference.inMinutes < 60) {
      return 'il y a ${difference.inMinutes} min';
    }
    if (difference.inHours < 24) {
      return 'il y a ${difference.inHours} h';
    }
    if (difference.inDays < 7) {
      return 'il y a ${difference.inDays} j';
    }
    return '${datePosted.day.toString().padLeft(2, '0')}/'
        '${datePosted.month.toString().padLeft(2, '0')}/${datePosted.year}';
  }

  /// Transforme les noms de propriétés de l’API en modèle prêt pour l’interface.
  factory ForumPost.fromJson(Map<String, dynamic> json) {
    final userData = json['user'];
    final user = userData is Map<String, dynamic>
        ? ForumUser.fromJson(userData)
        : null;
    // L’API peut inclure le profil complet ou renvoyer uniquement son IRI.
    final userId = user?.id ?? parseApiResourceId(userData);
    final author = user?.displayName.isNotEmpty == true
        ? user!.displayName
        : 'Utilisateur';
    // Les initiales servent d’avatar textuel lorsque le forum n’a pas de photo.
    final names = author.split(RegExp(r'\s+'));
    final initials = names
        .where((name) => name.isNotEmpty)
        .take(2)
        .map((name) => name[0].toUpperCase())
        .join();
    // Une date invalide est remplacée par l’époque ; l’interface peut quand même s’afficher.
    final date = DateTime.tryParse(json['datePoste'] as String? ?? '');

    return ForumPost(
      id: parseApiResourceId(json['id']) ?? 0,
      author: author,
      initials: initials.isEmpty ? '?' : initials,
      datePosted: date ?? DateTime.fromMillisecondsSinceEpoch(0),
      title: json['titre'] as String? ?? '',
      body: json['contenu'] as String? ?? '',
      // L’identifiant choisit une couleur stable pour une même publication.
      avatarColor:
          _avatarColors[(parseApiResourceId(json['id']) ?? 0) %
              _avatarColors.length],
      parentId:
          _relationId(json['parent']) ?? parseApiResourceId(json['parent_id']),
      userId: userId,
    );
  }

  /// Accepte une relation parent sous forme d’objet, d’IRI ou d’identifiant brut.
  static int? _relationId(dynamic value) {
    if (value is Map<String, dynamic>) {
      return parseApiResourceId(value['id']) ??
          parseApiResourceId(value['@id']);
    }
    return parseApiResourceId(value);
  }

  static const _avatarColors = [
    Color(0xFFAA9FFF),
    Color(0xFF65C6A8),
    Color(0xFFFFB77E),
    Color(0xFF82B7FF),
    Color(0xFFFF8FA3),
  ];
}
