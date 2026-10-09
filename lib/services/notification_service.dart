// Fichier: lib/services/notification_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    print("NotificationService: Début de initNotifications()");

    // Demander la permission à l'utilisateur
    final NotificationSettings settings = await _fcm.requestPermission();
    print("NotificationService: Statut de la permission : ${settings.authorizationStatus}");

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("NotificationService: Permission accordée. Tentative de récupération du token...");
      // Récupérer le "token" unique du téléphone
      final fcmToken = await _fcm.getToken();

      print("===== FCM TOKEN =====");
      print(fcmToken);
      print("=====================");

      // Sauvegarder ce token dans le profil de l'utilisateur sur Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && fcmToken != null) {
        print("NotificationService: Sauvegarde du token dans Firestore...");
        final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        await userDocRef.set({
          'fcmToken': fcmToken,
        }, SetOptions(merge: true));
        print("NotificationService: Token sauvegardé.");
      }
    } else {
      print("NotificationService: Permission pour les notifications refusée.");
    }
    
    print("NotificationService: Fin de initNotifications()");
  }
}