Use Cases Détaillés - Services Auth & Subscription
SERVICE 1 : AUTHENTICATION SERVICE (Port 3001)
UC-AUTH-1.1 : Création de Compte Multi-Provider
Acteur Principal : Utilisateur Non Authentifié
Acteurs Secondaires : Google OAuth, Apple Sign In, Email SMTP Service
Préconditions :

L'application est enregistrée dans applications table
API key valide
Providers OAuth configurés (credentials valides)
Network disponible

Flux Principal :

User → Lance l'application pour la première fois
App → Affiche écran d'accueil :

Bienvenue dans Quiz Geography

[Continuer avec Apple]      🍎
[Continuer avec Google]     🔵
[Continuer avec Email]      ✉️
[Jouer en tant qu'invité]   👤

En continuant, vous acceptez nos
[Conditions] et [Politique de confidentialité]

User → Sélectionne "Continuer avec Google"
App → Initie Google Sign-In flow :

dart   final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;
final idToken = googleAuth.idToken;

Google → Affiche écran de sélection compte
User → Sélectionne compte Google
Google → Retourne id_token et profil (email, name, photo)
App → POST /auth/v1/auth/register

json   {
"provider": "google",
"credentials": {
"google_id_token": "eyJhbGciOiJSUzI1NiIs..."
},
"device_info": {
"device_id": "uuid-device",
"platform": "ios",
"app_version": "1.0.0",
"os_version": "17.2"
}
}

Auth Service → Valide headers (X-App-ID, X-API-Key)
Auth Service → Valide google_id_token :

10a. Appel Google API : https://oauth2.googleapis.com/tokeninfo?id_token=...
10b. Google retourne payload :



json      {
"sub": "google_user_id_123",
"email": "user@gmail.com",
"email_verified": true,
"name": "John Doe",
"picture": "https://..."
}
- 10c. Vérifie signature JWT valide
- 10d. Vérifie `aud` (audience) = client_id de l'app
- 10e. Vérifie `exp` (expiration) non dépassée
11. Auth Service → Extrait google_id = "google_user_id_123"
12. Auth Service → Vérifie si google_id existe déjà :
    sql    SELECT * FROM users
    WHERE app_id = ? AND google_id = ?

Auth Service → Si existe → UC-AUTH-1.2 (Login)
Auth Service → Si n'existe pas → Crée utilisateur :

sql    INSERT INTO users (
id, app_id, email, email_verified,
google_id, auth_provider, status,
created_at, updated_at
) VALUES (
uuid_generate_v4(), ?, ?, true,
?, 'google', 'free',
NOW(), NOW()
)

Auth Service → Crée entrée oauth_connections :

sql    INSERT INTO oauth_connections (
id, user_id, provider, provider_user_id,
access_token, profile_data, connected_at
) VALUES (
uuid_generate_v4(), ?, 'google', ?,
encrypt(?), ?::jsonb, NOW()
)

Auth Service → Crée privacy_settings par défaut :

sql    INSERT INTO privacy_settings (
id, user_id,
consent_analytics, consent_third_party,
consent_geolocation, consent_personalized_ads,
updated_at
) VALUES (
uuid_generate_v4(), ?,
false, false, false, false,
NOW()
)

Auth Service → Génère JWT tokens :

typescript    const accessTokenPayload = {
user_id: user.id,
app_id: user.app_id,
email: user.email,
status: user.status,
exp: Math.floor(Date.now() / 1000) + (7 * 24 * 60 * 60) // 7 days
};

    const accessToken = jwt.sign(accessTokenPayload, JWT_SECRET);
    
    const refreshTokenPayload = {
      user_id: user.id,
      app_id: user.app_id,
      type: 'refresh',
      exp: Math.floor(Date.now() / 1000) + (30 * 24 * 60 * 60) // 30 days
    };
    
    const refreshToken = jwt.sign(refreshTokenPayload, JWT_REFRESH_SECRET);

Auth Service → Stocke refresh token :

sql    INSERT INTO refresh_tokens (
id, user_id, token_hash, device_info, expires_at, revoked
) VALUES (
uuid_generate_v4(), ?, sha256(?), ?::jsonb, NOW() + INTERVAL '30 days', false
)

Auth Service → Crée audit log :

sql    INSERT INTO audit_logs (
id, user_id, app_id, action, ip_address,
user_agent, result, details, timestamp
) VALUES (
uuid_generate_v4(), ?, ?, 'register', ?, ?,
'success', ?::jsonb, NOW()
)

Auth Service → Retourne response 201 :

json    {
"user": {
"id": "uuid-user",
"email": "user@gmail.com",
"provider": "google",
"status": "free",
"created_at": "2025-11-23T16:00:00Z"
},
"tokens": {
"access_token": "eyJhbGciOiJIUzI1NiIs...",
"refresh_token": "eyJhbGciOiJIUzI1NiIs...",
"expires_in": 604800,
"token_type": "Bearer"
}
}
```
21. **App** → Stocke tokens localement (Keychain iOS / Keystore Android)
22. **App** → Stocke user data dans state management
23. **App** → Envoie analytics event : "user_registered"
24. **App** → Redirige vers écran principal

**Flux Alternatifs** :

**3a. User choisit "Continuer avec Apple"**
```
3a.1. App initie Apple Sign In :
let appleIDProvider = ASAuthorizationAppleIDProvider()
let request = appleIDProvider.createRequest()
request.requestedScopes = [.fullName, .email]

3a.2. Apple affiche écran authentification
3a.3. User authentifie (Face ID / Touch ID)
3a.4. Apple retourne :
- authorization_code
- identity_token
- user (firstName, lastName, email) [première fois seulement]

3a.5. App POST /auth/register avec :
{
"provider": "apple",
"credentials": {
"apple_authorization_code": "...",
"apple_identity_token": "...",
"user_info": {
"first_name": "John",
"last_name": "Doe",
"email": "user@privaterelay.appleid.com"
}
}
}

3a.6. Auth Service :
- Valide identity_token avec Apple
- Extrait apple_id (sub claim du JWT)
- Vérifie signature avec Apple public keys
- Crée user avec apple_id

3a.7. Continue flux principal étape 14
```

**3b. User choisit "Continuer avec Email"**
```
3b.1. App affiche formulaire :
Email: [_______________]
Mot de passe: [_______________]
Confirmer mot de passe: [_______________]
[Créer mon compte]

3b.2. User remplit formulaire
3b.3. App valide côté client :
- Email format valide (regex)
- Password >= 8 caractères
- Password contient 1 majuscule, 1 chiffre
- Passwords match

3b.4. App POST /auth/register avec :
{
"provider": "email",
"credentials": {
"email": "user@example.com",
"password": "SecurePass123"
}
}

3b.5. Auth Service valide côté serveur :
- Email unique (pas déjà utilisé)
- Password strength (zxcvbn score >= 3)

3b.6. Auth Service hash password :
const salt = await bcrypt.genSalt(12);
const hash = await bcrypt.hash(password, salt);

3b.7. Auth Service crée user avec :
- email
- password_hash
- email_verified = false

3b.8. Auth Service génère email verification token :
const token = crypto.randomBytes(32).toString('hex');
INSERT INTO email_verification_tokens (
user_id, token, expires_at
) VALUES (?, ?, NOW() + INTERVAL '24 hours')

3b.9. Auth Service envoie email vérification :
To: user@example.com
Subject: Vérifiez votre email
Body:
Cliquez ici pour vérifier votre compte :
https://app.example.com/verify-email?token=...

3b.10. Auth Service retourne response (tokens inclus)
3b.11. App affiche banner :
"Email de vérification envoyé"
"Consultez votre boîte mail"

3b.12. User peut utiliser l'app mais :
- Badge "Email non vérifié" affiché
- Certaines fonctions limitées
```

**3c. User choisit "Jouer en tant qu'invité"**
```
3c.1. App affiche warning :
"Mode Invité - Limitations"
- Pas de sauvegarde cloud
- Pas de Game Center
- Données perdues si app supprimée
[Continuer en invité] [Annuler]

3c.2. User confirme
3c.3. App POST /auth/register avec :
{
"provider": "guest",
"credentials": {
"device_id": "uuid-device"
}
}

3c.4. Auth Service crée user temporaire :
- email = NULL
- password_hash = NULL
- is_guest = true
- guest_expires_at = NOW() + 30 days
- Identifiant unique basé sur device_id

3c.5. Auth Service retourne tokens
3c.6. App affiche banner permanent :
"Mode Invité - Créez un compte pour sauvegarder"
```

**10a. Token Google invalide ou expiré**
```
10a.1. Google API retourne erreur 400
10a.2. Auth Service log erreur
10a.3. Auth Service retourne 401 Unauthorized :
{
"error": "invalid_token",
"message": "Google authentication failed"
}
10a.4. App affiche :
"Échec de connexion avec Google"
"Veuillez réessayer"
10a.5. User peut retry
```

**12a. Google ID déjà utilisé (compte existe)**
```
12a.1. Query retourne user existant
12a.2. Auth Service redirige vers Login flow
12a.3. Continue avec UC-AUTH-1.2 étape 8
```

**14a. Email déjà utilisé par autre provider**
```
14a.1. Auth Service détecte email existe avec autre provider
14a.2. Auth Service retourne 409 Conflict :
{
"error": "email_already_exists",
"message": "Email already registered with Apple",
"existing_provider": "apple",
"can_link": true
}
14a.3. App affiche :
"Email déjà utilisé"
"Vous êtes déjà inscrit avec Apple"
"Souhaitez-vous lier les comptes ?"
[Lier les comptes] [Se connecter] [Annuler]
14a.4. Si "Lier" → UC-AUTH-1.7 (Link accounts)
```

**17a. JWT secret manquant ou invalide**
```
17a.1. Auth Service erreur critique
17a.2. Log erreur + alerte équipe
17a.3. Retourne 500 Internal Server Error
17a.4. App affiche :
"Erreur temporaire du service"
"Veuillez réessayer dans quelques instants"
```

**20a. Database connection échoue**
```
20a.1. Auth Service timeout DB
20a.2. Rollback transaction
20a.3. Retourne 503 Service Unavailable
20a.4. App affiche :
"Service temporairement indisponible"
"Réessayez dans quelques instants"
20a.5. Retry automatique avec exponential backoff
Postconditions :

User créé dans users table
OAuth connection enregistrée (si applicable)
Privacy settings créées avec defaults
JWT tokens générés et stockés
Refresh token enregistré
Audit log créé
Email vérification envoyé (si email provider)
User redirigé vers app principale
Analytics event envoyé

Règles Métier :

Google : email_verified automatique si Google confirme
Apple : peut fournir email relay (privaterelay.appleid.com)
Email : vérification requise mais pas bloquante
Guest : expire après 30 jours d'inactivité
Password strength : minimum zxcvbn score 3
JWT access token : 7 jours validité
JWT refresh token : 30 jours validité
Multi-provider : même email peut être lié à plusieurs providers
Rate limiting : 5 tentatives / 15 minutes par IP


UC-AUTH-1.2 : Connexion Utilisateur
Acteur Principal : Utilisateur avec Compte Existant
Préconditions :

User a un compte créé
User n'est pas connecté (pas de token valide)

Flux Principal :

User → Lance l'application
App → Vérifie si token local existe :

dart   final accessToken = await secureStorage.read(key: 'access_token');

App → Si token existe → Vérifie validité :

dart   final isValid = JwtDecoder.isExpired(accessToken);
```
4. **App** → Si token expiré → Tente refresh (UC-AUTH-1.8)
5. **App** → Si pas de token ou refresh échoue → Affiche écran login :
```
Bon retour !

[Continuer avec Apple]
[Continuer avec Google]
[Se connecter avec Email]
[Mode Invité]

Pas encore de compte ? [Créer un compte]

User → Sélectionne "Continuer avec Google"
App → Initie Google Sign-In
Google → User sélectionne compte
Google → Retourne id_token
App → POST /auth/v1/auth/login

json    {
"provider": "google",
"credentials": {
"google_id_token": "eyJhbGciOiJSUzI1NiIs..."
},
"device_info": {
"device_id": "uuid-device",
"platform": "ios",
"app_version": "1.0.0"
}
}

Auth Service → Valide google_id_token (comme UC-AUTH-1.1 étape 10)
Auth Service → Extrait google_id
Auth Service → Query user :

sql    SELECT u.*, ps.*
FROM users u
LEFT JOIN privacy_settings ps ON u.id = ps.user_id
WHERE u.app_id = ? AND u.google_id = ?

Auth Service → Si user trouvé :

14a. Vérifie status != 'suspended'
14b. Met à jour last_login = NOW()
14c. Génère nouveaux JWT tokens
14d. Révoque ancien refresh token de cet appareil :



sql      UPDATE refresh_tokens
SET revoked = true
WHERE user_id = ? AND device_info->>'device_id' = ?
- 14e. Crée nouveau refresh token
15. Auth Service → Crée audit log :
    sql    INSERT INTO audit_logs (
    user_id, app_id, action, ip_address, result, timestamp
    ) VALUES (?, ?, 'login', ?, 'success', NOW())

Auth Service → Retourne response 200 :

json    {
"user": {
"id": "uuid",
"email": "user@gmail.com",
"provider": "google",
"status": "premium",
"last_login": "2025-11-23T16:30:00Z",
"privacy_settings": {
"consent_analytics": true,
"consent_geolocation": false
}
},
"tokens": {
"access_token": "...",
"refresh_token": "...",
"expires_in": 604800
}
}
```
17. **App** → Stocke tokens
18. **App** → Charge profil user dans state
19. **App** → Sync data si nécessaire (Game Center, offline content)
20. **App** → Redirige vers écran principal

**Flux Alternatifs** :

**3a. Token valide trouvé (auto-login)**
```
3a.1. App détecte token non expiré
3a.2. App decode token pour extraire user_id
3a.3. App skip écran login
3a.4. App charge profil depuis cache local
3a.5. App continue vers écran principal
3a.6. En background :
- Vérifie token serveur (GET /auth/me)
- Si invalide → force re-login
- Si valide → met à jour profil
```

**6a. User sélectionne "Se connecter avec Email"**
```
6a.1. App affiche formulaire :
Email: [_______________]
Mot de passe: [_______________]
[Se connecter]
[Mot de passe oublié ?]

6a.2. User remplit et soumet
6a.3. App POST /auth/login avec :
{
"provider": "email",
"credentials": {
"email": "user@example.com",
"password": "SecurePass123"
}
}

6a.4. Auth Service :
- Query user par email
- Vérifie password avec bcrypt :
const match = await bcrypt.compare(password, user.password_hash);
- Si match → génère tokens
- Si pas match → flux 13a

6a.5. Continue flux principal étape 16
```

**13a. User non trouvé**
```
13a.1. Query retourne null
13a.2. Auth Service retourne 404 Not Found :
{
"error": "user_not_found",
"message": "No account found with this Google ID",
"can_register": true
}
13a.3. App affiche :
"Aucun compte trouvé"
"Souhaitez-vous créer un compte ?"
[Créer un compte] [Annuler]
13a.4. Si "Créer" → Redirige vers UC-AUTH-1.1
```

**13b. Password incorrect (pour email login)**
```
13b.1. bcrypt.compare retourne false
13b.2. Auth Service incrémente login_attempts :
UPDATE users SET login_attempts = login_attempts + 1
WHERE id = ?
13b.3. Si login_attempts >= 5 :
UPDATE users SET locked_until = NOW() + INTERVAL '15 minutes'
WHERE id = ?
13b.4. Auth Service retourne 401 Unauthorized :
{
"error": "invalid_credentials",
"message": "Incorrect email or password",
"attempts_remaining": 2
}
13b.5. App affiche :
"Email ou mot de passe incorrect"
"2 tentatives restantes avant verrouillage"
13b.6. User peut réessayer ou utiliser "Mot de passe oublié"
```

**14a. Compte suspendu**
```
14a.1. Auth Service détecte status = 'suspended'
14a.2. Auth Service retourne 403 Forbidden :
{
"error": "account_suspended",
"message": "Your account has been suspended",
"reason": "Terms of service violation",
"contact": "support@example.com"
}
14a.3. App affiche :
"Compte suspendu"
"Raison : Violation des conditions d'utilisation"
"Contactez support@example.com pour plus d'informations"
[Contacter le support]
```

**14b. Compte verrouillé (trop de tentatives)**
```
14b.1. Auth Service détecte locked_until > NOW()
14b.2. Auth Service calcule temps restant
14b.3. Auth Service retourne 429 Too Many Requests :
{
"error": "account_locked",
"message": "Too many login attempts",
"locked_until": "2025-11-23T16:45:00Z",
"retry_after": 900
}
14b.4. App affiche :
"Compte temporairement verrouillé"
"Trop de tentatives de connexion"
"Réessayez dans 15 minutes"
[Timer countdown]
```

**Postconditions** :
- User authentifié avec nouveaux tokens
- `last_login` mis à jour
- Ancien refresh token révoqué
- Nouveau refresh token créé
- Audit log créé
- Profil chargé dans app
- Session active

**Règles Métier** :
- Auto-login si token valide < 7 jours
- Max 5 tentatives login / 15 minutes
- Verrouillage compte : 15 minutes après 5 échecs
- Tokens refresh automatiquement si proche expiration
- Un seul refresh token actif par appareil
- Login_attempts reset après login réussi
- Suspended accounts = login bloqué définitivement

---

### UC-AUTH-1.3 : Synchronisation Game Center

**Acteur Principal** : Utilisateur Authentifié (iOS)

**Préconditions** :
- User authentifié dans l'app
- Game Center disponible sur appareil
- iOS >= 14.0
- User connecté à Game Center

**Flux Principal** :
1. **User** → Ouvre "Paramètres" → "Game Center"
2. **App** → Affiche écran :
```
Synchronisation Game Center

Statut: Non lié

Avantages:
✓ Sauvegarde de vos scores
✓ Classements mondiaux
✓ Achievements synchronisés
✓ Jouer sur plusieurs appareils

[Lier Game Center]

User → Clique "Lier Game Center"
App → Vérifie disponibilité Game Center :

swift   import GameKit

GKLocalPlayer.local.authenticateHandler = { viewController, error in
if let vc = viewController {
// Présenter écran auth GC
present(vc, animated: true)
} else if GKLocalPlayer.local.isAuthenticated {
// User authentifié
} else {
// Erreur ou pas connecté
}
}

Game Center → Si pas authentifié, affiche popup Apple
User → Authentifie avec Apple ID (si nécessaire)
Game Center → Retourne player info :

swift   let player = GKLocalPlayer.local
let playerId = player.gamePlayerID // Unique ID
let alias = player.alias // Display name

App → Génère preuve d'authentification :

swift   player.generateIdentityVerificationSignature {
publicKeyUrl, signature, salt, timestamp, error in
// Ces données prouvent que le player est authentique
}

App → POST /auth/v1/auth/game-center/link

json   {
"player_id": "G:1234567890",
"alias": "ProGamer2025",
"public_key_url": "https://...",
"signature": "base64...",
"salt": "base64...",
"timestamp": 1700000000
}
```
10. **Auth Service** → Valide signature :
    - 10a. Download public key from `public_key_url`
    - 10b. Reconstruit payload :
```
      player_id + bundle_id + timestamp + salt
- 10c. Vérifie signature avec clé publique Apple
- 10d. Vérifie timestamp < 5 minutes
11. Auth Service → Vérifie player_id unique :
    sql    SELECT user_id FROM game_center_connections
    WHERE player_id = ?

Auth Service → Si player_id déjà lié à autre user → Erreur 409
Auth Service → Si OK, crée connexion :

sql    INSERT INTO game_center_connections (
id, user_id, player_id, alias, linked_at, last_sync
) VALUES (
uuid_generate_v4(), ?, ?, ?, NOW(), NOW()
)

Auth Service → Sync données initiales :

14a. Query achievements user depuis app DB
14b. Report à Game Center via API
14c. Query leaderboard scores
14d. Met à jour Game Center si local > GC


Auth Service → Retourne :

json    {
"linked": true,
"player_id": "G:1234567890",
"alias": "ProGamer2025",
"synced": {
"achievements": 5,
"leaderboard_score": 1250
}
}
```
16. **App** → Affiche confirmation :
    "✓ Game Center lié avec succès"
    "ProGamer2025"
    "5 achievements synchronisés"
17. **App** → Met à jour UI (badge "GC" actif)

**Flux Alternatifs** :

**4a. Game Center non disponible**
```
4a.1. App détecte GKLocalPlayer.local.isAuthenticated = false
4a.2. App affiche :
"Game Center non disponible"
"Connectez-vous à Game Center dans Réglages iOS"
[Ouvrir Réglages]
4a.3. Si "Ouvrir Réglages" :
UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString))
```

**10a. Signature invalide**
```
10a.1. Vérification signature échoue
10a.2. Auth Service retourne 401 Unauthorized :
{
"error": "invalid_signature",
"message": "Game Center authentication failed"
}
10a.3. App affiche :
"Échec de vérification Game Center"
"Veuillez réessayer"
10a.4. User peut retry
```

**12a. Player ID déjà lié à autre compte**
```
12a.1. Query retourne user_id différent
12a.2. Auth Service retourne 409 Conflict :
{
"error": "player_id_already_linked",
"message": "This Game Center account is already linked to another user",
"linked_user_email": "oth***@example.com",
"can_unlink": true
}
12a.3. App affiche :
"Game Center déjà lié"
"Ce compte GC est lié à : oth***@example.com"
"Options :"
- "Utiliser ce compte" (switch accounts)
- "Dissocier l'ancien compte" (si c'est le même user)
- "Annuler"
12a.4. Si "Dissocier" :
- POST /game-center/unlink (autre compte)
- Retry link
```

**14a. Conflit de données (GC score > local)**
```
14a.1. Auth Service détecte :
- Local leaderboard score: 1000
- Game Center score: 1500
14a.2. Auth Service retourne warning :
{
"linked": true,
"conflicts": [
{
"type": "leaderboard_score",
"local": 1000,
"game_center": 1500,
"resolution": "game_center_wins"
}
]
}
14a.3. App affiche :
"Conflit de données détecté"
"Score Game Center (1500) > Score local (1000)"
"Quelle version conserver ?"
[Garder Game Center] [Garder Local]
14a.4. Selon choix :
- GC : Met à jour app DB avec 1500
- Local : Report 1000 vers GC
Postconditions :

Game Center lié dans game_center_connections
player_id associé à user_id
Achievements synchronisés
Leaderboard mis à jour
Sync automatique activé pour futures sessions

Règles Métier :

Un player_id = un seul user_id
Signature valide < 5 minutes
Sync automatique à chaque login
Conflit resolution : par défaut Game Center wins (plus récent)
Achievements = cumulatifs (merge, pas overwrite)
Leaderboard = meilleur score (max)
Unlinking possible mais perte sync


UC-AUTH-1.4 : Modification Paramètres Confidentialité
Acteur Principal : Utilisateur Authentifié
Préconditions :

User authentifié
Privacy settings créées

Flux Principal :

User → Ouvre "Paramètres" → "Confidentialité"
App → GET /auth/v1/auth/privacy
Auth Service → Query :

sql   SELECT * FROM privacy_settings WHERE user_id = ?
```
4. **Auth Service** → Retourne settings actuelles
5. **App** → Affiche écran :
```
Confidentialité

Collecte de données
[✓] Analytiques d'utilisation
[ ] Partage avec partenaires
[✓] Géolocalisation
[ ] Publicités personnalisées
[✓] Notifications push

Game Center
[✓] Synchronisation achievements

Gestion des données
[Exporter mes données]
[Supprimer mon compte]

[Enregistrer]

User → Modifie toggles (ex: désactive "Géolocalisation")
User → Clique "Enregistrer"
App → PATCH /auth/v1/auth/privacy

json   {
"consent_analytics": true,
"consent_third_party": false,
"consent_geolocation": false,
"consent_personalized_ads": false,
"consent_notifications": true,
"consent_game_center": true
}

Auth Service → Valide changements (tous boolean)
Auth Service → Met à jour :

sql    UPDATE privacy_settings
SET
consent_analytics = ?,
consent_third_party = ?,
consent_geolocation = ?,
consent_personalized_ads = ?,
consent_notifications = ?,
consent_game_center = ?,
updated_at = NOW()
WHERE user_id = ?

Auth Service → Applique changements immédiatement :

11a. Si consent_geolocation = false :

Supprime user_locations WHERE user_id = ?
Notifie Offline Service de désactiver geo


11b. Si consent_personalized_ads = false :

Notifie Ads Service de passer en non-personalized


11c. Si consent_analytics = false :

Arrête envoi events analytics




Auth Service → Crée audit log
Auth Service → Retourne :

json    {
"privacy": {
"consent_analytics": true,
"consent_geolocation": false,
...
"updated_at": "2025-11-23T17:00:00Z"
},
"applied_immediately": true
}
```
14. **App** → Applique localement :
    - Désactive GPS tracking
    - Configure analytics SDK
    - Met à jour ads consent
15. **App** → Affiche confirmation :
    "✓ Paramètres enregistrés"
    "Modifications appliquées immédiatement"

**Flux Alternatifs** :

**6a. User clique "Exporter mes données"**
```
6a.1. App affiche confirmation :
"Exporter vos données"
"Nous préparerons un export complet au format JSON"
"Vous recevrez un email quand c'est prêt (24-48h)"
[Confirmer] [Annuler]

6a.2. User confirme
6a.3. App POST /auth/privacy/export
6a.4. Auth Service :
- Crée entrée dans privacy_settings.exports[]
- Lance job async pour agréger données :
* User profile
* Quiz history
* Achievements
* Transactions
* Settings
- Génère fichier JSON
- Upload vers storage sécurisé
- Génère signed URL (expire 7 jours)
- Envoie email avec lien download

6a.5. Auth Service retourne :
{
"export_id": "uuid",
"status": "pending",
"estimated_time": "24-48 hours"
}

6a.6. App affiche :
"Export en cours"
"Vous recevrez un email dans 24-48h"
```

**6b. User clique "Supprimer mon compte"**
```
6b.1. App affiche warning sévère :
"⚠️ Supprimer mon compte"

      "Cette action est irréversible !"
      
      "Sera supprimé :"
      - Profil utilisateur
      - Historique de jeux
      - Achievements
      - Abonnements (sans remboursement)
      
      "Délai de rétractation : 30 jours"
      "Vous pouvez annuler avant"
      
      Tapez "SUPPRIMER" pour confirmer :
      [_______________]

6b.2. User tape "SUPPRIMER" et confirme
6b.3. App DELETE /auth/me
Body: { reason: "user_request" }

6b.4. Auth Service :
- Met à jour privacy_settings :
SET delete_requested = true,
delete_scheduled_at = NOW() + INTERVAL '30 days'
- N'efface PAS immédiatement
- Crée job programmé pour J+30
- Envoie email confirmation avec lien annulation

6b.5. Auth Service retourne :
{
"scheduled_deletion_date": "2025-12-23T17:00:00Z",
"cancellation_token": "uuid"
}

6b.6. App affiche :
"Suppression programmée"
"Votre compte sera supprimé le 23/12/2025"
"Vous pouvez annuler via l'email reçu"

6b.7. App logout user
6b.8. Email envoyé :
"Votre compte sera supprimé dans 30 jours"
"Pour annuler : https://app.../cancel-deletion?token=..."
```

**11a. Désactivation géolocalisation impacte features**
```
11a.1. Auth Service détecte consent_geolocation = false
11a.2. Auth Service retourne warning :
{
"privacy": {...},
"warnings": [
{
"setting": "consent_geolocation",
"impact": "local_questions_unavailable",
"message": "Questions locales ne seront plus disponibles"
}
]
}
11a.3. App affiche :
"⚠️ Géolocalisation désactivée"
"Les questions 'Autour de vous' ne seront plus disponibles"
[J'ai compris]
Postconditions :

Privacy settings mis à jour
Changements appliqués immédiatement
Services notifiés (Ads, Offline, Analytics)
Audit log créé
Email confirmation (si export/deletion)

Règles Métier :

RGPD : droit d'accès, rectification, suppression
Export : format JSON structuré
Export : lien valide 7 jours
Suppression : délai 30 jours (grace period)
Suppression : anonymisation après 30 jours
Désactivation geo : supprime locations immédiatement
Ads consent : appliqué dès prochaine pub
Analytics : arrêté immédiatement si refusé


SERVICE 2 : SUBSCRIPTION SERVICE (Port 3002)
UC-SUB-2.1 : Souscription Abonnement Apple IAP
Acteur Principal : Utilisateur Gratuit
Préconditions :

User authentifié
Status = 'free'
Pas d'abonnement actif
StoreKit configuré

Flux Principal :

User → Clique "Devenir Premium" ou essaie d'accéder contenu premium
App → GET /subscription/v1/plans
Subscription Service → Query :

sql   SELECT * FROM subscription_plans
WHERE app_id = ? AND active = true
ORDER BY price ASC

Subscription Service → Retourne :

json   {
"plans": [
{
"id": "uuid-plan-monthly",
"name": "Premium Mensuel",
"plan_type": "monthly",
"apple_product_id": "com.quiz.premium.monthly",
"price": 4.99,
"currency": "EUR",
"trial_enabled": true,
"trial_duration_days": 7,
"features": {
"unlimited_content": true,
"no_ads": true,
"offline_unlimited": true,
"premium_categories": ["all"]
}
},
{
"id": "uuid-plan-annual",
"name": "Premium Annuel",
"plan_type": "annual",
"apple_product_id": "com.quiz.premium.annual",
"price": 39.99,
"currency": "EUR",
"discount_vs_monthly": "-33%",
"trial_enabled": true,
"trial_duration_days": 7,
"features": {...}
}
]
}
```
5. **App** → Affiche paywall :
```
🌟 Passez Premium

📦 Mensuel - 4,99€/mois
✓ Essai gratuit 7 jours
✓ Annulable à tout moment

💎 Annuel - 39,99€/an
🏷️ Économisez 33%
✓ Essai gratuit 7 jours

Ce qui est inclus :
✓ Contenu illimité
✓ Aucune publicité
✓ Hors-ligne illimité
✓ Catégories premium

[Essayer gratuitement] ← Bouton principal
[Restaurer mes achats]

Renouvelé automatiquement, annulable à tout moment

User → Sélectionne "Annuel" et clique "Essayer gratuitement"
App → Initie achat StoreKit :

swift   import StoreKit

// 1. Fetch product from App Store
let productIds: Set = ["com.quiz.premium.annual"]
let request = SKProductsRequest(productIdentifiers: productIds)
request.delegate = self
request.start()

// 2. Receive product
func productsRequest(_ request: SKProductsRequest,
didReceive response: SKProductsResponse) {
let product = response.products.first!

     // 3. Initiate purchase
     let payment = SKPayment(product: product)
     SKPaymentQueue.default().add(payment)
}
```
8. **StoreKit** → Affiche popup Apple :
```
Confirmer l'abonnement

Premium Annuel
39,99€ par an

Essai gratuit de 7 jours
Puis 39,99€/an renouvelé automatiquement

[Face ID / Touch ID pour confirmer]
[Annuler]

User → Confirme avec Face ID / Touch ID
StoreKit → Traite paiement Apple
StoreKit → Callback paymentQueue(_:updatedTransactions:)
App → Reçoit transaction avec status .purchased
App → Extrait receipt :

swift    let receiptURL = Bundle.main.appStoreReceiptURL!
let receiptData = try Data(contentsOf: receiptURL)
let receiptString = receiptData.base64EncodedString()

App → POST /subscription/v1/subscriptions/purchase

json    {
"plan_id": "uuid-plan-annual",
"store": "apple",
"receipt_data": "base64-encoded-receipt...",
"transaction_id": "1000000123456789",
"device_info": {
"device_id": "uuid",
"platform": "ios"
}
}

Subscription Service → Valide receipt avec Apple :

15a. POST https://buy.itunes.apple.com/verifyReceipt (production)



json      {
"receipt-data": "...",
"password": "shared_secret",
"exclude-old-transactions": true
}
- 15b. Apple retourne :
  json      {
  "status": 0,
  "latest_receipt_info": [{
  "transaction_id": "1000000123456789",
  "original_transaction_id": "1000000123456789",
  "product_id": "com.quiz.premium.annual",
  "purchase_date_ms": "1700000000000",
  "expires_date_ms": "1700604800000",
  "is_trial_period": "true",
  "cancellation_date": null
  }]
  }
- 15c. Vérifie `status = 0` (valide)
- 15d. Vérifie `product_id` correspond au plan
16. Subscription Service → Crée/met à jour subscription :
    sql    INSERT INTO subscriptions (
    id, app_id, user_id, plan_type, status,
    start_date, end_date, trial_end_date,
    auto_renew, store, store_product_id,
    store_transaction_id, store_original_transaction_id,
    store_receipt, price, currency
    ) VALUES (
    uuid_generate_v4(), ?, ?, 'annual', 'trial',
    NOW(),
    NOW() + INTERVAL '7 days', -- trial end
    NOW() + INTERVAL '7 days',
    true, 'apple', 'com.quiz.premium.annual',
    '1000000123456789', '1000000123456789',
    ?, 39.99, 'EUR'
    )
    ON CONFLICT (store_transaction_id) DO UPDATE ...

Subscription Service → Met à jour user status :

sql    UPDATE users
SET status = 'premium', subscription_id = ?
WHERE id = ?

Subscription Service → Crée event :

sql    INSERT INTO subscription_events (
subscription_id, event_type, event_data, timestamp
) VALUES (
?, 'trial_started', ?::jsonb, NOW()
)

Subscription Service → Enregistre receipt :

sql    INSERT INTO iap_receipts (
app_id, user_id, subscription_id,
store, receipt_data, transaction_id,
original_transaction_id, product_id,
purchase_date, expiration_date,
is_trial, is_active, validated, validation_date
) VALUES (
?, ?, ?, 'apple', ?, ?,
?, 'com.quiz.premium.annual',
to_timestamp(?), to_timestamp(?),
true, true, true, NOW()
)

Subscription Service → Appel Auth Service pour maj status
Subscription Service → Retourne :

json    {
"subscription": {
"id": "uuid-sub",
"status": "trial",
"plan_type": "annual",
"start_date": "2025-11-23T17:00:00Z",
"trial_end_date": "2025-11-30T17:00:00Z",
"end_date": "2026-11-23T17:00:00Z",
"auto_renew": true,
"features": {
"unlimited_content": true,
"no_ads": true,
"offline_unlimited": true
}
},
"activated": true
}

App → Finalise transaction StoreKit :

swift    SKPaymentQueue.default().finishTransaction(transaction)
```
23. **App** → Affiche animation congratulations :
```
    🎉 Bienvenue Premium !
    
    Essai gratuit activé
    7 jours gratuits, puis 39,99€/an
    
    Vos nouveaux avantages :
    ✓ Contenu illimité débloqué
    ✓ Publicités désactivées
    ✓ Hors-ligne illimité
    
    [Commencer]
```
24. **App** → Met à jour UI (retire pubs, débloque contenu)
25. **App** → Envoie analytics event "subscription_started"

**Flux Alternatifs** :

**9a. User annule pendant popup**
```
9a.1. User clique "Annuler"
9a.2. StoreKit callback avec status `.cancelled`
9a.3. App affiche message :
"Achat annulé"
"Vous pouvez souscrire à tout moment"
9a.4. Aucun appel backend
9a.5. Retour au paywall
```

**10a. Paiement échoue (carte refusée, etc.)**
```
10a.1. Apple rejette paiement
10a.2. StoreKit callback avec status `.failed` et error
10a.3. App affiche selon error code :
- .paymentCancelled : "Paiement annulé"
- .paymentInvalid : "Informations de paiement invalides"
- .paymentNotAllowed : "Achats non autorisés sur cet appareil"
- .storeProductNotAvailable : "Produit temporairement indisponible"
10a.4. App propose :
"Réessayer" ou "Modifier méthode de paiement"
```

**15a. Receipt invalide ou frauduleux**
```
15a.1. Apple retourne status != 0 :
- 21007 : Receipt is sandbox, use sandbox URL
- 21008 : Receipt is production, use production URL
- 21002, 21003, etc. : Invalid receipt

15a.2. Si 21007/21008 : retry avec bon environnement
15a.3. Si autre erreur :
Subscription Service retourne 400 Bad Request :
{
"error": "invalid_receipt",
"message": "Apple receipt validation failed",
"apple_status": 21002
}

15a.4. App affiche :
"Erreur de validation"
"Contactez le support avec code : RCV-21002"

15a.5. Log alerte sécurité (possible fraude)
```

**16a. Transaction déjà traitée (duplicate)**
```
16a.1. INSERT retourne conflict sur store_transaction_id
16a.2. Subscription Service vérifie état actuel
16a.3. Si subscription déjà active :
Retourne 200 OK avec subscription existante
16a.4. App affiche :
"Abonnement déjà activé"
[Continue]
```

**User déjà utilisé trial**
```
Lors du fetch product StoreKit (étape 7) :
- Apple détecte trial déjà utilisé
- product.introductoryPrice = nil
- App masque "Essai gratuit"
- App affiche seulement prix régulier
- User paie immédiatement
```

**Postconditions** :
- Subscription créée dans DB
- User status = 'premium'
- Receipt validé et stocké
- Transaction finalisée avec Apple
- Events trackés
- Contenu premium débloqué
- Publicités désactivées
- Email confirmation envoyé

**Règles Métier** :
- Trial : 7 jours gratuits (une fois par Apple ID)
- Renouvellement : automatique sauf annulation
- Vérification receipt : à chaque app launch
- Grace period : 16 jours si renouvellement échoue (Apple)
- Billing retry : Apple tente 60 jours
- Remboursement : selon politique Apple (14 jours)
- Webhook : Apple Server Notifications pour events

---

### UC-SUB-2.2 : Vérification Accès Contenu Premium

**Acteur Principal** : Utilisateur

**Préconditions** :
- User authentifié
- User tente d'accéder à du contenu

**Flux Principal** :
1. **User** → Navigue dans app, sélectionne une catégorie
2. **App** → Affiche liste contenus avec badges :
```
Géographie Europe
[FREE] Capitales         →
[FREE] Drapeaux          →
[💎] Monuments          → (lock icon)
[💰] Histoire          → (credit icon)

User → Clique sur "Monuments" (premium)
App → Vérifie cache local user.status
App → Si status != 'premium' → GET /subscription/v1/subscriptions/me
Subscription Service → Query :

sql   SELECT s.*, sp.features
FROM subscriptions s
LEFT JOIN subscription_plans sp ON s.plan_type = sp.plan_type
WHERE s.app_id = ?
AND s.user_id = ?
AND s.status IN ('active', 'trial', 'grace_period')
ORDER BY s.created_at DESC
LIMIT 1

Subscription Service → Si trouvé :

7a. Vérifie end_date > NOW()
7b. Si expiré → Met à jour status = 'expired'
7c. Si dans grace period → Garde 'grace_period'


Subscription Service → Retourne :

json   {
"subscription": {
"id": "uuid",
"status": "active",
"plan_type": "annual",
"end_date": "2026-11-23T17:00:00Z",
"auto_renew": true
},
"is_premium": true,
"features": {
"unlimited_content": true,
"no_ads": true,
"offline_unlimited": true,
"premium_categories": ["all"]
}
}

App → Met à jour cache local
App → Vérifie feature unlimited_content = true
App → Accès accordé → Charge contenu "Monuments"
App → POST /subscription/v1/content/:content_id/check-access

json    {
"content_id": "cat_monuments_premium"
}

Subscription Service → Enregistre dans access_logs :

sql    INSERT INTO access_logs (
app_id, user_id, content_id,
access_granted, user_status, timestamp
) VALUES (
?, ?, ?, true, 'premium', NOW()
)
```

**Flux Alternatifs** :

**5a. User FREE tente accès contenu premium**
```
5a.1. App détecte status = 'free'
5a.2. App appelle quand même /subscriptions/me (vérifier côté serveur)
5a.3. Subscription Service retourne :
{
"subscription": null,
"is_premium": false,
"features": {}
}
5a.4. App GET /content/:id
5a.5. Subscription Service retourne :
{
"content": {...},
"has_access": false,
"unlock_options": {
"via_subscription": {
"available": true,
"plans": [...]
},
"via_credits": null
}
}
5a.6. App affiche popup :
"Contenu Premium"

      Ce contenu est réservé aux membres Premium
      
      Avec Premium :
      ✓ Accès illimité à tout le contenu
      ✓ Aucune publicité
      ✓ Mode hors-ligne illimité
      
      [Essayer gratuitement] [Fermer]

5a.7. Si "Essayer" → UC-SUB-2.1
```

**5b. User FREE tente accès contenu freemium**
```
5b.1. App détecte content.access_level = 'freemium'
5b.2. App GET /content/:id
5b.3. Subscription Service retourne :
{
"content": {...},
"has_access": false,
"unlock_options": {
"via_subscription": {
"available": true,
"unlimited": true
},
"via_credits": {
"cost": 3,
"duration_hours": 24,
"user_can_afford": true,
"user_balance": 5
}
}
}
5b.4. App affiche popup :
"Débloquer Histoire d'Europe"

      Options :
      
      💎 Premium - Accès illimité
      [Essayer gratuitement]
      
      💰 Débloquer 24h - 3 crédits
      Votre solde : 5 crédits
      [Utiliser 3 crédits]
      
      [Fermer]

5b.5. Si "Utiliser crédits" → UC-SUB-2.4
```

**7a. Subscription expirée récemment**
```
7a.1. Query détecte end_date < NOW()
7a.2. Subscription Service met à jour :
UPDATE subscriptions
SET status = 'expired'
WHERE id = ?
7a.3. Subscription Service crée event :
INSERT INTO subscription_events (
subscription_id, event_type, timestamp
) VALUES (?, 'expired', NOW())
7a.4. Subscription Service met à jour Auth Service :
PATCH /auth/users/:id { status: 'free' }
7a.5. Subscription Service retourne :
{
"subscription": {
"status": "expired",
"expired_at": "2025-11-22T17:00:00Z"
},
"is_premium": false
}
7a.6. App affiche banner :
"Votre abonnement a expiré"
[Renouveler]
```

**7b. Subscription en grace period (paiement échoué)**
```
7b.1. Query détecte status = 'grace_period'
7b.2. Subscription Service calcule jours restants grace
7b.3. Subscription Service retourne :
{
"subscription": {
"status": "grace_period",
"grace_period_end": "2025-12-09T17:00:00Z",
"days_remaining": 3,
"billing_issue": true
},
"is_premium": true,
"warning": "billing_retry_in_progress"
}
7b.4. App affiche banner permanent :
"⚠️ Problème de paiement"
"Votre abonnement expire dans 3 jours"
"Mettez à jour vos infos de paiement"
[Gérer l'abonnement]

7b.5. Accès premium maintenu pendant grace period
```

**12a. Accès depuis multiple appareils simultanément**
```
12a.1. Subscription Service détecte accès depuis 2+ devices
12a.2. Selon règles business :
- Autorisé : continue normalement
- OU Limité : vérifie concurrent access count
12a.3. Si limite dépassée (ex: 5 appareils) :
Retourne 429 Too Many Requests :
{
"error": "concurrent_access_limit",
"message": "Maximum 5 devices simultaneously",
"active_devices": 6
}
12a.4. App affiche :
"Trop d'appareils connectés"
"Déconnectez-vous d'un autre appareil"
Postconditions :

Accès contenu accordé/refusé selon statut
Access log créé
Cache local mis à jour
UI adaptée (badges, locks)
Métriques trackées

Règles Métier :

Vérification accès : à chaque ouverture contenu
Cache status : 5 minutes max
Grace period : 16 jours (Apple), 3 jours (Google)
Accès concurrent : 5 appareils max
Contenu FREE : toujours accessible
Contenu PREMIUM : seulement si subscription active
Contenu FREEMIUM : subscription OU crédits


Use Cases Détaillés - Services Offline & Ads
SERVICE 3 : OFFLINE & GEOLOCATION SERVICE
UC-OFFLINE-3.1 : Téléchargement Contenu Offline
Acteur Principal : Utilisateur Authentifié
Préconditions :

L'utilisateur est authentifié
L'utilisateur a une connexion réseau active
Le service Offline est activé pour l'application
L'utilisateur a accepté le stockage local

Flux Principal :

User → Accède à "Paramètres" → "Mode Hors-ligne"
App → GET /offline/v1/sync/profile
Offline Service → Retourne profil avec :

Catégories disponibles au téléchargement
Espace utilisé / disponible
Limites selon statut (FREE/PREMIUM)


App → Affiche :

Storage bar : "45 MB / 50 MB utilisés"
Liste catégories disponibles
Pour chaque catégorie :

Nom
Nombre d'items
Taille estimée
Statut : "Non téléchargé" / "Téléchargé" / "À mettre à jour"




User → Sélectionne catégories à télécharger
App → Vérifie limites utilisateur :

FREE : Max 3 catégories, 50 items/catégorie
PREMIUM : Illimité


App → Calcule taille totale
App → Affiche confirmation :

"Télécharger 3 catégories (28 MB)"
"Temps estimé : 2 minutes"
Boutons : "Télécharger" / "Annuler"


User → Confirme "Télécharger"
App → POST /offline/v1/categories/download

json    {
"category_ids": ["cat1", "cat2", "cat3"]
}

Offline Service → Crée job de téléchargement
Offline Service → Retourne :

json    {
"job_id": "uuid",
"estimated_size_mb": 28,
"estimated_time_seconds": 120
}

App → Affiche barre de progression
App → Polling GET /offline/v1/categories/download/:job_id
Offline Service → Pour chaque catégorie :

15a. Récupère liste des items depuis app principale
15b. Filtre selon limites utilisateur (50 items si FREE)
15c. Télécharge données de chaque item
15d. Compresse données si nécessaire
15e. Stocke dans offline_items table
15f. Met à jour offline_categories table
15g. Met à jour compteur progression


Offline Service → Retourne progression :

json    {
"status": "downloading",
"progress": 65,
"downloaded_count": 98,
"total_count": 150
}

App → Met à jour barre : "65% - 98/150 items"
Offline Service → Une fois terminé :

18a. Calcule checksum de chaque item
18b. Définit expires_at = now + 30 jours
18c. Met à jour sync_profiles.last_full_sync_at
18d. Marque job comme "completed"


Offline Service → Retourne :

json    {
"status": "completed",
"progress": 100,
"downloaded_count": 150,
"total_count": 150
}
```
20. **App** → Affiche confirmation :
    - "✓ 3 catégories téléchargées"
    - "150 items disponibles hors-ligne"
    - "Prochaine mise à jour : [date]"

**Flux Alternatifs** :

**5a. Utilisateur FREE sélectionne > 3 catégories**
```
5a.1. App affiche message :
"Version gratuite : max 3 catégories"
"Passez Premium pour téléchargements illimités"
5a.2. Désactive sélection au-delà de 3
5a.3. Bouton "Devenir Premium"
```

**7a. Espace insuffisant**
```
7a.1. App calcule : taille_requise > espace_disponible
7a.2. App affiche popup :
"Espace insuffisant"
"Requis : 28 MB"
"Disponible : 5 MB"
"Libérez 23 MB ou réduisez la sélection"
7a.3. Boutons :
- "Gérer stockage" → UC-OFFLINE-3.6
- "Réduire sélection"
- "Annuler"
```

**15a. Connexion perdue pendant téléchargement**
```
15a.1. App détecte perte connexion
15a.2. Offline Service sauvegarde progression dans job
15a.3. Offline Service met status = 'paused'
15a.4. App affiche banner :
"Téléchargement en pause - Connexion perdue"
"Reprise automatique quand connexion revenue"
15a.5. App surveille connexion
15a.6. Quand connexion revenue :
- App envoie POST /categories/download/:job_id/resume
- Offline Service reprend où c'était arrêté
- Continue flux principal à l'étape 15
```

**15b. Erreur serveur pendant téléchargement**
```
15b.1. Offline Service rencontre erreur (ex: item introuvable)
15b.2. Offline Service log erreur
15b.3. Offline Service continue avec autres items
15b.4. À la fin, status = 'completed_with_errors'
15b.5. App affiche :
"Téléchargé avec avertissements"
"145/150 items téléchargés"
"5 items indisponibles"
Bouton "Voir détails"
Postconditions :

Catégories stockées dans offline_categories
Items stockés dans offline_items avec données complètes
Espace stockage mis à jour dans sync_profiles
Cache local SQLite peuplé (côté app)
Utilisateur peut jouer hors-ligne

Règles Métier :

FREE : Max 3 catégories, 50 items par catégorie, 50 MB total
PREMIUM : Illimité, 500 MB total
Téléchargement uniquement sur WiFi par défaut (paramétrable)
Expiration cache : 30 jours
Compression : gzip si item > 10 KB
Checksum : SHA-256 pour vérification intégrité
Retry automatique : 3 tentatives par item
Priorisation : items récemment accédés en premier

Modèle de Données :
typescript// Job de téléchargement (temporaire, en mémoire)
DownloadJob {
id: UUID
user_id: UUID
app_id: UUID
category_ids: string[]
status: 'pending' | 'downloading' | 'paused' | 'completed' | 'failed'
progress: {
current: number
total: number
percentage: number
}
errors: {
item_id: string
error: string
}[]
started_at: timestamp
completed_at: timestamp
estimated_completion: timestamp
}

UC-OFFLINE-3.2 : Synchronisation Automatique
Acteur Principal : Système (tâche automatique)
Préconditions :

L'utilisateur a activé sync automatique
Des catégories sont téléchargées
L'app est ouverte ou en arrière-plan
Connexion WiFi disponible (si paramètre activé)

Flux Principal :

System → Détecte conditions de sync :

App ouverte
Connexion WiFi active
Dernière sync > sync_frequency_hours (ex: 24h)


System → Vérifie sync_profiles.auto_sync_enabled = true
System → GET /offline/v1/categories/downloaded
Offline Service → Retourne liste catégories téléchargées
System → Pour chaque catégorie :

5a. Calcule last_updated_at catégorie
5b. GET /offline/v1/categories/:id/check-updates
5c. Offline Service compare avec version serveur
5d. Si nouvelles updates disponibles → Marque pour update


System → Si updates disponibles :

6a. Affiche notification discrète :
"Contenu hors-ligne mis à jour"
6b. POST /offline/v1/categories/:id/refresh pour chaque


Offline Service → Pour chaque refresh :

7a. Identifie items modifiés/nouveaux/supprimés
7b. Télécharge nouveaux items
7c. Met à jour items modifiés
7d. Marque items supprimés comme marked_for_deletion
7e. Met à jour last_updated_at


Offline Service → Retourne :

json   {
"updated": true,
"changes": {
"added": 5,
"updated": 12,
"deleted": 2
}
}
```
9. **System** → Met à jour cache local (SQLite)
10. **System** → Met à jour `sync_profiles.last_sync_at`
11. **System** → Si changements significatifs :
    - 11a. Affiche notification utilisateur :
         "5 nouvelles questions disponibles !"

**Flux Alternatifs** :

**1a. Connexion Cellular et sync_on_wifi_only = true**
```
1a.1. System détecte connexion cellular
1a.2. System vérifie sync_on_wifi_only = true
1a.3. System skip synchronisation
1a.4. System enregistre tentative dans logs
1a.5. System planifie retry dans 1 heure
```

**3a. Pas de catégories téléchargées**
```
3a.1. Offline Service retourne liste vide
3a.2. System skip synchronisation
3a.3. Fin du flux
```

**6a. Batterie faible (< 20%)**
```
6a.1. System détecte batterie < 20%
6a.2. System affiche notification :
"Sync hors-ligne reportée (batterie faible)"
6a.3. System planifie retry quand batterie > 50%
```

**7a. Conflit de version détecté**
```
7a.1. Offline Service détecte version locale modifiée
7a.2. Offline Service crée entrée dans sync_conflicts
7a.3. Offline Service applique stratégie selon config :
- 'server_wins' : Écrase local par serveur
- 'local_wins' : Garde local, ignore serveur
- 'manual' : Demande résolution utilisateur
7a.4. Si 'manual' :
- App affiche notification :
"Conflit détecté, résolution requise"
- User ouvre → UC-OFFLINE-3.5
Postconditions :

Contenu local à jour avec serveur
Changements reflétés dans cache SQLite
last_sync_at mis à jour
Notifications envoyées si changements importants

Règles Métier :

Sync automatique : max 1 fois par jour par défaut
WiFi only : activé par défaut pour FREE, désactivable pour PREMIUM
Batterie minimale : 20%
Retry : 3 tentatives espacées de 1h
Conflit resolution : 'server_wins' par défaut
Silent sync : pas de notification si < 3 changements


UC-OFFLINE-3.3 : Jeu Hors-ligne avec Queue
Acteur Principal : Utilisateur
Préconditions :

Utilisateur a du contenu téléchargé
Utilisateur est hors-ligne (pas de connexion)

Flux Principal :

User → Lance app sans connexion réseau
App → Détecte absence de connexion
App → Vérifie contenu local disponible
App → Affiche banner discret :
"Mode hors-ligne - Sync quand connexion revenue"
User → Sélectionne catégorie hors-ligne
App → Charge questions depuis SQLite local
App → Affiche quiz normalement
User → Répond aux questions
App → Pour chaque réponse :

9a. Enregistre dans SQLite local :



sql     INSERT INTO local_answers (
question_id, answer, is_correct, timestamp
) VALUES (?, ?, ?, ?)

9b. Calcule score local
9c. Met à jour stats locales


User → Termine le quiz
App → Affiche résultats (score local)
App → Crée action dans sync queue locale
App → Quand connexion revenue :

13a. Détecte connexion
13b. POST /offline/v1/sync/queue



json    {
"action_type": "answer_submit",
"entity_type": "quiz_completion",
"entity_id": "quiz_123",
"payload": {
"quiz_id": "quiz_123",
"answers": [
{ "question_id": "q1", "answer": 2, "is_correct": true, "timestamp": "..." },
{ "question_id": "q2", "answer": 1, "is_correct": false, "timestamp": "..." }
],
"score": 8,
"completed_at": "2025-11-23T15:30:00Z"
},
"priority": 5
}

Offline Service → Enregistre dans sync_queue
Offline Service → Retourne :

json    {
"queue_item": {...},
"position": 3
}

App → Affiche notification :
"Résultats en cours de synchronisation..."
App → POST /offline/v1/sync/execute
Offline Service → Traite queue par priorité :

18a. Pour chaque item dans queue :
18b. Forward vers service principal (ex: Quiz Service)
18c. Quiz Service enregistre réponses
18d. Quiz Service met à jour stats utilisateur
18e. Si succès → marque item status = 'success'
18f. Si erreur → incrémente attempts, schedule retry


Offline Service → Retourne résultat global :

json    {
"job_id": "uuid",
"items_to_process": 3
}
```
20. **App** → Polling GET `/offline/v1/sync/execute/:job_id`
21. **Offline Service** → Retourne progression
22. **App** → Une fois terminé, affiche :
    "✓ Résultats synchronisés"
    "Ton classement a été mis à jour"

**Flux Alternatifs** :

**3a. Aucun contenu local**
```
3a.1. App détecte SQLite vide
3a.2. App affiche écran bloquant :
"Aucun contenu hors-ligne disponible"
"Connectez-vous pour télécharger du contenu"
3a.3. Bouton "Paramètres Hors-ligne" (grisé)
```

**6a. Cache expiré (> 30 jours)**
```
6a.1. App vérifie expires_at des items
6a.2. Si expiré :
- App affiche popup :
"Contenu expiré"
"Reconnectez-vous pour mettre à jour"
- Griser catégorie
- Afficher badge "Expiré"
```

**13a. Connexion revient puis se perd**
```
13a.1. App commence sync
13a.2. Connexion perdue pendant envoi
13a.3. App détecte erreur réseau
13a.4. App marque items dans queue locale comme 'pending'
13a.5. App attend prochaine connexion
13a.6. Retry automatique avec next_retry_at
```

**18b. Service principal rejette données**
```
18b.1. Quiz Service retourne erreur (ex: question n'existe plus)
18b.2. Offline Service incrémente attempts
18b.3. Si attempts >= max_attempts (5) :
- Marque status = 'failed'
- Log erreur détaillée
- Notification utilisateur :
"Impossible de synchroniser certains résultats"
Bouton "Voir détails"
Postconditions :

Réponses enregistrées localement
Queue de synchronisation remplie
Sync automatique dès connexion revenue
Stats serveur mises à jour post-sync

Règles Métier :

Réponses locales = provisoires jusqu'à sync
Leaderboard/classement = désactivé en offline
Achievements = calculés localement, validés au sync
Max 100 actions en queue (purge après)
Retry : exponentiel backoff (2s, 4s, 8s, 16s, 32s)
Priority : answer_submit = 5, progress_save = 7, autres = 10


UC-OFFLINE-3.4 : Mise à Jour Géolocalisation
Acteur Principal : Utilisateur / Système
Préconditions :

L'utilisateur a autorisé géolocalisation
L'app a permission "When In Use" ou "Always"
GPS ou réseau disponible

Flux Principal :

App → Lance app ou revient au foreground
App → Vérifie permission géolocalisation
App → Si autorisée → Récupère coordonnées
System → Selon source disponible :

GPS : précision 10-30m
WiFi/Cell : précision 100-1000m
IP : précision ville (fallback)


App → Récupère :

dart   Position {
latitude: 48.8566,
longitude: 2.3522,
accuracy: 15.0, // meters
altitude: 35.0,
timestamp: DateTime.now()
}

App → Vérifie si mise à jour nécessaire :

Dernière location > 1 heure
OU distance > 5 km depuis dernière


App → POST /offline/v1/location/update

json   {
"latitude": 48.8566,
"longitude": 2.3522,
"accuracy": 15.0,
"altitude": 35.0,
"source": "gps",
"consent_given": true
}

Offline Service → Vérifie consent_given
Offline Service → Enregistre dans user_locations
Offline Service → Reverse geocoding :

10a. Appel API externe (Google Maps, OpenStreetMap)
10b. Récupère adresse structurée
10c. Extrait : country_code, country, city


Offline Service → Retourne :

json    {
"location": {
"id": "uuid",
"latitude": 48.8566,
"longitude": 2.3522,
"accuracy": 15.0,
"geocoded": {
"country_code": "FR",
"country": "France",
"city": "Paris"
},
"timestamp": "2025-11-23T15:30:00Z"
}
}

App → Stocke location localement
App → GET /offline/v1/location/nearby-content?radius_km=50
Offline Service → Query spatial :

sql    SELECT * FROM location_based_content
WHERE app_id = ?
AND active = true
AND ST_DWithin(
ST_MakePoint(longitude, latitude)::geography,
ST_MakePoint(?, ?)::geography,
? * 1000 -- km to meters
)
AND (available_until IS NULL OR available_until > NOW())
ORDER BY ST_Distance(
ST_MakePoint(longitude, latitude)::geography,
ST_MakePoint(?, ?)::geography
)
LIMIT 20

Offline Service → Retourne contenu local :

json    {
"content": [
{
"id": "content_paris_1",
"type": "quiz",
"title": "Monuments de Paris",
"distance_km": 2.3,
"metadata": {...}
}
]
}
```
16. **App** → Affiche section "Autour de vous"
17. **App** → User peut jouer quiz local

**Flux Alternatifs** :

**2a. Permission refusée**
```
2a.1. App détecte permission denied
2a.2. App affiche banner informatif :
"Géolocalisation désactivée"
"Activez pour voir les questions locales"
2a.3. Bouton "Paramètres"
2a.4. Section "Autour de vous" cachée
```

**4a. GPS indisponible**
```
4a.1. App timeout GPS après 10s
4a.2. App fallback sur WiFi/Cell location
4a.3. Si également indisponible :
- App fallback sur IP geolocation
- Précision = ville uniquement
- Flag source = 'ip'
```

**8a. Consent pas donné**
```
8a.1. Offline Service détecte consent_given = false
8a.2. Offline Service retourne erreur 403
8a.3. App affiche popup :
"Autorisation requise"
"Activez la géolocalisation dans Confidentialité"
8a.4. Redirect vers Privacy Settings
```

**10a. Geocoding échoue**
```
10a.1. API geocoding timeout ou erreur
10a.2. Offline Service log erreur
10a.3. Offline Service stocke coordonnées brutes seulement
10a.4. country/city = null
10a.5. Content nearby basé uniquement sur distance
```

**13a. Pas de contenu local disponible**
```
13a.1. Query retourne 0 résultats
13a.2. App affiche :
"Aucune question locale pour l'instant"
"Explorez les catégories générales"
13a.3. Section "Autour de vous" affiche placeholder
```

**Postconditions** :
- Location enregistrée dans `user_locations`
- Geocoding effectué si possible
- Contenu local chargé et affiché
- Cache local mis à jour

**Règles Métier** :
- Update uniquement si > 1h ou > 5km
- Précision minimale acceptable : 1000m
- Anonymisation : après 90 jours
- RGPD : opt-in explicite requis
- Fréquence max : 1 update / 15 minutes
- Geocoding cache : 24h
- Radius recherche : 50 km par défaut, max 200 km

---

### UC-OFFLINE-3.5 : Résolution Conflit Manuel

**Acteur Principal** : Utilisateur

**Préconditions** :
- Un conflit de sync existe
- Stratégie = 'manual'
- L'utilisateur est en ligne

**Flux Principal** :
1. **App** → Après sync, détecte conflits
2. **App** → GET `/offline/v1/sync/conflicts`
3. **Offline Service** → Retourne liste conflits non résolus
4. **App** → Affiche notification :
   "2 conflits nécessitent votre attention"
5. **User** → Clique sur notification
6. **App** → Affiche écran "Résolution Conflits"
7. **App** → Pour chaque conflit, affiche :
   - Type d'entité (ex: "Réponse au quiz")
   - Version locale vs serveur
   - Timestamps
   - Données divergentes
8. **User** → Examine conflit 1 :
```
Quiz: "Capitales d'Europe"

Version Locale (23/11 14:30):
- Question 5 : Réponse = 2 (Rome)
- Score : 8/10

Version Serveur (23/11 14:28):
- Question 5 : Réponse = 3 (Madrid)
- Score : 7/10

Que faire ?
[Garder Local] [Garder Serveur] [Fusionner]

User → Choisit "Garder Local"
App → POST /offline/v1/sync/conflicts/:conflict_id/resolve

json    {
"resolution": "local_wins"
}

Offline Service → Applique résolution :

11a. Forward version locale vers service principal
11b. Écrase version serveur
11c. Marque conflit comme resolved = true
11d. Enregistre resolved_by = 'user'


Offline Service → Retourne :

json    {
"resolved": true,
"final_data": {...} // Version finale
}
```
13. **App** → Affiche confirmation :
    "✓ Conflit résolu - Version locale conservée"
14. **App** → Passe au conflit suivant ou termine

**Flux Alternatifs** :

**9a. User choisit "Fusionner"**
```
9a.1. App affiche interface fusion :
- Checkbox pour chaque champ divergent
- User sélectionne quelle valeur garder
9a.2. User valide fusion
9a.3. App construit merge_data :
{
"question_5": "local", // Garder réponse locale
"score": "server",     // Garder score serveur
"timestamp": "local"
}
9a.4. App POST avec resolution: "merge" et merge_data
9a.5. Offline Service combine versions selon merge_data
9a.6. Continue flux principal étape 11
```

**9b. User choisit "Garder Serveur"**
```
9b.1. App POST avec resolution: "server_wins"
9b.2. Offline Service :
- Garde version serveur intacte
- Écrase cache local avec serveur
- Marque conflit resolved
9b.3. App affiche :
"✓ Version serveur conservée"
"Vos données locales ont été remplacées"
```

**11a. Résolution échoue**
```
11a.1. Service principal rejette résolution
11a.2. Offline Service retourne erreur
11a.3. App affiche :
"Impossible de résoudre le conflit"
"Erreur: [raison]"
11a.4. Conflit reste non résolu
11a.5. User peut réessayer ou skip
```

**Postconditions** :
- Conflit résolu selon choix utilisateur
- Données cohérentes entre local et serveur
- Conflit marqué `resolved = true`
- Historique de résolution conservé

**Règles Métier** :
- Conflits > 7 jours → Auto-résolution 'server_wins'
- User peut skip temporairement (max 3 fois)
- Analytics : tracker taux résolution manuelle
- Notification persistante tant que conflits non résolus
- Max 10 conflits simultanés (sinon force 'server_wins')

---

### UC-OFFLINE-3.6 : Gestion Stockage Local

**Acteur Principal** : Utilisateur

**Préconditions** :
- L'utilisateur a du contenu téléchargé
- L'utilisateur est authentifié

**Flux Principal** :
1. **User** → Accède à "Paramètres" → "Stockage"
2. **App** → GET `/offline/v1/sync/profile`
3. **Offline Service** → Retourne profil complet
4. **App** → Affiche écran "Gestion Stockage" :
```
Stockage Utilisé: 45 MB / 50 MB
[==========>      ] 90%

Par Catégorie:
- Géographie Europe : 18 MB (120 items)
- Capitales Monde : 15 MB (85 items)
- Drapeaux : 12 MB (50 items)

Actions:
[Libérer Espace] [Tout Supprimer]
```
5. **User** → Clique sur une catégorie
6. **App** → Affiche détails :
```
Géographie Europe

Items: 120
Taille: 18 MB
Téléchargé: Il y a 5 jours
Dernière utilisation: Hier
Expire: Dans 25 jours

[Mettre à jour] [Supprimer]

User → Clique "Supprimer"
App → Affiche confirmation :
"Supprimer Géographie Europe ?"
"18 MB seront libérés"
[Supprimer] [Annuler]
User → Confirme
App → DELETE /offline/v1/categories/:category_id
Offline Service → Supprime :

11a. DELETE FROM offline_items WHERE category_id = ?
11b. DELETE FROM offline_categories WHERE id = ?
11c. Met à jour sync_profiles.storage_used_bytes


Offline Service → Retourne :

json    {
"deleted": true,
"space_freed_mb": 18
}
```
13. **App** → Supprime cache SQLite local
14. **App** → Affiche confirmation :
    "✓ Géographie Europe supprimée"
    "18 MB libérés"
15. **App** → Rafraîchit affichage stockage

**Flux Alternatifs** :

**5a. User clique "Libérer Espace"**
```
5a.1. App analyse contenu :
- Items jamais accédés
- Items accédés > 30 jours
- Catégories partiellement téléchargées
5a.2. App affiche suggestions :
"Libérer 22 MB en supprimant :"
- Drapeaux (jamais utilisé) : 12 MB
- 15 items anciens : 10 MB
[Libérer] [Personnaliser]
5a.3. Si User confirme :
- DELETE items suggérés
- Update storage
- Affiche espace libéré
```

**5b. User clique "Tout Supprimer"**
```
5b.1. App affiche warning sévère :
"⚠️ Tout supprimer ?"
"Toutes les données hors-ligne seront effacées"
"Vous devrez tout re-télécharger"
[Je comprends, supprimer] [Annuler]
5b.2. Si User confirme :
- DELETE toutes categories
- DELETE tous items
- Reset sync_profile
- Clear SQLite local
- Affiche confirmation
```

**11a. Suppression échoue**
```
11a.1. Offline Service rencontre erreur DB
11a.2. Rollback transaction
11a.3. Retourne erreur 500
11a.4. App affiche :
"Impossible de supprimer"
"Réessayez plus tard"
11a.5. Aucun changement effectué
Postconditions :

Contenu supprimé de offline_categories et offline_items
Espace libéré dans storage_used_bytes
Cache SQLite nettoyé
User peut télécharger nouveau contenu

Règles Métier :

Suppression = immédiate, pas de corbeille
Items en queue sync = avertissement avant suppression
Auto-cleanup : items > 90 jours non accédés
Compression automatique DB après suppression > 50 MB
Suggestion "Libérer" : basée sur usage réel


SERVICE 4 : ADS & FREEMIUM SERVICE
UC-ADS-4.1 : Visionner Publicité Rewarded
Acteur Principal : Utilisateur Gratuit
Préconditions :

L'utilisateur est FREE (pas Premium)
L'utilisateur est authentifié ou guest
AdMob SDK initialisé
Consent donné (GDPR/ATT)

Flux Principal :

User → Clique "Gagner des crédits" ou "Débloquer contenu"
App → GET /ads/v1/ads/available?ad_type=rewarded&placement=earn_credits
Ads Service → Vérifie éligibilité :

3a. Query user_ad_limits pour aujourd'hui
3b. Vérifie rewarded_views < daily_limit (10)
3c. Vérifie last_rewarded_at + cooldown (30s) passé
3d. Vérifie consent donné


Ads Service → Retourne :

json   {
"available": true,
"reason": null,
"cooldown_seconds": 0,
"next_available_at": null
}
```
5. **App** → Affiche popup :
```
Gagner 1 Crédit

Regardez une pub de 30 secondes

Crédits actuels: 3
Après la pub: 4

[Regarder] [Annuler]

User → Clique "Regarder"
App → POST /ads/v1/ads/request

json   {
"ad_type": "rewarded",
"placement": "earn_credits",
"provider_preference": "admob"
}

Ads Service → Crée ad request :

8a. Génère UUID pour tracking
8b. Query ad_providers WHERE app_id AND active
8c. Sélectionne provider par priorité
8d. Récupère rewarded_unit_id


Ads Service → Retourne :

json   {
"ad_request_id": "uuid",
"provider": "admob",
"ad_unit_id": "ca-app-pub-xxx/rewarded",
"can_show": true,
"test_mode": false
}

App → Charge pub avec AdMob SDK :

dart    RewardedAd.load(
adUnitId: response.adUnitId,
request: AdRequest(),
rewardedAdLoadCallback: ...
)

App → Affiche loading :
"Chargement de la publicité..."
AdMob SDK → Charge pub depuis réseau
AdMob SDK → Callback onAdLoaded
App → POST /ads/v1/ads/:ad_request_id/impression

json    {
"loaded": true,
"shown": false,
"load_time_ms": 1200
}

App → Affiche pub plein écran
AdMob SDK → Callback onAdShowed
App → POST /ads/v1/ads/:ad_request_id/impression

json    {
"loaded": true,
"shown": true,
"load_time_ms": 1200
}

User → Regarde pub (30 secondes)
AdMob SDK → Callback onUserEarnedReward
App → POST /ads/v1/ads/:ad_request_id/complete

json    {
"completed": true,
"clicked": false,
"display_duration_ms": 30500
}

Ads Service → Traite completion :

21a. Vérifie display_duration >= 80% durée pub (24s)
21b. Crée entrée dans ad_views avec reward_granted = true
21c. Appel Subscription Service :
POST /subscription/v1/credits/earn
{ amount: 1, source: 'ad_reward', reference_id: ad_request_id }
21d. Met à jour user_ad_limits :
INCREMENT rewarded_views
SET last_rewarded_at = NOW()
SET rewarded_cooldown_until = NOW() + 30 seconds


Ads Service → Retourne :

json    {
"reward_granted": true,
"reward": {
"type": "credits",
"amount": 1
},
"new_balance": 4
}
```
23. **App** → Affiche animation reward :
    "✨ +1 Crédit !"
    "Nouveau solde: 4 crédits"
24. **App** → Met à jour UI locale
25. **App** → Pré-charge prochaine pub (background)

**Flux Alternatifs** :

**3b. Limite quotidienne atteinte**
```
3b.1. Ads Service détecte rewarded_views >= 10
3b.2. Ads Service retourne :
{
"available": false,
"reason": "daily_limit_reached",
"cooldown_seconds": null,
"next_available_at": "2025-11-24T00:00:00Z"
}
3b.3. App affiche :
"Limite quotidienne atteinte"
"10 pubs regardées aujourd'hui"
"Revenez demain ou passez Premium"
[Devenir Premium] [OK]
```

**3c. Cooldown actif**
```
3c.1. Ads Service calcule temps restant
3c.2. Ads Service retourne :
{
"available": false,
"reason": "cooldown_active",
"cooldown_seconds": 15,
"next_available_at": "2025-11-23T15:30:15Z"
}
3c.3. App affiche :
"Veuillez patienter 15 secondes"
[Countdown timer]
Retry automatique après countdown
```

**12a. Chargement pub échoue**
```
12a.1. AdMob SDK callback onAdFailedToLoad
12a.2. App POST impression avec loaded: false, error
12a.3. App affiche :
"Publicité temporairement indisponible"
"Réessayez dans quelques instants"
12a.4. App attend 30s et retry automatiquement
12a.5. Après 3 échecs :
- Affiche "Service pub indisponible"
- Log erreur pour investigation
- Pas de pénalité utilisateur
```

**18a. User ferme pub avant fin**
```
18a.1. AdMob SDK callback onAdDismissed (pas onUserEarnedReward)
18a.2. App POST complete avec completed: false
18a.3. Ads Service :
- Crée ad_views avec reward_granted = false
- N'accorde PAS de crédit
- Active cooldown court (15s)
18a.4. App affiche :
"Publicité non complète"
"Regardez la pub entière pour gagner le crédit"
```

**18b. User clique sur pub**
```
18b.1. AdMob SDK callback onAdClicked
18b.2. App ouvre browser externe (store)
18b.3. App passe en background
18b.4. User revient à l'app
18b.5. Si pub complète → Continue flux principal
18b.6. Sinon → Flux alternatif 18a
```

**21c. Subscription Service indisponible**
```
21c.1. Ads Service appel timeout
21c.2. Ads Service met en queue retry :
- Enregistre pending_reward
- Retry jusqu'à succès
21c.3. App affiche temporairement :
"Crédit en cours d'attribution..."
21c.4. Notification push quand crédit ajouté
```

**Postconditions** :
- 1 crédit ajouté au solde utilisateur
- `ad_views` enregistré avec métadonnées
- `user_ad_limits` mis à jour (count + cooldown)
- Analytics envoyées (impressions, completions)
- Prochaine pub pré-chargée

**Règles Métier** :
- 1 pub rewarded = 1 crédit
- Limite FREE : 10 pubs/jour
- Premium : pas de pubs
- Cooldown : 30s entre pubs
- Durée visionnage minimum : 80% de la pub
- Retry chargement : 3 fois max
- Pré-chargement : 1 pub en avance
- COPPA : pas de pub si age < 13 ans
- GDPR : consent explicite requis
- ATT (iOS) : respect statut tracking

---

### UC-ADS-4.2 : Affichage Publicité Interstitielle

**Acteur Principal** : Système (automatique)

**Acteurs Secondaires** : Utilisateur

**Préconditions** :
- Utilisateur FREE (pas Premium)
- Event trigger atteint (ex: fin de quiz)
- Consent donné

**Flux Principal** :
1. **User** → Termine un quiz
2. **App** → Affiche écran résultats (2 secondes)
3. **App** → Vérifie conditions interstitiel :
   - 3a. Statut user = FREE
   - 3b. Count quizzes depuis dernière pub >= 2
   - 3c. Time depuis dernière pub >= 3 minutes
4. **App** → Conditions OK → GET `/ads/v1/ads/available?ad_type=interstitial&placement=post_quiz`
5. **Ads Service** → Vérifie :
   - 5a. Query `user_ad_limits`
   - 5b. Vérifie `last_interstitial_at + 180s` < NOW()
   - 5c. Vérifie pas en cooldown
6. **Ads Service** → Retourne `available: true`
7. **App** → POST `/ads/v1/ads/request` (interstitial)
8. **Ads Service** → Retourne config pub
9. **App** → Charge pub interstitielle (background)
10. **App** → Attend 2 secondes (UX - voir résultats)
11. **App** → Affiche pub plein écran
12. **User** → Voit pub (5-15 secondes)
13. **User** → Clique X (après 5s minimum)
14. **App** → POST `/ads/v1/ads/:id/complete`
15. **Ads Service** → Enregistre :
    - 15a. Crée `ad_views` avec completed: true
    - 15b. Met à jour `user_ad_limits.last_interstitial_at`
    - 15c. Set cooldown 180s
    - 15d. Reset compteur quizzes
16. **App** → Retour à navigation normale
17. **User** → Continue à utiliser app

**Flux Alternatifs** :

**3a. User est Premium**
```
3a.1. App détecte status = 'premium'
3a.2. Skip complètement pub
3a.3. Transition immédiate vers écran suivant
3a.4. Aucun appel Ads Service
```

**3c. Intervalle minimum non atteint**
```
3c.1. App calcule : last_interstitial_at + 180s > NOW()
3c.2. Skip pub silencieusement
3c.3. Incrémenter compteur quizzes localement
3c.4. Continue navigation
```

**5b. Trop de pubs aujourd'hui**
```
5b.1. Ads Service détecte interstitial_views > seuil (ex: 20/jour)
5b.2. Retourne available: false
5b.3. App skip pub
5b.4. Log pour analytics (fatigue publicitaire)
```

**9a. Chargement pub échoue**
```
9a.1. AdMob SDK timeout ou erreur
9a.2. App skip silencieusement
9a.3. Continue navigation normalement
9a.4. Aucune pénalité utilisateur
9a.5. Log erreur pour monitoring
```

**12a. User ferme app pendant pub**
```
12a.1. App passe en background
12a.2. Pub se ferme automatiquement
12a.3. Ad_view marqué completed: false
12a.4. Pas de pénalité
12a.5. Au retour app : continue normalement
Postconditions :

Pub affichée (ou skippée si conditions non remplies)
ad_views enregistré
user_ad_limits mis à jour
Cooldown activé
Compteur quizzes reset
UX maintenue (pas de blocage)

Règles Métier :

Fréquence : 1 pub / 2 quizzes minimum
Intervalle minimum : 3 minutes
FREE uniquement (jamais Premium)
Durée affichage min : 5 secondes
Bouton X : après 5s obligatoire
Max pubs/jour : 20 (soft limit)
Pas de pub pendant :

Tutoriel initial
Première session (< 3 minutes)
Moins de 2 quiz complétés


Silent fail : échec chargement = skip transparent


UC-ADS-4.3 : Gestion Consent Publicités (GDPR/ATT)
Acteur Principal : Utilisateur
Préconditions :

Première ouverture app OU changement politique
Localisation nécessitant consent (UE, UK, etc.)

Flux Principal :

App → Lance, détecte première ouverture
App → Détecte région utilisateur (IP ou locale iOS)
App → Si UE/UK → GDPR s'applique
App → GET /ads/v1/ads/consent
Ads Service → Retourne :

json   {
"consent": null,
"required": true,
"gdpr_applies": true
}
```
6. **App** → Affiche écran Consent (AVANT toute pub) :
```
Confidentialité & Publicités

Nous et nos partenaires publicitaires utilisons
des cookies pour personnaliser les publicités.

[En savoir plus]

Acceptez-vous les publicités personnalisées ?

[Accepter] [Refuser]

Vous pouvez changer d'avis à tout moment dans
Paramètres > Confidentialité

User → Fait un choix
App → POST /ads/v1/ads/consent

json   {
"consent_personalized_ads": true,
"consent_data_sharing": true,
"age_gate_passed": true,
"is_under_age": false
}

Ads Service → Enregistre dans user_consent_ads
Ads Service → Retourne :

json    {
"consent": {...},
"ads_enabled": true
}

App → Configure AdMob selon consent :

dart    MobileAds.instance.setConsent({
'npa': consent ? '0' : '1', // npa = non-personalized ads
});
```
12. **App** → Continue onboarding

**iOS ATT (App Tracking Transparency)** :
13. **App** → Après GDPR, si iOS >= 14.5
14. **App** → Affiche prompt système ATT :
```
    [App] souhaite vous suivre sur les apps et sites
    d'autres sociétés
    
    Vos données seront utilisées pour vous proposer
    des publicités personnalisées.
    
    [Demander à l'app de ne pas suivre]
    [Autoriser]

User → Fait choix
App → Récupère ATTrackingManager.trackingAuthorizationStatus
App → POST /ads/v1/ads/consent (update)

json    {
"att_status": "authorized" | "denied" | "restricted"
}
```
18. **Ads Service** → Met à jour consent
19. **App** → Configure ads selon ATT

**Flux Alternatifs** :

**2a. Région hors UE**
```
2a.1. App détecte region US/CA/etc
2a.2. GDPR ne s'applique pas
2a.3. Skip étape consent GDPR
2a.4. Va directement à ATT (iOS) si applicable
2a.5. Consent implicite pour ads
```

**7a. User clique "En savoir plus"**
```
7a.1. App affiche détails :
- Liste partenaires publicitaires
- Données collectées
- Usage des données
- Lien politique confidentialité
7a.2. User revient et fait choix
```

**7b. User refuse tout**
```
7b.1. App POST avec all consent = false
7b.2. Ads Service enregistre refus
7b.3. App configure :
- Pubs non-personnalisées uniquement
- Revenus réduits (eCPM plus faible)
7b.4. User peut quand même gagner crédits
```

**8a. User < 13 ans (COPPA)**
```
8a.1. App détecte is_under_age = true (age gate)
8a.2. App POST avec flags COPPA
8a.3. Ads Service enregistre
8a.4. App configure :
- AUCUNE pub personnalisée
- Pas de tracking
- Pas de rewarded ads
8a.5. Mode contenu uniquement
```

**15a. User refuse ATT**
```
15a.1. ATT status = 'denied'
15a.2. App POST avec att_status: denied
15a.3. Ads Service enregistre
15a.4. App configure :
- Pubs contextuelles seulement
- Pas d'IDFA tracking
- Revenus réduits
15a.5. Fonctionnalités app maintenues
Postconditions :

Consent enregistré dans user_consent_ads
Configuration ads appliquée
Conformité GDPR/COPPA/ATT respectée
User peut changer avis plus tard

Règles Métier :

GDPR : opt-in explicite requis en UE
COPPA : < 13 ans = pas de pub personnalisée
ATT : iOS 14.5+ requis
Consent = granulaire (personnalisé vs non-personnalisé)
Révocable : user peut changer dans Paramètres
Audit log : tracer tous changements consent
TCF 2.0 : si intégration avec CMPs externes


UC-ADS-4.4 : Participation Campagne Freemium
Acteur Principal : Utilisateur Gratuit
Préconditions :

User authentifié
Campagne active existe
User n'a pas épuisé max_uses

Flux Principal :

App → Au lancement, GET /ads/v1/campaigns/active
Ads Service → Query freemium_campaigns WHERE active AND now BETWEEN starts_at AND ends_at
Ads Service → Retourne :

json   {
"campaigns": [
{
"id": "uuid",
"name": "Semaine Bonus",
"description": "Regardez 5 pubs, gagnez 10 crédits !",
"campaign_type": "watch_ads",
"reward": {
"type": "credits",
"amount": 10
},
"conditions": {
"min_ads_watched": 5
},
"progress": {
"current": 2,
"required": 5,
"completed": false
},
"ends_at": "2025-11-30T23:59:59Z"
}
]
}
```
4. **App** → Affiche banner campagne :
```
🎉 Semaine Bonus
Regardez 5 pubs, gagnez 10 crédits !
Progression: 2/5 ⭐⭐☆☆☆
[Participer]
```
5. **User** → Clique "Participer"
6. **App** → GET `/ads/v1/campaigns/:id`
7. **Ads Service** → Retourne détails complets
8. **App** → Affiche écran campagne :
```
Semaine Bonus

Conditions:
- Regardez 5 publicités rewarded
- Valide jusqu'au 30/11

Récompense:
+10 crédits bonus

Votre progression: 2/5
[==========>          ] 40%

[Regarder une pub maintenant]

User → Clique "Regarder une pub"
App → Lance UC-ADS-4.1 (Rewarded Ad)
User → Regarde pub, gagne 1 crédit
App → Après completion pub :

12a. Vérifie si pub compte pour campagne
12b. POST /ads/v1/campaigns/:id (update progress)


Ads Service → Met à jour campaign_participations :

13a. INCREMENT progress
13b. Si progress >= conditions.min_ads_watched :
SET completed = true


Ads Service → Retourne :

json    {
"campaign_id": "uuid",
"progress": 3,
"completed": false
}

App → Affiche toast :
"Progression campagne: 3/5 ⭐⭐⭐☆☆"
User → Continue à regarder pubs...
User → Après 5ème pub :
Ads Service → Détecte completion
Ads Service → Retourne :

json    {
"campaign_id": "uuid",
"progress": 5,
"completed": true,
"can_claim_reward": true
}
```
20. **App** → Affiche popup congratulations :
```
    🎉 Campagne Terminée !
    
    Vous avez regardé 5 pubs
    
    Réclamez votre récompense:
    +10 Crédits Bonus
    
    [Réclamer]

User → Clique "Réclamer"
App → POST /ads/v1/campaigns/:id/claim-reward
Ads Service → Traite claim :

23a. Vérifie completed = true
23b. Vérifie reward_claimed = false
23c. Appel Subscription Service :
POST /credits/earn
{ amount: 10, source: 'promo', reference: campaign_id }
23d. Met à jour campaign_participations :
SET reward_claimed = true, reward_claimed_at = NOW()


Ads Service → Retourne :

json    {
"claimed": true,
"reward": {
"type": "credits",
"amount": 10
},
"new_balance": 14
}
```
25. **App** → Animation reward :
    "✨ +10 Crédits Bonus !"
    "Nouveau solde: 14 crédits"
26. **App** → Cache campagne (déjà complétée)

**Flux Alternatifs** :

**12a. Pub ne compte pas pour campagne**
```
12a.1. Ads Service vérifie :
- Campaign actif ?
- User déjà participé ?
- Conditions spécifiques (ex: placement) ?
12a.2. Si conditions non remplies :
- Pas d'update campaign_participations
- User gagne crédit normal seulement
12a.3. App n'affiche pas toast progression
```

**17a. Campagne expire avant completion**
```
17a.1. User à 4/5, campagne expire
17a.2. Ads Service détecte ends_at < NOW()
17a.3. Campaign devient inactive
17a.4. App affiche :
"⏰ Campagne expirée"
"Vous étiez à 4/5"
"Restez attentif aux prochaines campagnes !"
17a.5. Participation archivée, pas de reward
```

**23a. Max uses atteint**
```
23a.1. Campaign a max_uses_per_user = 1
23a.2. Ads Service détecte user a déjà claim
23a.3. Retourne erreur 400 "Already claimed"
23a.4. App affiche :
"Récompense déjà réclamée"
"Vous ne pouvez participer qu'une fois"
```

**23c. Subscription Service échoue**
```
23c.1. Appel timeout ou erreur
23c.2. Ads Service met en pending_rewards
23c.3. Retry automatique (5 tentatives)
23c.4. App affiche :
"Récompense en cours d'attribution"
23c.5. Notification push quand crédits ajoutés
```

**Autres Types de Campagnes** :

**Campagne Streak (connexion quotidienne)**
```
Type: 'streak_bonus'
Conditions: { streak_days: 7 }
Reward: 20 crédits

Flow:
- User se connecte chaque jour
- Ads Service incrémente streak
- Jour 7 : completed = true
- User claim 20 crédits
```

**Campagne Parrainage**
```
Type: 'referral'
Conditions: { referrals_count: 3 }
Reward: 50 crédits

Flow:
- User partage code parrain
- 3 amis installent et jouent
- Campaign completed
- User claim 50 crédits
  Postconditions :

Campaign participation créée/mise à jour
Progress trackée dans DB
Reward claimed enregistrée
Crédits ajoutés au solde
Analytics enrichies

Règles Métier :

Max 1 participation par campagne par user
Progress = sauvegardée même si campagne expire
Reward = rétroactive si conditions remplies avant claim
Notification : 1 jour avant expiration si proche completion
Analytics : track taux completion campagnes
A/B testing : différents rewards selon cohortes


UC-ADS-4.5 : Analytics Revenus Publicitaires (Admin)
Acteur Principal : Admin / System
Préconditions :

Accès admin authentifié
Données ad_views disponibles

Flux Principal :

Admin → Accède dashboard analytics
Admin → GET /ads/v1/analytics/revenue?start_date=2025-11-01&end_date=2025-11-30
Ads Service → Query agrégée :

sql   SELECT
DATE(created_at) as date,
COUNT(*) as total_impressions,
SUM(CASE WHEN ad_clicked THEN 1 ELSE 0 END) as total_clicks,
SUM(CASE WHEN ad_completed THEN 1 ELSE 0 END) as total_completions,
SUM(revenue_usd) as total_revenue,
AVG(display_duration_ms) as avg_duration,
-- Par type
SUM(CASE WHEN ad_type = 'rewarded' THEN 1 ELSE 0 END) as rewarded_count,
SUM(CASE WHEN ad_type = 'interstitial' THEN 1 ELSE 0 END) as interstitial_count,
-- eCPM
(SUM(revenue_usd) / COUNT(*) * 1000) as ecpm
FROM ad_views
WHERE app_id = ?
AND created_at BETWEEN ? AND ?
GROUP BY DATE(created_at)
ORDER BY date DESC

Ads Service → Calcule métriques additionnelles :

Fill rate : impressions / requests
CTR : clicks / impressions
Completion rate : completions / impressions (rewarded)


Ads Service → Retourne :

json   {
"total_revenue": 1234.56,
"total_impressions": 45678,
"avg_ecpm": 27.03,
"by_date": [
{
"date": "2025-11-23",
"revenue": 42.30,
"impressions": 1523,
"completions": 412,
"ecpm": 27.77
}
],
"by_type": {
"rewarded": {
"impressions": 12340,
"completions": 9876,
"completion_rate": 0.80,
"revenue": 987.65,
"avg_ecpm": 80.00
},
"interstitial": {
"impressions": 33338,
"revenue": 246.91,
"avg_ecpm": 7.41
}
},
"by_provider": {
"admob": {
"impressions": 40123,
"revenue": 1123.45,
"ecpm": 28.00
},
"unity": {
"impressions": 5555,
"revenue": 111.11,
"ecpm": 20.00
}
}
}
```
6. **Admin** → Visualise dans dashboard :
   - Graphique revenus par jour
   - Breakdown par type de pub
   - Comparaison providers
   - Top performing placements
7. **Admin** → Peut exporter CSV pour analyse approfondie

**Flux Alternatifs** :

**3a. Filtres additionnels**
```
GET /analytics/revenue?
start_date=2025-11-01&
end_date=2025-11-30&
ad_type=rewarded&
provider=admob&
placement=post_quiz

→ Données filtrées selon critères
```

**5a. Données incomplètes (revenue_usd NULL)**
```
5a.1. Ads Service détecte ad_views sans revenue
5a.2. Utilise eCPM moyen pour estimer
5a.3. Flag données comme "estimated"
5a.4. Affiche disclaimer dans dashboard
Postconditions :

Métriques calculées et retournées
Dashboard actualisé
Export disponible
Décisions business informées

Règles Métier :

Données mises à jour : toutes les heures
Rétention : 2 ans de données détaillées
Agrégats : calculés nightly pour performances
Privacy : pas de données user identifiables
eCPM = (Revenue / Impressions) * 1000


RÉSUMÉ COMPLET DES USE CASES
Service Auth (3001)

✅ UC-AUTH-1.1 : Création compte multi-provider (Google, Apple, Email, Guest)
✅ UC-AUTH-1.2 : Connexion
✅ UC-AUTH-1.3 : Sync Game Center
✅ UC-AUTH-1.4 : Gestion confidentialité

Service Subscription (3002)

✅ UC-SUB-2.1 : Souscription abonnement
✅ UC-SUB-2.2 : Restriction contenu premium
✅ UC-SUB-2.3 : Annulation abonnement
✅ UC-SUB-2.4 : Utilisation crédits

Service Offline (3003)

✅ UC-OFFLINE-3.1 : Téléchargement contenu offline
✅ UC-OFFLINE-3.2 : Synchronisation automatique
✅ UC-OFFLINE-3.3 : Jeu hors-ligne avec queue
✅ UC-OFFLINE-3.4 : Mise à jour géolocalisation
✅ UC-OFFLINE-3.5 : Résolution conflit manuel
✅ UC-OFFLINE-3.6 : Gestion stockage local

Service Ads (3004)

✅ UC-ADS-4.1 : Visionner pub rewarded
✅ UC-ADS-4.2 : Affichage pub interstitielle
✅ UC-ADS-4.3 : Gestion consent (GDPR/ATT)
✅ UC-ADS-4.4 : Participation campagne freemium
✅ UC-ADS-4.5 : Analytics revenus (Admin)