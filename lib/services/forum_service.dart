import '../models/forum_post.dart';
import '../models/forum_user.dart';

/// Contrat commun au service API et aux doublures utilisées dans les tests.
abstract interface class ForumService {
  /// Récupère les messages du fil.
  Future<List<ForumPost>> getMessages();

  /// Publie une réponse rattachée à [parentId].
  Future<void> createReply({required int parentId, required String content});

  /// Modifie le titre et le contenu du message fourni.
  Future<void> updateMessage({
    required ForumPost post,
    required String title,
    required String content,
  });

  /// Restaure la session enregistrée, ou retourne `null` si elle est absente.
  Future<ForumUser?> restoreSession();

  /// Ouvre une session avec l’adresse et le mot de passe.
  Future<ForumUser> signIn({required String email, required String password});

  /// Crée un compte puis retourne le profil connecté.
  Future<ForumUser> signUp({
    required String email,
    required String password,
    required String nom,
    required String prenom,
  });

  /// Enregistre les nouvelles informations du profil.
  Future<ForumUser> updateUser({
    required ForumUser user,
    required String email,
    required String nom,
    required String prenom,
    String? newPassword,
  });

  /// Termine la session et efface les identifiants persistés.
  Future<void> signOut();
}
