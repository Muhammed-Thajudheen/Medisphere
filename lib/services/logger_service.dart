import 'package:logger/logger.dart';

/// A centralized logging service for the app.
class LoggerService {
  // Create a singleton instance of the logger
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2, // Number of method calls to show in the log
      errorMethodCount: 8, // Number of method calls to show for errors
      lineLength: 50, // Length of each line in the log
      colors: true, // Enable colored output (disabled in production)
      printEmojis: true, // Enable emojis for log levels
      dateTimeFormat:
          DateTimeFormat.onlyTimeAndSinceStart, // Replaces `printTime`
    ),
  );

  /// Logs a debug message.
  static void debug(String message) {
    _logger.d(message);
  }

  /// Logs an informational message.
  static void info(String message) {
    _logger.i(message);
  }

  /// Logs a warning message.
  static void warning(String message) {
    _logger.w(message);
  }

  /// Logs an error message.
  static void error(String message, {dynamic error, StackTrace? stackTrace}) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
}
