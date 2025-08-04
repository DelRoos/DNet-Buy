import 'package:get/get.dart';
import 'package:dnet_buy/app/controllers/auth_controller.dart';
import 'package:dnet_buy/app/services/merchant_service.dart';

class DashboardController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final MerchantService _merchantService = Get.find<MerchantService>();

  var totalRevenue = 0.obs;
  var ticketsSoldToday = 0.obs;
  var activeZones = 0.obs;
  var availableTickets = 0.obs;
  var isLoading = true.obs;

  // Getters
  String get userName => _authController.userName;

  @override
  void onInit() {
    super.onInit();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    try {
      isLoading.value = true;

      final uid = _authController.currentUser.value?.uid;
      if (uid == null) return;

      final stats = await _merchantService.getMerchantStats(uid);

      totalRevenue.value = stats['totalRevenue'] ?? 0;
      ticketsSoldToday.value = stats['ticketsSoldToday'] ?? 0;
      activeZones.value = stats['activeZones'] ?? 0;
      availableTickets.value = stats['availableTickets'] ?? 0;
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de charger les données');
    } finally {
      isLoading.value = false;
    }
  }

  void logout() {
    _authController.signOut();
  }
}
