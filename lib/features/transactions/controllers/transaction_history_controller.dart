import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dnet_buy/features/transactions/models/transaction_model.dart';

class TransactionHistoryController extends GetxController {
  var isLoading = true.obs;

  var allTransactions = <TransactionModel>[].obs;

  var filteredTransactions = <TransactionModel>[].obs;

  var activeFilter = Rx<TransactionStatus?>(null);

  @override
  void onInit() {
    fetchTransactions();
    super.onInit();
  }

  Future<void> fetchTransactions() async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1));

    allTransactions.assignAll([
      TransactionModel(
        id: 'a67691ed',
        status: TransactionStatus.success,
        amount: 1000,
        buyerPhoneNumber: '699112233',
        transactionDate: DateTime.now().subtract(const Duration(hours: 1)),
        ticketUsername: 'user-abc1',
        ticketTypeName: 'Pass Journée',
      ),
      TransactionModel(
        id: 'cecb550c',
        status: TransactionStatus.failed,
        amount: 500,
        buyerPhoneNumber: '677445566',
        transactionDate: DateTime.now().subtract(const Duration(hours: 2)),
        ticketUsername: 'N/A',
        ticketTypeName: 'Forfait Soirée',
      ),
      TransactionModel(
        id: 'b4766726',
        status: TransactionStatus.success,
        amount: 200,
        buyerPhoneNumber: '655889900',
        transactionDate: DateTime.now().subtract(const Duration(hours: 3)),
        ticketUsername: 'user-xyz9',
        ticketTypeName: 'Boost 1 Heure',
      ),
      TransactionModel(
        id: 'd1e2f3g4',
        status: TransactionStatus.success,
        amount: 1000,
        buyerPhoneNumber: '699112233',
        transactionDate: DateTime.now().subtract(const Duration(days: 1)),
        ticketUsername: 'user-ghi5',
        ticketTypeName: 'Pass Journée',
      ),
    ]);

    applyFilter(null);
    isLoading.value = false;
  }

  void applyFilter(TransactionStatus? filter) {
    activeFilter.value = filter;
    if (filter == null) {
      filteredTransactions.assignAll(allTransactions);
    } else {
      filteredTransactions.assignAll(
        allTransactions.where((t) => t.status == filter).toList(),
      );
    }
  }

  Color getStatusColor(TransactionStatus status) =>
      status == TransactionStatus.success ? Colors.green : Colors.red;
  IconData getStatusIcon(TransactionStatus status) =>
      status == TransactionStatus.success ? Icons.check_circle : Icons.cancel;
}
