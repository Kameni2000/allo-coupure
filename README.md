# Allo Coupure — signaler les coupures d'électricité et d'eau

Application mobile Flutter de signalement collaboratif des coupures d'électricité et d'eau au Cameroun. Les habitants signalent une panne dans leur quartier, les voisins la confirment, et tout le quartier reçoit une notification quand la coupure commence puis quand le service revient.

## Fonctionnalités

- 📱 **Connexion par numéro de téléphone** (code SMS, Firebase Authentication).
- 🏘️ **Profil par ville et quartier** (Yaoundé, Douala, Bafoussam…), pour ne recevoir que les alertes qui concernent l'utilisateur.
- ⚡💧 **Signalement en un geste** : coupure d'électricité ou d'eau.
- 👍 **Confirmation par les voisins** : chaque panne affiche le nombre de personnes qui l'ont confirmée.
- ✅ **Retour du service** : la notification « service rétabli » ne part qu'après **au moins 2 confirmations**, pour éviter les fausses alertes.
- 🗺️ **Carte des pannes** avec OpenStreetMap (flutter_map), thème clair et sombre.
- 🔔 **Notifications push ciblées par quartier**, envoyées par des Cloud Functions, avec nettoyage automatique des jetons FCM invalides.
- 🛡️ **Firebase App Check** pour protéger le back-end des appels non autorisés.

## Stack technique

| Domaine | Technologies |
|---|---|
| Mobile | Flutter, Dart, Provider |
| Back-end | Firebase Cloud Functions (Node.js, v2 : déclencheurs Firestore, région europe-west3) |
| Données | Cloud Firestore |
| Authentification | Firebase Auth (téléphone / OTP), Firebase App Check |
| Notifications | Firebase Cloud Messaging, flutter_local_notifications |
| Carte | flutter_map (OpenStreetMap), Geolocator, Geocoding |

## Structure

```
lib/
  screens/     connexion, OTP, profil, carte et signalements
  data/        villes et quartiers
  providers/   thème clair / sombre
  services/    notifications
functions/
  index.js     alertes de panne et de retour du service
```

## Lancer le projet

1. Créer un projet Firebase et lancer `flutterfire configure` (génère `android/app/google-services.json`, voir `google-services.example.json`).
2. `flutter pub get` puis `flutter run`.
3. Cloud Functions : `cd functions && npm install && firebase deploy --only functions`.

> Les clés et fichiers de configuration Firebase ne sont pas publiés dans ce dépôt.

## Auteur

**Yvan Kameni** — Développeur full-stack Web & Mobile, Québec
[GitHub](https://github.com/Kameni2000) · [LinkedIn](https://www.linkedin.com/in/yvan-kameni-dev)
