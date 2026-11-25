import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/forum_post.dart';
import '../models/forum_user.dart';
import 'forum_service.dart';
import 'token_store.dart';

/// Gère l’API du forum, avec des requêtes limitées dans le temps et des liens vérifiés.
class ApiForumService implements ForumService {
  /// [baseUri] remplace l’adresse définie par `FORUM_API_BASE_URL`.
  /// [requestTimeout] fixe la durée maximale d’attente d’un appel réseau.
  ApiForumService({
    http.Client? client,
    TokenStore? tokenStore,
    Uri? baseUri,
    this.requestTimeout = _defaultRequestTimeout,
  }) : _client = client ?? http.Client(),
       _tokenStore = tokenStore ?? SecureTokenStore(),
       _baseUri = _normalizeBaseUri(baseUri ?? Uri.parse(_defaultBaseUriValue));

  // Évite qu’une connexion lente laisse l’interface en chargement indéfini.
  static const _defaultRequestTimeout = Duration(seconds: 15);

  // Garde-fou contre une API qui renverrait un nombre anormal de pages.
  static const _maxCollectionPages = 100;

  // --dart-define permet de changer de serveur sans modifier les sources.
  static const _defaultBaseUriValue = String.fromEnvironment(
    'FORUM_API_BASE_URL',
    defaultValue: 'https://4720.s3.nuage-peda.fr/forum/api/',
  );
  final http.Client _client;
  final TokenStore _tokenStore;
  // Racine utilisée pour toutes les routes et tous les liens de ressources.
  final Uri _baseUri;
  final Duration requestTimeout;

  /// Charge toutes les pages de `/messages`, convertit les entrées puis les trie.
  @override
  Future<List<ForumPost>> getMessages() async {
    final posts = <ForumPost>[];
    var uri = _baseUri.resolve('messages');
    final visitedPages = <Uri>{};
    var pageNumber = 0;

    while (true) {
      _trackPage(uri, visitedPages, ++pageNumber, 'messages');
      final response = await _get(uri);
      final body = _decodeJson(response);
      if (body is! Map<String, dynamic>) {
        throw const ForumApiException(
          'Format de réponse des messages invalide.',
        );
      }

      final members = body['member'];
      if (members is List) {
        posts.addAll(
          members.whereType<Map<String, dynamic>>().map(ForumPost.fromJson),
        );
      }

      final view = body['view'];
      final next = view is Map<String, dynamic> ? view['next'] : null;
      if (next is! String || next.isEmpty) break;
      uri = _resolveApiUri(next, relativeTo: uri);
    }

    posts.sort((a, b) => b.datePosted.compareTo(a.datePosted));
    return posts;
  }

  /// Crée une réponse en associant son auteur connecté et son message parent.
  @override
  Future<void> createReply({
    required int parentId,
    required String content,
  }) async {
    final token = await _requireToken();
    final user = await _loadCurrentUser(token);
    final userId = user.id;
    if (userId == null) {
      throw const ForumApiException(
        'Impossible de retrouver votre identifiant utilisateur.',
      );
    }

    final response = await _send(
      () => _client.post(
        _baseUri.resolve('messages'),
        headers: {
          'Accept': 'application/ld+json',
          'Content-Type': 'application/ld+json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'titre': '',
          'datePoste': DateTime.now().toUtc().toIso8601String(),
          'contenu': content.trim(),
          'user': _baseUri.resolve('users/$userId').path,
          'parent': _baseUri.resolve('messages/$parentId').path,
        }),
      ),
    );
    _decodeJson(response);
  }

  /// Vérifie la propriété du message avant d’envoyer sa modification à l’API.
  @override
  Future<void> updateMessage({
    required ForumPost post,
    required String title,
    required String content,
  }) async {
    final token = await _requireToken();
    final user = await _loadCurrentUser(token);
    if (post.userId == null || post.userId != user.id) {
      throw const ForumApiException(
        'Vous ne pouvez modifier que vos propres messages.',
      );
    }

    final response = await _send(
      () => _client.patch(
        _baseUri.resolve('messages/${post.id}'),
        headers: {
          'Accept': 'application/ld+json',
          'Content-Type': 'application/merge-patch+json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'titre': title.trim(), 'contenu': content.trim()}),
      ),
    );
    _decodeJson(response);
  }

  /// Lit le jeton local et récupère le profil correspondant, s’il existe.
  @override
  Future<ForumUser?> restoreSession() async {
    final token = await _tokenStore.read();
    if (token == null || token.isEmpty) return null;
    return _loadCurrentUser(token);
  }

  /// Retourne le jeton ou arrête l’action avec un message compréhensible.
  Future<String> _requireToken() async {
    final token = await _tokenStore.read();
    if (token == null || token.isEmpty) {
      throw const ForumApiException(
        'Connectez-vous pour participer aux discussions.',
      );
    }
    return token;
  }

  /// Authentifie l’adresse et le mot de passe, récupère le profil et mémorise le JWT.
  @override
  Future<ForumUser> signIn({
    required String email,
    required String password,
  }) async {
    // Le jeton n’est conservé qu’après récupération réussie du profil associé.
    final response = await _send(
      () => _client.post(
        _baseUri.resolve('authentication_token'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.trim(), 'password': password}),
      ),
    );
    final body = _decodeJson(response);
    if (body is! Map<String, dynamic> || body['token'] is! String) {
      throw const ForumApiException('L’API n’a pas renvoyé de token valide.');
    }

    final token = body['token'] as String;
    final user = await _loadCurrentUser(token, emailHint: email.trim());
    await _tokenStore.write(token);
    return user;
  }

  /// Crée le compte puis utilise le même flux que la connexion pour ouvrir la session.
  @override
  Future<ForumUser> signUp({
    required String email,
    required String password,
    required String nom,
    required String prenom,
  }) async {
    // L’API crée d’abord le compte ; une connexion récupère ensuite le JWT.
    final response = await _send(
      () => _client.post(
        _baseUri.resolve('users'),
        headers: const {
          'Content-Type': 'application/ld+json',
          'Accept': 'application/ld+json',
        },
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
          'nom': nom.trim(),
          'prenom': prenom.trim(),
        }),
      ),
    );
    _decodeJson(response);
    return signIn(email: email, password: password);
  }

  /// Envoie les champs modifiés ; le nouveau mot de passe reste facultatif.
  @override
  Future<ForumUser> updateUser({
    required ForumUser user,
    required String email,
    required String nom,
    required String prenom,
    String? newPassword,
  }) async {
    final userId = user.id;
    if (userId == null) {
      throw const ForumApiException(
        'Impossible de retrouver votre identifiant utilisateur.',
      );
    }

    final token = await _requireToken();
    // N’inclut pas le mot de passe si l’utilisateur n’a pas demandé à le changer.
    final update = <String, dynamic>{
      'email': email.trim(),
      'nom': nom.trim(),
      'prenom': prenom.trim(),
      if (newPassword != null && newPassword.isNotEmpty)
        'password': newPassword,
    };
    final response = await _send(
      () => _client.patch(
        _baseUri.resolve('users/$userId'),
        headers: {
          'Accept': 'application/ld+json',
          'Content-Type': 'application/merge-patch+json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(update),
      ),
    );
    final body = _decodeJson(response);
    if (body is Map<String, dynamic>) return ForumUser.fromJson(body);
    return ForumUser(
      id: userId,
      email: email.trim(),
      nom: nom.trim(),
      prenom: prenom.trim(),
    );
  }

  /// Supprime le jeton local, ce qui termine la session sur l’appareil.
  @override
  Future<void> signOut() => _tokenStore.clear();

  /// Retrouve l’utilisateur d’abord par identifiant, puis par courriel si nécessaire.
  Future<ForumUser> _loadCurrentUser(String token, {String? emailHint}) async {
    final claims = _tokenClaims(token);
    final userId = _intClaim(claims, const ['id', 'user_id', 'userId']);
    if (userId != null) {
      final response = await _get(
        _baseUri.resolve('users/$userId'),
        token: token,
      );
      final body = _decodeJson(response);
      if (body is Map<String, dynamic>) return ForumUser.fromJson(body);
    }

    final email =
        emailHint ??
        _stringClaim(claims, const [
          'email',
          'username',
          'userIdentifier',
          'sub',
        ]);
    if (email == null || !email.contains('@')) {
      throw const ForumApiException(
        'Impossible de retrouver votre compte à partir du token.',
      );
    }

    // Certains JWT ne contiennent pas d’identifiant numérique ; dans ce cas,
    // parcourt la collection et compare l’adresse avec le profil de chaque IRI.
    var uri = _baseUri.resolve('users');
    final visitedPages = <Uri>{};
    var pageNumber = 0;
    while (true) {
      _trackPage(uri, visitedPages, ++pageNumber, 'users');
      final response = await _get(uri, token: token);
      final body = _decodeJson(response);
      if (body is! Map<String, dynamic>) {
        throw const ForumApiException(
          'Format de réponse des utilisateurs invalide.',
        );
      }
      final members = body['member'];
      if (members is List) {
        for (final member in members.whereType<Map<String, dynamic>>()) {
          final iri = member['@id'];
          if (iri is! String) continue;
          final userResponse = await _get(_resolveApiUri(iri), token: token);
          final userBody = _decodeJson(userResponse);
          if (userBody is Map<String, dynamic>) {
            final user = ForumUser.fromJson(userBody);
            if (user.email.toLowerCase() == email.toLowerCase()) return user;
          }
        }
      }

      final view = body['view'];
      final next = view is Map<String, dynamic> ? view['next'] : null;
      if (next is! String || next.isEmpty) break;
      uri = _resolveApiUri(next, relativeTo: uri);
    }

    throw const ForumApiException(
      'Le token est valide, mais le profil utilisateur est introuvable.',
    );
  }

  /// Envoie une requête GET et ajoute le jeton lorsqu’une session est disponible.
  Future<http.Response> _get(Uri uri, {String? token}) async {
    _validateApiUri(uri);
    final headers = <String, String>{
      'Accept': 'application/ld+json, application/json',
    };
    final accessToken = token ?? await _tokenStore.read();
    if (accessToken != null && accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }
    return _send(() => _client.get(uri, headers: headers));
  }

  /// Applique le même délai maximal à toutes les requêtes HTTP.
  Future<http.Response> _send(Future<http.Response> Function() send) async {
    try {
      return await send().timeout(requestTimeout);
    } on TimeoutException {
      throw const ForumApiException(
        'Le serveur du forum ne répond pas dans le délai imparti.',
      );
    }
  }

  /// Résout un lien fourni par l’API et empêche la transmission du jeton ailleurs.
  Uri _resolveApiUri(String reference, {Uri? relativeTo}) {
    late final Uri uri;
    try {
      uri = (relativeTo ?? _baseUri).resolve(reference);
    } on FormatException {
      throw const ForumApiException('L’API a renvoyé un lien invalide.');
    }
    _validateApiUri(uri);
    return uri;
  }

  /// Refuse les liens hors de l’API avant qu’ils puissent recevoir le jeton.
  void _validateApiUri(Uri uri) {
    // Le schéma, l’hôte, le port et le chemin doivent rester dans l’API configurée.
    final isSameApi =
        uri.scheme == _baseUri.scheme &&
        uri.host.toLowerCase() == _baseUri.host.toLowerCase() &&
        uri.port == _baseUri.port &&
        uri.userInfo.isEmpty &&
        uri.path.startsWith(_baseUri.path);
    if (!isSameApi) {
      throw const ForumApiException(
        'L’API a renvoyé un lien vers une adresse inattendue.',
      );
    }
  }

  /// Limite le parcours d’une collection et détecte les pages répétées.
  void _trackPage(
    Uri uri,
    Set<Uri> visitedPages,
    int pageNumber,
    String collection,
  ) {
    if (pageNumber > _maxCollectionPages) {
      throw ForumApiException(
        'La pagination de $collection dépasse $_maxCollectionPages pages.',
      );
    }
    if (!visitedPages.add(uri)) {
      throw ForumApiException(
        'La pagination de $collection renvoie une page déjà chargée.',
      );
    }
  }

  /// Ajoute une barre finale et rejette les URL qui ne sont pas des racines HTTP(S).
  static Uri _normalizeBaseUri(Uri uri) {
    if ((uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw ArgumentError.value(uri, 'baseUri', 'URL d’API invalide.');
    }
    final path = uri.path.endsWith('/') ? uri.path : '${uri.path}/';
    return uri.replace(path: path);
  }

  /// Décode le JSON et convertit les réponses HTTP non réussies en erreur API.
  dynamic _decodeJson(http.Response response) {
    dynamic body;
    // Certaines réponses réussies peuvent être vides ; sinon, elles doivent être JSON.
    if (response.body.isNotEmpty) {
      try {
        body = jsonDecode(response.body);
      } on FormatException {
        throw const ForumApiException('L’API a renvoyé une réponse illisible.');
      }
    }
    // Convertit les erreurs HTTP en messages réutilisables par l’interface.
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = body is Map<String, dynamic>
          ? body['detail'] as String? ??
                body['hydra:description'] as String? ??
                body['message'] as String?
          : null;
      throw ForumApiException(
        message ?? 'Erreur API (${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }
    return body;
  }

  /// Lit les revendications du JWT sans prétendre vérifier sa signature.
  Map<String, dynamic> _tokenClaims(String token) {
    // Un JWT comporte trois segments ; seule sa charge utile est décodée ici.
    final parts = token.split('.');
    if (parts.length != 3) {
      throw const ForumApiException('Le token reçu n’est pas un JWT valide.');
    }
    try {
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final claims = jsonDecode(payload);
      if (claims is Map<String, dynamic>) return claims;
    } on FormatException {
      throw const ForumApiException(
        'Impossible de lire les informations du token.',
      );
    }
    throw const ForumApiException(
      'Le token ne contient pas de profil utilisateur.',
    );
  }

  /// Convertit la première revendication JWT numérique en entier.
  int? _intClaim(Map<String, dynamic> claims, List<String> keys) {
    for (final key in keys) {
      final value = claims[key];
      if (value is int) return value;
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  /// Retourne la première revendication JWT textuelle non vide.
  String? _stringClaim(Map<String, dynamic> claims, List<String> keys) {
    for (final key in keys) {
      final value = claims[key];
      if (value is String && value.isNotEmpty) return value;
    }
    return null;
  }
}

/// Erreur API affichable par les pages et associée éventuellement à un statut HTTP.
class ForumApiException implements Exception {
  const ForumApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
