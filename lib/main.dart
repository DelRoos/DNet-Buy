// lib/main.dart - Solution temporaire
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:dnet_buy/app/bindings/app_bindings.dart';
import 'package:dnet_buy/app/config/router.dart';
import 'package:dnet_buy/app/config/theme.dart';
import 'package:dnet_buy/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ✅ Initialisation Firebase avec gestion d'erreur
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Erreur Firebase: $e');
    // Continuer sans Firebase pour le développement
    // await Firebase.initializeApp(); // Version par défaut
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