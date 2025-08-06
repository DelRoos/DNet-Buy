import 'package:dnet_buy/app/middleware/public_middleware.dart';
import 'package:dnet_buy/features/zones/controllers/add_zone_controller.dart';
import 'package:get/get.dart';
import 'package:dnet_buy/app/middleware/auth_middleware.dart';
import 'package:dnet_buy/features/auth/views/login_page.dart';
import 'package:dnet_buy/features/auth/views/register_page.dart';
import 'package:dnet_buy/features/auth/views/email_verification_page.dart';
import 'package:dnet_buy/features/auth/views/forgot_password_page.dart';
import 'package:dnet_buy/features/auth/views/splash_screen.dart';
import 'package:dnet_buy/features/dashboard/views/dashboard_page.dart';
import 'package:dnet_buy/features/portal/views/portal_page.dart';
import 'package:dnet_buy/features/settings/views/settings_page.dart';
import 'package:dnet_buy/features/ticket_retrieval/views/ticket_retrieval_page.dart';
import 'package:dnet_buy/features/transactions/views/transaction_history_page.dart';
import 'package:dnet_buy/features/zones/controllers/add_ticket_type_controller.dart';
import 'package:dnet_buy/features/zones/controllers/ticket_management_controller.dart';
import 'package:dnet_buy/features/zones/controllers/zone_details_controller.dart';
import 'package:dnet_buy/features/zones/views/add_ticket_type_page.dart';
import 'package:dnet_buy/features/zones/views/add_zone_page.dart';
import 'package:dnet_buy/features/zones/views/ticket_management_page.dart';
import 'package:dnet_buy/features/zones/views/zone_details_page.dart';
import 'package:dnet_buy/features/zones/views/zones_page.dart';

class AppRoutes {
  // Routes publiques
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String buy = '/buy';
  static const String retrieveTicket = '/retrieve-ticket';

  // Routes d'authentification
  static const String emailVerification = '/email-verification';

  // Routes protégées
  static const String dashboard = '/dashboard';
  static const String dashboardZones = '/dashboard/zones';
  static const String dashboardTransactions = '/dashboard/transactions';
  static const String dashboardSettings = '/dashboard/settings';
  static const String addZone = '/dashboard/zones/add';

  // Routes dynamiques
  static String addTicketType(String zoneId) =>
      '/dashboard/zones/$zoneId/add-ticket';
  static String ticketManagement(String zoneId, String typeId) =>
      '/dashboard/zones/$zoneId/ticket-types/$typeId';
  static String zoneDetails(String zoneId) => '/dashboard/zones/$zoneId';

  // Routes portail client
  static const String portal = '/portal';
}

class AppPages {
  static final routes = [
    // Route de démarrage
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
    ),

    // Routes publiques (guest only)
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginPage(),
      middlewares: [GuestOnlyMiddleware()],
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterPage(),
      middlewares: [GuestOnlyMiddleware()],
    ),
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const ForgotPasswordPage(),
      middlewares: [GuestOnlyMiddleware()],
    ),

    // Routes d'authentification
    GetPage(
      name: AppRoutes.emailVerification,
      page: () => const EmailVerificationPage(),
      middlewares: [AuthMiddleware()],
    ),

    GetPage(
      name: '/dashboard/zones/:zoneId/edit',
      page: () => const AddZonePage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<AddZoneController>(() => AddZoneController());
      }),
      middlewares: [AuthMiddleware()],
    ),

    GetPage(
      name: AppRoutes.dashboard,
      page: () => const DashboardPage(),
      middlewares: [AuthMiddleware(requireVerifiedEmail: true)],
    ),
    GetPage(
      name: AppRoutes.dashboardZones,
      page: () => const ZonesPage(),
      middlewares: [AuthMiddleware(requireVerifiedEmail: true)],
    ),
    GetPage(
      name: AppRoutes.addZone,
      page: () => const AddZonePage(),
      middlewares: [AuthMiddleware(requireVerifiedEmail: true)],
    ),
    GetPage(
      name: AppRoutes.dashboardTransactions,
      page: () => const TransactionHistoryPage(),
      middlewares: [AuthMiddleware(requireVerifiedEmail: true)],
    ),
    GetPage(
      name: AppRoutes.dashboardSettings,
      page: () => const SettingsPage(),
      middlewares: [AuthMiddleware(requireVerifiedEmail: true)],
    ),

    // Routes dynamiques protégées
    GetPage(
      name: '/dashboard/zones/:zoneId',
      page: () => const ZoneDetailsPage(),
      middlewares: [AuthMiddleware(requireVerifiedEmail: true)],
      binding: BindingsBuilder(() {
        final zoneId = Get.parameters['zoneId']!;
        Get.lazyPut<ZoneDetailsController>(
          () => ZoneDetailsController(zoneId: zoneId),
        );
      }),
    ),
    // Route pour créer un nouveau type de ticket
    GetPage(
      name: '/dashboard/zones/:zoneId/tickets/add',
      page: () => const AddTicketTypePage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<AddTicketTypeController>(() => AddTicketTypeController());
      }),
      middlewares: [AuthMiddleware()],
    ),

// Ajouter cette route pour l'édition des tickets
    GetPage(
      name: '/dashboard/zones/:zoneId/tickets/:ticketTypeId/edit',
      page: () => const AddTicketTypePage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<AddTicketTypeController>(() => AddTicketTypeController());
      }),
      middlewares: [AuthMiddleware()],
    ),

    GetPage(
      name: '/dashboard/zones/:zoneId/tickets/:typeId/manage',
      page: () => const TicketManagementPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<TicketManagementController>(
            () => TicketManagementController(
                  zoneId: Get.parameters['zoneId']!,
                  ticketTypeId: Get.parameters['typeId'],
                ));
      }),
      middlewares: [AuthMiddleware()],
    ),

// Route pour la gestion de tous les tickets d'une zone
    GetPage(
      name: '/dashboard/zones/:zoneId/tickets/manage',
      page: () => const TicketManagementPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<TicketManagementController>(
            () => TicketManagementController(
                  zoneId: Get.parameters['zoneId']!,
                ));
      }),
      middlewares: [AuthMiddleware()],
    ),

    // Routes publiques (portail client)
    GetPage(
      name: AppRoutes.portal,
      page: () => const PortalPage(),
      middlewares: [PublicMiddleware()],
    ),
    GetPage(
      name: AppRoutes.retrieveTicket,
      page: () => const TicketRetrievalPage(),
      middlewares: [PublicMiddleware()],
    ),
  ];
}
