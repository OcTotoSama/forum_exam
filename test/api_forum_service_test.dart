import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:forum_app/models/forum_post.dart';
import 'package:forum_app/models/forum_user.dart';
import 'package:forum_app/services/api_forum_service.dart';
import 'package:forum_app/services/token_store.dart';

void main() {
  test(
    'charge toutes les pages et envoie le token aux routes protégées',
    () async {
      final tokenStore = MemoryTokenStore()..token = 'stored-token';
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        if (request.url.path == '/forum/api/messages' &&
            request.url.queryParameters['page'] == null) {
          return _jsonResponse({
            '@type': 'Collection',
            'member': [_message(1, '2026-01-01T10:00:00Z')],
            'view': {'next': '/forum/api/messages?page=2'},
          });
        }
        if (request.url.path == '/forum/api/messages') {
          return _jsonResponse({
            '@type': 'Collection',
            'member': [_message(2, '2026-01-02T10:00:00Z', parentId: 1)],
          });
        }
        return http.Response('Not found', 404);
      });
      final service = ApiForumService(client: client, tokenStore: tokenStore);

      final messages = await service.getMessages();

      expect(messages.map((message) => message.id), [2, 1]);
      expect(messages.first.title, 'Titre API');
      expect(messages.first.author, 'Alex Martin');
      expect(messages.first.parentId, 1);
      expect(messages.first.userId, 7);
      expect(requests, hasLength(2));
      expect(requests.first.headers['authorization'], 'Bearer stored-token');
      expect(requests.last.url.queryParameters['page'], '2');
    },
  );

  test('arrête une requête qui dépasse le délai maximal', () async {
    final service = ApiForumService(
      client: MockClient((request) async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return _jsonResponse({'member': []});
      }),
      tokenStore: MemoryTokenStore(),
      requestTimeout: const Duration(milliseconds: 10),
    );

    await expectLater(
      service.getMessages(),
      throwsA(
        isA<ForumApiException>().having(
          (error) => error.message,
          'message',
          contains('délai imparti'),
        ),
      ),
    );
  });

  test('refuse une pagination qui renvoie la même page', () async {
    final requests = <http.Request>[];
    final service = ApiForumService(
      client: MockClient((request) async {
        requests.add(request);
        return _jsonResponse({
          'member': [],
          'view': {'next': '/forum/api/messages'},
        });
      }),
      tokenStore: MemoryTokenStore(),
    );

    await expectLater(service.getMessages(), throwsA(isA<ForumApiException>()));

    expect(requests, hasLength(1));
  });

  test('arrête la pagination après 100 pages', () async {
    final requests = <http.Request>[];
    final service = ApiForumService(
      client: MockClient((request) async {
        requests.add(request);
        final page =
            int.tryParse(request.url.queryParameters['page'] ?? '') ?? 1;
        return _jsonResponse({
          'member': [],
          'view': {'next': '/forum/api/messages?page=${page + 1}'},
        });
      }),
      tokenStore: MemoryTokenStore(),
    );

    await expectLater(service.getMessages(), throwsA(isA<ForumApiException>()));

    expect(requests, hasLength(100));
  });

  test(
    'ne transmet pas le token à un lien externe renvoyé par l’API',
    () async {
      final tokenStore = MemoryTokenStore()..token = 'stored-token';
      final requests = <http.Request>[];
      final service = ApiForumService(
        client: MockClient((request) async {
          requests.add(request);
          return _jsonResponse({
            'member': [],
            'view': {'next': 'https://other.example/collect'},
          });
        }),
        tokenStore: tokenStore,
      );

      await expectLater(
        service.getMessages(),
        throwsA(isA<ForumApiException>()),
      );

      expect(requests, hasLength(1));
      expect(requests.single.headers['authorization'], 'Bearer stored-token');
    },
  );

  test('utilise la nouvelle racine API dans les routes et les IRI', () async {
    final token = _token({'id': 42});
    final requests = <http.Request>[];
    final service = ApiForumService(
      baseUri: Uri.parse('https://api.example/custom/forum'),
      client: MockClient((request) async {
        requests.add(request);
        if (request.method == 'GET' &&
            request.url.path == '/custom/forum/users/42') {
          return _jsonResponse({
            'id': 42,
            'email': 'alex@example.fr',
            'nom': 'Martin',
            'prenom': 'Alex',
          });
        }
        if (request.method == 'POST' &&
            request.url.path == '/custom/forum/messages') {
          return _jsonResponse({'id': 20});
        }
        return http.Response('Not found', 404);
      }),
      tokenStore: MemoryTokenStore()..token = token,
    );

    await service.createReply(parentId: 3, content: 'Ma réponse');

    final createRequest = requests.last;
    expect(createRequest.url.path, '/custom/forum/messages');
    expect(jsonDecode(createRequest.body), {
      'titre': '',
      'datePoste': isA<String>(),
      'contenu': 'Ma réponse',
      'user': '/custom/forum/users/42',
      'parent': '/custom/forum/messages/3',
    });
  });

  test('publie une réponse et modifie uniquement un message à soi', () async {
    final token = _token({'id': 42});
    final tokenStore = MemoryTokenStore()..token = token;
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      if (request.url.path == '/forum/api/users/42') {
        return _jsonResponse({
          'id': 42,
          'email': 'alex@example.fr',
          'nom': 'Martin',
          'prenom': 'Alex',
        });
      }
      if (request.method == 'POST' &&
          request.url.path == '/forum/api/messages') {
        return _jsonResponse({'id': 20});
      }
      if (request.method == 'PATCH' &&
          request.url.path == '/forum/api/messages/8') {
        return _jsonResponse({'id': 8});
      }
      return http.Response('Not found', 404);
    });
    final service = ApiForumService(client: client, tokenStore: tokenStore);

    await service.createReply(parentId: 3, content: 'Ma réponse');
    await service.updateMessage(
      post: ForumPost(
        id: 8,
        author: 'Alex Martin',
        initials: 'AM',
        datePosted: DateTime.now(),
        title: 'Avant',
        body: 'Ancien contenu',
        avatarColor: const Color(0xFFAA9FFF),
        userId: 42,
      ),
      title: 'Après',
      content: 'Nouveau contenu',
    );
    await expectLater(
      service.updateMessage(
        post: ForumPost(
          id: 9,
          author: 'Autre utilisateur',
          initials: 'AU',
          datePosted: DateTime.now(),
          title: 'Message privé',
          body: 'Contenu',
          avatarColor: const Color(0xFFAA9FFF),
          userId: 99,
        ),
        title: 'Modifié',
        content: 'Contenu modifié',
      ),
      throwsA(isA<ForumApiException>()),
    );

    final createRequest = requests.firstWhere(
      (request) => request.method == 'POST',
    );
    expect(jsonDecode(createRequest.body), {
      'titre': '',
      'datePoste': isA<String>(),
      'contenu': 'Ma réponse',
      'user': '/forum/api/users/42',
      'parent': '/forum/api/messages/3',
    });
    expect(createRequest.headers['authorization'], 'Bearer $token');

    final updateRequest = requests.firstWhere(
      (request) => request.method == 'PATCH',
    );
    expect(
      updateRequest.headers['content-type'],
      'application/merge-patch+json',
    );
    expect(jsonDecode(updateRequest.body), {
      'titre': 'Après',
      'contenu': 'Nouveau contenu',
    });
    expect(
      requests.where((request) => request.method == 'PATCH'),
      hasLength(1),
    );
  });

  test('lit parent_id et conserve la lecture des relations parent en IRI', () {
    final parentIdMessage = ForumPost.fromJson(
      _message(2, '2026-01-02T10:00:00Z', parentId: 1),
    );
    final parentIriMessage = ForumPost.fromJson(
      _message(3, '2026-01-03T10:00:00Z', parent: '/forum/api/messages/1'),
    );

    expect(parentIdMessage.parentId, 1);
    expect(parentIriMessage.parentId, 1);
  });

  test('récupère aussi l’identifiant auteur quand user est une IRI', () {
    final message = _message(3, '2026-01-03T10:00:00Z')
      ..['user'] = '/forum/api/users/7';

    expect(ForumPost.fromJson(message).userId, 7);
  });

  test('connecte, récupère le profil et conserve le JWT', () async {
    final tokenStore = MemoryTokenStore();
    final token = _token({'sub': 'alex@example.fr'});
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      if (request.method == 'POST' &&
          request.url.path == '/forum/api/authentication_token') {
        expect(jsonDecode(request.body), {
          'email': 'alex@example.fr',
          'password': 'secret123',
        });
        return _jsonResponse({'token': token});
      }
      if (request.url.path == '/forum/api/users') {
        return _jsonResponse({
          '@type': 'Collection',
          'member': [
            {'@id': '/forum/api/users/42'},
          ],
        });
      }
      if (request.url.path == '/forum/api/users/42') {
        expect(request.headers['authorization'], 'Bearer $token');
        return _jsonResponse({
          'id': 42,
          'email': 'alex@example.fr',
          'nom': 'Martin',
          'prenom': 'Alex',
        });
      }
      return http.Response('Not found', 404);
    });
    final service = ApiForumService(client: client, tokenStore: tokenStore);

    final user = await service.signIn(
      email: 'alex@example.fr',
      password: 'secret123',
    );

    expect(user.displayName, 'Alex Martin');
    expect(user.email, 'alex@example.fr');
    expect(tokenStore.token, token);
    expect(requests.map((request) => request.method), ['POST', 'GET', 'GET']);

    await service.signOut();
    expect(tokenStore.token, isNull);
  });

  test(
    'modifie le profil avec le token et renvoie les nouvelles informations',
    () async {
      final token = _token({'id': 42});
      final tokenStore = MemoryTokenStore()..token = token;
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        if (request.method == 'PATCH' &&
            request.url.path == '/forum/api/users/42') {
          return _jsonResponse({
            'id': 42,
            'email': 'alex.nouveau@example.fr',
            'nom': 'Durand',
            'prenom': 'Alexandre',
          });
        }
        return http.Response('Not found', 404);
      });
      final service = ApiForumService(client: client, tokenStore: tokenStore);

      final user = await service.updateUser(
        user: const ForumUser(
          id: 42,
          email: 'alex@example.fr',
          nom: 'Martin',
          prenom: 'Alex',
        ),
        email: ' alex.nouveau@example.fr ',
        nom: ' Durand ',
        prenom: ' Alexandre ',
        newPassword: 'NouveauPass123!',
      );

      expect(user.displayName, 'Alexandre Durand');
      expect(user.email, 'alex.nouveau@example.fr');
      expect(requests, hasLength(1));
      expect(requests.single.headers['authorization'], 'Bearer $token');
      expect(
        requests.single.headers['content-type'],
        'application/merge-patch+json',
      );
      expect(jsonDecode(requests.single.body), {
        'email': 'alex.nouveau@example.fr',
        'nom': 'Durand',
        'prenom': 'Alexandre',
        'password': 'NouveauPass123!',
      });
    },
  );
}

// Construit une publication au format JSON attendu depuis l’API du forum.
Map<String, dynamic> _message(
  int id,
  String date, {
  Object? parent,
  int? parentId,
}) => {
  'id': id,
  'titre': 'Titre API',
  'datePoste': date,
  'contenu': 'Contenu API',
  'parent': ?parent,
  'parent_id': ?parentId,
  'user': {'@id': '/forum/api/users/7', 'nom': 'Martin', 'prenom': 'Alex'},
};

// Simule une réponse réussie avec le type de contenu renvoyé par l’API.
http.Response _jsonResponse(Object body) => http.Response(
  jsonEncode(body),
  200,
  headers: {'content-type': 'application/ld+json'},
);

// Fabrique un JWT minimal pour les tests ; il ne sert pas à vérifier une signature.
String _token(Map<String, Object> claims) {
  final payload = base64Url
      .encode(utf8.encode(jsonEncode(claims)))
      .replaceAll('=', '');
  return 'header.$payload.signature';
}

// Remplace le stockage sécurisé par une valeur en mémoire dans les tests.
class MemoryTokenStore implements TokenStore {
  String? token;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String value) async {
    token = value;
  }

  @override
  Future<void> clear() async {
    token = null;
  }
}
