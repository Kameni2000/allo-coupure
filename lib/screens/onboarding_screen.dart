// Fichier: lib/screens/onboarding_screen.dart
import 'package:allo_coupure/auth_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:page_transition/page_transition.dart';
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  // Fonction appelée quand l'utilisateur termine la présentation
  void _onIntroEnd(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    // On sauvegarde le fait que l'utilisateur a vu l'accueil
    await prefs.setBool('hasSeenOnboarding', true);
    Navigator.pushAndRemoveUntil(
    context,
    PageTransition(
      type: PageTransitionType.rightToLeft, // C'est ici qu'on choisit l'animation
      child: const AuthWrapper(),
    ),
    (route) => false,
  );
  }

  @override
  Widget build(BuildContext context) {
    const pageDecoration = PageDecoration(
      titleTextStyle: TextStyle(fontSize: 28.0, fontWeight: FontWeight.w700),
      bodyTextStyle: TextStyle(fontSize: 19.0),
      bodyPadding: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      pageColor: Colors.white,
      imagePadding: EdgeInsets.zero,
    );

    return IntroductionScreen(
      pages: [
        PageViewModel(
          title: "Bienvenue sur Allo Coupure",
          body: "L'application communautaire pour suivre les coupures d'eau et d'électricité au Cameroun.",
          image: const Center(child: Icon(Icons.power_off, size: 100.0, color: Colors.orange)),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "Signalez en temps réel",
          body: "Vous subissez une coupure ? Signalez-la en un clic pour alerter votre communauté.",
          image: const Center(child: Icon(Icons.add_alert, size: 100.0, color: Colors.orange)),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "Confirmez et soyez informé",
          body: "Voyez les pannes signalées par d'autres et confirmez-les pour augmenter la fiabilité des alertes.",
          image: const Center(child: Icon(Icons.map, size: 100.0, color: Colors.orange)),
          decoration: pageDecoration,
        ),
      ],
      onDone: () => _onIntroEnd(context),
      onSkip: () => _onIntroEnd(context), // L'utilisateur peut aussi passer
      showSkipButton: true,
      skip: const Text('Passer'),
      next: const Icon(Icons.arrow_forward),
      done: const Text('Terminé', style: TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}