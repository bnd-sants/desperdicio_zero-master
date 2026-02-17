import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../utils/logger_util.dart';
import 'telemetry_service.dart';

class ErrorMonitoringService {
  ErrorMonitoringService._();

  static bool _initialized = false;

  static void initialize() {
    if (_initialized) return;
    _initialized = true;

    final previousHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      _reportError(
        exception: details.exception,
        stackTrace: details.stack,
        library: details.library,
        context: details.context?.toDescription(),
      );
      previousHandler?.call(details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      _reportError(exception: error, stackTrace: stack);
      return false;
    };
  }

  static Future<void> runGuarded(Future<void> Function() body) async {
    return runZonedGuarded(() async {
      await body();
    }, (error, stack) {
      _reportError(exception: error, stackTrace: stack);
    });
  }

  static void _reportError({
    required Object exception,
    StackTrace? stackTrace,
    String? library,
    String? context,
  }) {
    logError('Unhandled exception: $exception', exception, stackTrace);
    TelemetryService.logEvent(
      category: 'runtime',
      severity: 'critical',
      message: exception.toString(),
      data: {
        'stackTrace': stackTrace?.toString(),
        'library': library,
        'context': context,
      },
    );
  }
}
