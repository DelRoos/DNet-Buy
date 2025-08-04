import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dnet_buy/app/controllers/auth_controller.dart';

class AuthMiddleware extends GetMiddleware {
  final bool requireVerifiedEmail;

  AuthMiddleware({this.requireVerifiedEmail = false});

  @override
  RouteSettings? redirect(String? route) {
    final authController = Get.find<AuthController>();

    // Pas connecté
    if (!authController.isLoggedIn) {
      return const RouteSettings(name: '/login');
    }

    // Email non vérifié pour les routes sensibles
    if (requireVerifiedEmail && !authController.isEmailVerified) {
      return const RouteSettings(name: '/email-verification');
    }

    return null;
  }
}

class GuestOnlyMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final authController = Get.find<AuthController>();

    if (authController.isLoggedIn) {
      if (authController.isEmailVerified) {
        return const RouteSettings(name: '/dashboard');
      } else {
        return const RouteSettings(name: '/email-verification');
      }
    }

    return null;
  }
}
