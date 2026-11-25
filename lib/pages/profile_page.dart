import 'package:flutter/material.dart';

import '../models/forum_user.dart';
import '../services/forum_service.dart';
import '../theme/app_theme.dart';
import 'profile/profile_auth_form.dart';
import 'profile/profile_edit_form.dart';
import 'profile/profile_view.dart';

/// Affiche la connexion, l’inscription et les paramètres du compte connecté.
class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.service,
    required this.session,
    required this.userPostCount,
  });

  final ForumService service;
  final ValueNotifier<ForumUser?> session;
  final ValueNotifier<int?> userPostCount;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _profileScrollController = ScrollController();
  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isRegistering = false;
  bool _isEditingProfile = false;
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  bool _isRestoringSession = true;
  ForumUser? _user;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  @override
  void dispose() {
    _lastNameController.dispose();
    _firstNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _profileScrollController.dispose();
    super.dispose();
  }

  /// Lit la session enregistrée puis partage l’utilisateur restauré.
  Future<void> _restoreSession() async {
    try {
      final user = await widget.service.restoreSession();
      if (!mounted) return;
      setState(() {
        _user = user;
        _isRestoringSession = false;
      });
      widget.session.value = user;
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isRestoringSession = false;
      });
    }
  }

  /// Replace le début de la page après un changement de formulaire.
  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_profileScrollController.hasClients) return;
      _profileScrollController.jumpTo(0);
    });
  }

  /// Valide puis appelle la connexion ou l’inscription.
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      final user = _isRegistering
          ? await widget.service.signUp(
              email: _emailController.text.trim(),
              password: _passwordController.text,
              nom: _lastNameController.text.trim(),
              prenom: _firstNameController.text.trim(),
            )
          : await widget.service.signIn(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );
      if (!mounted) return;
      setState(() {
        _user = user;
        _isSubmitting = false;
        _passwordController.clear();
      });
      _scrollToTop();
      widget.session.value = user;
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = error.toString();
      });
    }
  }

  /// Prépare les champs puis affiche le formulaire de modification.
  void _openProfileSettings(ForumUser user) {
    _lastNameController.text = user.nom;
    _firstNameController.text = user.prenom;
    _emailController.text = user.email;
    _passwordController.clear();
    _confirmPasswordController.clear();
    setState(() {
      _isEditingProfile = true;
      _errorMessage = null;
    });
  }

  /// Annule la modification et revient au profil connecté.
  void _cancelProfileEdit() {
    _passwordController.clear();
    _confirmPasswordController.clear();
    setState(() {
      _isEditingProfile = false;
      _errorMessage = null;
    });
  }

  /// Envoie les informations modifiées puis actualise la session.
  Future<void> _submitProfileChanges() async {
    if (!_formKey.currentState!.validate()) return;
    final currentUser = _user;
    if (currentUser == null) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      final user = await widget.service.updateUser(
        user: currentUser,
        email: _emailController.text.trim(),
        nom: _lastNameController.text.trim(),
        prenom: _firstNameController.text.trim(),
        newPassword: _passwordController.text.isEmpty
            ? null
            : _passwordController.text,
      );
      if (!mounted) return;
      _passwordController.clear();
      _confirmPasswordController.clear();
      setState(() {
        _user = user;
        _isEditingProfile = false;
        _isSubmitting = false;
      });
      _scrollToTop();
      widget.session.value = user;
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = error.toString();
      });
    }
  }

  /// Ferme la session locale puis revient au formulaire d’authentification.
  Future<void> _signOut() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await widget.service.signOut();
      if (!mounted) return;
      setState(() {
        _user = null;
        _isRegistering = false;
        _isSubmitting = false;
      });
      _scrollToTop();
      widget.session.value = null;
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // SingleChildScrollView garde tous les états du profil défilables sur petit écran.
    return SingleChildScrollView(
      controller: _profileScrollController,
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
      child: _isRestoringSession
          // SizedBox centre l’indicateur pendant la restauration.
          ? const SizedBox(
              height: 300,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.violet),
              ),
            )
          : _user == null
          // Affiche la connexion ou l’inscription si aucune session n’est active.
          ? ProfileAuthForm(
              formKey: _formKey,
              isRegistering: _isRegistering,
              obscurePassword: _obscurePassword,
              isSubmitting: _isSubmitting,
              errorMessage: _errorMessage,
              lastNameController: _lastNameController,
              firstNameController: _firstNameController,
              emailController: _emailController,
              passwordController: _passwordController,
              onModeChanged: (isRegistering) {
                setState(() {
                  _isRegistering = isRegistering;
                  _errorMessage = null;
                });
                _formKey.currentState?.reset();
              },
              onTogglePasswordVisibility: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
              onSubmit: _submitForm,
            )
          : _isEditingProfile
          // Affiche la modification du compte.
          ? ProfileEditForm(
              formKey: _formKey,
              obscurePassword: _obscurePassword,
              isSubmitting: _isSubmitting,
              errorMessage: _errorMessage,
              lastNameController: _lastNameController,
              firstNameController: _firstNameController,
              emailController: _emailController,
              passwordController: _passwordController,
              confirmPasswordController: _confirmPasswordController,
              onTogglePasswordVisibility: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
              onSubmit: _submitProfileChanges,
              onCancel: _cancelProfileEdit,
            )
          // Affiche les informations du compte connecté.
          : ProfileView(
              user: _user!,
              userPostCount: widget.userPostCount,
              isSubmitting: _isSubmitting,
              errorMessage: _errorMessage,
              onOpenSettings: _openProfileSettings,
              onSignOut: _signOut,
            ),
    );
  }
}
