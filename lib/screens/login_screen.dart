// Fichier: lib/screens/login_screen.dart
import 'package:allo_coupure/screens/otp_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController phoneController = TextEditingController(text: "+1");
  bool isLoading = false;

  void _verifyPhoneNumber() async {
    setState(() {
      isLoading = true;
    });
    
    // NOTRE "ESPION" EST ICI
    print("--- Envoi de la demande pour le numéro : '${phoneController.text}' ---");

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneController.text.trim(), // On nettoie le numéro
      verificationCompleted: (PhoneAuthCredential credential) {
        setState(() { isLoading = false; });
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() { isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur : ${e.message}")),
        );
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() { isLoading = false; });
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpScreen(verificationId: verificationId),
            ),
          );
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Connexion"),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Entrez votre numéro de téléphone pour commencer",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            TextFormField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Numéro de téléphone",
                hintText: "+15551234567",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _verifyPhoneNumber,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text("Recevoir le code"),
                  ),
          ],
        ),
      ),
    );
  }
}