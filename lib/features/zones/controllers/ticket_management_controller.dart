import 'package:get/get.dart';
import 'package:dnet_buy/features/zones/models/ticket_model.dart';
import 'package:dnet_buy/features/zones/models/ticket_type_model.dart';

class TicketManagementController extends GetxController {
  final String zoneId;
  final String ticketTypeId;

  TicketManagementController({
    required this.zoneId,
    required this.ticketTypeId,
  });

  var isLoading = true.obs;
  var isUploading = false.obs;

  var ticketType = Rx<TicketTypeModel?>(null);

  var tickets = <TicketModel>[].obs;

  @override
  void onInit() {
    fetchData();
    super.onInit();
  }

  Future<void> fetchData() async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1));

    ticketType.value = TicketTypeModel(
      id: ticketTypeId,
      name: 'Pass Journée',
      description: 'Accès 24h',
      price: 1000,
      validity: '24 Heures',
      expirationAfterCreation: 30,
      nbMaxUtilisations: 1,
      isActive: true,
    );

    tickets.assignAll([
      TicketModel(
        id: 'tkt1',
        username: 'user-abc1',
        password: 'pwd-xyz2',
        status: 'sold',
        soldAt: DateTime.now().subtract(const Duration(days: 2, hours: 3)),
        firstUsedAt: DateTime.now().subtract(const Duration(days: 2, hours: 2)),
        buyerPhoneNumber: '237699112233',
        paymentReference: 'a67691ed-3185-4153-9ede-7dc62601a177',
      ),
      TicketModel(
        id: 'tkt2',
        username: 'user-def3',
        password: 'pwd-uvw4',
        status: 'sold',
        soldAt: DateTime.now().subtract(const Duration(hours: 5)),
        firstUsedAt: DateTime.now().subtract(
          const Duration(hours: 4, minutes: 30),
        ),
        buyerPhoneNumber: '237677445566',
        paymentReference: 'b4766726-ccbb-0000-b53c-0b387686a397',
      ),
      TicketModel(
        id: 'tkt3',
        username: 'user-ghi5',
        password: 'pwd-rst6',
        status: 'available',
      ),
      TicketModel(
        id: 'tkt4',
        username: 'user-jkl7',
        password: 'pwd-opq8',
        status: 'available',
      ),
    ]);

    isLoading.value = false;
  }

  Future<void> pickAndUploadCsv() async {
    isUploading.value = true;


    Get.snackbar('Simulation', 'Sélection du fichier CSV...');
    await Future.delayed(const Duration(seconds: 3));

    tickets.addAll([
      TicketModel(
        id: 'tkt5',
        username: 'new-user1',
        password: 'new-pwd1',
        status: 'available',
      ),
      TicketModel(
        id: 'tkt6',
        username: 'new-user2',
        password: 'new-pwd2',
        status: 'available',
      ),
    ]);

    isUploading.value = false;
    Get.snackbar(
      'Succès',
      'Les nouveaux tickets ont été importés.',
      backgroundColor: Get.theme.colorScheme.secondary,
    );
  }
}
