// Filename: service_status_provider.dart
// Purpose: State management provider for service status monitoring
// Author: Kevin Doyle Jr. / Infinitum Imagery LLC
// Last Modified: 2025-01-27
// Dependencies: flutter, models/service_status.dart, services/health_check_service.dart, services/third_party_status_service.dart, services/status_cache_service.dart, core/config.dart, core/logger.dart
// Platform Compatibility: Web, iOS, Android

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import '../models/service_status.dart';
import '../services/health_check_service.dart';
import '../services/third_party_status_service.dart';
import '../services/status_cache_service.dart';
import '../core/config.dart';
import '../core/logger.dart';
import '../models/service_component.dart';

// MARK: - Service Status Provider
// Manages the state of all monitored services and coordinates health checks
class ServiceStatusProvider with ChangeNotifier {
  final HealthCheckService _healthCheckService;
  final ThirdPartyStatusService _thirdPartyStatusService;
  final StatusCacheService _cacheService;
  
  List<ServiceStatus> _infinitumServices = [];
  List<ServiceStatus> _thirdPartyServices = [];
  bool _isChecking = false;
  Timer? _periodicCheckTimer;
  DateTime? _lastCheckTime;
  StreamSubscription<firestore.QuerySnapshot>? _realtimeListener;
  
  // MARK: - Getters
  // Returns list of all Infinitum services
  List<ServiceStatus> get infinitumServices => List.unmodifiable(_infinitumServices);
  
  // Returns list of all third-party services
  List<ServiceStatus> get thirdPartyServices => List.unmodifiable(_thirdPartyServices);
  
  // Returns all services combined
  List<ServiceStatus> get allServices => [..._infinitumServices, ..._thirdPartyServices];
  
  // Returns whether a health check is currently in progress
  bool get isChecking => _isChecking;
  
  // Returns the last check time
  DateTime? get lastCheckTime => _lastCheckTime;
  
  // Returns count of operational services
  int get operationalCount => allServices.where((s) => s.isOperational).length;
  
  // Returns count of services with issues
  int get issuesCount => allServices.where((s) => s.hasIssues).length;
  
  // MARK: - Initialization
  // Initializes the provider and sets up initial service list
  ServiceStatusProvider({
    HealthCheckService? healthCheckService, 
    ThirdPartyStatusService? thirdPartyStatusService,
    StatusCacheService? cacheService,
  }) : _healthCheckService = healthCheckService ?? HealthCheckService(),
        _thirdPartyStatusService = thirdPartyStatusService ?? ThirdPartyStatusService(),
        _cacheService = cacheService ?? StatusCacheService() {
    _initializeServices();
    _loadFromCache();
    _setupRealtimeListener();
    Logger.logInfo('ServiceStatusProvider initialized', 'service_status_provider.dart', 'ServiceStatusProvider');
  }
  
  // MARK: - Real-Time Updates
  /// Sets up real-time listener for service status updates from Firestore
  /// Returns void
  void _setupRealtimeListener() {
    _realtimeListener = _cacheService.listenToServiceUpdates((updatedServices) {
      if (updatedServices.isEmpty) return;
      
      // Create a map of updated services by ID
      final updatedMap = <String, ServiceStatus>{};
      for (final service in updatedServices) {
        updatedMap[service.id] = service;
      }
      
      // Update infinitum services
      bool infinitumUpdated = false;
      for (int i = 0; i < _infinitumServices.length; i++) {
        final updated = updatedMap[_infinitumServices[i].id];
        if (updated != null) {
          _infinitumServices[i] = updated;
          infinitumUpdated = true;
        }
      }
      
      // Update third-party services
      bool thirdPartyUpdated = false;
      for (int i = 0; i < _thirdPartyServices.length; i++) {
        final updated = updatedMap[_thirdPartyServices[i].id];
        if (updated != null) {
          _thirdPartyServices[i] = updated;
          thirdPartyUpdated = true;
        }
      }
      
      if (infinitumUpdated || thirdPartyUpdated) {
        Logger.logDebug('Real-time update received: ${updatedServices.length} services', 
            'service_status_provider.dart', '_setupRealtimeListener');
        notifyListeners();
      }
    });
  }
  
  // MARK: - Cache Operations
  /// Loads service statuses from cache
  /// Returns void
  Future<void> _loadFromCache() async {
    try {
      final cachedServices = await _cacheService.loadServiceStatuses();
      if (cachedServices.isEmpty) {
        Logger.logDebug('No cached services found', 'service_status_provider.dart', '_loadFromCache');
        return;
      }
      
      // Merge cached services with initialized services
      final cachedMap = <String, ServiceStatus>{};
      for (final service in cachedServices) {
        cachedMap[service.id] = service;
      }
      
      // Update infinitum services with cached data
      _infinitumServices = _infinitumServices.map((service) {
        final cached = cachedMap[service.id];
        return cached ?? service;
      }).toList();
      
      // Update third-party services with cached data
      _thirdPartyServices = _thirdPartyServices.map((service) {
        final cached = cachedMap[service.id];
        return cached ?? service;
      }).toList();
      
      // Update last check time from cache
      final lastUpdate = await _cacheService.getLastUpdateTime();
      if (lastUpdate != null) {
        _lastCheckTime = lastUpdate;
      }
      
      notifyListeners();
      Logger.logInfo('Loaded ${cachedServices.length} services from cache', 
          'service_status_provider.dart', '_loadFromCache');
    } catch (e) {
      Logger.logError('Error loading from cache', 'service_status_provider.dart', '_loadFromCache', e);
    }
  }
  
  /// Saves service statuses to cache
  /// Returns void
  Future<void> _saveToCache() async {
    try {
      final allServices = [..._infinitumServices, ..._thirdPartyServices];
      await _cacheService.saveServiceStatuses(allServices);
      Logger.logDebug('Saved ${allServices.length} services to cache', 
          'service_status_provider.dart', '_saveToCache');
    } catch (e) {
      Logger.logError('Error saving to cache', 'service_status_provider.dart', '_saveToCache', e);
    }
  }
  
  // MARK: - Service Initialization
  // Creates initial service status objects for all monitored services
  void _initializeServices() {
    _infinitumServices = [
      ServiceStatus.initial(
        id: 'infinitum-view',
        name: 'iView/InfiniView',
        url: 'https://view.infinitumlive.com/',
        type: ServiceType.infinitum,
        components: ServiceComponentDefinitions.getComponentsForService('infinitum-view'),
      ),
      ServiceStatus.initial(
        id: 'infinitum-live',
        name: 'Infinitum Live',
        url: 'https://infinitumlive.com/',
        type: ServiceType.infinitum,
        components: ServiceComponentDefinitions.getComponentsForService('infinitum-live'),
      ),
      ServiceStatus.initial(
        id: 'infinitum-crm',
        name: 'Infinitum CRM',
        url: 'https://crm.infinitumlive.com/',
        type: ServiceType.infinitum,
        components: ServiceComponentDefinitions.getComponentsForService('infinitum-crm'),
      ),
      ServiceStatus.initial(
        id: 'infinitum-onboarding',
        name: 'Onboarding',
        url: 'https://infinitum-onboarding.web.app/',
        type: ServiceType.infinitum,
        components: ServiceComponentDefinitions.getComponentsForService('infinitum-onboarding'),
      ),
      ServiceStatus.initial(
        id: 'infinitum-board',
        name: 'InfiniBoard',
        url: 'https://iboard2--infinitum-dashboard.us-east4.hosted.app/',
        type: ServiceType.infinitum,
      ),
      ServiceStatus.initial(
        id: 'infinitum-imagery',
        name: 'Infinitum Imagery',
        url: 'https://www.infinitumimagery.com/',
        type: ServiceType.infinitum,
      ),
    ];
    
    _thirdPartyServices = [
      ServiceStatus.initial(
        id: 'firebase',
        name: 'Firebase',
        url: 'https://status.firebase.google.com/',
        type: ServiceType.thirdParty,
        components: ServiceComponentDefinitions.getComponentsForService('firebase'),
      ),
      ServiceStatus.initial(
        id: 'google',
        name: 'Google Services',
        url: 'https://www.google.com/appsstatus/dashboard/',
        type: ServiceType.thirdParty,
        components: ServiceComponentDefinitions.getComponentsForService('google'),
      ),
      ServiceStatus.initial(
        id: 'apple',
        name: 'Apple Services',
        url: 'https://www.apple.com/support/systemstatus/',
        type: ServiceType.thirdParty,
      ),
      ServiceStatus.initial(
        id: 'discord',
        name: 'Discord',
        url: 'https://discordstatus.com/',
        type: ServiceType.thirdParty,
      ),
      ServiceStatus.initial(
        id: 'tiktok',
        name: 'TikTok',
        url: 'https://www.tiktok.com/',
        type: ServiceType.thirdParty,
      ),
      ServiceStatus.initial(
        id: 'aws',
        name: 'AWS',
        url: 'https://status.aws.amazon.com/',
        type: ServiceType.thirdParty,
      ),
    ];
    
    Logger.logInfo('Initialized ${_infinitumServices.length} Infinitum services and ${_thirdPartyServices.length} third-party services', 
        'service_status_provider.dart', '_initializeServices');
  }
  
  // MARK: - Health Check Methods
  /// Performs health checks on all services
  /// NOTE: Health checks are now performed server-side by scheduled Firebase Function
  /// This method is kept for manual refresh capability but primarily relies on Firestore updates
  /// Returns void, notifies listeners when complete
  Future<void> checkAllServices() async {
    // Health checks are now performed server-side by scheduled Firebase Function
    // The real-time listener will automatically update the UI when Firestore is updated
    // This method is kept for compatibility but does not perform client-side checks
    Logger.logInfo('Health checks are performed server-side. Reading from Firestore cache.', 
        'service_status_provider.dart', 'checkAllServices');
    
    // Reload from cache to get latest server-side results
    await _loadFromCache();
    notifyListeners();
  }
  
  /// Performs a health check on a single service
  /// NOTE: Health checks are now performed server-side by scheduled Firebase Function
  /// This method reloads the service from Firestore cache
  /// [serviceId] - ID of the service to refresh
  /// Returns void, notifies listeners when complete
  Future<void> checkService(String serviceId) async {
    // Health checks are now performed server-side
    // Just reload from cache to get latest server-side results
    Logger.logInfo('Health checks are server-side. Reloading service $serviceId from Firestore cache.', 
        'service_status_provider.dart', 'checkService');
    
    await _loadFromCache();
    notifyListeners();
  }
  
  // MARK: - Periodic Checking
  /// Starts periodic health checks
  /// NOTE: Health checks are now performed server-side by scheduled Firebase Function
  /// This method is kept for compatibility but does not start client-side checks
  /// The real-time listener automatically updates the UI when Firestore is updated
  /// [intervalSeconds] - Interval between checks in seconds (ignored, server handles this)
  /// Returns void
  void startPeriodicChecks({int intervalSeconds = DEFAULT_HEALTH_CHECK_INTERVAL}) {
    stopPeriodicChecks();
    
    Logger.logInfo('Health checks are performed server-side by scheduled Firebase Function. Real-time listener is active.', 
        'service_status_provider.dart', 'startPeriodicChecks');
    
    // No need for client-side periodic checks - server handles this
    // Real-time listener will automatically update UI when Firestore is updated
    
    // Load initial data from cache
    _loadFromCache();
  }
  
  /// Stops periodic health checks
  /// NOTE: This is kept for compatibility but has no effect since checks are server-side
  /// Returns void
  void stopPeriodicChecks() {
    _periodicCheckTimer?.cancel();
    _periodicCheckTimer = null;
    Logger.logInfo('Periodic checks are server-side. Real-time listener remains active.', 
        'service_status_provider.dart', 'stopPeriodicChecks');
  }
  
  // MARK: - Cleanup
  // Disposes resources and stops timers
  @override
  void dispose() {
    stopPeriodicChecks();
    _realtimeListener?.cancel();
    _realtimeListener = null;
    _healthCheckService.dispose();
    _thirdPartyStatusService.dispose();
    _cacheService.dispose();
    Logger.logInfo('ServiceStatusProvider disposed', 'service_status_provider.dart', 'dispose');
    super.dispose();
  }
}

// Suggestions For Features and Additions Later:
// - Add service status history tracking
// - Implement status change notifications
// - Add service grouping and filtering
// - Create status aggregation and statistics
// - Add custom check intervals per service
// - Implement status caching and persistence
// - Add service dependency tracking
// - Create status export functionality

