// Fichier: lib/screens/profile_screen.dart
import 'package:allo_coupure/data/locations.dart';
import 'package:allo_coupure/providers/theme_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  String? _selectedCity;
  String? _selectedQuartier;
  List<String> _quartiersForSelectedCity = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        _usernameController.text = data['pseudonyme'] ?? '';
        _selectedCity = data['ville'];
        _selectedQuartier = data['quartier'];
        if (_selectedCity != null) {
          _quartiersForSelectedCity = villesEtQuartiers[_selectedCity!] ?? [];
        }
      }
    }
    setState(() { _isLoading = false; });
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; });
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'pseudonyme': _usernameController.text,
          'ville': _selectedCity,
          'quartier': _selectedQuartier,
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profil mis à jour !")),
          );
          Navigator.of(context).pop();
        }
      }
    }
     setState(() { _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    // On récupère le provider de thème
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Mon Profil")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20.0),
                children: [
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(labelText: "Pseudonyme"),
                    validator: (value) => value!.isEmpty ? 'Champ requis' : null,
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: _selectedCity,
                    hint: const Text("Choisissez votre ville"),
                    onChanged: (value) {
                      setState(() {
                        _selectedCity = value;
                        _selectedQuartier = null;
                        _quartiersForSelectedCity = villesEtQuartiers[value!] ?? [];
                      });
                    },
                    items: villesEtQuartiers.keys.map((city) => DropdownMenuItem(value: city, child: Text(city))).toList(),
                    validator: (value) => value == null ? 'Champ requis' : null,
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: _selectedQuartier,
                    hint: const Text("Choisissez votre quartier"),
                    onChanged: (value) => setState(() => _selectedQuartier = value),
                    items: _quartiersForSelectedCity.map((quartier) => DropdownMenuItem(value: quartier, child: Text(quartier))).toList(),
                    validator: (value) => value == null ? 'Champ requis' : null,
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _updateProfile,
                    child: const Text("Mettre à jour le profil"),
                  ),
                  const Divider(height: 40),
                  // ON AJOUTE L'INTERRUPTEUR POUR LE THÈME
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Mode Sombre", style: TextStyle(fontSize: 16)),
                      Switch(
                        value: themeProvider.themeMode == ThemeMode.dark,
                        onChanged: (value) {
                          themeProvider.toggleTheme(value);
                        },
                      )
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}