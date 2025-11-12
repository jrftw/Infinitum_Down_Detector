// Filename: health_check_service.dart
// Purpose: Service for performing health checks on monitored URLs
// Author: Kevin Doyle Jr. / Infinitum Imagery LLC
// Last Modified: 2025-01-27
// Dependencies: dio, cloud_functions, config.dart, logger.dart, models/service_status.dart
// Platform Compatibility: Web, iOS, Android

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../core/config.dart';
import '../core/logger.dart';
import '../models/service_status.dart';

// MARK: - Health Check Service
// Handles HTTP health checks for monitored services
class HealthCheckService {
  late final Dio _dio;
  Timer? _periodicTimer;
  
  // MARK: - Initialization
  // Sets up the HTTP client with appropriate configuration
  HealthCheckService() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: Duration(seconds: HTTP_REQUEST_TIMEOUT),
        receiveTimeout: Duration(seconds: HTTP_REQUEST_TIMEOUT),
        headers: {
          'User-Agent': 'InfinitumDownDetector/1.0',
        },
      ),
    );
    
    Logger.logInfo('HealthCheckService initialized', 'health_check_service.dart', 'HealthCheckService');
  }

  // MARK: - Health Check Methods
  /// Performs a health check on a single service
  /// On web, uses Firebase Functions to bypass CORS restrictions
  /// On mobile, uses direct HTTP requests
  /// [serviceStatus] - The current service status to check
  /// Returns updated ServiceStatus with latest health information
  Future<ServiceStatus> checkServiceHealth(ServiceStatus serviceStatus) async {
    final startTime = DateTime.now();
    
    // MARK: - Web Platform: Use Firebase Functions
    // On web, use Firebase Functions to bypass CORS restrictions
    if (kIsWeb) {
      try {
        Logger.logDebug('Checking health for ${serviceStatus.name} via Firebase Function (${serviceStatus.url})', 
            'health_check_service.dart', 'checkServiceHealth');
        
        final functions = FirebaseFunctions.instance;
        final callable = functions.httpsCallable('checkServiceHealth');
        
        final result = await callable.call({
          'url': serviceStatus.url,
          'serviceId': serviceStatus.id,
          'serviceName': serviceStatus.name,
        });
        
        final data = result.data as Map<String, dynamic>;
        final endTime = DateTime.now();
        final responseTime = data['responseTime'] as int? ?? endTime.difference(startTime).inMilliseconds;
        
        ServiceHealthStatus newStatus;
        final statusString = data['status'] as String? ?? 'unknown';
        switch (statusString) {
          case 'operational':
            newStatus = ServiceHealthStatus.operational;
            break;
          case 'degraded':
            newStatus = ServiceHealthStatus.degraded;
            break;
          case 'down':
            newStatus = ServiceHealthStatus.down;
            break;
          default:
            newStatus = ServiceHealthStatus.unknown;
        }
        
        final errorMessage = data['errorMessage'] as String?;
        final hasDataFeedIssue = data['hasDataFeedIssue'] as bool? ?? false;
        
        int consecutiveFailures = serviceStatus.consecutiveFailures;
        DateTime? lastUpTime = serviceStatus.lastUpTime;
        
        if (newStatus == ServiceHealthStatus.operational) {
          consecutiveFailures = 0;
          lastUpTime = DateTime.now();
          Logger.logInfo('${serviceStatus.name} is operational', 
              'health_check_service.dart', 'checkServiceHealth');
        } else if (hasDataFeedIssue) {
          consecutiveFailures++;
          Logger.logWarning('${serviceStatus.name} is up but has data feed issue', 
              'health_check_service.dart', 'checkServiceHealth');
        } else {
          consecutiveFailures++;
          Logger.logWarning('${serviceStatus.name} status: $statusString', 
              'health_check_service.dart', 'checkServiceHealth');
        }
        
        return serviceStatus.copyWith(
          status: newStatus,
          lastChecked: DateTime.now(),
          lastUpTime: lastUpTime,
          responseTimeMs: responseTime,
          errorMessage: errorMessage,
          consecutiveFailures: consecutiveFailures,
        );
        
      } on FirebaseFunctionsException catch (e) {
        final endTime = DateTime.now();
        final responseTime = endTime.difference(startTime).inMilliseconds;
        
        Logger.logError('Firebase Function error checking ${serviceStatus.name}: ${e.message}', 
            'health_check_service.dart', 'checkServiceHealth', e);
        
        return serviceStatus.copyWith(
          status: ServiceHealthStatus.unknown,
          lastChecked: DateTime.now(),
          responseTimeMs: responseTime,
          errorMessage: 'Function error: ${e.message}',
          consecutiveFailures: serviceStatus.consecutiveFailures + 1,
        );
      } catch (e) {
        final endTime = DateTime.now();
        final responseTime = endTime.difference(startTime).inMilliseconds;
        
        Logger.logError('Unexpected error checking ${serviceStatus.name} via Firebase Function', 
            'health_check_service.dart', 'checkServiceHealth', e);
        
        return serviceStatus.copyWith(
          status: ServiceHealthStatus.unknown,
          lastChecked: DateTime.now(),
          responseTimeMs: responseTime,
          errorMessage: 'Unexpected error: ${e.toString()}',
          consecutiveFailures: serviceStatus.consecutiveFailures + 1,
        );
      }
    }
    
    // MARK: - Mobile Platform: Use Direct HTTP
    // On mobile (iOS/Android), use direct HTTP requests (no CORS restrictions)
    try {
      Logger.logDebug('Checking health for ${serviceStatus.name} (${serviceStatus.url})', 
          'health_check_service.dart', 'checkServiceHealth');
      
      final response = await _dio.get(
        serviceStatus.url,
        options: Options(
          validateStatus: (status) => status != null && status < 500,
          followRedirects: true,
          maxRedirects: 5,
          responseType: ResponseType.plain, // Get response as plain text for content checking
        ),
      );
      
      final endTime = DateTime.now();
      final responseTime = endTime.difference(startTime).inMilliseconds;
      
      ServiceHealthStatus newStatus;
      String? errorMessage;
      int consecutiveFailures = serviceStatus.consecutiveFailures;
      DateTime? lastUpTime = serviceStatus.lastUpTime;
      
      // MARK: - Response Body Content Check
      // Check response body for specific issues (e.g., data feed issues for iView)
      String? responseBody;
      bool hasDataFeedIssue = false;
      
      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 400) {
        // Get response body as string for content checking
        try {
          responseBody = response.data?.toString() ?? '';
          
          // Check for data feed issue specifically for iView/InfiniView
          if (serviceStatus.id == 'infinitum-view') {
            // Search for data feed issue text (case-insensitive, handles whitespace variations)
            const dataFeedIssueText = 'Stats may be delayed/inaccurate due to a data feed issue.';
            final responseBodyLower = responseBody.toLowerCase();
            final searchTextLower = dataFeedIssueText.toLowerCase();
            // Also check for variations without the period
            final searchTextNoPeriod = searchTextLower.replaceAll('.', '');
            hasDataFeedIssue = responseBodyLower.contains(searchTextLower) || 
                              responseBodyLower.contains(searchTextNoPeriod);
            
            if (hasDataFeedIssue) {
              newStatus = ServiceHealthStatus.degraded;
              errorMessage = 'Data feed issue detected';
              consecutiveFailures++;
              Logger.logWarning('${serviceStatus.name} is up but has data feed issue', 
                  'health_check_service.dart', 'checkServiceHealth');
            } else {
              newStatus = ServiceHealthStatus.operational;
              consecutiveFailures = 0;
              lastUpTime = DateTime.now();
              Logger.logInfo('${serviceStatus.name} is operational (${response.statusCode})', 
                  'health_check_service.dart', 'checkServiceHealth');
            }
          } else {
            newStatus = ServiceHealthStatus.operational;
            consecutiveFailures = 0;
            lastUpTime = DateTime.now();
            Logger.logInfo('${serviceStatus.name} is operational (${response.statusCode})', 
                'health_check_service.dart', 'checkServiceHealth');
          }
        } catch (e) {
          // If we can't parse the response body, assume operational if status is good
          newStatus = ServiceHealthStatus.operational;
          consecutiveFailures = 0;
          lastUpTime = DateTime.now();
          Logger.logWarning('${serviceStatus.name} is operational but could not parse response body', 
              'health_check_service.dart', 'checkServiceHealth');
        }
      } else if (response.statusCode != null && response.statusCode! >= 400 && response.statusCode! < 500) {
        newStatus = ServiceHealthStatus.degraded;
        errorMessage = 'HTTP ${response.statusCode}';
        consecutiveFailures++;
        Logger.logWarning('${serviceStatus.name} returned ${response.statusCode}', 
            'health_check_service.dart', 'checkServiceHealth');
      } else {
        newStatus = ServiceHealthStatus.down;
        errorMessage = 'HTTP ${response.statusCode ?? "Unknown"}';
        consecutiveFailures++;
        Logger.logError('${serviceStatus.name} is down (${response.statusCode})', 
            'health_check_service.dart', 'checkServiceHealth');
      }
      
      return serviceStatus.copyWith(
        status: newStatus,
        lastChecked: DateTime.now(),
        lastUpTime: lastUpTime,
        responseTimeMs: responseTime,
        errorMessage: errorMessage,
        consecutiveFailures: consecutiveFailures,
      );
      
    } on DioException catch (e) {
      final endTime = DateTime.now();
      final responseTime = endTime.difference(startTime).inMilliseconds;
      
      String errorMsg;
      ServiceHealthStatus newStatus;
      
      if (e.type == DioExceptionType.connectionTimeout || 
          e.type == DioExceptionType.receiveTimeout) {
        errorMsg = 'Connection timeout';
        newStatus = ServiceHealthStatus.down;
      } else if (e.type == DioExceptionType.connectionError) {
        errorMsg = 'Connection error';
        newStatus = ServiceHealthStatus.down;
      } else {
        errorMsg = e.message ?? 'Unknown error';
        newStatus = ServiceHealthStatus.degraded;
      }
      
      Logger.logError('Health check failed for ${serviceStatus.name}: $errorMsg', 
          'health_check_service.dart', 'checkServiceHealth', e);
      
      return serviceStatus.copyWith(
        status: newStatus,
        lastChecked: DateTime.now(),
        responseTimeMs: responseTime,
        errorMessage: errorMsg,
        consecutiveFailures: serviceStatus.consecutiveFailures + 1,
      );
      
    } catch (e) {
      final endTime = DateTime.now();
      final responseTime = endTime.difference(startTime).inMilliseconds;
      
      Logger.logError('Unexpected error checking ${serviceStatus.name}', 
          'health_check_service.dart', 'checkServiceHealth', e);
      
      return serviceStatus.copyWith(
        status: ServiceHealthStatus.unknown,
        lastChecked: DateTime.now(),
        responseTimeMs: responseTime,
        errorMessage: 'Unexpected error: ${e.toString()}',
        consecutiveFailures: serviceStatus.consecutiveFailures + 1,
      );
    }
  }
  
  /// Performs health checks on multiple services concurrently
  /// [services] - List of services to check
  /// Returns list of updated ServiceStatus objects
  Future<List<ServiceStatus>> checkMultipleServices(List<ServiceStatus> services) async {
    Logger.logInfo('Checking ${services.length} services', 
        'health_check_service.dart', 'checkMultipleServices');
    
    final futures = services.map((service) => checkServiceHealth(service));
    final results = await Future.wait(futures);
    
    Logger.logInfo('Completed health checks for ${services.length} services', 
        'health_check_service.dart', 'checkMultipleServices');
    
    return results;
  }
  
  // MARK: - Cleanup
  // Cancels any active periodic timers
  void dispose() {
    _periodicTimer?.cancel();
    _dio.close();
    Logger.logInfo('HealthCheckService disposed', 'health_check_service.dart', 'dispose');
  }
}

// Suggestions For Features and Additions Later:
// - Add retry logic with exponential backoff
// - Implement health check result caching
// - Add custom health check endpoints per service
// - Create health check result history
// - Add SSL certificate validation checks
// - Implement service-specific timeout configurations
// - Add response body validation
// - Create health check scheduling system

