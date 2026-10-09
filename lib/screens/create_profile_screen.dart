// Fichier: lib/screens/create_profile_screen.dart
import 'package:allo_coupure/data/locations.dart'; // Importer notre liste
import 'package:allo_coupure/screens/home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  bool _isLoading = false;

  // Variables pour gérer la sélection
  String? _selectedCity;
  String? _selectedQuartier;
  List<String> _quartiersForSelectedCity = [];

  void _saveProfile() async {
    if (_usernameController.text.isEmpty || _selectedCity == null || _selectedQuartier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez remplir tous les champs.")),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'pseudonyme': _usernameController.text,
          'ville': _selectedCity,
          'quartier': _selectedQuartier,
          'createdAt': FieldValue.serverTimestamp(),
          'numero': user.phoneNumber,
        });

        if (mounted) {
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
      setState(() { _isLoading = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur : $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Finaliser votre profil")),
      body: SingleChildScrollView( // Permet de faire défiler si le clavier cache les champs
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Choisissez un pseudonyme", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: "Pseudonyme",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              // LISTE DÉROULANTE POUR LES VILLES
              DropdownButtonFormField<String>(
                value: _selectedCity,
                hint: const Text("Choisissez votre ville"),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCity = newValue;
                    _selectedQuartier = null; // Réinitialise le quartier
                    _quartiersForSelectedCity = villesEtQuartiers[newValue!] ?? [];
                  });
                },
                items: villesEtQuartiers.keys.map<DropdownMenuItem<String>>((String city) {
                  return DropdownMenuItem<String>(
                    value: city,
                    child: Text(city),
                  );
                }).toList(),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              // LISTE DÉROULANTE POUR LES QUARTIERS
              DropdownButtonFormField<String>(
                value: _selectedQuartier,
                hint: const Text("Choisissez votre quartier"),
                onChanged: _selectedCity == null ? null : (String? newValue) { // Désactivé si aucune ville n'est choisie
                  setState(() {
                    _selectedQuartier = newValue;
                  });
                },
                items: _quartiersForSelectedCity.map<DropdownMenuItem<String>>((String quartier) {
                  return DropdownMenuItem<String>(
                    value: quartier,
                    child: Text(quartier),
                  );
                }).toList(),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _saveProfile,
                      child: const Text("Enregistrer et continuer"),
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}