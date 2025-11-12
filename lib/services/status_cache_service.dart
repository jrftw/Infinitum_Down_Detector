// Filename: status_cache_service.dart
// Purpose: Service for caching service status in Firestore for shared access across users
// Author: Kevin Doyle Jr. / Infinitum Imagery LLC
// Last Modified: 2025-01-27
// Dependencies: cloud_firestore, models/service_status.dart, models/service_component.dart, core/config.dart, core/logger.dart
// Platform Compatibility: Web, iOS, Android

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import '../models/service_status.dart';
import '../models/service_component.dart';
import '../core/logger.dart';
import '../core/config.dart';

// MARK: - Status Cache Service
// Handles caching of service status in Firestore for shared access
class StatusCacheService {
  firestore.FirebaseFirestore? _firestore;
  bool _firestoreAvailable = false;
  static const String _collectionName = 'service_status_cache';
  static const String _lastUpdateDocId = 'last_update';
  
  // Real-time listener streams
  StreamSubscription<firestore.QuerySnapshot>? _servicesListener;
  
  // Rate limiting and caching
  DateTime? _lastWriteTime;
  int _writesThisHour = 0;
  DateTime? _hourStartTime;
  Map<String, ServiceStatus> _lastCachedStatuses = {};
  
  // MARK: - Initialization
  // Initializes Firestore connection for caching
  StatusCacheService() {
    try {
      _firestore = firestore.FirebaseFirestore.instance;
      _firestoreAvailable = true;
      Logger.logInfo('StatusCacheService initialized with Firestore', 
          'status_cache_service.dart', 'StatusCacheService');
    } catch (e) {
      _firestoreAvailable = false;
      Logger.logInfo('StatusCacheService initialized without Firestore (caching disabled)', 
          'status_cache_service.dart', 'StatusCacheService');
    }
  }
  
  // MARK: - Cache Operations
  /// Saves service statuses to Firestore cache with rate limiting and change detection
  /// Only writes if status changed or enough time has passed since last write
  /// [services] - List of services to cache
  /// Returns void
  Future<void> saveServiceStatuses(List<ServiceStatus> services) async {
    if (!_firestoreAvailable || _firestore == null) {
      Logger.logDebug('Cannot save to cache: Firestore not available', 
          'status_cache_service.dart', 'saveServiceStatuses');
      return;
    }
    
    // MARK: - Rate Limiting Check
    // Check if we've exceeded hourly write limit
    final now = DateTime.now();
    if (_hourStartTime == null || now.difference(_hourStartTime!).inHours >= 1) {
      _hourStartTime = now;
      _writesThisHour = 0;
    }
    
    if (_writesThisHour >= MAX_CACHE_WRITES_PER_HOUR) {
      Logger.logWarning('Cache write rate limit reached (${MAX_CACHE_WRITES_PER_HOUR} writes/hour). Skipping write.', 
          'status_cache_service.dart', 'saveServiceStatuses');
      return;
    }
    
    // Check minimum interval between writes
    if (_lastWriteTime != null) {
      final timeSinceLastWrite = now.difference(_lastWriteTime!);
      if (timeSinceLastWrite.inSeconds < CACHE_WRITE_INTERVAL_SECONDS) {
        Logger.logDebug('Skipping cache write - too soon since last write (${timeSinceLastWrite.inSeconds}s < ${CACHE_WRITE_INTERVAL_SECONDS}s)', 
            'status_cache_service.dart', 'saveServiceStatuses');
        return;
      }
    }
    
    // MARK: - Change Detection
    // Only write services that have actually changed
    final servicesToWrite = <ServiceStatus>[];
    for (final service in services) {
      final lastCached = _lastCachedStatuses[service.id];
      
      // Write if:
      // 1. Service not in cache
      // 2. Status changed
      // 3. Response time changed significantly (>10%)
      // 4. Error message changed
      // 5. Last checked time is significantly different (>30 seconds)
      bool shouldWrite = false;
      
      if (lastCached == null) {
        shouldWrite = true;
      } else if (lastCached.status != service.status) {
        shouldWrite = true;
        Logger.logDebug('Status changed for ${service.name}: ${lastCached.status} -> ${service.status}', 
            'status_cache_service.dart', 'saveServiceStatuses');
      } else if (lastCached.errorMessage != service.errorMessage) {
        shouldWrite = true;
        Logger.logDebug('Error message changed for ${service.name}', 
            'status_cache_service.dart', 'saveServiceStatuses');
      } else if (lastCached.responseTimeMs != service.responseTimeMs) {
        // Only write if response time changed significantly
        final timeDiff = (lastCached.responseTimeMs - service.responseTimeMs).abs();
        final avgTime = (lastCached.responseTimeMs + service.responseTimeMs) / 2;
        if (avgTime > 0 && (timeDiff / avgTime) > 0.1) {
          shouldWrite = true;
        }
      } else if (service.lastChecked.difference(lastCached.lastChecked).inSeconds > 30) {
        // Write if last checked time is significantly different (more than 30 seconds)
        shouldWrite = true;
      }
      
      if (shouldWrite) {
        servicesToWrite.add(service);
      }
    }
    
    // If no services changed, skip write
    if (servicesToWrite.isEmpty) {
      Logger.logDebug('No service changes detected. Skipping cache write.', 
          'status_cache_service.dart', 'saveServiceStatuses');
      return;
    }
    
    try {
      final batch = _firestore!.batch();
      
      // Save only changed service statuses
      for (final service in servicesToWrite) {
        final docRef = _firestore!.collection(_collectionName).doc(service.id);
        final data = _serviceStatusToMap(service);
        batch.set(docRef, data, firestore.SetOptions(merge: true));
        // Update local cache
        _lastCachedStatuses[service.id] = service;
      }
      
      // Save last update timestamp (only if we wrote something)
      final lastUpdateRef = _firestore!.collection(_collectionName).doc(_lastUpdateDocId);
      batch.set(lastUpdateRef, {
        'timestamp': firestore.FieldValue.serverTimestamp(),
        'serviceCount': services.length,
        'lastWriteCount': servicesToWrite.length,
      }, firestore.SetOptions(merge: true));
      
      await batch.commit();
      
      // Update rate limiting counters
      _lastWriteTime = now;
      _writesThisHour++;
      
      Logger.logInfo('Saved ${servicesToWrite.length} changed service statuses to cache (${services.length} total, ${_writesThisHour}/${MAX_CACHE_WRITES_PER_HOUR} writes this hour)', 
          'status_cache_service.dart', 'saveServiceStatuses');
    } catch (e) {
      Logger.logError('Error saving service statuses to cache', 
          'status_cache_service.dart', 'saveServiceStatuses', e);
    }
  }
  
  /// Loads service statuses from Firestore cache
  /// Returns list of cached ServiceStatus objects, or empty list if cache unavailable
  Future<List<ServiceStatus>> loadServiceStatuses() async {
    if (!_firestoreAvailable || _firestore == null) {
      Logger.logDebug('Cannot load from cache: Firestore not available', 
          'status_cache_service.dart', 'loadServiceStatuses');
      return [];
    }
    
    try {
      final snapshot = await _firestore!.collection(_collectionName)
          .where(firestore.FieldPath.documentId, isNotEqualTo: _lastUpdateDocId)
          .get();
      final services = <ServiceStatus>[];
      
      for (final doc in snapshot.docs) {
        try {
          final service = _mapToServiceStatus(doc.id, doc.data());
          services.add(service);
          // Update local cache
          _lastCachedStatuses[service.id] = service;
        } catch (e) {
          Logger.logWarning('Error parsing cached service ${doc.id}: $e', 
              'status_cache_service.dart', 'loadServiceStatuses');
        }
      }
      
      Logger.logInfo('Loaded ${services.length} service statuses from cache', 
          'status_cache_service.dart', 'loadServiceStatuses');
      return services;
    } catch (e) {
      Logger.logError('Error loading service statuses from cache', 
          'status_cache_service.dart', 'loadServiceStatuses', e);
      return [];
    }
  }
  
  /// Gets the last update timestamp from cache
  /// Returns DateTime of last update, or null if unavailable
  Future<DateTime?> getLastUpdateTime() async {
    if (!_firestoreAvailable || _firestore == null) {
      return null;
    }
    
    try {
      final doc = await _firestore!.collection(_collectionName)
          .doc(_lastUpdateDocId)
          .get();
      
      if (doc.exists && doc.data() != null) {
        final timestamp = doc.data()!['timestamp'] as firestore.Timestamp?;
        return timestamp?.toDate();
      }
    } catch (e) {
      Logger.logError('Error getting last update time from cache', 
          'status_cache_service.dart', 'getLastUpdateTime', e);
    }
    
    return null;
  }
  
  /// Clears all cached service statuses
  /// Returns void
  Future<void> clearCache() async {
    if (!_firestoreAvailable || _firestore == null) {
      return;
    }
    
    try {
      final snapshot = await _firestore!.collection(_collectionName).get();
      final batch = _firestore!.batch();
      
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      Logger.logInfo('Cleared service status cache', 
          'status_cache_service.dart', 'clearCache');
    } catch (e) {
      Logger.logError('Error clearing cache', 
          'status_cache_service.dart', 'clearCache', e);
    }
  }
  
  // MARK: - Helper Methods
  /// Converts ServiceStatus to Map for Firestore storage
  /// [service] - ServiceStatus to convert
  /// Returns Map representation
  Map<String, dynamic> _serviceStatusToMap(ServiceStatus service) {
    return {
      'id': service.id,
      'name': service.name,
      'url': service.url,
      'type': service.type.name,
      'status': service.status.name,
      'lastChecked': firestore.Timestamp.fromDate(service.lastChecked),
      'lastUpTime': service.lastUpTime != null 
          ? firestore.Timestamp.fromDate(service.lastUpTime!) 
          : null,
      'responseTimeMs': service.responseTimeMs,
      'errorMessage': service.errorMessage,
      'consecutiveFailures': service.consecutiveFailures,
      'components': service.components.map((comp) => _serviceComponentToMap(comp)).toList(),
    };
  }
  
  /// Converts Map from Firestore to ServiceStatus
  /// [id] - Service ID
  /// [data] - Map data from Firestore
  /// Returns ServiceStatus object
  ServiceStatus _mapToServiceStatus(String id, Map<String, dynamic> data) {
    // Parse components if present, otherwise get from config
    List<ServiceComponent> components = [];
    if (data['components'] != null && data['components'] is List) {
      try {
        components = (data['components'] as List)
            .map((compData) => _mapToServiceComponent(compData as Map<String, dynamic>))
            .toList();
      } catch (e) {
        Logger.logWarning('Error parsing components for service $id: $e', 
            'status_cache_service.dart', '_mapToServiceStatus');
        // Fall back to config if parsing fails
        components = ServiceComponentDefinitions.getComponentsForService(id);
      }
    } else {
      // If no components in Firestore, get from config
      components = ServiceComponentDefinitions.getComponentsForService(id);
    }
    
    return ServiceStatus(
      id: data['id'] as String? ?? id,
      name: data['name'] as String? ?? 'Unknown',
      url: data['url'] as String? ?? '',
      type: _parseServiceType(data['type'] as String?),
      status: _parseServiceHealthStatus(data['status'] as String?),
      lastChecked: (data['lastChecked'] as firestore.Timestamp?)?.toDate() ?? DateTime.now(),
      lastUpTime: (data['lastUpTime'] as firestore.Timestamp?)?.toDate(),
      responseTimeMs: data['responseTimeMs'] as int? ?? 0,
      errorMessage: data['errorMessage'] as String?,
      consecutiveFailures: data['consecutiveFailures'] as int? ?? 0,
      components: components,
    );
  }
  
  /// Converts ServiceComponent to Map for Firestore storage
  /// [component] - ServiceComponent to convert
  /// Returns Map representation
  Map<String, dynamic> _serviceComponentToMap(ServiceComponent component) {
    return {
      'id': component.id,
      'name': component.name,
      'url': component.url,
      'type': component.type.name,
      'status': component.status.name,
      'lastChecked': firestore.Timestamp.fromDate(component.lastChecked),
      'responseTimeMs': component.responseTimeMs,
      'errorMessage': component.errorMessage,
      'statusCode': component.statusCode,
    };
  }
  
  /// Converts Map from Firestore to ServiceComponent
  /// [data] - Map data from Firestore
  /// Returns ServiceComponent object
  ServiceComponent _mapToServiceComponent(Map<String, dynamic> data) {
    return ServiceComponent(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? 'Unknown',
      url: data['url'] as String? ?? '',
      type: _parseComponentType(data['type'] as String?),
      status: _parseServiceHealthStatus(data['status'] as String?),
      lastChecked: (data['lastChecked'] as firestore.Timestamp?)?.toDate() ?? DateTime.now(),
      responseTimeMs: data['responseTimeMs'] as int? ?? 0,
      errorMessage: data['errorMessage'] as String?,
      statusCode: data['statusCode'] as int?,
    );
  }
  
  /// Parses ComponentType from string
  /// [typeString] - String representation of ComponentType
  /// Returns ComponentType enum value
  ComponentType _parseComponentType(String? typeString) {
    if (typeString == null) return ComponentType.other;
    
    switch (typeString.toLowerCase()) {
      case 'main':
        return ComponentType.main;
      case 'auth':
        return ComponentType.auth;
      case 'api':
        return ComponentType.api;
      case 'database':
        return ComponentType.database;
      case 'cdn':
        return ComponentType.cdn;
      case 'other':
      default:
        return ComponentType.other;
    }
  }
  
  /// Parses ServiceType from string
  /// [typeString] - String representation of ServiceType
  /// Returns ServiceType enum value
  ServiceType _parseServiceType(String? typeString) {
    if (typeString == null) return ServiceType.infinitum;
    
    switch (typeString.toLowerCase()) {
      case 'infinitum':
        return ServiceType.infinitum;
      case 'thirdparty':
        return ServiceType.thirdParty;
      default:
        return ServiceType.infinitum;
    }
  }
  
  /// Parses ServiceHealthStatus from string
  /// [statusString] - String representation of ServiceHealthStatus
  /// Returns ServiceHealthStatus enum value
  ServiceHealthStatus _parseServiceHealthStatus(String? statusString) {
    if (statusString == null) return ServiceHealthStatus.unknown;
    
    switch (statusString.toLowerCase()) {
      case 'operational':
        return ServiceHealthStatus.operational;
      case 'degraded':
        return ServiceHealthStatus.degraded;
      case 'down':
        return ServiceHealthStatus.down;
      case 'unknown':
      default:
        return ServiceHealthStatus.unknown;
    }
  }
  
  // MARK: - Real-Time Listeners
  /// Sets up a real-time listener for service status changes
  /// [onUpdate] - Callback function called when services are updated
  /// Returns StreamSubscription for the listener
  StreamSubscription<firestore.QuerySnapshot>? listenToServiceUpdates(
    void Function(List<ServiceStatus>) onUpdate,
  ) {
    if (!_firestoreAvailable || _firestore == null) {
      Logger.logDebug('Cannot set up real-time listener: Firestore not available', 
          'status_cache_service.dart', 'listenToServiceUpdates');
      return null;
    }
    
    try {
      final stream = _firestore!.collection(_collectionName)
          .where(firestore.FieldPath.documentId, isNotEqualTo: _lastUpdateDocId)
          .snapshots();
      
      return stream.listen((snapshot) {
        try {
          final services = <ServiceStatus>[];
          
          for (final doc in snapshot.docs) {
            if (doc.id == _lastUpdateDocId) continue;
            
            try {
              final service = _mapToServiceStatus(doc.id, doc.data());
              services.add(service);
            } catch (e) {
              Logger.logWarning('Error parsing real-time service update ${doc.id}: $e', 
                  'status_cache_service.dart', 'listenToServiceUpdates');
            }
          }
          
          Logger.logDebug('Real-time update: ${services.length} services', 
              'status_cache_service.dart', 'listenToServiceUpdates');
          onUpdate(services);
        } catch (e) {
          Logger.logError('Error processing real-time update', 
              'status_cache_service.dart', 'listenToServiceUpdates', e);
        }
      }, onError: (error) {
        Logger.logError('Real-time listener error', 
            'status_cache_service.dart', 'listenToServiceUpdates', error);
      });
    } catch (e) {
      Logger.logError('Error setting up real-time listener', 
          'status_cache_service.dart', 'listenToServiceUpdates', e);
      return null;
    }
  }
  
  // MARK: - Cleanup
  // Cleans up Firestore listeners
  void dispose() {
    _servicesListener?.cancel();
    _servicesListener = null;
    Logger.logInfo('StatusCacheService disposed', 
        'status_cache_service.dart', 'dispose');
  }
}

// Suggestions For Features and Additions Later:
// - Add cache expiration/TTL logic
// - Implement cache versioning for schema changes
// - Add cache statistics and monitoring
// - Create cache invalidation strategies
// - Add support for partial cache updates
// - Implement cache compression for large datasets
// - Add cache backup and restore functionality

