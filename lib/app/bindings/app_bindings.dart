// lib/app/bindings/app_bindings.dart (mise à jour)
import 'package:get/get.dart';
import 'package:dnet_buy/app/controllers/auth_controller.dart';
import 'package:dnet_buy/app/services/auth_service.dart';
import 'package:dnet_buy/app/services/merchant_service.dart';
import 'package:dnet_buy/app/services/logger_service.dart';
import 'package:dnet_buy/app/services/advanced_logger_service.dart';
import 'package:dnet_buy/app/services/zone_service.dart';
import 'package:dnet_buy/app/services/ticket_type_service.dart';
import 'package:dnet_buy/app/services/ticket_service.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    // Logger (doit être initialisé en premier)
    Get.put<LoggerService>(LoggerService(), permanent: true);
    Get.put<AdvancedLoggerService>(AdvancedLoggerService(), permanent: true);

    // Services (permanents)
    Get.put<AuthService>(AuthService(), permanent: true);
    Get.put<MerchantService>(MerchantService(), permanent: true);
    Get.put<ZoneService>(ZoneService(), permanent: true);
    Get.put<TicketTypeService>(TicketTypeService(), permanent: true);
    Get.put<TicketService>(TicketService(), permanent: true);

    // Contrôleur d'authentification (permanent)
    Get.put<AuthController>(AuthController(), permanent: true);

    // Log de l'initialisation
    LoggerService.to
        .info('✅ Application bindings initialisés avec tous les services');
  }
}
