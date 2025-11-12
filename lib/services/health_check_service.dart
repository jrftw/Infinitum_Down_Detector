// Filename: health_check_service.dart
// Purpose: Service for performing health checks on monitored URLs
// Author: Kevin Doyle Jr. / Infinitum Imagery LLC
// Last Modified: 2025-01-27
// Dependencies: dio, config.dart, logger.dart, models/service_status.dart
// Platform Compatibility: Web, iOS, Android

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/config.dart';
import '../core/logger.dart';
import '../models/service_status.dart';
import '../models/service_component.dart';

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

  // MARK: - Helper Method: Process Health Check Response
  // Processes HTTP response and returns updated ServiceStatus
  // [serviceStatus] - Current service status
  // [response] - HTTP response from Dio
  // [startTime] - Start time of the request
  // Returns updated ServiceStatus
  ServiceStatus _processHealthCheckResponse({
    required ServiceStatus serviceStatus,
    required Response response,
    required DateTime startTime,
  }) {
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
          // Search for data feed issue text (case-insensitive, handles whitespace variations and line breaks)
          // The text can appear as: "Stats may be delayed/inaccurate due to a data feed issue."
          // Or with line break: "Stats may be delayed/inaccurate\ndue to a data feed issue."
          const dataFeedIssueText = 'Stats may be delayed/inaccurate due to a data feed issue.';
          final responseBodyLower = responseBody.toLowerCase();
          final searchTextLower = dataFeedIssueText.toLowerCase();
          
          // Normalize whitespace (replace all whitespace including line breaks with single space)
          final normalizedBody = responseBodyLower.replaceAll(RegExp(r'\s+'), ' ');
          final normalizedSearch = searchTextLower.replaceAll(RegExp(r'\s+'), ' ');
          
          // Check variations: with period, without period, with normalized whitespace
          final searchTextNoPeriod = normalizedSearch.replaceAll('.', '');
          hasDataFeedIssue = normalizedBody.contains(normalizedSearch) || 
                            normalizedBody.contains(searchTextNoPeriod) ||
                            (responseBodyLower.contains('stats may be delayed/inaccurate') &&
                            responseBodyLower.contains('data feed issue'));
          
          if (hasDataFeedIssue) {
            newStatus = ServiceHealthStatus.degraded;
            errorMessage = 'Data feed issue detected';
            consecutiveFailures++;
            Logger.logWarning('${serviceStatus.name} is up but has data feed issue', 
                'health_check_service.dart', '_processHealthCheckResponse');
          } else {
            newStatus = ServiceHealthStatus.operational;
            consecutiveFailures = 0;
            lastUpTime = DateTime.now();
            Logger.logInfo('${serviceStatus.name} is operational (${response.statusCode})', 
                'health_check_service.dart', '_processHealthCheckResponse');
          }
        } else {
          newStatus = ServiceHealthStatus.operational;
          consecutiveFailures = 0;
          lastUpTime = DateTime.now();
          Logger.logInfo('${serviceStatus.name} is operational (${response.statusCode})', 
              'health_check_service.dart', '_processHealthCheckResponse');
        }
      } catch (e) {
        // If we can't parse the response body, assume operational if status is good
        newStatus = ServiceHealthStatus.operational;
        consecutiveFailures = 0;
        lastUpTime = DateTime.now();
        Logger.logWarning('${serviceStatus.name} is operational but could not parse response body', 
            'health_check_service.dart', '_processHealthCheckResponse');
      }
    } else if (response.statusCode != null && response.statusCode! >= 400 && response.statusCode! < 500) {
      newStatus = ServiceHealthStatus.degraded;
      errorMessage = 'HTTP ${response.statusCode}';
      consecutiveFailures++;
      Logger.logWarning('${serviceStatus.name} returned ${response.statusCode}', 
          'health_check_service.dart', '_processHealthCheckResponse');
    } else {
      newStatus = ServiceHealthStatus.down;
      errorMessage = 'HTTP ${response.statusCode ?? "Unknown"}';
      consecutiveFailures++;
      Logger.logError('${serviceStatus.name} is down (${response.statusCode})', 
          'health_check_service.dart', '_processHealthCheckResponse');
    }
    
    return serviceStatus.copyWith(
      status: newStatus,
      lastChecked: DateTime.now(),
      lastUpTime: lastUpTime,
      responseTimeMs: responseTime,
      errorMessage: errorMessage,
      consecutiveFailures: consecutiveFailures,
    );
  }

  // MARK: - Health Check Methods
  /// Performs a health check on a single service
  /// On web, uses CORS proxy to bypass CORS restrictions
  /// On mobile, uses direct HTTP requests
  /// Also checks service components if they exist
  /// [serviceStatus] - The current service status to check
  /// Returns updated ServiceStatus with latest health information
  Future<ServiceStatus> checkServiceHealth(ServiceStatus serviceStatus) async {
    final startTime = DateTime.now();
    
    // MARK: - Check Components First
    // If service has components, check them first
    List<ServiceComponent> updatedComponents = [];
    if (serviceStatus.components.isNotEmpty) {
      Logger.logInfo('Checking ${serviceStatus.components.length} components for ${serviceStatus.name}', 
          'health_check_service.dart', 'checkServiceHealth');
      updatedComponents = await checkMultipleComponents(serviceStatus.components);
    }
    
    // MARK: - Web Platform: Use CORS Proxy
    // On web, always use CORS proxy for external domains to avoid CORS issues
    if (kIsWeb) {
      try {
        Logger.logDebug('Checking health for ${serviceStatus.name} (${serviceStatus.url})', 
            'health_check_service.dart', 'checkServiceHealth');
        
        // On web, always use CORS proxy for external requests
        // Try primary proxy first
        Response? proxyResponse;
        bool proxySuccess = false;
        
        try {
          final primaryProxyUrl = '$CORS_PROXY_URL${Uri.encodeComponent(serviceStatus.url)}';
          proxyResponse = await _dio.get(
            primaryProxyUrl,
            options: Options(
              validateStatus: (status) => status != null && status < 500,
              followRedirects: true,
              maxRedirects: 5,
              responseType: ResponseType.plain,
            ),
          );
          
          // If proxy returns content, treat as success (proxy returns 200 even if service is down)
          // We check if we got actual content back
          if (proxyResponse.data != null && proxyResponse.data.toString().isNotEmpty) {
            proxySuccess = true;
            final mainResult = _processHealthCheckResponse(
              serviceStatus: serviceStatus,
              response: proxyResponse,
              startTime: startTime,
            );
            return _combineServiceAndComponentStatus(mainResult, updatedComponents);
          }
        } on DioException catch (e) {
          Logger.logDebug('Primary CORS proxy failed for ${serviceStatus.name}, trying fallback', 
              'health_check_service.dart', 'checkServiceHealth');
        }
        
        // Try fallback proxy if primary failed or returned empty
        if (!proxySuccess) {
          try {
            final fallbackProxyUrl = '$CORS_PROXY_FALLBACK_URL${Uri.encodeComponent(serviceStatus.url)}';
            proxyResponse = await _dio.get(
              fallbackProxyUrl,
              options: Options(
                validateStatus: (status) => status != null && status < 500,
                followRedirects: true,
                maxRedirects: 5,
                responseType: ResponseType.plain,
              ),
            );
            
            if (proxyResponse.data != null && proxyResponse.data.toString().isNotEmpty) {
              proxySuccess = true;
              final mainResult = _processHealthCheckResponse(
                serviceStatus: serviceStatus,
                response: proxyResponse,
                startTime: startTime,
              );
              return _combineServiceAndComponentStatus(mainResult, updatedComponents);
            }
          } on DioException catch (e) {
            Logger.logDebug('Fallback CORS proxy failed for ${serviceStatus.name}, trying direct request', 
                'health_check_service.dart', 'checkServiceHealth');
          }
        }
        
        // If both proxies failed, try direct request as last resort
        try {
          final response = await _dio.get(
            serviceStatus.url,
            options: Options(
              validateStatus: (status) => status != null && status < 500,
              followRedirects: true,
              maxRedirects: 5,
              responseType: ResponseType.plain,
            ),
          );
          
          final mainResult = _processHealthCheckResponse(
            serviceStatus: serviceStatus,
            response: response,
            startTime: startTime,
          );
          return _combineServiceAndComponentStatus(mainResult, updatedComponents);
        } catch (directError) {
          // All methods failed
          final endTime = DateTime.now();
          final responseTime = endTime.difference(startTime).inMilliseconds;
          
          String errorMsg = 'All connection methods failed';
          ServiceHealthStatus newStatus = ServiceHealthStatus.unknown;
          
          if (directError is DioException) {
            if (directError.type == DioExceptionType.connectionTimeout || 
                directError.type == DioExceptionType.receiveTimeout) {
              errorMsg = 'Connection timeout';
              newStatus = ServiceHealthStatus.down;
            } else if (directError.type == DioExceptionType.connectionError) {
              errorMsg = 'Connection error (CORS blocked)';
              newStatus = ServiceHealthStatus.unknown;
            } else {
              errorMsg = directError.message ?? 'Unknown error';
            }
          }
          
          Logger.logError('Error checking ${serviceStatus.name} on web: $errorMsg', 
              'health_check_service.dart', 'checkServiceHealth', directError);
          
          final errorResult = serviceStatus.copyWith(
            status: newStatus,
            lastChecked: DateTime.now(),
            responseTimeMs: responseTime,
            errorMessage: errorMsg,
            consecutiveFailures: serviceStatus.consecutiveFailures + 1,
            components: updatedComponents,
          );
          return _combineServiceAndComponentStatus(errorResult, updatedComponents);
        }
      } catch (e) {
        final endTime = DateTime.now();
        final responseTime = endTime.difference(startTime).inMilliseconds;
        
        Logger.logError('Unexpected error checking ${serviceStatus.name} on web', 
            'health_check_service.dart', 'checkServiceHealth', e);
        
        final errorResult = serviceStatus.copyWith(
          status: ServiceHealthStatus.unknown,
          lastChecked: DateTime.now(),
          responseTimeMs: responseTime,
          errorMessage: 'Error: ${e.toString()}',
          consecutiveFailures: serviceStatus.consecutiveFailures + 1,
          components: updatedComponents,
        );
        return _combineServiceAndComponentStatus(errorResult, updatedComponents);
      }
    }
    
    // MARK: - Mobile Platform: Use Direct HTTP
    // On mobile (iOS/Android), use direct HTTP requests (no CORS restrictions)
    ServiceStatus mainServiceResult;
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
      
      mainServiceResult = _processHealthCheckResponse(
        serviceStatus: serviceStatus,
        response: response,
        startTime: startTime,
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
      
      mainServiceResult = serviceStatus.copyWith(
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
      
      mainServiceResult = serviceStatus.copyWith(
        status: ServiceHealthStatus.unknown,
        lastChecked: DateTime.now(),
        responseTimeMs: responseTime,
        errorMessage: 'Unexpected error: ${e.toString()}',
        consecutiveFailures: serviceStatus.consecutiveFailures + 1,
      );
    }
    
    // Combine main service result with component results
    return _combineServiceAndComponentStatus(mainServiceResult, updatedComponents);
  }

  // MARK: - Helper Method: Combine Service and Component Status
  // Combines main service status with component statuses to determine overall status
  ServiceStatus _combineServiceAndComponentStatus(
    ServiceStatus serviceResult,
    List<ServiceComponent> components,
  ) {
    // If no components, return service result as-is
    if (components.isEmpty) {
      return serviceResult;
    }
    
    // Determine overall status from components
    final hasDown = components.any((c) => c.status == ServiceHealthStatus.down);
    final hasDegraded = components.any((c) => c.status == ServiceHealthStatus.degraded);
    final allOperational = components.every((c) => c.status == ServiceHealthStatus.operational);
    
    ServiceHealthStatus finalStatus;
    if (hasDown) {
      finalStatus = ServiceHealthStatus.down;
    } else if (hasDegraded) {
      finalStatus = ServiceHealthStatus.degraded;
    } else if (allOperational) {
      finalStatus = ServiceHealthStatus.operational;
    } else {
      // If components have mixed status, use the worse of service status or component status
      finalStatus = serviceResult.status;
    }
    
    return serviceResult.copyWith(
      status: finalStatus,
      components: components,
    );
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

  // MARK: - Component Health Check Methods
  /// Performs a health check on a single component/endpoint
  /// [component] - The component to check
  /// Returns updated ServiceComponent with latest health information
  Future<ServiceComponent> checkComponentHealth(ServiceComponent component) async {
    final startTime = DateTime.now();
    
    // MARK: - Web Platform: Use CORS Proxy
    if (kIsWeb) {
      try {
        Logger.logDebug('Checking component health for ${component.name} (${component.url})', 
            'health_check_service.dart', 'checkComponentHealth');
        
        Response? proxyResponse;
        bool proxySuccess = false;
        
        try {
          final primaryProxyUrl = '$CORS_PROXY_URL${Uri.encodeComponent(component.url)}';
          proxyResponse = await _dio.get(
            primaryProxyUrl,
            options: Options(
              validateStatus: (status) => status != null && status < 500,
              followRedirects: true,
              maxRedirects: 5,
              responseType: ResponseType.plain,
            ),
          );
          
          if (proxyResponse.data != null && proxyResponse.data.toString().isNotEmpty) {
            proxySuccess = true;
            return _processComponentResponse(component: component, response: proxyResponse, startTime: startTime);
          }
        } on DioException catch (e) {
          Logger.logDebug('Primary CORS proxy failed for ${component.name}, trying fallback', 
              'health_check_service.dart', 'checkComponentHealth');
        }
        
        if (!proxySuccess) {
          try {
            final fallbackProxyUrl = '$CORS_PROXY_FALLBACK_URL${Uri.encodeComponent(component.url)}';
            proxyResponse = await _dio.get(
              fallbackProxyUrl,
              options: Options(
                validateStatus: (status) => status != null && status < 500,
                followRedirects: true,
                maxRedirects: 5,
                responseType: ResponseType.plain,
              ),
            );
            
            if (proxyResponse.data != null && proxyResponse.data.toString().isNotEmpty) {
              proxySuccess = true;
              return _processComponentResponse(component: component, response: proxyResponse, startTime: startTime);
            }
          } on DioException catch (e) {
            Logger.logDebug('Fallback CORS proxy failed for ${component.name}, trying direct request', 
                'health_check_service.dart', 'checkComponentHealth');
          }
        }
        
        // Try direct request as last resort
        try {
          final response = await _dio.get(
            component.url,
            options: Options(
              validateStatus: (status) => status != null && status < 500,
              followRedirects: true,
              maxRedirects: 5,
              responseType: ResponseType.plain,
            ),
          );
          
          return _processComponentResponse(component: component, response: response, startTime: startTime);
        } catch (directError) {
          return _handleComponentError(component: component, error: directError, startTime: startTime);
        }
      } catch (e) {
        return _handleComponentError(component: component, error: e, startTime: startTime);
      }
    }
    
    // MARK: - Mobile Platform: Use Direct HTTP
    try {
      Logger.logDebug('Checking component health for ${component.name} (${component.url})', 
          'health_check_service.dart', 'checkComponentHealth');
      
      final response = await _dio.get(
        component.url,
        options: Options(
          validateStatus: (status) => status != null && status < 500,
          followRedirects: true,
          maxRedirects: 5,
          responseType: ResponseType.plain,
        ),
      );
      
      return _processComponentResponse(component: component, response: response, startTime: startTime);
      
    } catch (e) {
      return _handleComponentError(component: component, error: e, startTime: startTime);
    }
  }

  // MARK: - Helper Method: Process Component Response
  // Processes HTTP response for a component and returns updated ServiceComponent
  ServiceComponent _processComponentResponse({
    required ServiceComponent component,
    required Response response,
    required DateTime startTime,
  }) {
    final endTime = DateTime.now();
    final responseTime = endTime.difference(startTime).inMilliseconds;
    
    ServiceHealthStatus newStatus;
    String? errorMessage;
    
    if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 400) {
      newStatus = ServiceHealthStatus.operational;
      Logger.logInfo('${component.name} is operational (${response.statusCode})', 
          'health_check_service.dart', '_processComponentResponse');
    } else if (response.statusCode != null && response.statusCode! >= 400 && response.statusCode! < 500) {
      newStatus = ServiceHealthStatus.degraded;
      errorMessage = 'HTTP ${response.statusCode}';
      Logger.logWarning('${component.name} returned ${response.statusCode}', 
          'health_check_service.dart', '_processComponentResponse');
    } else {
      newStatus = ServiceHealthStatus.down;
      errorMessage = 'HTTP ${response.statusCode ?? "Unknown"}';
      Logger.logError('${component.name} is down (${response.statusCode})', 
          'health_check_service.dart', '_processComponentResponse');
    }
    
    return component.copyWith(
      status: newStatus,
      lastChecked: DateTime.now(),
      responseTimeMs: responseTime,
      errorMessage: errorMessage,
      statusCode: response.statusCode,
    );
  }

  // MARK: - Helper Method: Handle Component Error
  // Handles errors during component health checks
  ServiceComponent _handleComponentError({
    required ServiceComponent component,
    required dynamic error,
    required DateTime startTime,
  }) {
    final endTime = DateTime.now();
    final responseTime = endTime.difference(startTime).inMilliseconds;
    
    String errorMsg;
    ServiceHealthStatus newStatus;
    
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout || 
          error.type == DioExceptionType.receiveTimeout) {
        errorMsg = 'Connection timeout';
        newStatus = ServiceHealthStatus.down;
      } else if (error.type == DioExceptionType.connectionError) {
        errorMsg = kIsWeb ? 'Connection error (CORS blocked)' : 'Connection error';
        newStatus = kIsWeb ? ServiceHealthStatus.unknown : ServiceHealthStatus.down;
      } else {
        errorMsg = error.message ?? 'Unknown error';
        newStatus = ServiceHealthStatus.degraded;
      }
    } else {
      errorMsg = 'Unexpected error: ${error.toString()}';
      newStatus = ServiceHealthStatus.unknown;
    }
    
    Logger.logError('Error checking ${component.name}: $errorMsg', 
        'health_check_service.dart', '_handleComponentError', error);
    
    return component.copyWith(
      status: newStatus,
      lastChecked: DateTime.now(),
      responseTimeMs: responseTime,
      errorMessage: errorMsg,
    );
  }

  /// Performs health checks on multiple components concurrently
  /// [components] - List of components to check
  /// Returns list of updated ServiceComponent objects
  Future<List<ServiceComponent>> checkMultipleComponents(List<ServiceComponent> components) async {
    Logger.logInfo('Checking ${components.length} components', 
        'health_check_service.dart', 'checkMultipleComponents');
    
    final futures = components.map((component) => checkComponentHealth(component));
    final results = await Future.wait(futures);
    
    Logger.logInfo('Completed health checks for ${components.length} components', 
        'health_check_service.dart', 'checkMultipleComponents');
    
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

