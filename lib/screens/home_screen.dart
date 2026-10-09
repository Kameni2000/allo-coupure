// Fichier: lib/screens/home_screen.dart

import 'dart:async';

import 'package:allo_coupure/providers/theme_provider.dart';
import 'package:allo_coupure/screens/login_screen.dart';
import 'package:allo_coupure/screens/profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();
  final List<Marker> _markers = [];
  StreamSubscription? _pannesSubscription;

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('fr', timeago.FrMessages());
    _centerMapOnProfileLocation();
    _listenToPannes();
  }

  @override
  void dispose() {
    _pannesSubscription?.cancel();
    super.dispose();
  }

  void _centerMapOnProfileLocation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;
        final String? ville = data['ville'];
        final String? quartier = data['quartier'];
        if (ville != null && quartier != null) {
          final String address = "$quartier, $ville, Cameroun";
          List<Location> locations = await locationFromAddress(address);
          if (locations.isNotEmpty) {
            final location = locations.first;
            _mapController.move(
                LatLng(location.latitude, location.longitude), 13.0);
          }
        }
      }
    } catch (e) {
      // Gérer l'erreur si besoin
    }
  }

  void _listenToPannes() {
    final twentyFourHoursAgo =
        DateTime.now().subtract(const Duration(hours: 24));
    _pannesSubscription = FirebaseFirestore.instance
        .collection('pannes')
        .where('timestamp', isGreaterThan: twentyFourHoursAgo)
        .snapshots()
        .listen((querySnapshot) {
      final List<Marker> loadedMarkers = [];
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        if (data['position'] != null &&
            data['type'] != null &&
            data['timestamp'] != null) {
          final String panneId = doc.id;
          final GeoPoint position = data['position'];
          final String type = data['type'];
          final Timestamp timestamp = data['timestamp'];
          final List<dynamic> confirmations = data['confirmations'] ?? [];

          loadedMarkers.add(
            Marker(
              width: 80.0,
              height: 80.0,
              point: LatLng(position.latitude, position.longitude),
              child: GestureDetector(
                onTap: () {
                  _showMarkerDetails(
                      panneId, type, timestamp, confirmations, position);
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      type == 'electricite'
                          ? Icons.flash_on
                          : Icons.water_drop,
                      color: type == 'electricite'
                          ? Colors.amber[700]
                          : Colors.blue[700],
                      size: 40.0,
                      shadows: const [
                        Shadow(color: Colors.black, blurRadius: 15.0)
                      ],
                    ),
                    if (confirmations.length > 1)
                      Positioned(
                        right: 15,
                        top: 15,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          constraints: const BoxConstraints(
                              minWidth: 18, minHeight: 18),
                          child: Text(
                            '${confirmations.length}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                  ],
                ),
              ),
            ),
          );
        }
      }
      if (mounted) {
        setState(() {
          _markers.clear();
          _markers.addAll(loadedMarkers);
        });
      }
    });
  }

  void _showMarkerDetails(String panneId, String type, Timestamp timestamp,
      List<dynamic> confirmations, GeoPoint position) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    String locationName = "Quartier inconnu";
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        locationName = "${placemark.subLocality}, ${placemark.locality}";
      }
    } catch (e) {}

    if (mounted) Navigator.of(context).pop();

    final DateTime date = timestamp.toDate();
    final String timeAgo = timeago.format(date, locale: 'fr');
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final bool hasConfirmed =
        currentUserId != null && confirmations.contains(currentUserId);

    if (mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Wrap(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type == 'electricite'
                          ? "Coupure d'Électricité ⚡"
                          : "Coupure d'Eau 💧",
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text("📍 Lieu : $locationName",
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 10),
                    Text("🕒 Signalé ${timeAgo}",
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 10),
                    Text("👍 Confirmé par ${confirmations.length} personne(s)",
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 20),
                    if (!hasConfirmed)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            _confirmCoupure(panneId);
                            Navigator.of(context).pop();
                          },
                          child: const Text("Confirmer cette panne"),
                        ),
                      ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          _reportRestoration(panneId);
                          Navigator.of(context).pop();
                        },
                        child: const Text("Signaler le retour du service"),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ],
            ),
          );
        },
      );
    }
  }

  void _reportRestoration(String? panneId) async {
    if (panneId == null) return;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final panneRef =
        FirebaseFirestore.instance.collection('pannes').doc(panneId);

    await panneRef.update({
      'restaurations': FieldValue.arrayUnion([userId])
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Merci d'avoir signalé le retour du service !")),
      );
    }
  }

  void _confirmCoupure(String panneId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    final panneRef =
        FirebaseFirestore.instance.collection('pannes').doc(panneId);
    await panneRef.update({
      'confirmations': FieldValue.arrayUnion([userId])
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Confirmation enregistrée ! Merci.")),
      );
    }
  }

  void _reportCoupure(String type) async {
    try {
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()));
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) Navigator.of(context).pop();
        return;
      }
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!userDoc.exists || userDoc.data() == null) {
        if (mounted) Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profil utilisateur introuvable.")),
        );
        return;
      }
      final userData = userDoc.data()!;
      final String ville = userData['ville'];
      final String quartier = userData['quartier'];
      LatLng positionDeLaPanne = _mapController.camera.center;
      try {
        final String address = "$quartier, $ville, Cameroun";
        List<Location> locations = await locationFromAddress(address);
        if (locations.isNotEmpty) {
          positionDeLaPanne =
              LatLng(locations.first.latitude, locations.first.longitude);
        }
      } catch (e) {}
      await FirebaseFirestore.instance.collection('pannes').add({
        'type': type,
        'position':
            GeoPoint(positionDeLaPanne.latitude, positionDeLaPanne.longitude),
        'timestamp': FieldValue.serverTimestamp(),
        'userId': user.uid,
        'confirmations': [user.uid],
        'ville': ville,
        'quartier': quartier,
      });
      if (mounted) Navigator.of(context).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Signalement envoyé avec succès !")),
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors du signalement : $e")),
        );
      }
    }
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Signaler une nouvelle panne"),
          content: const Text("Quel type de panne souhaitez-vous signaler ?"),
          actions: <Widget>[
            TextButton(
              child: const Text("Coupure d'Électricité ⚡"),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _reportCoupure('electricite');
              },
            ),
            TextButton(
              child: const Text("Coupure d'Eau 💧"),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _reportCoupure('eau');
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    const lightMapUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    const darkMapUrl = 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Allo Coupure - Carte"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          )
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: const MapOptions(
          initialCenter:
              LatLng(4.0511, 11.5213),
          initialZoom: 6.0,
        ),
        children: [
          TileLayer(
            urlTemplate: isDarkMode ? darkMapUrl : lightMapUrl,
            userAgentPackageName: 'com.example.allo_coupure',
            subdomains: const ['a', 'b', 'c'],
          ),
          MarkerLayer(markers: _markers),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showReportDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      