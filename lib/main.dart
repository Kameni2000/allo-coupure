import 'package:allo_coupure/auth_wrapper.dart';
import 'package:allo_coupure/providers/theme_provider.dart';
import 'package:allo_coupure/screens/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_app_check/firebase_app_check.dart'; 
// 🔔 Plugin de notifications locales
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// 🔔 Canal de notifications (Android 8+)
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'default_channel',
  'Notifications',
  description: 'Ce canal est utilisé pour les alertes Allo Coupure',
  importance: Importance.high,
);

// 🔁 Gestion des notifications en arrière-plan
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  // Affiche le token de debug dans le terminal
  String? token = await FirebaseAppCheck.instance.getToken(true);
  print("🔥 App Check Debug Token: $token");
  
  await FirebaseAppCheck.instance.activate(
  androidProvider: AndroidProvider.debug,
    webProvider: ReCaptchaV3Provider('recaptcha-public-key'), // facultatif
  
);

  final notification = message.notification;
  if (notification != null) {
    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: Importance.high,
          icon: '@mipmap/launcher_icon',
        ),
      ),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // ✅ Créer le canal Android
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // ✅ Demander l'autorisation des notifications (Android 13+)
  await FirebaseMessaging.instance.requestPermission();

  // ✅ Gérer les messages reçus quand l'app est en arrière-plan
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // ✅ Vérifier si l'onboarding a été vu
  final prefs = await SharedPreferences.getInstance();
  final bool hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: MyApp(hasSeenOnboarding: hasSeenOnboarding),
    ),
  );
}

class MyApp extends StatefulWidget {
  final bool hasSeenOnboarding;
  const MyApp({super.key, required this.hasSeenOnboarding});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    // 🔐 Afficher le token FCM (utile pour tests)
    FirebaseMessaging.instance.getToken().then((token) {
      print('📟 Token FCM : $token');
    });

    // 🔔 Notifications reçues en foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        final notification = message.notification!;
        print('📲 Notification reçue : ${notification.title}');

        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              importance: Importance.high,
              icon: '@mipmap/launcher_icon',
            ),
          ),
        );

        final snackBar = SnackBar(
          content: Text(
            '${notification.title ?? ''} - ${notification.body ?? ''}',
          ),
          duration: const Duration(seconds: 4),
        );

        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Allo Coupure',
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: widget.hasSeenOnboarding
          ? const AuthWrapper()
          : const OnboardingScreen(),
    );
  }
}
