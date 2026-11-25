import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'profile_form_widgets.dart';

/// Affiche le formulaire de connexion ou d’inscription.
class ProfileAuthForm extends StatelessWidget {
  const ProfileAuthForm({
    super.key,
    required this.formKey,
    required this.isRegistering,
    required this.obscurePassword,
    required this.isSubmitting,
    required this.errorMessage,
    required this.lastNameController,
    required this.firstNameController,
    required this.emailController,
    required this.passwordController,
    required this.onModeChanged,
    required this.onTogglePasswordVisibility,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final bool isRegistering;
  final bool obscurePassword;
  final bool isSubmitting;
  final String? errorMessage;
  final TextEditingController lastNameController;
  final TextEditingController firstNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final ValueChanged<bool> onModeChanged;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
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
              child: const Icon(
                Icons.person_outline_rounded,
                color: AppColors.background,
                size: 25,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
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
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    ProfileFormWidgets.modeButton(
                      label: 'Connexion',
                      selected: !isRegistering,
                      isSubmitting: isSubmitting,
                      onSelected: (_) => onModeChanged(false),
                    ),
                    ProfileFormWidgets.modeButton(
                      label: 'Inscription',
                      selected: isRegistering,
                      isSubmitting: isSubmitting,
                      onSelected: (_) => onModeChanged(true),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isRegistering) ...[
                      ProfileFormWidgets.nameField(
                        label: 'Nom',
                        hint: 'Votre nom',
                        controller: lastNameController,
                      ),
                      const SizedBox(height: 18),
                      ProfileFormWidgets.nameField(
                        label: 'Prénom',
                        hint: 'Votre prénom',
                        controller: firstNameController,
                      ),
                      const SizedBox(height: 18),
                    ],
                    ProfileFormWidgets.emailField(emailController),
                    const SizedBox(height: 18),
                    ProfileFormWidgets.fieldLabel('Mot de passe'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      decoration:
                          ProfileFormWidgets.inputDecoration(
                            hint: 'Votre mot de passe',
                            icon: Icons.lock_outline_rounded,
                          ).copyWith(
                            suffixIcon:
                                ProfileFormWidgets.passwordVisibilityToggle(
                                  obscurePassword: obscurePassword,
                                  onPressed: onTogglePasswordVisibility,
                                ),
                          ),
                      validator: ProfileFormWidgets.requiredValidator,
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 16),
                      ProfileFormWidgets.errorMessage(errorMessage!),
                    ],
                    const SizedBox(height: 22),
                    ProfileFormWidgets.submitButton(
                      label: isRegistering
                          ? 'Créer mon compte'
                          : 'Se connecter',
                      isSubmitting: isSubmitting,
                      onPressed: onSubmit,
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
}
