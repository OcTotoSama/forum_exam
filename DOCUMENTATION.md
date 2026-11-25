# Documentation du projet Forum

Cette documentation explique les classes, les widgets, les méthodes et les données principales du projet Flutter.

## Architecture générale

Le projet est organisé ainsi :

- `lib/main.dart` : lancement de l'application, navigation et gestion de la session.
- `lib/pages/` : écrans principaux.
- `lib/widgets/` : composants visuels réutilisables.
- `lib/models/` : modèles des utilisateurs et des messages.
- `lib/services/` : accès à l'API, authentification et stockage sécurisé du jeton.
- `lib/theme/` : couleurs et thème graphique.

Le fil de discussion et la page Profil partagent les objets `session` et `userPostCount`. Ainsi, lorsqu'un utilisateur se connecte ou se déconnecte, les deux pages sont mises à jour.

---

## `lib/main.dart`

### `main()`

Point d'entrée de l'application.

- Démarre l'application avec `runApp`.
- Crée le widget racine `ForumApp`.

### `_defaultService`

Service API partagé par défaut.

- `ApiForumService` est utilisé par les pages lorsqu'aucun service n'est injecté.
- Le paramètre `service` permet aux tests d'utiliser une fausse implémentation de `ForumService`.

### `ForumApp`

Widget statique qui configure l'application.

- Définit le titre `Le Forum`.
- Désactive la bannière de debug.
- Applique le thème sombre `AppTheme.dark`.
- Affiche `ForumShell` comme écran principal.
- Injecte le service API dans l'arborescence.

### `ForumApp.build(BuildContext context)`

Construit le widget `MaterialApp`.

`MaterialApp` fournit le thème, les composants Material et l'écran racine.

### `ForumShell`

Widget avec état qui contient les deux pages principales.

- `_selectedPage` vaut `0` pour Accueil et `1` pour Profil.
- `_session` contient l'utilisateur connecté.
- `_userPostCount` contient le nombre de publications de cet utilisateur.

### `_ForumShellState.dispose()`

Libère les deux `ValueNotifier` avant la suppression de l'état.

### `_ForumShellState.build(BuildContext context)`

Construit la structure principale de l'application.

- `Scaffold` fournit le corps et la barre de navigation.
- `SafeArea` évite les zones du système.
- `IndexedStack` garde les pages Accueil et Profil en mémoire.
- `NavigationBar` permet de changer d'onglet.
- `setState` reconstruit l'interface après la sélection d'un onglet.

---

## `lib/pages/forum_home_page.dart`

### `ForumHomePage`

Widget avec état qui affiche le fil de discussion.

Ses paramètres sont :

- `service` : accès aux messages et à l'API.
- `session` : utilisateur actuellement connecté.
- `userPostCount` : compteur partagé avec la page Profil.

### `_ForumHomePageState.initState()`

Exécutée à la création de la page.

- S'abonne aux changements de `session`.
- Lance le chargement des messages.

### `didUpdateWidget`

Exécutée si les paramètres du widget sont remplacés.

- Déplace l'écouteur si un autre `ValueNotifier` de session est fourni.
- Actualise le nombre de publications.

### `dispose()`

Désabonne la page des changements de session.

### `_onSessionChanged()`

Réagit à une connexion ou déconnexion.

- Actualise le compteur des publications.
- Reconstruit l'interface avec `setState`.

### `_loadMessages()`

Charge les messages depuis l'API.

- Active l'état de chargement.
- Supprime l'ancien message d'erreur.
- Récupère la liste avec `widget.service.getMessages()`.
- Trie ou transforme les données dans le service API.
- Met à jour `_posts`.
- Affiche une erreur si la requête échoue.
- Actualise le compteur de l'utilisateur.

Cette méthode est utilisée par :

- le chargement initial ;
- le bouton Actualiser ;
- le geste de rafraîchissement ;
- le bouton Réessayer ;
- l'ajout ou la modification d'un message.

### `_updateUserPostCount()`

Compte les publications racines appartenant à l'utilisateur connecté.

- Retourne `null` si aucun utilisateur n'est connecté.
- Ignore les réponses en vérifiant `parentId == null`.
- Met à jour `userPostCount.value`.

### `_repliesByParent`

Getter qui construit une association `identifiant du parent -> liste des réponses`.

Il permet d'afficher rapidement les réponses sous chaque message.

### `_rootPosts`

Getter qui retourne seulement les messages sans parent.

Ces messages sont placés au premier niveau du fil.

### `build(BuildContext context)`

Construit toute la page du forum.

Widgets principaux :

- `RefreshIndicator` : active le rafraîchissement par glissement.
- `CustomScrollView` : rend la page défilante.
- `SliverToBoxAdapter` : contient l'en-tête et le titre.
- `SliverFillRemaining` : affiche le chargement, l'erreur ou une liste vide.
- `SliverList.builder` : construit les publications une par une.

### `_buildMessageTree(...)`

Construit récursivement un message et ses réponses.

Paramètres :

- `post` : message actuel.
- `depth` : profondeur dans l'arborescence.
- `ancestors` : identifiants déjà parcourus pour éviter une boucle.
- `repliesByParent` : index des réponses.

Comportement :

- Ignore un message déjà rencontré pour éviter une relation cyclique.
- Affiche une `PostCard`.
- Ouvre ou ferme les réponses au tap.
- Affiche les réponses dans un `Container` avec rail vertical.
- Permet la modification seulement si le message appartient à l'utilisateur connecté.

### `_openMessageEditor(...)`

Ouvre une boîte de dialogue pour répondre ou modifier.

- Bloque un nouvel envoi si une soumission est déjà en cours.
- Vérifie que l'utilisateur est connecté.
- Vérifie qu'il peut modifier son propre message.
- Crée les contrôleurs du titre et du contenu.
- Affiche un `AlertDialog` via `showDialog`.
- Valide que le contenu n'est pas vide.
- Envoie une réponse avec `createReply`.
- Modifie un message avec `updateMessage`.
- Recharge les messages.
- Affiche un `SnackBar` de confirmation ou d'erreur.
- Libère les contrôleurs.

### `_buildTopBar()`

Construit l'en-tête du forum.

- Affiche une icône de forum.
- Affiche le titre `Le Forum`.
- Affiche la description.
- Contient le bouton d'actualisation.

### `_buildSectionTitle()`

Construit le titre `Le fil de discussion`.

- Affiche la description du fil.
- Affiche le nombre total de messages chargés.

### `_buildError()`

Construit l'écran complet affiché lorsqu'un premier chargement échoue.

Contient :

- une icône d'erreur ;
- un texte explicatif ;
- le détail de l'erreur ;
- un bouton `Réessayer`.

### `_buildInlineError()`

Construit l'avertissement affiché lors d'un rafraîchissement échoué.

Contrairement à `_buildError`, il conserve les anciens messages déjà chargés.

### `_MessageDraft`

Classe privée qui contient temporairement les données saisies dans le dialogue.

- `title` : titre du message.
- `content` : contenu du message ou de la réponse.

---

## `lib/pages/profile_page.dart`

### `ProfilePage`

Widget avec état qui gère la connexion, l'inscription et le profil.

### `_ProfilePageState.initState()`

Restaure la session enregistrée dès l'ouverture de la page.

### `dispose()`

Libère les contrôleurs de texte et le contrôleur de défilement.

### `_restoreSession()`

Demande au service de restaurer la session.

- Lit le jeton enregistré.
- Charge le profil correspondant.
- Met `_user` à jour.
- Partage l'utilisateur avec `widget.session`.
- Affiche une erreur si la restauration échoue.

### `build(BuildContext context)`

Choisit l'affichage selon l'état :

- chargement de session ;
- formulaire de connexion ou d'inscription ;
- formulaire de modification ;
- profil connecté.

`SingleChildScrollView` permet de faire défiler tous les formulaires.

### `_buildAuthForm()`

Construit l'écran non connecté.

- Affiche l'en-tête du profil.
- Affiche le sélecteur `Connexion / Inscription`.
- Affiche les champs du formulaire.
- Affiche les erreurs éventuelles.
- Affiche le bouton de validation.

### `_requiredValidator`

Vérifie qu'un champ obligatoire n'est ni nul ni composé uniquement d'espaces.

### `_emailValidator`

Vérifie qu'une adresse contient approximativement la forme `texte@texte.texte`.

### `_newPasswordValidator`

Valide un nouveau mot de passe.

- La valeur est facultative lors d'une modification de profil.
- Sinon, elle doit contenir au moins 12 caractères.
- Elle doit contenir une majuscule, une minuscule, un chiffre et un caractère spécial.

### `_confirmPasswordValidator`

Compare la confirmation au mot de passe saisi.

### `_buildNameField(...)`

Construit un champ Nom ou Prénom avec son libellé, son icône et sa validation.

### `_buildEmailField()`

Construit le champ Adresse e-mail avec validation.

### `_buildPasswordVisibilityToggle()`

Construit l'icône permettant d'afficher ou masquer le mot de passe.

### `_buildSubmitButton(...)`

Construit le bouton principal des formulaires.

- Désactivé pendant l'envoi.
- Affiche un `CircularProgressIndicator` pendant l'action.

### `_buildModeButton(...)`

Construit un bouton du sélecteur Connexion / Inscription.

- Enregistre le mode choisi.
- Efface le message d'erreur.
- Réinitialise l'état du formulaire.

### `_buildFieldLabel(...)`

Construit un libellé visuel placé au-dessus d'un champ.

### `_inputDecoration(...)`

Construit la décoration commune des champs.

- Texte d'indice.
- Icône à gauche.
- Espacement uniforme.

### `_buildErrorMessage(...)`

Affiche un message d'erreur dans un bloc rouge foncé.

### `_submitForm()`

Valide puis soumet le formulaire d'authentification.

- Appelle `signUp` en mode Inscription.
- Appelle `signIn` en mode Connexion.
- Affiche le chargement.
- Enregistre l'utilisateur dans `_user`.
- Partage l'utilisateur dans `widget.session`.
- Efface le mot de passe.
- Revient en haut de la page.
- Affiche l'erreur en cas d'échec.

### `_buildConnectedProfile(...)`

Construit l'écran visible lorsqu'une session est active.

Il affiche :

- la carte du compte ;
- l'avatar formé par l'initiale ;
- le nom complet ;
- le bouton des paramètres ;
- les compteurs ;
- l'adresse e-mail ;
- le bouton de déconnexion ;
- les erreurs éventuelles.

### `_buildProfileStat(...)`

Construit un compteur horizontal du profil : valeur + libellé.

### `_buildProfileStatDivider()`

Construit une fine ligne verticale entre les compteurs.

### `_scrollToTop()`

Déplace le défilement au début après un changement d'écran.

Elle attend le prochain rendu avec `addPostFrameCallback`.

### `_openProfileSettings(...)`

Prépare le formulaire de modification.

- Remplit les noms et l'adresse e-mail.
- Efface les champs de mot de passe.
- Active `_isEditingProfile`.

### `_buildEditProfileForm()`

Construit le formulaire de modification du profil.

Il contient :

- les champs Nom ;
- les champs Prénom ;
- le champ Adresse e-mail ;
- le nouveau mot de passe facultatif ;
- la confirmation du mot de passe ;
- les boutons Enregistrer et Annuler.

### `_submitProfileChanges()`

Envoie les informations modifiées.

- Valide le formulaire.
- Appelle `updateUser`.
- Transmet `null` si aucun nouveau mot de passe n'a été demandé.
- Met à jour `_user`.
- Ferme le formulaire de modification.
- Partage le nouvel utilisateur.
- Affiche une erreur en cas d'échec.

### `_signOut()`

Déconnecte l'utilisateur.

- Appelle `signOut`.
- Vide `_user`.
- Réinitialise le mode du formulaire.
- Réinitialise la session partagée.
- Revient en haut de la page.

---

## `lib/widgets/post_card.dart`

### `PostCard`

Widget statique représentant une publication ou une réponse.

Propriétés :

- `post` : données du message.
- `replyCount` : nombre de réponses.
- `isExpanded` : indique si les réponses sont ouvertes.
- `onTap` : ouvre ou ferme les réponses.
- `onReply` : ouvre le formulaire de réponse.
- `isReply` : adapte l'apparence pour une réponse imbriquée.
- `onEdit` : ouvre la modification lorsqu'elle est autorisée.

### `build`

Construit la carte.

- `Material` fournit le fond Material.
- `InkWell` reçoit le toucher.
- `Ink` applique les couleurs, les bordures et les marges.
- `Container` entoure l'avatar.
- `CircleAvatar` affiche les initiales.
- `Text` affiche l'auteur, la date, le titre et le contenu.
- `IconButton` permet la modification.
- `Divider` sépare le contenu des actions.
- `TextButton.icon` ouvre les réponses ou publie une réponse.

---

## `lib/models/forum_post.dart`

### `ForumPost`

Modèle immuable représentant un message.

Champs :

- `id` : identifiant du message.
- `author` : nom affiché.
- `initials` : initiales de l'auteur.
- `datePosted` : date de publication.
- `title` : titre facultatif.
- `body` : contenu du message.
- `avatarColor` : couleur stable de l'avatar.
- `parentId` : identifiant du message parent.
- `userId` : identifiant de l'auteur.

### `time`

Getter qui transforme la date en texte court.

- `à l'instant`
- `il y a X min`
- `il y a X h`
- `il y a X j`
- `jj/mm/aaaa` pour les anciens messages

### `ForumPost.fromJson`

Fabrique un `ForumPost` à partir du JSON de l'API.

- Lit l'auteur.
- Calcule les initiales.
- Lit la date.
- Lit le titre et le contenu.
- Détermine l'identifiant du parent.
- Choisit une couleur d'avatar.

### `_relationId`

Convertit une relation parent sous forme d'objet JSON, d'IRI ou d'entier.

---

## `lib/models/forum_user.dart`

### `ForumUser`

Modèle immuable représentant un utilisateur.

Champs :

- `id` : identifiant facultatif.
- `email` : adresse e-mail.
- `nom` : nom de famille.
- `prenom` : prénom.

### `displayName`

Getter qui assemble le prénom et le nom.

### `ForumUser.fromJson`

Fabrique un utilisateur à partir du JSON.

- Lit `id` ou `@id`.
- Lit l'e-mail, le nom et le prénom.

---

## `lib/models/api_resource_id.dart`

### `parseApiResourceId`

Convertit un identifiant provenant de l'API en `int`.

Les formats acceptés sont notamment :

- entier ;
- chaîne contenant un identifiant ;
- IRI du type `/api/users/12` ;
- chaîne ou objet Hydra contenant `@id`.

Cette fonction évite les erreurs lors de l'exploitation des relations API.

---

## `lib/services/forum_service.dart`

### `ForumService`

Interface commune aux implémentations du service du forum.

Elle définit les opérations suivantes :

- `getMessages()` : récupère toutes les publications.
- `createReply()` : publie une réponse.
- `updateMessage()` : modifie un message.
- `restoreSession()` : restaure la session locale.
- `signIn()` : authentifie un utilisateur.
- `signUp()` : crée un compte.
- `updateUser()` : modifie le profil.
- `signOut()` : ferme la session locale.

---

## `lib/services/api_forum_service.dart`

### `ApiForumService`

Implémentation réelle de `ForumService` utilisant HTTP.

L'adresse de base peut être remplacée par `FORUM_API_BASE_URL`. Par défaut, elle utilise l'API du forum hébergée.

### `getMessages`

- Parcourt toutes les pages `/messages`.
- Limite la pagination à 100 pages.
- Détecte les boucles de pagination.
- Convertit les objets JSON en `ForumPost`.
- Trie les messages du plus récent au plus ancien.

### `createReply`

- Vérifie que l'utilisateur possède un jeton.
- Charge son profil.
- Vérifie son identifiant.
- Envoie une réponse au serveur avec le parent sélectionné.

### `updateMessage`

- Vérifie le jeton.
- Charge l'utilisateur connecté.
- Vérifie que le message appartient à cet utilisateur.
- Envoie une requête PATCH pour modifier le titre et le contenu.

### `restoreSession`

Lit le jeton du stockage sécurisé, puis charge le profil correspondant.

### `_requireToken`

Retourne le jeton local ou provoque une exception demandant une connexion.

### `signIn`

- Appelle `/authentication_token`.
- Récupère le JWT.
- Charge le profil associé.
- Enregistre le jeton uniquement après succès.

### `signUp`

- Crée un utilisateur via `/users`.
- Effectue ensuite une authentification.
- Retourne le profil connecté.

### `updateUser`

Met à jour les informations du compte.

- Vérifie le jeton.
- Modifie l'e-mail, le nom et le prénom.
- Ajoute le nouveau mot de passe seulement lorsqu'il est fourni.

### `signOut`

Supprime le jeton enregistré localement.

### `_loadCurrentUser`

Charge l'utilisateur correspondant à un jeton.

- Décode les claims JWT.
- Cherche l'utilisateur dans `/users`.
- Recherche éventuellement par adresse e-mail.
- Retourne un objet `ForumUser`.

### `_get`

Effectue une requête HTTP GET avec le bon jeton lorsque celui-ci est fourni.

### `_send`

Exécute une requête avec les protections suivantes :

- expiration après 15 secondes ;
- vérification du statut HTTP ;
- conversion du JSON ;
- limitation des erreurs réseau.

### `_resolveApiUri`

Transforme un lien relatif ou absolu de l'API en URI sûr.

### `_validateApiUri`

Vérifie que l'URI reste sur le serveur API autorisé.

Cette vérification réduit les risques de redirection vers un serveur externe.

### `_trackPage`

Contrôle la pagination.

- Détecte une page déjà visitée.
- Détecte une boucle.
- Bloque au-delà de 100 pages.

### `_decodeJson`

Décode le corps JSON d'une réponse.

- Déclenche une exception API si le JSON est invalide.
- Déclenche une exception API si le statut HTTP est supérieur ou égal à 400.

### `_tokenClaims`

Décode la partie centrale d'un JWT encodé en Base64.

### `_intClaim`

Recherche un identifiant numérique dans plusieurs clés possibles du JWT.

### `_stringClaim`

Recherche une chaîne dans plusieurs clés possibles du JWT.

### `ForumApiException`

Exception spécifique utilisée pour expliquer les erreurs API à l'utilisateur.

- Conserve un message lisible.
- Hérite de `Exception`.
- Son `toString()` renvoie directement le message.

---

## `lib/services/token_store.dart`

### `TokenStore`

Interface du stockage des jetons.

- `read()` : lit le jeton.
- `write()` : écrit le jeton.
- `clear()` : efface le jeton.

### `SecureTokenStore`

Implémentation utilisant `flutter_secure_storage`.

Le jeton est enregistré sous la clé `forum_access_token`.

Les méthodes utilisent directement le stockage chiffré du système :

- `read` pour restaurer la session ;
- `write` pour enregistrer le jeton ;
- `clear` pour déconnecter.

---

## Widgets Flutter utilisés fréquemment

| Widget | Rôle |
|---|---|
| `MaterialApp` | Configure l'application et son thème |
| `Scaffold` | Structure principale avec barre de navigation |
| `SafeArea` | Évite les zones système |
| `IndexedStack` | Affiche une page tout en conservant les autres |
| `NavigationBar` | Barre de navigation principale |
| `SingleChildScrollView` | Rend une page défilante |
| `RefreshIndicator` | Permet le rafraîchissement par glissement |
| `CustomScrollView` | Assemble une page à partir de slivers |
| `SliverList.builder` | Construit une liste optimisée |
| `Column` | Place les éléments verticalement |
| `Row` | Place les éléments horizontalement |
| `Container` | Donne une décoration ou une marge |
| `Padding` | Ajoute une marge intérieure |
| `SizedBox` | Définit une taille ou un espace |
| `Expanded` | Occupe l'espace restant dans une ligne ou une colonne |
| `Text` | Affiche du texte |
| `TextFormField` | Champ de formulaire avec validation |
| `TextButton` | Bouton simple |
| `FilledButton` | Bouton principal plein |
| `OutlinedButton` | Bouton secondaire avec bordure |
| `IconButton` | Bouton représenté par une icône |
| `Icon` | Affiche une icône |
| `CircleAvatar` | Affiche une initiale dans un cercle |
| `Divider` | Trace une séparation |
| `CircularProgressIndicator` | Affiche un chargement |
| `Form` | Regroupe les champs et leurs validateurs |
| `AlertDialog` | Affiche une fenêtre de saisie |
| `SnackBar` | Affiche une notification temporaire |
| `ValueListenableBuilder` | Reconstruit une partie de l'interface après changement |
