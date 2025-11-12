// Filename: third_party_status_service.dart
// Purpose: Service for checking third-party service status (Firebase, Google, Apple, Discord, TikTok)
// Author: Kevin Doyle Jr. / Infinitum Imagery LLC
// Last Modified: 2025-01-27
// Dependencies: dio, config.dart, logger.dart, models/service_status.dart
// Platform Compatibility: Web, iOS, Android

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/config.dart';
import '../core/logger.dart';
import '../models/service_status.dart';

// MARK: - Third Party Status Service
// Handles status checks for third-party services
class ThirdPartyStatusService {
  late final Dio _dio;
  
  // MARK: - Initialization
  // Sets up the HTTP client for third-party status checks
  ThirdPartyStatusService() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: Duration(seconds: HTTP_REQUEST_TIMEOUT),
        receiveTimeout: Duration(seconds: HTTP_REQUEST_TIMEOUT),
        headers: {
          'User-Agent': 'InfinitumDownDetector/1.0',
        },
      ),
    );
    
    Logger.logInfo('ThirdPartyStatusService initialized', 
        'third_party_status_service.dart', 'ThirdPartyStatusService');
  }

  // MARK: - Status Check Methods
  /// Checks Firebase service status
  /// Returns ServiceStatus for Firebase
  Future<ServiceStatus> checkFirebaseStatus() async {
    return _checkThirdPartyService(
      id: 'firebase',
      name: 'Firebase',
      url: ThirdPartyServiceUrls.firebaseStatus,
    );
  }
  
  /// Checks Google services status
  /// Returns ServiceStatus for Google
  Future<ServiceStatus> checkGoogleStatus() async {
    return _checkThirdPartyService(
      id: 'google',
      name: 'Google Services',
      url: ThirdPartyServiceUrls.googleStatus,
    );
  }
  
  /// Checks Apple services status
  /// Returns ServiceStatus for Apple
  Future<ServiceStatus> checkAppleStatus() async {
    return _checkThirdPartyService(
      id: 'apple',
      name: 'Apple Services',
      url: ThirdPartyServiceUrls.appleStatus,
    );
  }
  
  /// Checks Discord service status
  /// Returns ServiceStatus for Discord
  Future<ServiceStatus> checkDiscordStatus() async {
    return _checkThirdPartyService(
      id: 'discord',
      name: 'Discord',
      url: ThirdPartyServiceUrls.discordStatus,
    );
  }
  
  /// Checks TikTok service status
  /// Returns ServiceStatus for TikTok
  Future<ServiceStatus> checkTikTokStatus() async {
    return _checkThirdPartyService(
      id: 'tiktok',
      name: 'TikTok',
      url: ThirdPartyServiceUrls.tiktokStatus,
    );
  }
  
  /// Checks AWS service status
  /// Returns ServiceStatus for AWS
  Future<ServiceStatus> checkAWSStatus() async {
    return _checkThirdPartyService(
      id: 'aws',
      name: 'AWS',
      url: ThirdPartyServiceUrls.awsStatus,
    );
  }
  
  // MARK: - Helper Method: Process Third-Party Response
  // Processes HTTP response for third-party services
  // [initialStatus] - Initial service status
  // [response] - HTTP response from Dio
  // [name] - Service display name
  // [startTime] - Start time of the request
  // Returns updated ServiceStatus
  ServiceStatus _processThirdPartyResponse({
    required ServiceStatus initialStatus,
    required Response response,
    required String name,
    required DateTime startTime,
  }) {
    final endTime = DateTime.now();
    final responseTime = endTime.difference(startTime).inMilliseconds;
    
    ServiceHealthStatus newStatus;
    String? errorMessage;
    int consecutiveFailures = 0;
    DateTime? lastUpTime;
    
    if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 400) {
      // For third-party status pages, we check if the page loads
      // A more sophisticated check could parse the status page content
      newStatus = ServiceHealthStatus.operational;
      lastUpTime = DateTime.now();
      Logger.logInfo('$name status page accessible', 
          'third_party_status_service.dart', '_processThirdPartyResponse');
    } else {
      newStatus = ServiceHealthStatus.degraded;
      errorMessage = 'HTTP ${response.statusCode}';
      consecutiveFailures = 1;
      Logger.logWarning('$name status page returned ${response.statusCode}', 
          'third_party_status_service.dart', '_processThirdPartyResponse');
    }
    
    return initialStatus.copyWith(
      status: newStatus,
      lastChecked: DateTime.now(),
      lastUpTime: lastUpTime,
      responseTimeMs: responseTime,
      errorMessage: errorMessage,
      consecutiveFailures: consecutiveFailures,
    );
  }

  /// Generic method to check any third-party service
  /// On web, uses CORS proxy to bypass CORS restrictions
  /// On mobile, uses direct HTTP requests
  /// [id] - Unique identifier for the service
  /// [name] - Display name of the service
  /// [url] - URL to check
  /// Returns ServiceStatus for the service
  Future<ServiceStatus> _checkThirdPartyService({
    required String id,
    required String name,
    required String url,
  }) async {
    final startTime = DateTime.now();
    final initialStatus = ServiceStatus.initial(
      id: id,
      name: name,
      url: url,
      type: ServiceType.thirdParty,
    );
    
    // MARK: - Web Platform: Use CORS Proxy
    // On web, always use CORS proxy for external domains to avoid CORS issues
    if (kIsWeb) {
      try {
        Logger.logDebug('Checking third-party service: $name ($url)', 
            'third_party_status_service.dart', '_checkThirdPartyService');
        
        // On web, always use CORS proxy for external requests
        // Try primary proxy first
        Response? proxyResponse;
        bool proxySuccess = false;
        
        try {
          final primaryProxyUrl = '$CORS_PROXY_URL${Uri.encodeComponent(url)}';
          proxyResponse = await _dio.get(
            primaryProxyUrl,
            options: Options(
              validateStatus: (status) => status != null && status < 500,
              followRedirects: true,
              maxRedirects: 5,
              responseType: ResponseType.plain,
            ),
          );
          
          // If proxy returns content, treat as success
          if (proxyResponse.data != null && proxyResponse.data.toString().isNotEmpty) {
            proxySuccess = true;
            return _processThirdPartyResponse(
              initialStatus: initialStatus,
              response: proxyResponse,
              name: name,
              startTime: startTime,
            );
          }
        } on DioException catch (e) {
          Logger.logDebug('Primary CORS proxy failed for $name, trying fallback', 
              'third_party_status_service.dart', '_checkThirdPartyService');
        }
        
        // Try fallback proxy if primary failed or returned empty
        if (!proxySuccess) {
          try {
            final fallbackProxyUrl = '$CORS_PROXY_FALLBACK_URL${Uri.encodeComponent(url)}';
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
              return _processThirdPartyResponse(
                initialStatus: initialStatus,
                response: proxyResponse,
                name: name,
                startTime: startTime,
              );
            }
          } on DioException catch (e) {
            Logger.logDebug('Fallback CORS proxy failed for $name, trying direct request', 
                'third_party_status_service.dart', '_checkThirdPartyService');
          }
        }
        
        // If both proxies failed, try direct request as last resort
        try {
          final response = await _dio.get(
            url,
            options: Options(
              validateStatus: (status) => status != null && status < 500,
              followRedirects: true,
              maxRedirects: 5,
              responseType: ResponseType.plain,
            ),
          );
          
          return _processThirdPartyResponse(
            initialStatus: initialStatus,
            response: response,
            name: name,
            startTime: startTime,
          );
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
          
          Logger.logError('Error checking $name on web: $errorMsg', 
              'third_party_status_service.dart', '_checkThirdPartyService', directError);
          
          return initialStatus.copyWith(
            status: newStatus,
            lastChecked: DateTime.now(),
            responseTimeMs: responseTime,
            errorMessage: errorMsg,
            consecutiveFailures: 1,
          );
        }
      } catch (e) {
        final endTime = DateTime.now();
        final responseTime = endTime.difference(startTime).inMilliseconds;
        
        Logger.logError('Unexpected error checking $name on web', 
            'third_party_status_service.dart', '_checkThirdPartyService', e);
        
        return initialStatus.copyWith(
          status: ServiceHealthStatus.unknown,
          lastChecked: DateTime.now(),
          responseTimeMs: responseTime,
          errorMessage: 'Error: ${e.toString()}',
          consecutiveFailures: 1,
        );
      }
    }
    
    // MARK: - Mobile Platform: Use Direct HTTP
    // On mobile (iOS/Android), use direct HTTP requests (no CORS restrictions)
    try {
      Logger.logDebug('Checking third-party service: $name ($url)', 
          'third_party_status_service.dart', '_checkThirdPartyService');
      
      final response = await _dio.get(
        url,
        options: Options(
          validateStatus: (status) => status != null && status < 500,
          followRedirects: true,
          maxRedirects: 5,
        ),
      );
      
      return _processThirdPartyResponse(
        initialStatus: initialStatus,
        response: response,
        name: name,
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
      
      Logger.logError('Third-party status check failed for $name: $errorMsg', 
          'third_party_status_service.dart', '_checkThirdPartyService', e);
      
      return initialStatus.copyWith(
        status: newStatus,
        lastChecked: DateTime.now(),
        responseTimeMs: responseTime,
        errorMessage: errorMsg,
        consecutiveFailures: 1,
      );
      
    } catch (e) {
      final endTime = DateTime.now();
      final responseTime = endTime.difference(startTime).inMilliseconds;
      
      Logger.logError('Unexpected error checking $name', 
          'third_party_status_service.dart', '_checkThirdPartyService', e);
      
      return initialStatus.copyWith(
        status: ServiceHealthStatus.unknown,
        lastChecked: DateTime.now(),
        responseTimeMs: responseTime,
        errorMessage: 'Unexpected error: ${e.toString()}',
        consecutiveFailures: 1,
      );
    }
  }
  
  /// Checks all third-party services
  /// Returns list of ServiceStatus for all third-party services
  Future<List<ServiceStatus>> checkAllThirdPartyServices() async {
    Logger.logInfo('Checking all third-party services', 
        'third_party_status_service.dart', 'checkAllThirdPartyServices');
    
    final futures = [
      checkFirebaseStatus(),
      checkGoogleStatus(),
      checkAppleStatus(),
      checkDiscordStatus(),
      checkTikTokStatus(),
      checkAWSStatus(),
    ];
    
    final results = await Future.wait(futures);
    
    Logger.logInfo('Completed third-party service checks', 
        'third_party_status_service.dart', 'checkAllThirdPartyServices');
    
    return results;
  }
  
  // MARK: - Cleanup
  // Closes the HTTP client
  void dispose() {
    _dio.close();
    Logger.logInfo('ThirdPartyStatusService disposed', 
        'third_party_status_service.dart', 'dispose');
  }
}

// Suggestions For Features and Additions Later:
// - Parse actual status page content for more accurate status
// - Add API integrations for official status APIs (if available)
// - Implement status page RSS feed parsing
// - Add service-specific status indicators
// - Create status aggregation from multiple sources
// - Add historical status tracking for third-party services
// - Implement status change notifications
// - Add service dependency mapping

