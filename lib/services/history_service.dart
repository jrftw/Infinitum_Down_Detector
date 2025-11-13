// Filename: history_service.dart
// Purpose: Service for managing service status history and historical data
// Author: Kevin Doyle Jr. / Infinitum Imagery LLC
// Last Modified: 2025-01-27
// Dependencies: cloud_firestore, models/status_history.dart, models/service_status.dart, core/logger.dart
// Platform Compatibility: Web, iOS, Android

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import '../models/status_history.dart';
import '../models/service_status.dart';
import '../core/logger.dart';

// MARK: - History Service
// Handles storage and retrieval of service status history
class HistoryService {
  firestore.FirebaseFirestore? _firestore;
  bool _firestoreAvailable = false;
  static const String _collectionName = 'service_status_history';
  
  // MARK: - Initialization
  // Initializes Firestore connection for history storage
  HistoryService() {
    try {
      _firestore = firestore.FirebaseFirestore.instance;
      _firestoreAvailable = true;
      Logger.logInfo('HistoryService initialized with Firestore', 
          'history_service.dart', 'HistoryService');
    } catch (e) {
      _firestoreAvailable = false;
      Logger.logInfo('HistoryService initialized without Firestore (history disabled)', 
          'history_service.dart', 'HistoryService');
    }
  }
  
  // MARK: - History Storage
  /// Saves a status history entry for a service
  /// [serviceId] - ID of the service
  /// [entry] - StatusHistoryEntry to save
  /// Returns void
  Future<void> saveHistoryEntry(String serviceId, StatusHistoryEntry entry) async {
    if (!_firestoreAvailable || _firestore == null) {
      Logger.logDebug('Cannot save history: Firestore not available', 
          'history_service.dart', 'saveHistoryEntry');
      return;
    }
    
    try {
      final docRef = _firestore!.collection(_collectionName)
          .doc(serviceId)
          .collection('entries')
          .doc(entry.timestamp.toIso8601String());
      
      await docRef.set({
        'timestamp': firestore.Timestamp.fromDate(entry.timestamp),
        'status': entry.status.name,
        'responseTimeMs': entry.responseTimeMs,
        'errorMessage': entry.errorMessage,
        'hasDataFeedIssue': entry.hasDataFeedIssue,
      });
      
      Logger.logDebug('Saved history entry for $serviceId at ${entry.timestamp}', 
          'history_service.dart', 'saveHistoryEntry');
    } catch (e) {
      Logger.logError('Error saving history entry', 
          'history_service.dart', 'saveHistoryEntry', e);
    }
  }
  
  /// Saves multiple history entries in batch
  /// [serviceId] - ID of the service
  /// [entries] - List of StatusHistoryEntry to save
  /// Returns void
  Future<void> saveHistoryEntries(String serviceId, List<StatusHistoryEntry> entries) async {
    if (!_firestoreAvailable || _firestore == null || entries.isEmpty) {
      return;
    }
    
    try {
      final batch = _firestore!.batch();
      final entriesRef = _firestore!.collection(_collectionName)
          .doc(serviceId)
          .collection('entries');
      
      for (final entry in entries) {
        final docRef = entriesRef.doc(entry.timestamp.toIso8601String());
        batch.set(docRef, {
          'timestamp': firestore.Timestamp.fromDate(entry.timestamp),
          'status': entry.status.name,
          'responseTimeMs': entry.responseTimeMs,
          'errorMessage': entry.errorMessage,
          'hasDataFeedIssue': entry.hasDataFeedIssue,
        });
      }
      
      await batch.commit();
      Logger.logInfo('Saved ${entries.length} history entries for $serviceId', 
          'history_service.dart', 'saveHistoryEntries');
    } catch (e) {
      Logger.logError('Error saving history entries', 
          'history_service.dart', 'saveHistoryEntries', e);
    }
  }
  
  // MARK: - History Retrieval
  /// Retrieves history entries for a service within a time range
  /// [serviceId] - ID of the service
  /// [startTime] - Start of time range
  /// [endTime] - End of time range (defaults to now)
  /// [limit] - Maximum number of entries to retrieve (defaults to 1000)
  /// Returns list of StatusHistoryEntry
  Future<List<StatusHistoryEntry>> getHistoryEntries(
    String serviceId, {
    required DateTime startTime,
    DateTime? endTime,
    int limit = 1000,
  }) async {
    if (!_firestoreAvailable || _firestore == null) {
      Logger.logDebug('Cannot retrieve history: Firestore not available', 
          'history_service.dart', 'getHistoryEntries');
      return [];
    }
    
    try {
      final end = endTime ?? DateTime.now();
      final query = _firestore!.collection(_collectionName)
          .doc(serviceId)
          .collection('entries')
          .where('timestamp', isGreaterThanOrEqualTo: firestore.Timestamp.fromDate(startTime))
          .where('timestamp', isLessThanOrEqualTo: firestore.Timestamp.fromDate(end))
          .orderBy('timestamp', descending: false)
          .limit(limit);
      
      final snapshot = await query.get();
      final entries = <StatusHistoryEntry>[];
      
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          entries.add(StatusHistoryEntry(
            timestamp: (data['timestamp'] as firestore.Timestamp?)?.toDate() ?? DateTime.now(),
            status: _parseServiceHealthStatus(data['status'] as String?),
            responseTimeMs: data['responseTimeMs'] as int? ?? 0,
            errorMessage: data['errorMessage'] as String?,
            hasDataFeedIssue: data['hasDataFeedIssue'] as bool? ?? false,
          ));
        } catch (e) {
          Logger.logWarning('Error parsing history entry ${doc.id}: $e', 
              'history_service.dart', 'getHistoryEntries');
        }
      }
      
      Logger.logInfo('Retrieved ${entries.length} history entries for $serviceId', 
          'history_service.dart', 'getHistoryEntries');
      return entries;
    } catch (e) {
      Logger.logError('Error retrieving history entries', 
          'history_service.dart', 'getHistoryEntries', e);
      return [];
    }
  }
  
  /// Retrieves history entries for the last N hours
  /// [serviceId] - ID of the service
  /// [hours] - Number of hours to look back (defaults to 24)
  /// Returns list of StatusHistoryEntry
  Future<List<StatusHistoryEntry>> getRecentHistory(
    String serviceId, {
    int hours = 24,
  }) async {
    final startTime = DateTime.now().subtract(Duration(hours: hours));
    return getHistoryEntries(serviceId, startTime: startTime);
  }
  
  /// Retrieves history entries for the last N days
  /// [serviceId] - ID of the service
  /// [days] - Number of days to look back (defaults to 30)
  /// Returns list of StatusHistoryEntry
  Future<List<StatusHistoryEntry>> getHistoryForDays(
    String serviceId, {
    int days = 30,
  }) async {
    final startTime = DateTime.now().subtract(Duration(days: days));
    return getHistoryEntries(serviceId, startTime: startTime, limit: 10000);
  }
  
  /// Calculates statistics for a service over a time period
  /// [serviceId] - ID of the service
  /// [startTime] - Start of time range
  /// [endTime] - End of time range (defaults to now)
  /// Returns StatusStatistics
  Future<StatusStatistics> getStatistics(
    String serviceId, {
    required DateTime startTime,
    DateTime? endTime,
  }) async {
    final entries = await getHistoryEntries(serviceId, startTime: startTime, endTime: endTime);
    return StatusStatistics.fromHistory(entries);
  }
  
  // MARK: - History Cleanup
  /// Deletes history entries older than specified days
  /// [serviceId] - ID of the service (optional, if null cleans all services)
  /// [daysToKeep] - Number of days of history to keep (defaults to 90)
  /// Returns void
  Future<void> cleanupOldHistory({
    String? serviceId,
    int daysToKeep = 90,
  }) async {
    if (!_firestoreAvailable || _firestore == null) {
      return;
    }
    
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      final cutoffTimestamp = firestore.Timestamp.fromDate(cutoffDate);
      
      if (serviceId != null) {
        // Clean specific service
        final query = _firestore!.collection(_collectionName)
            .doc(serviceId)
            .collection('entries')
            .where('timestamp', isLessThan: cutoffTimestamp);
        
        final snapshot = await query.get();
        final batch = _firestore!.batch();
        
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        
        await batch.commit();
        Logger.logInfo('Cleaned up ${snapshot.docs.length} old history entries for $serviceId', 
            'history_service.dart', 'cleanupOldHistory');
      } else {
        // Clean all services
        final servicesSnapshot = await _firestore!.collection(_collectionName).get();
        int totalDeleted = 0;
        
        for (final serviceDoc in servicesSnapshot.docs) {
          final query = serviceDoc.reference
              .collection('entries')
              .where('timestamp', isLessThan: cutoffTimestamp);
          
          final entriesSnapshot = await query.get();
          final batch = _firestore!.batch();
          
          for (final doc in entriesSnapshot.docs) {
            batch.delete(doc.reference);
            totalDeleted++;
          }
          
          if (entriesSnapshot.docs.isNotEmpty) {
            await batch.commit();
          }
        }
        
        Logger.logInfo('Cleaned up $totalDeleted old history entries across all services', 
            'history_service.dart', 'cleanupOldHistory');
      }
    } catch (e) {
      Logger.logError('Error cleaning up old history', 
          'history_service.dart', 'cleanupOldHistory', e);
    }
  }
  
  // MARK: - Helper Methods
  /// Parses ServiceHealthStatus from string
  ServiceHealthStatus _parseServiceHealthStatus(String? statusString) {
    if (statusString == null) return ServiceHealthStatus.unknown;
    
    switch (statusString.toLowerCase()) {
      case 'operational':
        return ServiceHealthStatus.operational;
      case 'degraded':
        return ServiceHealthStatus.degraded;
      case 'partialoutage':
      case 'partial_outage':
        return ServiceHealthStatus.partialOutage;
      case 'majoroutage':
      case 'major_outage':
        return ServiceHealthStatus.majorOutage;
      case 'down':
        return ServiceHealthStatus.down;
      case 'maintenance':
        return ServiceHealthStatus.maintenance;
      case 'unknown':
      default:
        return ServiceHealthStatus.unknown;
    }
  }
  
  // MARK: - Cleanup
  void dispose() {
    Logger.logInfo('HistoryService disposed', 'history_service.dart', 'dispose');
  }
}

// Suggestions For Features and Additions Later:
// - Add history aggregation for performance
// - Implement history compression
// - Add history export functionality
// - Create history analytics
// - Add history search and filtering
// - Implement history backup and restore
// - Add history visualization helpers

