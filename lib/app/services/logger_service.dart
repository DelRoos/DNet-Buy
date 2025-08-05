import 'package:logger/logger.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';

class LoggerService extends GetxService {
  late final Logger _logger;

  // Niveau de log actuel
  Level _currentLevel = kDebugMode ? Level.debug : Level.warning;

  // Instance singleton
  static LoggerService get to => Get.find<LoggerService>();

  @override
  void onInit() {
    super.onInit();
    _initializeLogger();
  }

  void _initializeLogger() {
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 2, // Nombre de méthodes dans la stack trace
        errorMethodCount: 8, // Stack trace pour les erreurs
        lineLength: 120, // Largeur de ligne
        colors: true, // Couleurs dans la console
        printEmojis: true, // Emojis pour identifier les niveaux
        printTime: true, // Afficher l'heure
        noBoxingByDefault: false, // Encadrer les logs
      ),
      level: _currentLevel,
      filter: DevelopmentFilter(), // Filtre pour dev/prod
      output: ConsoleOutput(), // Sortie vers la console
    );
  }

  // Méthodes de logging améliorées avec category et data
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

  void wtf(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    String? category,
    Map<String, dynamic>? data,
  }) {
    final fullMessage = _buildMessage(message, category, data);
    _logger.f(fullMessage, error: error, stackTrace: stackTrace);
  }

  // Méthode helper pour construire le message avec catégorie et données
  String _buildMessage(
      String message, String? category, Map<String, dynamic>? data) {
    final parts = <String>[];

    // Ajouter la catégorie si présente
    if (category != null && category.isNotEmpty) {
      parts.add('[$category]');
    }

    // Ajouter le message principal
    parts.add(message);

    // Ajouter les données si présentes
    if (data != null && data.isNotEmpty) {
      final dataStr =
          data.entries.map((e) => '${e.key}: ${e.value}').join(', ');
      parts.add('| Data: {$dataStr}');
    }

    return parts.join(' ');
  }

  // Log avec données structurées
  void logEvent(String event, Map<String, dynamic>? data) {
    final dataStr = data != null
        ? data.entries.map((e) => '${e.key}: ${e.value}').join(', ')
        : 'No data';
    _logger.i('📊 Event: $event | Data: {$dataStr}');
  }

  // Log des requêtes API
  void logApiRequest(String method, String url, {Map<String, dynamic>? body}) {
    final bodyStr = body != null
        ? body.entries.map((e) => '${e.key}: ${e.value}').join(', ')
        : 'No body';
    _logger.d('🌐 API Request: $method $url | Body: {$bodyStr}');
  }

  void logApiResponse(String url, int statusCode, {dynamic body}) {
    if (statusCode >= 200 && statusCode < 300) {
      _logger.i('✅ API Response: $url - Status: $statusCode');
    } else {
      _logger.w('⚠️ API Response: $url - Status: $statusCode', error: body);
    }
  }

  // Log des actions utilisateur
  void logUserAction(String action, {Map<String, dynamic>? details}) {
    final detailsStr = details != null
        ? details.entries.map((e) => '${e.key}: ${e.value}').join(', ')
        : 'No details';
    _logger.i('👤 User Action: $action | Details: {$detailsStr}');
  }

  // Log de navigation
  void logNavigation(String route, {Map<String, dynamic>? params}) {
    final paramsStr = params != null
        ? params.entries.map((e) => '${e.key}: ${e.value}').join(', ')
        : 'No params';
    _logger.d('🧭 Navigation: $route | Params: {$paramsStr}');
  }

  // Changer le niveau de log dynamiquement
  void setLogLevel(Level level) {
    _currentLevel = level;
    _initializeLogger();
  }
}
