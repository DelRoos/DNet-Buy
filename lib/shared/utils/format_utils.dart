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

  static String formatValidityHours(int hours) {
    if (hours < 24) {
      return '$hours ${hours > 1 ? 'heures' : 'heure'}';
    } else if (hours < 168) {
      // Moins d'une semaine (24*7)
      final days = hours ~/ 24;
      final remainingHours = hours % 24;
      if (remainingHours == 0) {
        return '$days ${days > 1 ? 'jours' : 'jour'}';
      } else {
        return '$days ${days > 1 ? 'jours' : 'jour'} et $remainingHours ${remainingHours > 1 ? 'heures' : 'heure'}';
      }
    } else if (hours < 720) {
      // Moins d'un mois (24*30)
      final weeks = hours ~/ 168;
      final remainingDays = (hours % 168) ~/ 24;
      if (remainingDays == 0) {
        return '$weeks ${weeks > 1 ? 'semaines' : 'semaine'}';
      } else {
        return '$weeks ${weeks > 1 ? 'semaines' : 'semaine'} et $remainingDays ${remainingDays > 1 ? 'jours' : 'jour'}';
      }
    } else {
      final months = hours ~/ 720;
      final remainingWeeks = (hours % 720) ~/ 168;
      if (remainingWeeks == 0) {
        return '$months ${months > 1 ? 'mois' : 'mois'}';
      } else {
        return '$months ${months > 1 ? 'mois' : 'mois'} et $remainingWeeks ${remainingWeeks > 1 ? 'semaines' : 'semaine'}';
      }
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
