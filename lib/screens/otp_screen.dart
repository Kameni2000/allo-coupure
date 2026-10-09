// Fichier: lib/screens/otp_screen.dart
import 'package:allo_coupure/screens/create_profile_screen.dart';
import 'package:allo_coupure/screens/home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

class OtpScreen extends StatefulWidget {
  final String verificationId;
  const OtpScreen({super.key, required this.verificationId});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController otpController = TextEditingController();
  bool isLoading = false;

  void _verifyOtp() async {
    setState(() { isLoading = true; });

    // NOTRE DEUXIÈME "ESPION" EST ICI
    print("--- Tentative de vérification avec le code : '${otpController.text}' ---");

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: otpController.text.trim(), // On nettoie le code
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null && mounted) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          Navigator.pushAndRemoveUntil(
            context,
            PageTransition(
              type: PageTransitionType.fade, // C'est ici qu'on choisit l'animation
              child: const CreateProfileScreen(),
            ),
            (route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            PageTransition(
              type: PageTransitionType.fade, // C'est ici qu'on choisit l'animation
              child: const HomeScreen(),
            ),
            (route) => false,
          );
        }
      }
    } catch (e) {
      setState(() { isLoading = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Code invalide. Veuillez réessayer.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Vérification"),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Entrez le code reçu par SMS",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            TextFormField(
              controller: otpController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: "Code à 6 chiffres",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text("Vérifier"),
                  ),
          ],
        ),
      ),
    );
  }
}