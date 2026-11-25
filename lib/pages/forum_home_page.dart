import 'package:flutter/material.dart';

import '../models/forum_post.dart';
import '../models/forum_user.dart';
import '../services/forum_service.dart';
import '../theme/app_theme.dart';
import 'forum/forum_header.dart';
import 'forum/forum_loading_states.dart';
import 'forum/forum_message_editor.dart';
import 'forum/forum_message_tree.dart';

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
  List<ForumPost> _posts = const [];
  Object? _loadError;
  bool _isLoading = true;
  bool _isSubmittingMessage = false;
  bool _hasLoadedMessages = false;
  final Set<int> _expandedMessages = {};

  @override
  void initState() {
    super.initState();
    widget.session.addListener(_onSessionChanged);
    _loadMessages();
  }

  @override
  void didUpdateWidget(covariant ForumHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session) {
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

  /// Réagit aux changements de connexion sans reconstruire les services.
  void _onSessionChanged() {
    if (mounted) {
      _updateUserPostCount();
      setState(() {});
    }
  }

  /// Recharge les messages et conserve les erreurs pour les afficher.
  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final posts = await widget.service.getMessages();
      if (!mounted) return;
      setState(() {
        _posts = posts;
        _isLoading = false;
        _hasLoadedMessages = true;
      });
      _updateUserPostCount();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error;
        _isLoading = false;
      });
    }
  }

  /// Calcule uniquement les publications racines de l’utilisateur connecté.
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

  /// Retourne les messages racines à afficher au premier niveau.
  List<ForumPost> get _rootPosts =>
      _posts.where((post) => post.parentId == null).toList();

  /// Prépare une liste de réponses associée à chaque identifiant parent.
  Map<int, List<ForumPost>> get _repliesByParent {
    final replies = <int, List<ForumPost>>{};
    for (final post in _posts) {
      final parentId = post.parentId;
      if (parentId == null) continue;
      replies.putIfAbsent(parentId, () => []).add(post);
    }
    return replies;
  }

  /// Ouvre ou ferme les réponses d’un message.
  void _toggleReplies(int postId) {
    setState(() {
      if (_expandedMessages.contains(postId)) {
        _expandedMessages.remove(postId);
      } else {
        _expandedMessages.add(postId);
      }
    });
  }

  /// Demande un brouillon, puis publie ou modifie le message choisi.
  Future<void> _openMessageEditor(
    ForumPost post, {
    required bool isReply,
  }) async {
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

    final draft = await ForumMessageEditor.open(
      context: context,
      post: post,
      isReply: isReply,
    );
    if (draft == null || !mounted) return;

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

  @override
  Widget build(BuildContext context) {
    final repliesByParent = _repliesByParent;
    final rootPosts = _rootPosts;

    return RefreshIndicator(
      onRefresh: _loadMessages,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ForumHeader(isLoading: _isLoading, onRefresh: _loadMessages),
                  const SizedBox(height: 30),
                  ForumSectionTitle(postCount: _posts.length),
                ],
              ),
            ),
          ),
          if (_isLoading && _posts.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.violet),
              ),
            )
          else if (_loadError != null && _posts.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: ForumLoadingStates.error(
                error: _loadError,
                onRetry: _loadMessages,
              ),
            )
          else if (_posts.isEmpty)
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
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
                  child: ForumLoadingStates.inlineError(
                    error: _loadError,
                    onRetry: _loadMessages,
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverList.builder(
                itemCount: rootPosts.length,
                itemBuilder: (context, index) {
                  return ForumMessageTree(
                    post: rootPosts[index],
                    depth: 0,
                    ancestors: const <int>{},
                    repliesByParent: repliesByParent,
                    expandedMessages: _expandedMessages,
                    session: widget.session,
                    onToggleReplies: _toggleReplies,
                    onReply: (post) => _openMessageEditor(post, isReply: true),
                    onEdit: (post) => _openMessageEditor(post, isReply: false),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
