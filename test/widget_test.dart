import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:forum_app/main.dart';
import 'package:forum_app/models/forum_post.dart';
import 'package:forum_app/models/forum_user.dart';
import 'package:forum_app/services/forum_service.dart';

void main() {
  testWidgets('affiche les messages reçus du service et la navigation', (
    WidgetTester tester,
  ) async {
    final service = FakeForumService();
    await tester.pumpWidget(ForumApp(service: service));
    await tester.pumpAndSettle();

    expect(find.text('Le Forum'), findsOneWidget);
    expect(find.text('Le fil de discussion'), findsOneWidget);
    expect(find.text('Message chargé depuis le service'), findsOneWidget);
    expect(find.text('Accueil'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    expect(find.text('Mon profil'), findsOneWidget);
  });

  testWidgets('développe les réponses sous le message parent', (
    WidgetTester tester,
  ) async {
    final service = FakeForumService();
    await tester.pumpWidget(ForumApp(service: service));
    await tester.pumpAndSettle();

    expect(find.text('Réponse chargée depuis le service'), findsNothing);
    expect(find.text('1 réponse'), findsOneWidget);
    await tester.tap(find.text('Message chargé depuis le service'));
    await tester.pumpAndSettle();

    expect(find.text('Réponse chargée depuis le service'), findsOneWidget);
    await tester.tap(find.text('Masquer les réponses'));
    await tester.pumpAndSettle();

    expect(find.text('Réponse chargée depuis le service'), findsNothing);
  });

  testWidgets('inscrit puis déconnecte un utilisateur', (
    WidgetTester tester,
  ) async {
    final service = FakeForumService();
    await tester.pumpWidget(ForumApp(service: service));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Inscription'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Martin');
    await tester.enterText(find.byType(TextFormField).at(1), 'Alex');
    await tester.enterText(find.byType(TextFormField).at(2), 'alex@example.fr');
    await tester.enterText(find.byType(TextFormField).at(3), 'secret123');
    await tester.ensureVisible(find.text('Créer mon compte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer mon compte'));
    await tester.pumpAndSettle();

    expect(find.text('Alex Martin'), findsOneWidget);
    expect(find.text('alex@example.fr'), findsOneWidget);
    expect(find.text('Se déconnecter'), findsOneWidget);
    expect(find.text('Publications'), findsOneWidget);
    expect(find.text('Abonnés'), findsOneWidget);
    expect(find.text('Abonnements'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(2));
    expect(service.lastRegisteredNom, 'Martin');
    expect(service.lastRegisteredPrenom, 'Alex');

    await tester.tap(find.byTooltip('Paramètres du profil'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Durand');
    await tester.enterText(find.byType(TextFormField).at(1), 'Alexandre');
    await tester.enterText(
      find.byType(TextFormField).at(2),
      'alexandre@example.fr',
    );
    await tester.enterText(find.byType(TextFormField).at(3), 'NouveauPass123!');
    await tester.enterText(find.byType(TextFormField).at(4), 'NouveauPass123!');
    await tester.ensureVisible(find.text('Enregistrer'));
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(find.text('Alexandre Durand'), findsOneWidget);
    expect(find.text('alexandre@example.fr'), findsOneWidget);
    expect(service.lastUpdatedNom, 'Durand');
    expect(service.lastUpdatedPrenom, 'Alexandre');
    expect(service.lastUpdatedPassword, 'NouveauPass123!');

    await tester.ensureVisible(find.text('Se déconnecter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Se déconnecter'));
    await tester.pumpAndSettle();
    expect(find.text('Connexion'), findsOneWidget);
  });
}

// Fournit des réponses déterministes pour tester l’interface sans réseau réel.
class FakeForumService implements ForumService {
  ForumUser? currentUser;
  String? lastRegisteredNom;
  String? lastRegisteredPrenom;
  String? lastUpdatedNom;
  String? lastUpdatedPrenom;
  String? lastUpdatedPassword;

  @override
  Future<List<ForumPost>> getMessages() async => [
    ForumPost(
      id: 1,
      author: 'Alex Martin',
      initials: 'AM',
      datePosted: DateTime.now(),
      title: 'Message chargé depuis le service',
      body: 'Contenu provenant du service de test.',
      avatarColor: const Color(0xFFAA9FFF),
      userId: 7,
    ),
    ForumPost(
      id: 2,
      author: 'Alex Martin',
      initials: 'AM',
      datePosted: DateTime.now(),
      title: '',
      body: 'Réponse chargée depuis le service',
      avatarColor: const Color(0xFF65C6A8),
      parentId: 1,
      userId: 7,
    ),
  ];

  @override
  Future<void> createReply({
    required int parentId,
    required String content,
  }) async {}

  @override
  Future<void> updateMessage({
    required ForumPost post,
    required String title,
    required String content,
  }) async {}

  @override
  Future<ForumUser?> restoreSession() async => currentUser;

  @override
  Future<ForumUser> signIn({
    required String email,
    required String password,
  }) async {
    currentUser = ForumUser(id: 7, email: email, nom: 'Martin', prenom: 'Alex');
    return currentUser!;
  }

  @override
  Future<ForumUser> signUp({
    required String email,
    required String password,
    required String nom,
    required String prenom,
  }) async {
    lastRegisteredNom = nom;
    lastRegisteredPrenom = prenom;
    currentUser = ForumUser(id: 7, email: email, nom: nom, prenom: prenom);
    return currentUser!;
  }

  @override
  Future<ForumUser> updateUser({
    required ForumUser user,
    required String email,
    required String nom,
    required String prenom,
    String? newPassword,
  }) async {
    lastUpdatedNom = nom;
    lastUpdatedPrenom = prenom;
    lastUpdatedPassword = newPassword;
    currentUser = ForumUser(
      id: user.id,
      email: email,
      nom: nom,
      prenom: prenom,
    );
    return currentUser!;
  }

  @override
  Future<void> signOut() async {
    currentUser = null;
  }
}
