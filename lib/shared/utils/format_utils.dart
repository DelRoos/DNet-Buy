// lib/shared/utils/format_utils.dart
import 'package:intl/intl.dart';

class FormatUtils {
  // Formater un montant en devise
  static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(symbol: 'XAF ', decimalDigits: 0);
    return formatter.format(amount);
  }

  // Formater une taille de données (MB)
  static String formatDataSize(int sizeInMB) {
    if (sizeInMB < 1024) {
      return '$sizeInMB MB';
    } else {
      final sizeInGB = sizeInMB / 1024;
      return '${sizeInGB.toStringAsFixed(1)} GB';
    }
  }

  // Formater une durée en minutes
  static String formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '$hours h';
      } else {
        return '$hours h $remainingMinutes min';
      }
    }
  }
}
