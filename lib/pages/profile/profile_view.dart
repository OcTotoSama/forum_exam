import 'package:flutter/material.dart';

import '../../models/forum_user.dart';
import '../../theme/app_theme.dart';
import 'profile_form_widgets.dart';

/// Affiche les informations du compte connecté.
class ProfileView extends StatelessWidget {
  const ProfileView({
    super.key,
    required this.user,
    required this.userPostCount,
    required this.isSubmitting,
    required this.errorMessage,
    required this.onOpenSettings,
    required this.onSignOut,
  });

  final ForumUser user;
  final ValueNotifier<int?> userPostCount;
  final bool isSubmitting;
  final String? errorMessage;
  final ValueChanged<ForumUser> onOpenSettings;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final initial = user.prenom.isNotEmpty
        ? user.prenom[0].toUpperCase()
        : user.nom.isNotEmpty
        ? user.nom[0].toUpperCase()
        : '?';

    return Column(
      children: [
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
              Row(
                children: [
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
                  IconButton(
                    tooltip: 'Paramètres du profil',
                    onPressed: isSubmitting ? null : () => onOpenSettings(user),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      foregroundColor: AppColors.ink,
                    ),
                    icon: const Icon(Icons.settings_outlined, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 20),
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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: ValueListenableBuilder<int?>(
            valueListenable: userPostCount,
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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
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
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: isSubmitting ? null : onSignOut,
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
        if (errorMessage != null) ...[
          const SizedBox(height: 14),
          ProfileFormWidgets.errorMessage(errorMessage!),
        ],
      ],
    );
  }

  /// Affiche une valeur et son libellé dans les statistiques.
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

  /// Sépare les compteurs du profil.
  Widget _buildProfileStatDivider() {
    return Container(width: 1, height: 30, color: AppColors.border);
  }
}
