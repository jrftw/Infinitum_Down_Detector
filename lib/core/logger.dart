// Filename: logger.dart
// Purpose: Centralized logging system with debug toggle for the application
// Author: Kevin Doyle Jr. / Infinitum Imagery LLC
// Last Modified: 2025-01-27
// Dependencies: None
// Platform Compatibility: Web, iOS, Android

import 'package:flutter/foundation.dart';
import 'config.dart';

// MARK: - Logger Class
// Centralized logging system that respects the global debug toggle
class Logger {
  // MARK: - Logging Methods
  
  /// Logs an informational message
  /// [message] - The message to log
  /// [file] - The file where the log originated
  /// [function] - The function where the log originated
  static void logInfo(String message, String file, String function) {
    if (ENABLE_DEBUG_LOGGING || kDebugMode) {
      final timestamp = DateTime.now().toIso8601String();
      debugPrint('[$timestamp] [INFO] [$file::$function] $message');
    }
  }
  
  /// Logs an error message
  /// [message] - The error message to log
  /// [file] - The file where the error occurred
  /// [function] - The function where the error occurred
  /// [error] - Optional error object or stack trace
  static void logError(String message, String file, String function, [Object? error]) {
    if (ENABLE_DEBUG_LOGGING || kDebugMode) {
      final timestamp = DateTime.now().toIso8601String();
      debugPrint('[$timestamp] [ERROR] [$file::$function] $message');
      if (error != null) {
        debugPrint('[$timestamp] [ERROR] [$file::$function] Error details: $error');
      }
    }
  }
  
  /// Logs a debug message (only in debug mode)
  /// [message] - The debug message to log
  /// [file] - The file where the debug log originated
  /// [function] - The function where the debug log originated
  static void logDebug(String message, String file, String function) {
    if (kDebugMode) {
      final timestamp = DateTime.now().toIso8601String();
      debugPrint('[$timestamp] [DEBUG] [$file::$function] $message');
    }
  }
  
  /// Logs a warning message
  /// [message] - The warning message to log
  /// [file] - The file where the warning originated
  /// [function] - The function where the warning originated
  static void logWarning(String message, String file, String function) {
    if (ENABLE_DEBUG_LOGGING || kDebugMode) {
      final timestamp = DateTime.now().toIso8601String();
      debugPrint('[$timestamp] [WARNING] [$file::$function] $message');
    }
  }
}

// Suggestions For Features and Additions Later:
// - Add file-based logging for production
// - Implement log rotation and cleanup
// - Add remote logging service integration
// - Create log level filtering
// - Add structured logging with JSON format
// - Implement log analytics dashboard
// - Add crash reporting integration

