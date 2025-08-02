import 'package:get/get.dart';
import 'package:dnet_buy/features/auth/views/login_page.dart';
import 'package:dnet_buy/features/auth/views/register_page.dart';
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
  static const String login = '/login';
  static const String register = '/register';
  static const String buy = '/buy';
  static const String retrieveTicket = '/retrieve-ticket';

  static const String dashboard = '/dashboard';
  static const String addZone = '/dashboard/zones/add';
  static String addTicketType(String zoneId) =>
      '/dashboard/zones/$zoneId/add-ticket';
  static String ticketManagement(String zoneId, String typeId) =>
      '/dashboard/zones/$zoneId/ticket-types/$typeId';

  static const String dashboardZones = '/dashboard/zones';
  static const String dashboardTransactions = '/dashboard/transactions';
  static const String dashboardSettings = '/dashboard/settings';
  static String zoneDetails(String zoneId) => '/dashboard/zones/$zoneId';

  static const String portal = '/portal';
}

class AppPages {
  static final routes = [
    GetPage(name: AppRoutes.login, page: () => const LoginPage()),
    GetPage(name: AppRoutes.register, page: () => const RegisterPage()),
    GetPage(name: AppRoutes.dashboard, page: () => const DashboardPage()),
    GetPage(name: AppRoutes.dashboardZones, page: () => const ZonesPage()),
    GetPage(name: AppRoutes.addZone, page: () => const AddZonePage()),
    GetPage(name: AppRoutes.portal, page: () => const PortalPage()),

    GetPage(
      name: AppRoutes.retrieveTicket,
      page: () => const TicketRetrievalPage(),
    ),
    GetPage(
      name: '/dashboard/zones/:zoneId',
      page: () => const ZoneDetailsPage(),
      binding: BindingsBuilder(() {
        final zoneId = Get.parameters['zoneId']!;
        Get.lazyPut<ZoneDetailsController>(
          () => ZoneDetailsController(zoneId: zoneId),
        );
      }),
    ),
    GetPage(
      name: '/dashboard/zones/:zoneId/add-ticket',
      page: () => const AddTicketTypePage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<AddTicketTypeController>(
          () => AddTicketTypeController(zoneId: Get.parameters['zoneId']!),
        );
      }),
    ),
    GetPage(
      name: '/dashboard/zones/:zoneId/ticket-types/:typeId',
      page: () => const TicketManagementPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<TicketManagementController>(
          () => TicketManagementController(
            zoneId: Get.parameters['zoneId']!,
            ticketTypeId: Get.parameters['typeId']!,
          ),
        );
      }),
    ),
    GetPage(
      name: AppRoutes.dashboardTransactions,
      page: () => const TransactionHistoryPage(),
    ),
    GetPage(
      name: AppRoutes.dashboardSettings,
      page: () => const SettingsPage(),
    ),
  ];
}
