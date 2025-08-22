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
      TransactionModel.fromLegacy(
        id: 'a67691ed',
        status: TransactionStatus.completed,
        amount: 1000,
        buyerPhoneNumber: '699112233',
        transactionDate: DateTime.now().subtract(const Duration(hours: 1)),
        ticketUsername: 'user-abc1',
        ticketTypeName: 'Pass Journée',
      ),
      TransactionModel.fromLegacy(
        id: 'cecb550c',
        status: TransactionStatus.failed,
        amount: 500,
        buyerPhoneNumber: '677445566',
        transactionDate: DateTime.now().subtract(const Duration(hours: 2)),
        ticketUsername: 'N/A',
        ticketTypeName: 'Forfait Soirée',
      ),
      TransactionModel.fromLegacy(
        id: 'b4766726',
        status: TransactionStatus.completed,
        amount: 200,
        buyerPhoneNumber: '655889900',
        transactionDate: DateTime.now().subtract(const Duration(hours: 3)),
        ticketUsername: 'user-xyz9',
        ticketTypeName: 'Boost 1 Heure',
      ),
      TransactionModel.fromLegacy(
        id: 'd1e2f3g4',
        status: TransactionStatus.completed,
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

  Color getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.completed:
        return Colors.green;
      case TransactionStatus.failed:
        return Colors.red;
      case TransactionStatus.expired:
        return Colors.orange;
      case TransactionStatus.pending:
        return Colors.blue;
      case TransactionStatus.created:
        return Colors.grey;
    }
  }

  IconData getStatusIcon(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.completed:
        return Icons.check_circle;
      case TransactionStatus.failed:
        return Icons.cancel;
      case TransactionStatus.expired:
        return Icons.access_time;
      case TransactionStatus.pending:
        return Icons.hourglass_empty;
      case TransactionStatus.created:
        return Icons.radio_button_unchecked;
    }
  }
}
