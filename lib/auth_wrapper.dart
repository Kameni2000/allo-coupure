// Fichier: lib/auth_wrapper.dart
import 'package:allo_coupure/screens/home_screen.dart';
import 'package:allo_coupure/screens/login_screen.dart';
import 'package:allo_coupure/services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        print("AuthWrapper: Vérification de la connexion...");
        // Si l'utilisateur est connecté
        if (snapshot.connectionState == ConnectionState.active && snapshot.hasData) {
          print("AuthWrapper: Utilisateur trouvé. Lancement des notifications et de HomeScreen.");
          // On initialise les notifications pour cet utilisateur
          NotificationService().initNotifications();
          return const HomeScreen();
        }
        // Sinon, on affiche l'écran de connexion
        print("AuthWrapper: Pas d'utilisateur. Lancement de LoginScreen.");
        return const LoginScreen();
      },
    );
  }
}