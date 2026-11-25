import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'profile_form_widgets.dart';

/// Affiche le formulaire de modification du profil.
class ProfileEditForm extends StatelessWidget {
  const ProfileEditForm({
    super.key,
    required this.formKey,
    required this.obscurePassword,
    required this.isSubmitting,
    required this.errorMessage,
    required this.lastNameController,
    required this.firstNameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.onTogglePasswordVisibility,
    required this.onSubmit,
    required this.onCancel,
  });

  final GlobalKey<FormState> formKey;
  final bool obscurePassword;
  final bool isSubmitting;
  final String? errorMessage;
  final TextEditingController lastNameController;
  final TextEditingController firstNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
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
        Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              ProfileFormWidgets.emailField(emailController),
              const SizedBox(height: 24),
              ProfileFormWidgets.fieldLabel(
                'Nouveau mot de passe (facultatif)',
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: passwordController,
                obscureText: obscurePassword,
                autocorrect: false,
                enableSuggestions: false,
                decoration:
                    ProfileFormWidgets.inputDecoration(
                      hint: 'Laisser vide pour ne pas le modifier',
                      icon: Icons.lock_outline_rounded,
                    ).copyWith(
                      helperText:
                          '12 caractères minimum, avec majuscule, minuscule, '
                          'chiffre et caractère spécial.',
                      suffixIcon: ProfileFormWidgets.passwordVisibilityToggle(
                        obscurePassword: obscurePassword,
                        onPressed: onTogglePasswordVisibility,
                      ),
                    ),
                validator: ProfileFormWidgets.newPasswordValidator,
              ),
              const SizedBox(height: 18),
              ProfileFormWidgets.fieldLabel(
                'Confirmer le nouveau mot de passe',
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                decoration: ProfileFormWidgets.inputDecoration(
                  hint: 'Répétez le nouveau mot de passe',
                  icon: Icons.lock_outline_rounded,
                ),
                validator: (value) =>
                    ProfileFormWidgets.confirmPasswordValidator(
                      passwordController,
                      value,
                    ),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 16),
                ProfileFormWidgets.errorMessage(errorMessage!),
              ],
              const SizedBox(height: 22),
              ProfileFormWidgets.submitButton(
                label: 'Enregistrer',
                isSubmitting: isSubmitting,
                onPressed: onSubmit,
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: TextButton(
                  onPressed: isSubmitting ? null : onCancel,
                  child: const Text('Annuler'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
