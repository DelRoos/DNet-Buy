import 'package:dnet_buy/app/middleware/public_middleware.dart';
import 'package:dnet_buy/app/services/portal_service.dart';
import 'package:dnet_buy/features/portal/controllers/portal_controller.dart';
import 'package:dnet_buy/features/user_ticket/controllers/user_tickets_controller.dart';
import 'package:dnet_buy/features/user_ticket/views/user_tickets_page.dart';
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
  static const String portal = '/portal'; // La page de paiement publique
  static const String retrieveTicket = '/retrieve-ticket';

  // Routes d'authentification
  static const String emailVerification = '/email-verification';

  // Routes protégées (Dashboard)
  static const String dashboard = '/dashboard';
  static const String dashboardZones = '/dashboard/zones';
  static const String dashboardTransactions = '/dashboard/transactions';
  static const String dashboardSettings = '/dashboard/settings';
  static const String addZone = '/dashboard/zones/add';

  // Routes dynamiques protégées (utilisent des paramètres)
  static String zoneDetails(String zoneId) => '/dashboard/zones/$zoneId';
  static String editZone(String zoneId) => '/dashboard/zones/$zoneId/edit';
  static String addTicketType(String zoneId) =>
      '/dashboard/zones/$zoneId/tickets/add';
  static String editTicketType(String zoneId, String ticketTypeId) =>
      '/dashboard/zones/$zoneId/tickets/$ticketTypeId/edit';
  static String manageTicketType(String zoneId, String typeId) =>
      '/dashboard/zones/$zoneId/tickets/$typeId/manage';
  static String manageAllTickets(String zoneId) =>
      '/dashboard/zones/$zoneId/tickets/manage';
      static const userTickets = '/user-tickets';
}

class AppPages {
  static final routes = [
    // --- ROUTES PUBLIQUES ---
    GetPage(name: AppRoutes.splash, page: () => const SplashScreen()),
    GetPage(
        name: AppRoutes.login,
        page: () => const LoginPage(),
        middlewares: [GuestOnlyMiddleware()]),
    GetPage(
        name: AppRoutes.register,
        page: () => const RegisterPage(),
        middlewares: [GuestOnlyMiddleware()]),
    GetPage(
        name: AppRoutes.forgotPassword,
        page: () => const ForgotPasswordPage(),
        middlewares: [GuestOnlyMiddleware()]),

    // Page de paiement publique
    GetPage(
      name: AppRoutes.portal,
      page: () => const PortalPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<PortalService>(() => PortalService());
        Get.lazyPut<PortalController>(() => PortalController());
      }),
      middlewares: [PublicMiddleware()],
    ),

    // Page de récupération de ticket
    GetPage(
      name: AppRoutes.retrieveTicket,
      page: () => const TicketRetrievalPage(),
      middlewares: [PublicMiddleware()],
    ),

    // --- ROUTES D'AUTHENTIFICATION ---
    GetPage(
        name: AppRoutes.emailVerification,
        page: () => const EmailVerificationPage(),
        middlewares: [AuthMiddleware()]),
GetPage(
  name: AppRoutes.userTickets,
  page: () => const UserTicketsPage(),
  binding: BindingsBuilder(() {
    Get.lazyPut(() => UserTicketsController());
  }),
        middlewares: [AuthMiddleware()],
),

    // --- ROUTES PROTÉGÉES (DASHBOARD) ---
    GetPage(
        name: AppRoutes.dashboard,
        page: () => const DashboardPage(),
        middlewares: [AuthMiddleware(requireVerifiedEmail: true)]),
    GetPage(
        name: AppRoutes.dashboardZones,
        page: () => const ZonesPage(),
        middlewares: [AuthMiddleware(requireVerifiedEmail: true)]),
    GetPage(
        name: AppRoutes.dashboardTransactions,
        page: () => const TransactionHistoryPage(),
        middlewares: [AuthMiddleware(requireVerifiedEmail: true)]),
    GetPage(
        name: AppRoutes.dashboardSettings,
        page: () => const SettingsPage(),
        middlewares: [AuthMiddleware(requireVerifiedEmail: true)]),

    // Ajout/Édition de Zone
    GetPage(
        name: AppRoutes.addZone,
        page: () => const AddZonePage(),
        binding: BindingsBuilder(
            () => Get.lazyPut<AddZoneController>(() => AddZoneController())),
        middlewares: [AuthMiddleware(requireVerifiedEmail: true)]),
    GetPage(
      name: '/dashboard/zones/:zoneId/edit',
      page: () => const AddZonePage(),
      binding: BindingsBuilder(
          () => Get.lazyPut<AddZoneController>(() => AddZoneController())),
      middlewares: [AuthMiddleware(requireVerifiedEmail: true)],
    ),

    // Détails de Zone
    GetPage(
      name: '/dashboard/zones/:zoneId',
      page: () => const ZoneDetailsPage(),
      middlewares: [AuthMiddleware(requireVerifiedEmail: true)],
      binding: BindingsBuilder(() {
        final zoneId = Get.parameters['zoneId']!;
        Get.lazyPut<ZoneDetailsController>(
            () => ZoneDetailsController(zoneId: zoneId));
      }),
    ),

    // Ajout/Édition de Type de Ticket
    GetPage(
      name: '/dashboard/zones/:zoneId/tickets/add',
      page: () => const AddTicketTypePage(),
      binding: BindingsBuilder(() => Get.lazyPut<AddTicketTypeController>(
          () => AddTicketTypeController())),
      middlewares: [AuthMiddleware(requireVerifiedEmail: true)],
    ),
    GetPage(
      name: '/dashboard/zones/:zoneId/tickets/:ticketTypeId/edit',
      page: () => const AddTicketTypePage(),
      binding: BindingsBuilder(() => Get.lazyPut<AddTicketTypeController>(
          () => AddTicketTypeController())),
      middlewares: [AuthMiddleware(requireVerifiedEmail: true)],
    ),

    // Gestion des Tickets
    GetPage(
      name:
          '/dashboard/zones/:zoneId/tickets/manage', // Tous les tickets d'une zone
      page: () => const TicketManagementPage(),
      binding: BindingsBuilder(() => Get.lazyPut<TicketManagementController>(
          () => TicketManagementController(zoneId: Get.parameters['zoneId']!))),
      middlewares: [AuthMiddleware(requireVerifiedEmail: true)],
    ),
    GetPage(
      name:
          '/dashboard/zones/:zoneId/tickets/:typeId/manage', // Tickets d'un type spécifique
      page: () => const TicketManagementPage(),
      binding: BindingsBuilder(() => Get.lazyPut<TicketManagementController>(
          () => TicketManagementController(
              zoneId: Get.parameters['zoneId']!,
              ticketTypeId: Get.parameters['typeId']))),
      middlewares: [AuthMiddleware(requireVerifiedEmail: true)],
    ),
  ];
}
