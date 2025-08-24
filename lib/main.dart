// lib/main.dart - Solution temporaire
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:dnet_buy/app/bindings/app_bindings.dart';
import 'package:dnet_buy/app/config/router.dart';
import 'package:dnet_buy/app/config/theme.dart';
import 'package:dnet_buy/firebase_options.dart';

// Handler pour les messages reçus en background
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialiser Firebase pour ce handler
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  debugPrint('📱 Message reçu en background: ${message.messageId}');
  debugPrint('Titre: ${message.notification?.title}');
  debugPrint('Contenu: ${message.notification?.body}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialisation Firebase avec gestion d'erreur
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // ✅ Configuration du handler pour les messages en background
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    debugPrint('✅ Firebase initialisé avec succès');
  } catch (e) {
    debugPrint('❌ Erreur Firebase: $e');
  }

  runApp(const DNetApp());
}

class DNetApp extends StatelessWidget {
  const DNetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'DNet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.login,
      getPages: AppPages.routes,
      initialBinding: AppBindings(),
      defaultTransition: Transition.fadeIn,
    );
  }
}
