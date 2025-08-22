import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:dnet_buy/features/zones/services/zone_transaction_service.dart';
import 'package:dnet_buy/features/transactions/models/transaction_model.dart';
import 'package:dnet_buy/features/zones/views/widgets/transaction_details_bottomsheet.dart';
import 'package:dnet_buy/app/services/logger_service.dart';

class GeneralStats {
  final int totalCount;
  final double totalAmount;
  final Map<TransactionStatus, int> statusCounts;
  final Map<TransactionStatus, double> statusAmounts;

  GeneralStats({
    required this.totalCount,
    required this.totalAmount,
    required this.statusCounts,
    required this.statusAmounts,
  });

  factory GeneralStats.empty() {
    return GeneralStats(
      totalCount: 0,
      totalAmount: 0.0,
      statusCounts: {},
      statusAmounts: {},
    );
  }
}

class FilteredStats {
  final int filteredCount;
  final double filteredAmount;

  FilteredStats({
    required this.filteredCount,
    required this.filteredAmount,
  });

  factory FilteredStats.empty() {
    return FilteredStats(
      filteredCount: 0,
      filteredAmount: 0.0,
    );
  }
}

class ZoneTransactionsController extends GetxController {
  final String zoneId;
  final String zoneName;

  ZoneTransactionsController({
    required this.zoneId,
    required this.zoneName,
  });

  final ZoneTransactionService _transactionService =
      Get.find<ZoneTransactionService>();
  final LoggerService _logger = LoggerService.to;

  // États réactifs
  var isLoading = false.obs;
  var isRefreshing = false.obs;
  var isLoadingMore = false.obs;
  var transactions = <TransactionModel>[].obs;
  var generalStats = Rx<GeneralStats>(GeneralStats.empty());
  var filteredStats = Rx<FilteredStats>(FilteredStats.empty());

  // Scroll controller pour détection automatique
  final ScrollController scrollController = ScrollController();

  // Filtres
  var selectedStatus = Rx<TransactionStatus?>(null);
  var selectedDateRange = Rx<DateTimeRange?>(null);
  var searchQuery = ''.obs;

  // Pagination
  var currentPage = 0.obs;
  var itemsPerPage = 20;
  var hasMoreData = true.obs;

  @override
  void onInit() {
    super.onInit();
    _logger.info(
        '🚀 ZoneTransactionsController initialisé pour zone: $zoneId ($zoneName)');
    _setupScrollListener();
    loadTransactions();
    loadGeneralStats();
  }

  /// Configuration du scroll listener pour chargement automatique
  void _setupScrollListener() {
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 200) {
        // Charger plus quand on arrive à 200px de la fin
        loadMoreTransactions();
      }
    });
  }

  /// Charger les transactions avec filtres côté serveur
  Future<void> loadTransactions({bool loadMore = false}) async {
    if ((isLoading.value || isLoadingMore.value) && !loadMore) return;

    try {
      if (loadMore) {
        isLoadingMore.value = true;
      } else {
        isLoading.value = true;
        currentPage.value = 0;
        transactions.clear();
        hasMoreData.value = true;
      }

      _logger.debug('Chargement des transactions - Page: ${currentPage.value}');

      // Préparer les paramètres de filtrage pour le serveur
      final queryParams = <String, dynamic>{
        'page': currentPage.value,
        'limit': itemsPerPage,
      };

      if (selectedStatus.value != null) {
        queryParams['status'] = selectedStatus.value!.name;
      }

      if (selectedDateRange.value != null) {
        queryParams['startDate'] =
            selectedDateRange.value!.start.toIso8601String();
        queryParams['endDate'] = selectedDateRange.value!.end.toIso8601String();
      }

      if (searchQuery.value.isNotEmpty) {
        queryParams['search'] = searchQuery.value;
      }

      final newTransactions = await _transactionService.getZoneTransactions(
        zoneId: zoneId,
        queryParams: queryParams,
      );

      if (loadMore) {
        transactions.addAll(newTransactions);
      } else {
        transactions.assignAll(newTransactions);
      }

      hasMoreData.value = newTransactions.length == itemsPerPage;
      currentPage.value++;

      calculateFilteredStats();

      _logger.info(
          '✅ ${newTransactions.length} transactions chargées (total: ${transactions.length})');
    } catch (e, stackTrace) {
      _logger.error('Erreur lors du chargement des transactions',
          error: e, stackTrace: stackTrace);

      Get.snackbar(
        'Erreur',
        'Impossible de charger les transactions: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  /// Rafraîchir les transactions
  Future<void> refreshTransactions() async {
    isRefreshing.value = true;
    await loadTransactions();
    isRefreshing.value = false;
  }

  /// Charger plus de transactions automatiquement
  Future<void> loadMoreTransactions() async {
    if (!hasMoreData.value || isLoading.value || isLoadingMore.value) return;
    await loadTransactions(loadMore: true);
  }

  /// Charger les statistiques générales (non filtrées)
  Future<void> loadGeneralStats() async {
    try {
      _logger.debug('Chargement des statistiques générales');

      final stats =
          await _transactionService.getZoneTransactionStats(zoneId: zoneId);

      generalStats.value = GeneralStats(
        totalCount: stats['totalCount'] ?? 0,
        totalAmount: (stats['totalAmount'] ?? 0).toDouble(),
        statusCounts: Map<TransactionStatus, int>.from(
            (stats['statusCounts'] ?? {}).map((key, value) => MapEntry(
                TransactionStatus.values.firstWhere(
                  (status) => status.name == key,
                  orElse: () => TransactionStatus.created,
                ),
                value as int))),
        statusAmounts: Map<TransactionStatus, double>.from(
            (stats['statusAmounts'] ?? {}).map((key, value) => MapEntry(
                TransactionStatus.values.firstWhere(
                  (status) => status.name == key,
                  orElse: () => TransactionStatus.created,
                ),
                (value as num).toDouble()))),
      );

      _logger.info(
          '✅ Statistiques générales chargées: ${stats['totalCount']} transactions');
    } catch (e, stackTrace) {
      _logger.error('Erreur lors du chargement des statistiques',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Calculer les statistiques des transactions filtrées
  void calculateFilteredStats() {
    final filtered = transactions.length;
    final filteredAmount =
        transactions.fold<double>(0.0, (sum, t) => sum + t.amount.toDouble());

    filteredStats.value = FilteredStats(
      filteredCount: filtered,
      filteredAmount: filteredAmount,
    );
  }

  /// Filtrer par statut (recharge depuis le serveur)
  void filterByStatus(TransactionStatus? status) {
    selectedStatus.value = status;
    currentPage.value = 0;
    transactions.clear();
    loadTransactions();
    _logger.debug('Filtre statut appliqué: ${status?.name ?? 'tous'}');
  }

  /// Filtrer par période (recharge depuis le serveur)
  void filterByDateRange(DateTimeRange? range) {
    selectedDateRange.value = range;
    currentPage.value = 0;
    transactions.clear();
    loadTransactions();
    _logger.debug('Filtre date appliqué: ${range?.start} - ${range?.end}');
  }

  /// Rechercher (recharge depuis le serveur)
  void search(String query) {
    searchQuery.value = query;
    currentPage.value = 0;
    transactions.clear();
    loadTransactions();
    _logger.debug('Recherche appliquée: "$query"');
  }

  /// Effacer tous les filtres
  void clearFilters() {
    selectedStatus.value = null;
    selectedDateRange.value = null;
    searchQuery.value = '';
    currentPage.value = 0;
    transactions.clear();
    loadTransactions();
    _logger.debug('Filtres effacés');
  }

  /// Afficher les détails d'une transaction en BottomSheet
  void showTransactionDetails(TransactionModel transaction) {
    _logger.logUserAction('view_transaction_details', details: {
      'transactionId': transaction.id,
      'zoneId': zoneId,
      'status': transaction.status.name,
    });

    Get.bottomSheet(
      TransactionDetailsBottomSheet(
        transaction: transaction,
        onCancelReservation: () => cancelReservation(transaction),
        onRefresh: () => refreshTransaction(transaction),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  /// Actualiser une transaction spécifique
  Future<void> refreshTransaction(TransactionModel transaction) async {
    try {
      final updated = await _transactionService.refreshTransaction(transaction);
      if (updated != null) {
        final index = transactions.indexWhere((t) => t.id == transaction.id);
        if (index != -1) {
          transactions[index] = updated;
          calculateFilteredStats();
        }
      }
    } catch (e) {
      _logger.error('Erreur lors de l\'actualisation de la transaction',
          error: e);
    }
  }

  /// Annuler la réservation d'un ticket
  Future<void> cancelReservation(TransactionModel transaction) async {
    // Vérifier si la réservation peut être annulée
    if (transaction.status != TransactionStatus.pending &&
        transaction.status != TransactionStatus.created) {
      Get.snackbar(
        'Impossible',
        'Cette transaction ne peut pas être annulée (statut: ${transaction.statusText})',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
      );
      return;
    }

    // Confirmation
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Annuler la réservation'),
        content: Text(
            'Êtes-vous sûr de vouloir annuler la réservation pour cette transaction ?\n\n'
            'Montant: ${transaction.formattedAmount}\n'
            'Client: ${transaction.buyerPhoneNumber}'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      _logger.debug(
          'Annulation de la réservation pour la transaction: ${transaction.id}');

      await _transactionService.cancelReservation(transaction.id);

      // Actualiser la transaction
      await refreshTransaction(transaction);

      Get.back(); // Fermer le BottomSheet

      Get.snackbar(
        'Succès',
        'Réservation annulée avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );

      _logger.logUserAction('cancel_reservation', details: {
        'transactionId': transaction.id,
        'zoneId': zoneId,
      });
    } catch (e, stackTrace) {
      _logger.error('Erreur lors de l\'annulation de la réservation',
          error: e, stackTrace: stackTrace);

      Get.snackbar(
        'Erreur',
        'Impossible d\'annuler la réservation: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  /// Formater une période pour l'affichage
  String formatDateRange(DateTimeRange? range) {
    if (range == null) return 'Toutes les dates';

    final formatter = DateFormat('dd/MM/yyyy');
    if (range.start.year == range.end.year &&
        range.start.month == range.end.month &&
        range.start.day == range.end.day) {
      return formatter.format(range.start);
    }
    return '${formatter.format(range.start)} - ${formatter.format(range.end)}';
  }

  /// Formater un montant
  String formatAmount(double amount) {
    final formatter = NumberFormat.decimalPattern('fr_FR');
    return '${formatter.format(amount)} XAF';
  }

  /// Obtenir les raccourcis de dates
  List<Map<String, dynamic>> getDateShortcuts() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return [
      {
        'label': 'Aujourd\'hui',
        'range': DateTimeRange(start: today, end: today),
      },
      {
        'label': 'Cette semaine',
        'range': DateTimeRange(
          start: today.subtract(Duration(days: now.weekday - 1)),
          end: today.add(Duration(days: 7 - now.weekday)),
        ),
      },
      {
        'label': 'Ce mois',
        'range': DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0),
        ),
      },
      {
        'label': '7 derniers jours',
        'range': DateTimeRange(
          start: today.subtract(const Duration(days: 6)),
          end: today,
        ),
      },
      {
        'label': '30 derniers jours',
        'range': DateTimeRange(
          start: today.subtract(const Duration(days: 29)),
          end: today,
        ),
      },
    ];
  }

  @override
  void onClose() {
    scrollController.dispose();
    _logger.debug('ZoneTransactionsController fermé pour zone: $zoneId');
    super.onClose();
  }
}
