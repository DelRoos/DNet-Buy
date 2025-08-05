import 'package:logger/logger.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:collection';
import 'package:intl/intl.dart';

class LogEntry {
  final DateTime timestamp;
  final Level level;
  final String message;
  final String? error;
  final String? stackTrace;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.error,
    this.stackTrace,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'level': level.name,
        'message': message,
        'error': error,
        'stackTrace': stackTrace,
      };

  factory LogEntry.fromJson(Map<String, dynamic> json) => LogEntry(
        timestamp: DateTime.parse(json['timestamp']),
        level: Level.values.firstWhere((e) => e.name == json['level']),
        message: json['message'],
        error: json['error'],
        stackTrace: json['stackTrace'],
      );
}

class AdvancedLoggerService extends GetxService {
  late final Logger _logger;
  final GetStorage _storage = GetStorage('logs');
  final Queue<LogEntry> _logQueue = Queue<LogEntry>();
  final int _maxLogs = 1000; // Nombre max de logs en mémoire
  final int _maxStoredLogs = 5000; // Nombre max de logs stockés

  static AdvancedLoggerService get to => Get.find<AdvancedLoggerService>();

  @override
  void onInit() {
    super.onInit();
    _initializeLogger();
    _loadStoredLogs();
  }

  void _initializeLogger() {
    _logger = Logger(
      printer: _CustomPrinter(),
      output: _MultiOutput([
        ConsoleOutput(),
        _StorageOutput(this),
      ]),
      level: kDebugMode ? Level.debug : Level.warning,
    );
  }

  void _loadStoredLogs() {
    try {
      final stored = _storage.read<List>('logs') ?? [];
      for (var log in stored.take(_maxLogs)) {
        _logQueue.add(LogEntry.fromJson(log));
      }
    } catch (e) {
      print('Erreur lors du chargement des logs: $e');
    }
  }

  void _saveLog(LogEntry entry) {
    _logQueue.add(entry);

    // Limiter la taille de la queue
    while (_logQueue.length > _maxLogs) {
      _logQueue.removeFirst();
    }

    // Sauvegarder de manière asynchrone
    _saveToStorage();
  }

  Future<void> _saveToStorage() async {
    try {
      final logs = _logQueue.toList().map((e) => e.toJson()).toList();
      await _storage.write('logs', logs);
    } catch (e) {
      print('Erreur lors de la sauvegarde des logs: $e');
    }
  }

  // Méthodes de logging avec contexte
  void debug(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    String? category,
    Map<String, dynamic>? data,
  }) {
    final fullMessage = _buildMessage(message, category, data);
    _logger.d(fullMessage, error: error, stackTrace: stackTrace);
  }

  void info(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    String? category,
    Map<String, dynamic>? data,
  }) {
    final fullMessage = _buildMessage(message, category, data);
    _logger.i(fullMessage, error: error, stackTrace: stackTrace);
  }

  void warning(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    String? category,
    Map<String, dynamic>? data,
  }) {
    final fullMessage = _buildMessage(message, category, data);
    _logger.w(fullMessage, error: error, stackTrace: stackTrace);
  }

  void error(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    String? category,
    Map<String, dynamic>? data,
  }) {
    final fullMessage = _buildMessage(message, category, data);
    _logger.e(fullMessage, error: error, stackTrace: stackTrace);
  }

  String _buildMessage(
      String message, String? category, Map<String, dynamic>? data) {
    final parts = <String>[];
    if (category != null) parts.add('[$category]');
    parts.add(message);
    if (data != null && data.isNotEmpty) {
      parts.add('| Data: ${data.toString()}');
    }
    return parts.join(' ');
  }

  // Récupérer les logs
  List<LogEntry> getLogs({Level? level, String? filter}) {
    var logs = _logQueue.toList();

    if (level != null) {
      logs = logs.where((l) => l.level == level).toList();
    }

    if (filter != null && filter.isNotEmpty) {
      logs = logs
          .where((l) => l.message.toLowerCase().contains(filter.toLowerCase()))
          .toList();
    }

    return logs;
  }

  // Exporter les logs
  String exportLogs() {
    final buffer = StringBuffer();
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');

    for (var log in _logQueue) {
      buffer.writeln(
          '${formatter.format(log.timestamp)} [${log.level.name}] ${log.message}');
      if (log.error != null) {
        buffer.writeln('  Error: ${log.error}');
      }
      if (log.stackTrace != null) {
        buffer.writeln('  Stack: ${log.stackTrace}');
      }
    }

    return buffer.toString();
  }

  // Nettoyer les logs
  void clearLogs() {
    _logQueue.clear();
    _storage.remove('logs');
  }
}

// Printer personnalisé
class _CustomPrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) {
    final color = PrettyPrinter.defaultLevelColors[event.level]!;
    final emoji = PrettyPrinter.defaultLevelEmojis[event.level]!;
    final time = DateFormat('HH:mm:ss').format(DateTime.now());

    final messages = <String>[];
    messages.add(color('$emoji $time [${event.level.name}] ${event.message}'));

    if (event.error != null) {
      messages.add(color('Error: ${event.error}'));
    }

    if (event.stackTrace != null) {
      messages.add(color('Stack trace:\n${event.stackTrace}'));
    }

    return messages;
  }
}

// Output personnalisé pour stocker les logs
class _StorageOutput extends LogOutput {
  final AdvancedLoggerService _service;

  _StorageOutput(this._service);

  @override
  void output(OutputEvent event) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: event.level,
      message: event.lines.join('\n'),
    );
    _service._saveLog(entry);
  }
}

// Multi-output pour envoyer vers plusieurs destinations
class _MultiOutput extends LogOutput {
  final List<LogOutput> _outputs;

  _MultiOutput(this._outputs);

  @override
  void output(OutputEvent event) {
    for (var output in _outputs) {
      output.output(event);
    }
  }
}
