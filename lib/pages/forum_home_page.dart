import 'package:flutter/material.dart';

import '../models/forum_post.dart';
import '../models/forum_user.dart';
import '../services/forum_service.dart';
import '../theme/app_theme.dart';
import '../widgets/post_card.dart';

/// Affiche le fil de discussion, son actualisation et les réponses imbriquées.
class ForumHomePage extends StatefulWidget {
  const ForumHomePage({
    super.key,
    required this.service,
    required this.session,
    required this.userPostCount,
  });

  final ForumService service;
  final ValueNotifier<ForumUser?> session;
  final ValueNotifier<int?> userPostCount;

  @override
  State<ForumHomePage> createState() => _ForumHomePageState();
}

class _ForumHomePageState extends State<ForumHomePage> {
  // État du chargement, des messages et des actions effectuées dans le fil.
  List<ForumPost> _posts = const [];
  Object? _loadError;
  bool _isLoading = true;
  bool _isSubmittingMessage = false;
  bool _hasLoadedMessages = false;

  // Conserve l’ouverture des réponses indépendamment pour chaque message.
  final Set<int> _expandedMessages = {};

  @override
  void initState() {
    super.initState();
    // Les changements de session modifient notamment les droits de modification.
    widget.session.addListener(_onSessionChanged);
    // Charge le fil dès la création de l’onglet.
    _loadMessages();
  }

  @override
  void didUpdateWidget(covariant ForumHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session) {
      // Déplace l’écouteur si le parent fournit une nouvelle session partagée.
      oldWidget.session.removeListener(_onSessionChanged);
      widget.session.addListener(_onSessionChanged);
      _updateUserPostCount();
    }
  }

  @override
  void dispose() {
    widget.session.removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    // Met à jour les actions du fil sans reconstruire toute l’application.
    if (mounted) {
      _updateUserPostCount();
      setState(() {});
    }
  }

  /// Recharge les messages et conserve l’erreur pour l’afficher dans le fil.
  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final posts = await widget.service.getMessages();
      // L’écran peut avoir été fermé pendant la requête.
      if (!mounted) return;
      setState(() {
        _posts = posts;
        _isLoading = false;
        _hasLoadedMessages = true;
      });
      _updateUserPostCount();
    } catch (error) {
      if (!mounted) return;
      // Une panne réseau devient un état d’interface avec une action Réessayer.
      setState(() {
        _loadError = error;
        _isLoading = false;
      });
    }
  }

  /// Calcule les publications racines de l’utilisateur connecté.
  void _updateUserPostCount() {
    if (!_hasLoadedMessages) return;
    final userId = widget.session.value?.id;
    if (userId == null) {
      widget.userPostCount.value = null;
      return;
    }

    widget.userPostCount.value = _posts
        .where((post) => post.userId == userId && post.parentId == null)
        .length;
  }

  /// Prépare un index parent → réponses pour retrouver rapidement les enfants.
  Map<int, List<ForumPost>> get _repliesByParent {
    // Regroupe les réponses par identifiant de message parent pour construire l’arbre.
    final replies = <int, List<ForumPost>>{};
    for (final post in _posts) {
      final parentId = post.parentId;
      if (parentId == null) continue;
      replies.putIfAbsent(parentId, () => []).add(post);
    }
    return replies;
  }

  /// Retourne les messages sans parent qui commencent les branches du fil.
  List<ForumPost> get _rootPosts =>
      _posts.where((post) => post.parentId == null).toList();

  @override
  Widget build(BuildContext context) {
    // Construit l’index une seule fois par rendu, puis le partage dans l’arbre.
    final repliesByParent = _repliesByParent;
    final rootPosts = _rootPosts;

    // RefreshIndicator gère le geste d’actualisation ; CustomScrollView et ses
    // slivers regroupent l’en-tête, les états de chargement et la liste défilante.
    return RefreshIndicator(
      onRefresh: _loadMessages,
      // CustomScrollView assemble les blocs défilants du fil en utilisant des slivers.
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // SliverToBoxAdapter transforme les widgets classiques en contenu défilant.
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 26),
              // Column empile l’en-tête et le titre du forum verticalement.
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row personnalisé qui affiche le titre et le bouton d’actualisation.
                  _buildTopBar(),
                  const SizedBox(height: 30),
                  // Row personnalisé qui affiche le titre de section et le nombre de messages.
                  _buildSectionTitle(),
                ],
              ),
            ),
          ),
          if (_isLoading && _posts.isEmpty)
            // SliverFillRemaining occupe la zone disponible pendant le chargement initial.
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                // CircularProgressIndicator indique qu’une requête est en cours.
                child: CircularProgressIndicator(color: AppColors.violet),
              ),
            )
          else if (_loadError != null && _posts.isEmpty)
            // SliverFillRemaining affiche l’erreur principale au centre de l’écran.
            SliverFillRemaining(hasScrollBody: false, child: _buildError())
          else if (_posts.isEmpty)
            // SliverFillRemaining affiche un message lorsque le forum ne contient aucun post.
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'Aucun message pour le moment.',
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
            )
          else ...[
            if (_loadError != null)
              // SliverToBoxAdapter insère l’avertissement en haut de la liste existante.
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
                  child: _buildInlineError(),
                ),
              ),
            // SliverPadding ajoute les marges autour de la liste des messages.
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              // SliverList.builder crée uniquement les cartes visibles dans le fil.
              sliver: SliverList.builder(
                itemCount: rootPosts.length,
                itemBuilder: (context, index) {
                  return _buildMessageTree(
                    rootPosts[index],
                    0,
                    <int>{},
                    repliesByParent,
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Affiche un message puis ses descendants si l’utilisateur ouvre ses réponses.
  Widget _buildMessageTree(
    ForumPost post,
    int depth,
    Set<int> ancestors,
    Map<int, List<ForumPost>> repliesByParent,
  ) {
    // Ignore une relation cyclique éventuelle renvoyée par les données de l’API.
    if (ancestors.contains(post.id)) return const SizedBox.shrink();
    final path = {...ancestors, post.id};
    final children = repliesByParent[post.id] ?? const <ForumPost>[];
    final userId = widget.session.value?.id;
    final canEdit = userId != null && userId == post.userId;
    final isExpanded = _expandedMessages.contains(post.id);

    // Padding crée l’espacement vertical entre chaque message du fil.
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      // Column empile la carte du message et ses réponses éventuelles.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // PostCard affiche le contenu du message et expose ses actions de réponse.
          PostCard(
            post: post,
            replyCount: children.length,
            isExpanded: isExpanded,
            isReply: depth > 0,
            // Sans réponse, il n’y a pas de branche à développer.
            onTap: children.isEmpty
                ? () {}
                : () {
                    setState(() {
                      if (isExpanded) {
                        _expandedMessages.remove(post.id);
                      } else {
                        _expandedMessages.add(post.id);
                      }
                    });
                  },
            onReply: () => _openMessageEditor(post, isReply: true),
            onEdit: canEdit
                ? () => _openMessageEditor(post, isReply: false)
                : null,
          ),
          if (isExpanded && children.isNotEmpty)
            // Container dessine le rail vertical qui relie les réponses au parent.
            Container(
              margin: EdgeInsets.only(left: depth == 0 ? 22 : 16, top: 12),
              padding: const EdgeInsets.only(left: 14),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: AppColors.violet.withValues(alpha: 0.38),
                    width: 2,
                  ),
                ),
              ),
              // Column empile les cartes des réponses imbriquées sous leur parent.
              child: Column(
                children: [
                  for (final reply in children)
                    _buildMessageTree(reply, depth + 1, path, repliesByParent),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Demande un brouillon, le valide, puis crée ou modifie le message choisi.
  Future<void> _openMessageEditor(
    ForumPost post, {
    required bool isReply,
  }) async {
    // Un seul envoi à la fois évite les doubles soumissions.
    if (_isSubmittingMessage) return;
    final user = widget.session.value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connectez-vous depuis l’onglet Profil pour répondre.'),
        ),
      );
      return;
    }
    if (!isReply && (user.id == null || user.id != post.userId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous ne pouvez modifier que vos messages.'),
        ),
      );
      return;
    }

    // Les contrôleurs ne vivent que pendant le dialogue et sont libérés après.
    final titleController = TextEditingController(
      text: isReply ? '' : post.title,
    );
    final contentController = TextEditingController(
      text: isReply ? '' : post.body,
    );
    String? validationError;

    // AlertDialog recueille le brouillon ; l’appel API n’a lieu qu’après validation.
    final draft = await showDialog<_MessageDraft>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        // StatefulBuilder reconstruit le dialogue pour afficher les erreurs de validation.
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isReply ? 'Répondre au message' : 'Modifier mon message'),
          content: SingleChildScrollView(
            // Column organise les champs du formulaire dans le dialogue.
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isReply) ...[
                  // TextField permet de saisir ou modifier le titre du message.
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Titre'),
                  ),
                  const SizedBox(height: 12),
                ],
                // TextField permet de saisir le contenu du message ou de la réponse.
                TextField(
                  controller: contentController,
                  minLines: 3,
                  maxLines: 7,
                  decoration: InputDecoration(
                    labelText: isReply ? 'Votre réponse' : 'Contenu',
                    errorText: validationError,
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            // TextButton ferme le dialogue sans enregistrer les modifications.
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            // FilledButton valide le formulaire et renvoie le brouillon à la page.
            FilledButton(
              onPressed: () {
                if (contentController.text.trim().isEmpty) {
                  setDialogState(
                    () => validationError = 'Le contenu ne peut pas être vide.',
                  );
                  return;
                }
                Navigator.pop(
                  dialogContext,
                  _MessageDraft(
                    title: titleController.text,
                    content: contentController.text,
                  ),
                );
              },
              child: Text(isReply ? 'Envoyer' : 'Enregistrer'),
            ),
          ],
        ),
      ),
    );
    titleController.dispose();
    contentController.dispose();
    if (draft == null || !mounted) return;

    // Le même formulaire sert à publier une réponse ou modifier son message.
    setState(() => _isSubmittingMessage = true);
    try {
      if (isReply) {
        await widget.service.createReply(
          parentId: post.id,
          content: draft.content,
        );
        _expandedMessages.add(post.id);
      } else {
        await widget.service.updateMessage(
          post: post,
          title: draft.title,
          content: draft.content,
        );
      }
      await _loadMessages();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isReply ? 'Réponse publiée.' : 'Message modifié.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Action impossible : $error')));
    } finally {
      if (mounted) setState(() => _isSubmittingMessage = false);
    }
  }

  /// Construit l’en-tête du forum et son bouton d’actualisation.
  Widget _buildTopBar() {
    // Row place le logo, les titres et le bouton d’actualisation sur une même ligne.
    return Row(
      children: [
        // Container habille l’icône du forum avec un dégradé et une ombre.
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
          // Icon affiche le symbole du forum dans le carré coloré.
          child: const Icon(
            Icons.forum_rounded,
            color: AppColors.background,
            size: 24,
          ),
        ),
        const SizedBox(width: 13),
        // Expanded occupe l’espace restant pour afficher le nom et la description du forum.
        const Expanded(
          // Column empile le nom du forum et sa description.
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
        // IconButton permet de relancer manuellement le chargement des messages.
        IconButton(
          onPressed: _isLoading ? null : _loadMessages,
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

  /// Affiche le titre du fil et le nombre de messages chargés.
  Widget _buildSectionTitle() {
    // Row aligne le titre du fil avec le compteur à droite.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Expanded(
          // Column empile le titre de section et son texte descriptif.
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
        // Container affiche le nombre de messages dans un badge arrondi.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          // Row place l’icône du forum devant le nombre de messages.
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
                '${_posts.length}',
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

  /// Présente une erreur bloquante avec une action pour relancer le chargement.
  Widget _buildError() {
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
            '$_loadError',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _loadMessages,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  /// Présente une erreur de rafraîchissement sans masquer les anciens messages.
  Widget _buildInlineError() {
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
              'Actualisation impossible : $_loadError',
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ),
          TextButton(onPressed: _loadMessages, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}

class _MessageDraft {
  // Données temporaires du dialogue, séparées du modèle persisté ForumPost.
  const _MessageDraft({required this.title, required this.content});

  final String title;
  final String content;
}
