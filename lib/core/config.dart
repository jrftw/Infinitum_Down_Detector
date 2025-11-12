// Filename: config.dart
// Purpose: Global configuration constants and flags for the application
// Author: Kevin Doyle Jr. / Infinitum Imagery LLC
// Last Modified: 2025-01-27
// Dependencies: None
// Platform Compatibility: Web, iOS, Android

// MARK: - Global Configuration
// Centralized configuration constants

/// Global flag to enable/disable debug logging across the application
const bool ENABLE_DEBUG_LOGGING = true;

/// Default health check interval in seconds
const int DEFAULT_HEALTH_CHECK_INTERVAL = 60;

/// HTTP request timeout in seconds
const int HTTP_REQUEST_TIMEOUT = 10;

/// Maximum retry attempts for failed health checks
const int MAX_RETRY_ATTEMPTS = 3;

/// Retry delay in seconds between failed attempts
const int RETRY_DELAY_SECONDS = 5;

/// Minimum time between Firestore cache writes in seconds (rate limiting)
/// Set to 30 seconds to prevent excessive writes and stay within free tier
const int CACHE_WRITE_INTERVAL_SECONDS = 30;

/// Maximum number of cache writes per hour (rate limiting)
const int MAX_CACHE_WRITES_PER_HOUR = 60;

// MARK: - Service URLs
// URLs for Infinitum services to monitor
class ServiceUrls {
  static const String infinitumView = 'https://view.infinitumlive.com/';
  static const String infinitumLive = 'https://infinitumlive.com/';
  static const String infinitumCrm = 'https://crm.infinitumlive.com/';
  static const String infinitumOnboarding = 'https://infinitum-onboarding.web.app/';
  static const String infinitumBoard = 'https://iboard.duckdns.org/';
  static const String infinitumBoard2 = 'https://iboard2--infinitum-dashboard.us-east4.hosted.app/';
  static const String infinitumImagery = 'https://www.infinitumimagery.com/';
}

// MARK: - Third-Party Service Status URLs
// URLs for checking third-party service status
class ThirdPartyServiceUrls {
  static const String firebaseStatus = 'https://status.firebase.google.com/';
  static const String googleStatus = 'https://www.google.com/appsstatus/dashboard/';
  static const String appleStatus = 'https://www.apple.com/support/systemstatus/';
  static const String discordStatus = 'https://discordstatus.com/';
  static const String tiktokStatus = 'https://www.tiktok.com/';
  static const String awsStatus = 'https://status.aws.amazon.com/';
}

// MARK: - CORS Proxy Configuration
// CORS proxy URLs for web platform requests
// Using public CORS proxy services for web compatibility
// Primary proxy
const String CORS_PROXY_URL = 'https://api.allorigins.win/raw?url=';
// Fallback proxy (if primary fails)
const String CORS_PROXY_FALLBACK_URL = 'https://corsproxy.io/?';

// MARK: - Service URL Visibility Configuration
// List of service IDs whose URLs should be hidden from public display
// These services will still be monitored, but their URLs won't be shown
const Set<String> HIDDEN_URL_SERVICE_IDS = {
  'infinitum-crm',
  'infinitum-board',
  'infinitum-board-2',
};

/// Checks if a service's URL should be hidden from public display
/// [serviceId] - The service ID to check
/// Returns true if the URL should be hidden, false otherwise
bool shouldHideServiceUrl(String serviceId) {
  return HIDDEN_URL_SERVICE_IDS.contains(serviceId);
}

// Suggestions For Features and Additions Later:
// - Add environment-specific configurations (dev, staging, prod)
// - Implement feature flags system
// - Add API endpoint configurations
// - Create configuration file loading from remote source
// - Add service-specific timeout configurations
// - Implement configuration validation on startup

