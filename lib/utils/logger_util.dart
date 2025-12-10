import 'dart:developer' as developer;
import 'package:logging/logging.dart';

class LoggerUtil {
  static final Logger _logger = Logger('DesperdicioZero');
  static bool _isInitialized = false;

  static void initialize() {
    if (_isInitialized) return;
    
    // Set the log level
    Logger.root.level = Level.ALL;
    
    // Configure log output
    Logger.root.onRecord.listen((record) {
      final message = '${record.level.name}: ${record.time}: ${record.message}';
      
      // Use developer.log for better debugging in IDEs
      developer.log(
        message,
        time: record.time,
        level: _mapLogLevelToInt(record.level),
        error: record.error,
        stackTrace: record.stackTrace,
        name: record.loggerName,
      );
    });
    
    _isInitialized = true;
  }

  static int _mapLogLevelToInt(Level level) {
    if (level >= Level.SEVERE) {
      return 1200; // ERROR
    } else if (level >= Level.WARNING) {
      return 900;  // WARNING
    } else if (level >= Level.INFO) {
      return 800;  // INFO
    } else if (level >= Level.CONFIG) {
      return 700;  // DEBUG
    } else if (level >= Level.FINE) {
      return 500;  // FINE
    } else {
      return 300;  // FINER/FINEST
    }
  }

  static Logger get logger => _logger;
}

// Convenience methods for quick access to the logger
void logInfo(String message, [Object? error, StackTrace? stackTrace]) {
  LoggerUtil.logger.info(message, error, stackTrace);
}

void logWarning(String message, [Object? error, StackTrace? stackTrace]) {
  LoggerUtil.logger.warning(message, error, stackTrace);
}

void logError(String message, [Object? error, StackTrace? stackTrace]) {
  LoggerUtil.logger.severe(message, error, stackTrace);
}

void logDebug(String message, [Object? error, StackTrace? stackTrace]) {
  LoggerUtil.logger.fine(message, error, stackTrace);
}

void logVerbose(String message, [Object? error, StackTrace? stackTrace]) {
  LoggerUtil.logger.finer(message, error, stackTrace);
}
