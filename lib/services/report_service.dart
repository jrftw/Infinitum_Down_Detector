// Filename: report_service.dart
// Purpose: Service for handling user reports about service issues
// Author: Kevin Doyle Jr. / Infinitum Imagery LLC
// Last Modified: 2025-01-27
// Dependencies: cloud_firestore (optional), logger.dart, shared_preferences
// Platform Compatibility: Web, iOS, Android

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/logger.dart';

// MARK: - Report Service
// Handles submission and storage of user reports with rate limiting to prevent spam
class ReportService {
  firestore.FirebaseFirestore? _firestore;
  bool _firestoreAvailable = false;
  
  // MARK: - Rate Limiting Configuration
  // Maximum reports per time window to prevent spam
  static const int MAX_REPORTS_PER_HOUR = 5;
  static const int MAX_REPORTS_PER_DAY = 20;
  static const String REPORTS_TIMESTAMP_KEY = 'report_timestamps';

  // MARK: - Initialization
  // Initializes Firestore if available
  ReportService() {
    try {
      _firestore = firestore.FirebaseFirestore.instance;
      _firestoreAvailable = true;
      Logger.logInfo('ReportService initialized with Firestore', 'report_service.dart', 'ReportService');
    } catch (e) {
      _firestoreAvailable = false;
      Logger.logInfo('ReportService initialized without Firestore (reports will be logged only)', 
          'report_service.dart', 'ReportService');
    }
  }
  
  // MARK: - Rate Limiting Methods
  /// Checks if user can submit a report (rate limiting)
  /// Returns true if report can be submitted, false if rate limit exceeded
  Future<bool> canSubmitReport() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampsString = prefs.getString(REPORTS_TIMESTAMP_KEY);
      
      if (timestampsString == null) {
        return true; // No previous reports
      }
      
      final timestamps = timestampsString.split(',').map((s) {
        try {
          return DateTime.parse(s);
        } catch (e) {
          return null;
        }
      }).whereType<DateTime>().toList();
      
      final now = DateTime.now();
      final oneHourAgo = now.subtract(const Duration(hours: 1));
      final oneDayAgo = now.subtract(const Duration(days: 1));
      
      // Count reports in last hour
      final recentHourReports = timestamps.where((t) => t.isAfter(oneHourAgo)).length;
      if (recentHourReports >= MAX_REPORTS_PER_HOUR) {
        Logger.logWarning('Rate limit exceeded: $recentHourReports reports in last hour', 
            'report_service.dart', 'canSubmitReport');
        return false;
      }
      
      // Count reports in last day
      final recentDayReports = timestamps.where((t) => t.isAfter(oneDayAgo)).length;
      if (recentDayReports >= MAX_REPORTS_PER_DAY) {
        Logger.logWarning('Rate limit exceeded: $recentDayReports reports in last day', 
            'report_service.dart', 'canSubmitReport');
        return false;
      }
      
      return true;
    } catch (e) {
      Logger.logError('Error checking rate limit', 'report_service.dart', 'canSubmitReport', e);
      // On error, allow the report (fail open)
      return true;
    }
  }
  
  /// Records a report timestamp for rate limiting
  Future<void> _recordReportTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampsString = prefs.getString(REPORTS_TIMESTAMP_KEY);
      
      final now = DateTime.now();
      final oneDayAgo = now.subtract(const Duration(days: 1));
      
      List<DateTime> timestamps;
      if (timestampsString != null) {
        timestamps = timestampsString.split(',').map((s) {
          try {
            return DateTime.parse(s);
          } catch (e) {
            return null;
          }
        }).whereType<DateTime>().where((t) => t.isAfter(oneDayAgo)).toList();
      } else {
        timestamps = [];
      }
      
      timestamps.add(now);
      timestamps.sort((a, b) => b.compareTo(a)); // Sort descending
      
      // Keep only last 30 days of timestamps
      if (timestamps.length > 100) {
        timestamps = timestamps.take(100).toList();
      }
      
      final updatedString = timestamps.map((t) => t.toIso8601String()).join(',');
      await prefs.setString(REPORTS_TIMESTAMP_KEY, updatedString);
    } catch (e) {
      Logger.logError('Error recording report timestamp', 'report_service.dart', '_recordReportTimestamp', e);
    }
  }
  
  /// Gets time until next report can be submitted
  /// Returns Duration until next report allowed, or null if allowed now
  Future<Duration?> getTimeUntilNextReport() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampsString = prefs.getString(REPORTS_TIMESTAMP_KEY);
      
      if (timestampsString == null) {
        return null; // Can report now
      }
      
      final timestamps = timestampsString.split(',').map((s) {
        try {
          return DateTime.parse(s);
        } catch (e) {
          return null;
        }
      }).whereType<DateTime>().toList();
      
      final now = DateTime.now();
      final oneHourAgo = now.subtract(const Duration(hours: 1));
      final oneDayAgo = now.subtract(const Duration(days: 1));
      
      // Check hourly limit
      final recentHourReports = timestamps.where((t) => t.isAfter(oneHourAgo)).toList();
      if (recentHourReports.length >= MAX_REPORTS_PER_HOUR) {
        recentHourReports.sort();
        final oldestRecent = recentHourReports.first;
        final nextAllowed = oldestRecent.add(const Duration(hours: 1));
        return nextAllowed.isAfter(now) ? nextAllowed.difference(now) : null;
      }
      
      // Check daily limit
      final recentDayReports = timestamps.where((t) => t.isAfter(oneDayAgo)).toList();
      if (recentDayReports.length >= MAX_REPORTS_PER_DAY) {
        recentDayReports.sort();
        final oldestRecent = recentDayReports.first;
        final nextAllowed = oldestRecent.add(const Duration(days: 1));
        return nextAllowed.isAfter(now) ? nextAllowed.difference(now) : null;
      }
      
      return null; // Can report now
    } catch (e) {
      Logger.logError('Error getting time until next report', 'report_service.dart', 'getTimeUntilNextReport', e);
      return null;
    }
  }

  // MARK: - Report Submission
  /// Submits a user report about a service issue
  /// [serviceId] - ID of the service being reported
  /// [serviceName] - Name of the service being reported
  /// [reportType] - Type of issue (down, slow, error, other)
  /// [reporterName] - Name of the reporter (optional)
  /// [reporterEmail] - Email of the reporter (optional)
  /// [description] - Description of the issue
  /// Returns true if report was submitted, false if rate limited
  Future<bool> submitReport({
    required String serviceId,
    required String serviceName,
    required String reportType,
    String? reporterName,
    String? reporterEmail,
    required String description,
  }) async {
    // Check rate limiting
    final canSubmit = await canSubmitReport();
    if (!canSubmit) {
      Logger.logWarning('Report submission blocked due to rate limiting', 
          'report_service.dart', 'submitReport');
      return false;
    }
    final reportData = {
      'serviceId': serviceId,
      'serviceName': serviceName,
      'reportType': reportType,
      'reporterName': reporterName ?? 'Anonymous',
      'reporterEmail': reporterEmail ?? '',
      'description': description,
      'timestamp': DateTime.now().toIso8601String(),
      'status': 'new',
    };

    // Log the report
    Logger.logInfo(
      'Report submitted: $serviceName - $reportType by ${reporterName ?? "Anonymous"}',
      'report_service.dart',
      'submitReport',
    );
    Logger.logDebug('Report details: $reportData', 'report_service.dart', 'submitReport');

    // Store in Firestore if available
    if (_firestoreAvailable && _firestore != null) {
      try {
        await _firestore!.collection('reports').add(reportData);
        Logger.logInfo('Report stored in Firestore', 'report_service.dart', 'submitReport');
      } catch (e) {
        Logger.logError('Error storing report in Firestore', 'report_service.dart', 'submitReport', e);
        // Continue even if Firestore fails - report is still logged
      }
    } else {
      Logger.logInfo('Report logged but not stored (Firestore not available)', 
          'report_service.dart', 'submitReport');
    }
    
    // Record timestamp for rate limiting
    await _recordReportTimestamp();
    return true;
  }

  // MARK: - Report Retrieval
  /// Retrieves reports for a specific service
  /// [serviceId] - ID of the service
  /// [limit] - Maximum number of reports to retrieve
  /// Returns list of report data maps
  Future<List<Map<String, dynamic>>> getReportsForService(
    String serviceId, {
    int limit = 50,
  }) async {
    if (!_firestoreAvailable || _firestore == null) {
      Logger.logWarning('Cannot retrieve reports: Firestore not available', 
          'report_service.dart', 'getReportsForService');
      return [];
    }

    try {
      final querySnapshot = await _firestore!
          .collection('reports')
          .where('serviceId', isEqualTo: serviceId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      final reports = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      Logger.logInfo('Retrieved ${reports.length} reports for service: $serviceId', 
          'report_service.dart', 'getReportsForService');
      return reports;
    } catch (e) {
      Logger.logError('Error retrieving reports', 'report_service.dart', 'getReportsForService', e);
      return [];
    }
  }

  // MARK: - Report Statistics
  /// Gets statistics about reports
  /// Returns map with report statistics
  Future<Map<String, dynamic>> getReportStatistics() async {
    if (!_firestoreAvailable || _firestore == null) {
      return {
        'total': 0,
        'byType': {},
        'byService': {},
      };
    }

    try {
      final querySnapshot = await _firestore!.collection('reports').get();
      final reports = querySnapshot.docs.map((doc) => doc.data()).toList();

      final stats = <String, dynamic>{
        'total': reports.length,
        'byType': <String, int>{},
        'byService': <String, int>{},
      };

      for (final report in reports) {
        // Count by type
        final type = report['reportType'] as String? ?? 'unknown';
        stats['byType'][type] = (stats['byType'][type] as int? ?? 0) + 1;

        // Count by service
        final serviceId = report['serviceId'] as String? ?? 'unknown';
        stats['byService'][serviceId] = (stats['byService'][serviceId] as int? ?? 0) + 1;
      }

      Logger.logInfo('Retrieved report statistics', 'report_service.dart', 'getReportStatistics');
      return stats;
    } catch (e) {
      Logger.logError('Error retrieving report statistics', 'report_service.dart', 'getReportStatistics', e);
      return {
        'total': 0,
        'byType': {},
        'byService': {},
      };
    }
  }
}

// Suggestions For Features and Additions Later:
// - Add report status updates (new, in-progress, resolved)
// - Implement report notifications
// - Add report deduplication logic
// - Create report analytics dashboard
// - Add report export functionality
// - Implement report search and filtering
// - Add report attachments support
// - Create report API endpoints

