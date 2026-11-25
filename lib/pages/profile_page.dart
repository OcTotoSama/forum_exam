import 'package:flutter/material.dart';

import '../models/forum_user.dart';
import '../services/forum_service.dart';
import '../theme/app_theme.dart';

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
  // Les règles sont définies une fois et partagées par les formulaires.
  static final _emailPattern = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
  static final _newPasswordPattern = RegExp(
    r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[^A-Za-z0-9]).{12,}$',
  );

  // Les contrôleurs gardent la valeur des champs lors des changements d’écran.
  final _formKey = GlobalKey<FormState>();
  final _profileScrollController = ScrollController();
  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  // Ces indicateurs déterminent quel formulaire et quel état afficher.
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
    // Restaure la session sécurisée dès l’ouverture de l’onglet Profil.
    _restoreSession();
  }

  @override
  void dispose() {
    // Libère les ressources détenues par les champs du formulaire.
    _lastNameController.dispose();
    _firstNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _profileScrollController.dispose();
    super.dispose();
  }

  /// Lit la session enregistrée puis actualise l’écran et la session partagée.
  Future<void> _restoreSession() async {
    try {
      final user = await widget.service.restoreSession();
      // Ne met pas à jour l’état si l’utilisateur a quitté la page entre-temps.
      if (!mounted) return;
      setState(() {
        _user = user;
        _isRestoringSession = false;
      });
      // Partage le résultat avec le fil pour activer les actions autorisées.
      widget.session.value = user;
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isRestoringSession = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // SingleChildScrollView permet de parcourir les formulaires sur petit écran.
    // L’affichage passe du chargement à la connexion ou au profil selon la session.
    return SingleChildScrollView(
      controller: _profileScrollController,
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
      child: _isRestoringSession
          // SizedBox centre l’indicateur pendant la restauration de la session.
          ? const SizedBox(
              height: 300,
              child: Center(
                // CircularProgressIndicator indique que la session est en cours de restauration.
                child: CircularProgressIndicator(color: AppColors.violet),
              ),
            )
          : _user == null
          // Affiche le formulaire de connexion ou d’inscription si aucune session n’est active.
          ? _buildAuthForm()
          : _isEditingProfile
          // Affiche le formulaire de modification lorsque les réglages sont ouverts.
          ? _buildEditProfileForm()
          // Affiche les informations du compte lorsque la session est active.
          : _buildConnectedProfile(_user!),
    );
  }

  /// Construit l’interface de connexion et d’inscription.
  Widget _buildAuthForm() {
    // Column empile l’en-tête, le sélecteur de mode et le formulaire.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row place l’icône du profil et les titres sur une même ligne.
        Row(
          children: [
            // Container habille l’icône du profil avec un dégradé.
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.violet, Color(0xFF7867E8)],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.violet.withValues(alpha: 0.2),
                    blurRadius: 18,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              // Icon affiche le symbole du profil dans le carré coloré.
              child: const Icon(
                Icons.person_outline_rounded,
                color: AppColors.background,
                size: 25,
              ),
            ),
            const SizedBox(width: 14),
            // Expanded occupe l’espace restant pour les titres du profil.
            const Expanded(
              // Column empile le titre et la description.
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mon profil',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.7,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Votre espace au sein de la communauté',
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        // Container affiche le formulaire dans une carte distincte.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Ces deux boutons basculent entre les formulaires de connexion et d’inscription.
              // Container dessine l’arrière-plan arrondi du sélecteur de mode.
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(15),
                ),
                // Row place les boutons Connexion et Inscription côte à côte.
                child: Row(
                  children: [
                    _buildModeButton('Connexion', !_isRegistering),
                    _buildModeButton('Inscription', _isRegistering),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Form regroupe les champs et valide leur contenu avant l’envoi.
              // Form déclenche les validateurs avant la connexion ou l’inscription.
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isRegistering) ...[
                      _buildNameField(
                        label: 'Nom',
                        hint: 'Votre nom',
                        controller: _lastNameController,
                      ),
                      const SizedBox(height: 18),
                      _buildNameField(
                        label: 'Prénom',
                        hint: 'Votre prénom',
                        controller: _firstNameController,
                      ),
                      const SizedBox(height: 18),
                    ],
                    _buildEmailField(),
                    const SizedBox(height: 18),
                    _buildFieldLabel('Mot de passe'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: _inputDecoration(
                        hint: 'Votre mot de passe',
                        icon: Icons.lock_outline_rounded,
                      ).copyWith(suffixIcon: _buildPasswordVisibilityToggle()),
                      validator: _requiredValidator,
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      _buildErrorMessage(_errorMessage!),
                    ],
                    const SizedBox(height: 22),
                    _buildSubmitButton(
                      label: _isRegistering
                          ? 'Créer mon compte'
                          : 'Se connecter',
                      onPressed: _submitForm,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Refuse les champs obligatoires absents ou composés uniquement d’espaces.
  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ce champ est obligatoire';
    }
    return null;
  }

  /// Vérifie la forme générale de l’adresse avant l’appel à l’API.
  String? _emailValidator(String? value) {
    if (value == null || !_emailPattern.hasMatch(value.trim())) {
      return 'Veuillez saisir une adresse e-mail valide';
    }
    return null;
  }

  /// Le mot de passe reste facultatif lors d’une simple modification de profil.
  String? _newPasswordValidator(String? value) {
    if (value == null || value.isEmpty) return null;
    if (!_newPasswordPattern.hasMatch(value)) {
      return 'Le mot de passe ne respecte pas les critères requis';
    }
    return null;
  }

  /// Compare la confirmation avec la valeur actuelle du nouveau mot de passe.
  String? _confirmPasswordValidator(String? value) {
    if ((value ?? '') != _passwordController.text) {
      return 'Les mots de passe ne correspondent pas';
    }
    return null;
  }

  /// Construit un champ de nom avec la même décoration et validation.
  Widget _buildNameField({
    required String label,
    required String hint,
    required TextEditingController controller,
  }) {
    // Column associe le libellé à son champ de saisie.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label),
        const SizedBox(height: 8),
        // TextFormField collecte le nom ou le prénom et applique la validation.
        TextFormField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          decoration: _inputDecoration(
            hint: hint,
            icon: Icons.person_outline_rounded,
          ),
          validator: _requiredValidator,
        ),
      ],
    );
  }

  /// Construit le champ d’adresse réutilisé à l’inscription et dans les réglages.
  Widget _buildEmailField() {
    // Column associe le libellé à un champ de saisie d’adresse e-mail.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Adresse e-mail'),
        const SizedBox(height: 8),
        // TextFormField collecte l’adresse e-mail et vérifie son format.
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          decoration: _inputDecoration(
            hint: 'nom@exemple.fr',
            icon: Icons.mail_outline_rounded,
          ),
          validator: _emailValidator,
        ),
      ],
    );
  }

  /// Construit l’IconButton qui masque ou révèle le texte du mot de passe.
  Widget _buildPasswordVisibilityToggle() {
    // IconButton bascule la visibilité du mot de passe sans modifier sa valeur.
    return IconButton(
      tooltip: _obscurePassword
          ? 'Afficher le mot de passe'
          : 'Masquer le mot de passe',
      onPressed: () => setState(() {
        _obscurePassword = !_obscurePassword;
      }),
      icon: Icon(
        _obscurePassword
            ? Icons.visibility_outlined
            : Icons.visibility_off_outlined,
        color: AppColors.muted,
        size: 20,
      ),
    );
  }

  /// Construit le bouton principal, remplacé par un indicateur pendant l’envoi.
  Widget _buildSubmitButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    // SizedBox impose une largeur totale et une hauteur fixe au bouton principal.
    return SizedBox(
      width: double.infinity,
      height: 52,
      // FilledButton lance l’action choisie ou affiche un chargement.
      child: FilledButton(
        onPressed: _isSubmitting ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.violet,
          foregroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.background,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  /// Construit un choix de mode dans le sélecteur Connexion / Inscription.
  Widget _buildModeButton(String label, bool selected) {
    // Expanded répartit également la largeur entre les deux modes.
    return Expanded(
      // TextButton permet de basculer entre connexion et inscription.
      child: TextButton(
        onPressed: _isSubmitting
            ? null
            : () {
                setState(() {
                  _isRegistering = label == 'Inscription';
                  _errorMessage = null;
                });
                _formKey.currentState?.reset();
              },
        style: TextButton.styleFrom(
          backgroundColor: selected ? AppColors.surface : Colors.transparent,
          foregroundColor: selected ? AppColors.violet : AppColors.muted,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  /// Construit le libellé visuel affiché au-dessus d’un champ.
  Widget _buildFieldLabel(String label) {
    // Text affiche le libellé avec le style commun des formulaires.
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.ink,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  /// Ajoute l’indice et l’icône tout en conservant le thème global des champs.
  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.muted, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    );
  }

  /// Présente un message d’erreur dans le style commun aux deux formulaires.
  Widget _buildErrorMessage(String message) {
    // Container encadre le texte d’erreur dans une couleur visible.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF542E39),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: const TextStyle(color: AppColors.ink, fontSize: 12, height: 1.4),
      ),
    );
  }

  /// Valide puis appelle l’inscription ou la connexion selon le mode sélectionné.
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

  /// Assemble l’avatar, les informations du compte, les réglages et la déconnexion.
  Widget _buildConnectedProfile(ForumUser user) {
    final initial = user.prenom.isNotEmpty
        ? user.prenom[0].toUpperCase()
        : user.nom.isNotEmpty
        ? user.nom[0].toUpperCase()
        : '?';

    // Column empile toutes les sections visibles du profil connecté.
    return Column(
      children: [
        // Container présente l’en-tête du compte dans une carte arrondie.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.surfaceRaised, AppColors.surface],
            ),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Row place l’étiquette « MON COMPTE » et le bouton des paramètres.
              Row(
                children: [
                  // Container affiche l’étiquette du compte avec son icône.
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.indicator,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.person_rounded,
                          color: AppColors.violet,
                          size: 14,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'MON COMPTE',
                          style: TextStyle(
                            color: AppColors.violet,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // IconButton ouvre le formulaire de modification du profil.
                  IconButton(
                    tooltip: 'Paramètres du profil',
                    onPressed: _isSubmitting
                        ? null
                        : () => _openProfileSettings(user),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      foregroundColor: AppColors.ink,
                    ),
                    icon: const Icon(Icons.settings_outlined, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Container dessine le contour dégradé autour de l’avatar.
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.violet, Color(0xFF7867E8)],
                  ),
                ),
                // CircleAvatar affiche l’initiale du membre au centre.
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.surface,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: AppColors.violet,
                      fontSize: 29,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              // Text affiche le nom complet du membre connecté.
              Text(
                user.displayName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 9),
              // Container affiche un badge indiquant le statut de membre.
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      color: AppColors.violet,
                      size: 15,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Membre de la communauté',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        // Container regroupe les compteurs statistiques du membre.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          // ValueListenableBuilder met à jour les publications quand leur nombre change.
          child: ValueListenableBuilder<int?>(
            valueListenable: widget.userPostCount,
            builder: (context, publicationCount, _) => Row(
              children: [
                _buildProfileStat(
                  publicationCount?.toString() ?? '—',
                  'Publications',
                ),
                _buildProfileStatDivider(),
                _buildProfileStat('0', 'Abonnés'),
                _buildProfileStatDivider(),
                _buildProfileStat('0', 'Abonnements'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 9),
        const Text(
          'Les données d’abonnés seront disponibles plus tard',
          style: TextStyle(color: AppColors.muted, fontSize: 11),
        ),
        const SizedBox(height: 22),
        // Container affiche l’adresse e-mail dans une ligne dédiée.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          // Row place l’icône de courrier et l’adresse e-mail sur une même ligne.
          child: Row(
            children: [
              // Container habille l’icône de l’adresse e-mail.
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.indicator,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.mail_outline_rounded,
                  color: AppColors.violet,
                  size: 20,
                ),
              ),
              const SizedBox(width: 13),
              // Expanded limite l’adresse e-mail et ajoute des points si elle est trop longue.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Adresse e-mail',
                      style: TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // SizedBox donne au bouton de déconnexion une largeur totale.
        SizedBox(
          width: double.infinity,
          height: 52,
          // OutlinedButton permet de fermer la session courante.
          child: OutlinedButton.icon(
            onPressed: _isSubmitting ? null : _signOut,
            icon: const Icon(Icons.logout_rounded, size: 19),
            label: const Text('Se déconnecter'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.muted,
              side: const BorderSide(color: AppColors.border),
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 14),
          _buildErrorMessage(_errorMessage!),
        ],
      ],
    );
  }

  /// Affiche un compteur provisoire pour une statistique du profil.
  Widget _buildProfileStat(String count, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            count,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Sépare les trois compteurs sans alourdir leur présentation.
  Widget _buildProfileStatDivider() {
    return Container(width: 1, height: 30, color: AppColors.border);
  }

  /// Replace le début du nouvel écran visible après un changement de formulaire.
  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_profileScrollController.hasClients) return;
      _profileScrollController.jumpTo(0);
    });
  }

  /// Préremplit les champs avant de passer au formulaire de modification.
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

  /// Construit le formulaire de mise à jour des informations du compte.
  Widget _buildEditProfileForm() {
    // Column empile le titre et tous les champs de modification du profil.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Paramètres du profil',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.7,
          ),
        ),
        const SizedBox(height: 24),
        // Form valide les noms, l’e-mail et le nouveau mot de passe avant l’envoi.
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNameField(
                label: 'Nom',
                hint: 'Votre nom',
                controller: _lastNameController,
              ),
              const SizedBox(height: 18),
              _buildNameField(
                label: 'Prénom',
                hint: 'Votre prénom',
                controller: _firstNameController,
              ),
              const SizedBox(height: 18),
              _buildEmailField(),
              const SizedBox(height: 24),
              _buildFieldLabel('Nouveau mot de passe (facultatif)'),
              const SizedBox(height: 8),
              // Le changement de mot de passe est facultatif et contrôlé par l’API.
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                autocorrect: false,
                enableSuggestions: false,
                decoration:
                    _inputDecoration(
                      hint: 'Laisser vide pour ne pas le modifier',
                      icon: Icons.lock_outline_rounded,
                    ).copyWith(
                      helperText:
                          '12 caractères minimum, avec majuscule, minuscule, '
                          'chiffre et caractère spécial.',
                      suffixIcon: _buildPasswordVisibilityToggle(),
                    ),
                validator: _newPasswordValidator,
              ),
              const SizedBox(height: 18),
              _buildFieldLabel('Confirmer le nouveau mot de passe'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                decoration: _inputDecoration(
                  hint: 'Répétez le nouveau mot de passe',
                  icon: Icons.lock_outline_rounded,
                ),
                validator: _confirmPasswordValidator,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                _buildErrorMessage(_errorMessage!),
              ],
              const SizedBox(height: 22),
              _buildSubmitButton(
                label: 'Enregistrer',
                onPressed: _submitProfileChanges,
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: TextButton(
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          _passwordController.clear();
                          _confirmPasswordController.clear();
                          setState(() {
                            _isEditingProfile = false;
                            _errorMessage = null;
                          });
                        },
                  child: const Text('Annuler'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Envoie les informations modifiées et actualise la session partagée.
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

  /// Efface le jeton local avant de revenir au formulaire de connexion.
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
}
