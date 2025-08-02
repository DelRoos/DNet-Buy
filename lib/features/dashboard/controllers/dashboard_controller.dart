import 'package:get/get.dart';

class DashboardController extends GetxController {
  var userName = ''.obs;
  var totalRevenue = 0.obs;
  var ticketsSoldToday = 0.obs;
  var activeZones = 0.obs;
  var availableTickets = 0.obs;

  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    isLoading.value = true;
    print("Fetching dashboard data...");

    await Future.delayed(const Duration(milliseconds: 1500));

    userName.value = 'Restaurant Le Gourmet';
    totalRevenue.value = 125500;
    ticketsSoldToday.value = 83;
    activeZones.value = 3;
    availableTickets.value = 1452;

    isLoading.value = false;
    print("Dashboard data loaded.");
  }

  void logout() {
    Get.offAllNamed('/login');
    Get.snackbar('Déconnexion', 'Vous avez été déconnecté avec succès.');
  }
}
