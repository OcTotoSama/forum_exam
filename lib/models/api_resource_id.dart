/// Convertit un identifiant API fourni comme nombre ou comme IRI de ressource.
int? parseApiResourceId(dynamic value) {
  if (value is int) return value;
  if (value is! String) return null;

  // L’API peut fournir directement un nombre ou le dernier segment d’une URL.
  final directId = int.tryParse(value);
  if (directId != null) return directId;

  final match = RegExp(r'/(\d+)/?$').firstMatch(value);
  return match == null ? null : int.tryParse(match.group(1)!);
}
