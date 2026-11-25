import 'api_resource_id.dart';

/// Compte du forum avec les informations nécessaires à l’interface.
class ForumUser {
  const ForumUser({
    this.id,
    required this.email,
    required this.nom,
    required this.prenom,
  });

  final int? id;
  final String email;
  final String nom;
  final String prenom;

  /// Assemble les deux noms et retire les espaces superflus.
  String get displayName => '$prenom $nom'.trim();

  /// Convertit la représentation JSON de l’API en compte de forum.
  factory ForumUser.fromJson(Map<String, dynamic> json) {
    return ForumUser(
      // Les API de type Hydra exposent souvent l’identifiant via @id.
      id: parseApiResourceId(json['id']) ?? parseApiResourceId(json['@id']),
      email: json['email'] as String? ?? '',
      nom: json['nom'] as String? ?? '',
      prenom: json['prenom'] as String? ?? '',
    );
  }
}
