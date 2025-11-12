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
}

// MARK: - CORS Proxy Configuration
// CORS proxy URL for web platform requests
// Using a public CORS proxy service for web compatibility
const String CORS_PROXY_URL = 'https://api.allorigins.win/raw?url=';

// Suggestions For Features and Additions Later:
// - Add environment-specific configurations (dev, staging, prod)
// - Implement feature flags system
// - Add API endpoint configurations
// - Create configuration file loading from remote source
// - Add service-specific timeout configurations
// - Implement configuration validation on startup

