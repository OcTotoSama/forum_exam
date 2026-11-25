import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Regroupe les validateurs et petits widgets communs aux formulaires du profil.
abstract final class ProfileFormWidgets {
  static final RegExp emailPattern = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
  static final RegExp newPasswordPattern = RegExp(
    r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[^A-Za-z0-9]).{12,}$',
  );

  /// Refuse un champ obligatoire vide ou composé uniquement d’espaces.
  static String? requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ce champ est obligatoire';
    }
    return null;
  }

  /// Vérifie la forme générale de l’adresse e-mail.
  static String? emailValidator(String? value) {
    if (value == null || !emailPattern.hasMatch(value.trim())) {
      return 'Veuillez saisir une adresse e-mail valide';
    }
    return null;
  }

  /// Valide le nouveau mot de passe sans le rendre obligatoire.
  static String? newPasswordValidator(String? value) {
    if (value == null || value.isEmpty) return null;
    if (!newPasswordPattern.hasMatch(value)) {
      return 'Le mot de passe ne respecte pas les critères requis';
    }
    return null;
  }

  /// Compare la confirmation avec le nouveau mot de passe.
  static String? confirmPasswordValidator(
    TextEditingController passwordController,
    String? value,
  ) {
    if ((value ?? '') != passwordController.text) {
      return 'Les mots de passe ne correspondent pas';
    }
    return null;
  }

  /// Construit un champ de nom ou de prénom.
  static Widget nameField({
    required String label,
    required String hint,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        fieldLabel(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          decoration: inputDecoration(
            hint: hint,
            icon: Icons.person_outline_rounded,
          ),
          validator: requiredValidator,
        ),
      ],
    );
  }

  /// Construit le champ Adresse e-mail utilisé par les deux formulaires.
  static Widget emailField(TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        fieldLabel('Adresse e-mail'),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          decoration: inputDecoration(
            hint: 'nom@exemple.fr',
            icon: Icons.mail_outline_rounded,
          ),
          validator: emailValidator,
        ),
      ],
    );
  }

  /// Construit l’icône qui affiche ou masque le mot de passe.
  static Widget passwordVisibilityToggle({
    required bool obscurePassword,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      tooltip: obscurePassword
          ? 'Afficher le mot de passe'
          : 'Masquer le mot de passe',
      onPressed: onPressed,
      icon: Icon(
        obscurePassword
            ? Icons.visibility_outlined
            : Icons.visibility_off_outlined,
        color: AppColors.muted,
        size: 20,
      ),
    );
  }

  /// Construit le bouton principal des formulaires.
  static Widget submitButton({
    required String label,
    required bool isSubmitting,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: isSubmitting ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.violet,
          foregroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: isSubmitting
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

  /// Construit un bouton du sélecteur Connexion / Inscription.
  static Widget modeButton({
    required String label,
    required bool selected,
    required bool isSubmitting,
    required ValueChanged<String> onSelected,
  }) {
    return Expanded(
      child: TextButton(
        onPressed: isSubmitting ? null : () => onSelected(label),
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

  /// Construit un libellé placé au-dessus d’un champ.
  static Widget fieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.ink,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  /// Construit la décoration commune des champs.
  static InputDecoration inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.muted, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    );
  }

  /// Affiche un message d’erreur dans les formulaires.
  static Widget errorMessage(String message) {
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
}
