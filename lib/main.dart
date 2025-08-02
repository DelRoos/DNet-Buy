// lib/main.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dnet_buy/app/bindings/app_bindings.dart';
import 'package:dnet_buy/app/config/router.dart';
import 'package:dnet_buy/app/config/theme.dart';

void main() {
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
    );
  }
}
