import 'package:flutter/material.dart';

import 'models/forum_user.dart';
import 'pages/forum_home_page.dart';
import 'pages/profile_page.dart';
import 'services/api_forum_service.dart';
import 'services/forum_service.dart';
import 'theme/app_theme.dart';

/// Point d’entrée : démarre l’arbre de widgets de l’application.
void main() {
  runApp(const ForumApp());
}

// Service partagé par défaut ; les tests peuvent injecter une implémentation factice.
final _defaultService = ApiForumService();

/// Configure le thème de l’application et injecte le service du forum.
class ForumApp extends StatelessWidget {
  const ForumApp({super.key, this.service});

  final ForumService? service;

  @override
  Widget build(BuildContext context) {
    // MaterialApp fournit le thème, la navigation de base et l’écran racine de l’application.
    return MaterialApp(
      title: 'Le Forum',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: ForumShell(service: service ?? _defaultService),
    );
  }
}

/// Affiche les deux sections et conserve l’état de chaque onglet.
class ForumShell extends StatefulWidget {
  const ForumShell({super.key, required this.service});

  final ForumService service;

  @override
  State<ForumShell> createState() => _ForumShellState();
}

class _ForumShellState extends State<ForumShell> {
  // L’index correspond aux destinations Accueil et Profil de la barre du bas.
  int _selectedPage = 0;

  // ValueNotifier permet au profil et au fil de partager l’utilisateur connecté.
  final _session = ValueNotifier<ForumUser?>(null);
  // Le fil calcule le nombre de publications et le profil l’affiche en direct.
  final _userPostCount = ValueNotifier<int?>(null);

  @override
  void dispose() {
    _session.dispose();
    _userPostCount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold crée la structure principale de l’écran avec son contenu et sa barre de navigation.
    return Scaffold(
      // SafeArea évite les zones système ; IndexedStack garde les deux onglets
      // montés, sans perdre leur état lorsque l’utilisateur change de section.
      body: SafeArea(
        // IndexedStack affiche uniquement la page sélectionnée tout en conservant les deux états.
        child: IndexedStack(
          index: _selectedPage,
          children: [
            // ForumHomePage affiche le fil du forum et gère les publications de l’utilisateur.
            ForumHomePage(
              service: widget.service,
              session: _session,
              userPostCount: _userPostCount,
            ),
            // ProfilePage affiche les informations du profil et permet de modifier la session.
            ProfilePage(
              service: widget.service,
              session: _session,
              userPostCount: _userPostCount,
            ),
          ],
        ),
      ),
      // Container ajoute un fond et une bordure autour de la barre de navigation.
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        // NavigationBar permet de passer entre les pages Accueil et Profil.
        child: NavigationBar(
          height: 72,
          selectedIndex: _selectedPage,
          onDestinationSelected: (index) {
            setState(() => _selectedPage = index);
          },
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          indicatorColor: AppColors.indicator,
          indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            // NavigationDestination représente l’onglet Accueil dans la barre du bas.
            NavigationDestination(
              // Icon affiche une icône en forme de maison lorsque l’accueil n’est pas sélectionné.
              icon: Icon(Icons.home_outlined),
              // Icon affiche une icône de maison pleine lorsque l’accueil est sélectionné.
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Accueil',
            ),
            // NavigationDestination représente l’onglet Profil dans la barre du bas.
            NavigationDestination(
              // Icon affiche une icône de personne lorsque le profil n’est pas sélectionné.
              icon: Icon(Icons.person_outline_rounded),
              // Icon affiche une icône de personne pleine lorsque le profil est sélectionné.
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
