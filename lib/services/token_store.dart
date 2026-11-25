import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Interface de stockage qui évite d’enregistrer les jetons en clair.
abstract interface class TokenStore {
  /// Lit le jeton enregistré, ou retourne `null` si aucun jeton n’existe.
  Future<String?> read();

  /// Enregistre le nouveau jeton d’accès.
  Future<void> write(String token);

  /// Efface le jeton pour fermer la session locale.
  Future<void> clear();
}

/// Enregistre le jeton API dans le stockage sécurisé de la plateforme.
class SecureTokenStore implements TokenStore {
  SecureTokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  // Clé stable utilisée par toutes les lectures et écritures du jeton.
  static const _tokenKey = 'forum_access_token';

  final FlutterSecureStorage _storage;

  /// Lit la valeur dans le stockage chiffré fourni par la plateforme.
  @override
  Future<String?> read() => _storage.read(key: _tokenKey);

  /// Écrit la valeur dans le stockage chiffré fourni par la plateforme.
  @override
  Future<void> write(String token) =>
      _storage.write(key: _tokenKey, value: token);

  /// Supprime uniquement la clé associée à la session du forum.
  @override
  Future<void> clear() => _storage.delete(key: _tokenKey);
}
