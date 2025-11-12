// Filename: status_history.dart
// Purpose: Data models for service status history tracking
// Author: Kevin Doyle Jr. / Infinitum Imagery LLC
// Last Modified: 2025-01-27
// Dependencies: models/service_status.dart
// Platform Compatibility: Web, iOS, Android

import 'service_status.dart';

// MARK: - Status History Entry
// Represents a single status check result at a point in time
class StatusHistoryEntry {
  final DateTime timestamp;
  final ServiceHealthStatus status;
  final int responseTimeMs;
  final String? errorMessage;
  final bool hasDataFeedIssue;

  StatusHistoryEntry({
    required this.timestamp,
    required this.status,
    this.responseTimeMs = 0,
    this.errorMessage,
    this.hasDataFeedIssue = false,
  });

  // MARK: - Factory Constructor
  // Creates a StatusHistoryEntry from a ServiceStatus
  factory StatusHistoryEntry.fromServiceStatus(ServiceStatus service) {
    return StatusHistoryEntry(
      timestamp: service.lastChecked,
      status: service.status,
      responseTimeMs: service.responseTimeMs,
      errorMessage: service.errorMessage,
      hasDataFeedIssue: service.errorMessage == 'Data feed issue detected',
    );
  }

  // MARK: - Copy With Method
  StatusHistoryEntry copyWith({
    DateTime? timestamp,
    ServiceHealthStatus? status,
    int? responseTimeMs,
    String? errorMessage,
    bool? hasDataFeedIssue,
  }) {
    return StatusHistoryEntry(
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      responseTimeMs: responseTimeMs ?? this.responseTimeMs,
      errorMessage: errorMessage ?? this.errorMessage,
      hasDataFeedIssue: hasDataFeedIssue ?? this.hasDataFeedIssue,
    );
  }
}

// MARK: - Status Statistics
// Calculated statistics for a service over a time period
class StatusStatistics {
  final int totalChecks;
  final int operationalCount;
  final int degradedCount;
  final int downCount;
  final int unknownCount;
  final double uptimePercentage;
  final double averageResponseTime;
  final Duration? lastOutageDuration;
  final DateTime? lastOutageStart;
  final DateTime? lastOutageEnd;

  StatusStatistics({
    required this.totalChecks,
    required this.operationalCount,
    required this.degradedCount,
    required this.downCount,
    required this.unknownCount,
    required this.uptimePercentage,
    required this.averageResponseTime,
    this.lastOutageDuration,
    this.lastOutageStart,
    this.lastOutageEnd,
  });

  // MARK: - Factory Constructor
  // Calculates statistics from a list of history entries
  factory StatusStatistics.fromHistory(List<StatusHistoryEntry> history) {
    if (history.isEmpty) {
      return StatusStatistics(
        totalChecks: 0,
        operationalCount: 0,
        degradedCount: 0,
        downCount: 0,
        unknownCount: 0,
        uptimePercentage: 0.0,
        averageResponseTime: 0.0,
      );
    }

    int operational = 0;
    int degraded = 0;
    int down = 0;
    int unknown = 0;
    int totalResponseTime = 0;
    int responseTimeCount = 0;

    DateTime? outageStart;
    DateTime? lastOutageStart;
    DateTime? lastOutageEnd;
    Duration? lastOutageDuration;

    for (final entry in history) {
      switch (entry.status) {
        case ServiceHealthStatus.operational:
          operational++;
          if (outageStart != null) {
            // Outage ended
            lastOutageEnd = entry.timestamp;
            lastOutageDuration = lastOutageEnd.difference(outageStart);
            lastOutageStart = outageStart;
            outageStart = null;
          }
          break;
        case ServiceHealthStatus.degraded:
          degraded++;
          if (outageStart == null) {
            outageStart = entry.timestamp;
          }
          break;
        case ServiceHealthStatus.down:
          down++;
          if (outageStart == null) {
            outageStart = entry.timestamp;
          }
          break;
        case ServiceHealthStatus.unknown:
          unknown++;
          break;
      }

      if (entry.responseTimeMs > 0) {
        totalResponseTime += entry.responseTimeMs;
        responseTimeCount++;
      }
    }

    // If still in outage, calculate duration to now
    if (outageStart != null) {
      lastOutageStart = outageStart;
      lastOutageEnd = DateTime.now();
      lastOutageDuration = lastOutageEnd.difference(outageStart);
    }

    final total = history.length;
    final uptime = (operational / total * 100);

    return StatusStatistics(
      totalChecks: total,
      operationalCount: operational,
      degradedCount: degraded,
      downCount: down,
      unknownCount: unknown,
      uptimePercentage: uptime,
      averageResponseTime: responseTimeCount > 0
          ? totalResponseTime / responseTimeCount
          : 0.0,
      lastOutageDuration: lastOutageDuration,
      lastOutageStart: lastOutageStart,
      lastOutageEnd: lastOutageEnd,
    );
  }
}

// Suggestions For Features and Additions Later:
// - Add status change event tracking
// - Implement status trend analysis
// - Add status prediction based on history
// - Create status anomaly detection
// - Add status comparison across time periods

