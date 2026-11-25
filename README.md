# Le Forum

Application Flutter connectée à l’API du forum :
`https://4720.s3.nuage-peda.fr/forum/api`.

L’URL peut être remplacée au lancement sans modifier le code :

```powershell
flutter run --dart-define=FORUM_API_BASE_URL=https://serveur.example/forum/api/
```

Les appels HTTP échouent explicitement après 15 secondes. La lecture des
collections s’arrête si une page est répétée ou si elle dépasse 100 pages.

## Données de l’API utilisées

- `Message` : `id`, `titre`, `datePoste`, `contenu`, `user`, `parent`.
- `User` : `id`, `email`, `nom`, `prenom`.

Le fil charge toutes les pages de la collection. Les messages sans parent sont
affichés comme sujets principaux ; leurs réponses sont repliées sous chaque
message et le nombre de réponses directes est indiqué. Un utilisateur connecté
peut répondre aux messages et modifier les siens.

## Connexion

- Connexion : `POST /authentication_token` avec `email` et `password`.
- Inscription : `POST /users` avec `email`, `password`, `nom` et `prenom`,
  suivie d’une connexion.
- Modification du profil : `PATCH /users/{id}` pour `email`, `nom`, `prenom`
  et, facultativement, un nouveau `password`. L’API exige au moins 12
  caractères avec une majuscule, une minuscule, un chiffre et un caractère
  spécial. Le mot de passe n’est pas récupérable en lecture.
- Le JWT est stocké dans le stockage sécurisé de l’appareil et envoyé dans
  l’en-tête `Authorization: Bearer <token>`. Le profil est retrouvé à partir
  des informations d’identité du token et des ressources `User` de l’API.
