// lib/app/bindings/app_bindings.dart (mise à jour)
import 'package:dnet_buy/app/services/manual_sale_service.dart';
import 'package:dnet_buy/features/user_ticket/services/user_tickets_service.dart';
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
    // Ajouter dans la méthode dependencies()
    Get.lazyPut(() => UserTicketsService(), fenix: true);
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

    Get.lazyPut(() => ManualSaleService(), fenix: true);
    // Log de l'initialisation
    LoggerService.to
        .info('✅ Application bindings initialisés avec tous les services');
  }
}
