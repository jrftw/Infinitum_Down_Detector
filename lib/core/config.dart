// Filename: config.dart
// Purpose: Global configuration constants and flags for the application
// Author: Kevin Doyle Jr. / Infinitum Imagery LLC
// Last Modified: 2025-01-30
// Dependencies: models/service_component.dart
// Platform Compatibility: Web, iOS, Android

import '../models/service_component.dart';

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

// MARK: - Service Component Definitions
// Defines components/endpoints to monitor for each service
class ServiceComponentDefinitions {
  // Gets components for a specific service
  // [serviceId] - The service ID to get components for
  // Returns list of ServiceComponent definitions

  static List<ServiceComponent> getComponentsForService(String serviceId) {
    switch (serviceId) {
      case 'infinitum-view':
        return [
          ServiceComponent.initial(
            id: 'infinitum-view-main',
            name: 'Main Page',
            url: 'https://view.infinitumlive.com/',
            type: ComponentType.main,
          ),
          // Add auth endpoint if available
          ServiceComponent.initial(
            id: 'infinitum-view-api',
            name: 'API',
            url: 'https://view.infinitumlive.com/api/health',
            type: ComponentType.api,
          ),
        ];
      
      case 'infinitum-live':
        return [
          ServiceComponent.initial(
            id: 'infinitum-live-main',
            name: 'Main Page',
            url: 'https://infinitumlive.com/',
            type: ComponentType.main,
          ),
          ServiceComponent.initial(
            id: 'infinitum-live-auth',
            name: 'Auth',
            url: 'https://infinitumlive.com/auth',
            type: ComponentType.auth,
          ),
        ];
      
      case 'infinitum-crm':
        return [
          ServiceComponent.initial(
            id: 'infinitum-crm-main',
            name: 'Main Page',
            url: 'https://crm.infinitumlive.com/',
            type: ComponentType.main,
          ),
          ServiceComponent.initial(
            id: 'infinitum-crm-api',
            name: 'API',
            url: 'https://crm.infinitumlive.com/api/v1/status',
            type: ComponentType.api,
          ),
        ];
      
      case 'infinitum-onboarding':
        return [
          ServiceComponent.initial(
            id: 'infinitum-onboarding-main',
            name: 'Main Page',
            url: 'https://infinitum-onboarding.web.app/',
            type: ComponentType.main,
          ),
          ServiceComponent.initial(
            id: 'infinitum-onboarding-auth',
            name: 'Authentication',
            url: 'https://infinitum-onboarding.web.app/auth',
            type: ComponentType.auth,
          ),
          ServiceComponent.initial(
            id: 'infinitum-onboarding-start',
            name: 'Start Page',
            url: 'https://infinitum-onboarding.web.app/start',
            type: ComponentType.main,
          ),
          ServiceComponent.initial(
            id: 'infinitum-onboarding-health',
            name: 'Health Check',
            url: 'https://us-central1-infinitum-onboarding.cloudfunctions.net/healthCheck',
            type: ComponentType.api,
          ),
          ServiceComponent.initial(
            id: 'infinitum-onboarding-openapi',
            name: 'API Documentation',
            url: 'https://us-central1-infinitum-onboarding.cloudfunctions.net/openapi',
            type: ComponentType.api,
          ),
        ];
      
      case 'google':
        return [
          ServiceComponent.initial(
            id: 'google-apps-script',
            name: 'Apps Script',
            url: 'https://www.google.com/appsstatus/dashboard/',
            type: ComponentType.other,
          ),
          ServiceComponent.initial(
            id: 'google-appsheet',
            name: 'AppSheet',
            url: 'https://www.google.com/appsstatus/dashboard/',
            type: ComponentType.other,
          ),
          ServiceComponent.initial(
            id: 'google-gmail',
            name: 'Gmail',
            url: 'https://www.google.com/appsstatus/dashboard/',
            type: ComponentType.other,
          ),
          ServiceComponent.initial(
            id: 'google-calendar',
            name: 'Google Calendar',
            url: 'https://www.google.com/appsstatus/dashboard/',
            type: ComponentType.other,
          ),
          ServiceComponent.initial(
            id: 'google-docs',
            name: 'Google Docs',
            url: 'https://www.google.com/appsstatus/dashboard/',
            type: ComponentType.other,
          ),
          ServiceComponent.initial(
            id: 'google-drive',
            name: 'Google Drive',
            url: 'https://www.google.com/appsstatus/dashboard/',
            type: ComponentType.other,
          ),
          ServiceComponent.initial(
            id: 'google-forms',
            name: 'Google Forms',
            url: 'https://www.google.com/appsstatus/dashboard/',
            type: ComponentType.other,
          ),
          ServiceComponent.initial(
            id: 'google-sheets',
            name: 'Google Sheets',
            url: 'https://www.google.com/appsstatus/dashboard/',
            type: ComponentType.other,
          ),
          ServiceComponent.initial(
            id: 'google-slides',
            name: 'Google Slides',
            url: 'https://www.google.com/appsstatus/dashboard/',
            type: ComponentType.other,
          ),
        ];
      
      case 'firebase':
        return [
          ServiceComponent.initial(
            id: 'firebase-app-hosting',
            name: 'App Hosting',
            url: 'https://status.firebase.google.com/',
            type: ComponentType.other,
          ),
          ServiceComponent.initial(
            id: 'firebase-authentication',
            name: 'Authentication',
            url: 'https://status.firebase.google.com/',
            type: ComponentType.auth,
          ),
          ServiceComponent.initial(
            id: 'firebase-cloud-firestore',
            name: 'Cloud Firestore',
            url: 'https://status.firebase.google.com/',
            type: ComponentType.database,
          ),
          ServiceComponent.initial(
            id: 'firebase-cloud-messaging',
            name: 'Cloud Messaging',
            url: 'https://status.firebase.google.com/',
            type: ComponentType.other,
          ),
          ServiceComponent.initial(
            id: 'firebase-cloud-functions',
            name: 'Cloud Functions',
            url: 'https://status.firebase.google.com/',
            type: ComponentType.api,
          ),
          ServiceComponent.initial(
            id: 'firebase-console',
            name: 'Console',
            url: 'https://status.firebase.google.com/',
            type: ComponentType.other,
          ),
          ServiceComponent.initial(
            id: 'firebase-crashlytics',
            name: 'Crashlytics',
            url: 'https://status.firebase.google.com/',
            type: ComponentType.other,
          ),
          ServiceComponent.initial(
            id: 'firebase-hosting',
            name: 'Hosting',
            url: 'https://status.firebase.google.com/',
            type: ComponentType.cdn,
          ),
          ServiceComponent.initial(
            id: 'firebase-performance-monitoring',
            name: 'Performance Monitoring',
            url: 'https://status.firebase.google.com/',
            type: ComponentType.other,
          ),
          ServiceComponent.initial(
            id: 'firebase-realtime-database',
            name: 'Realtime Database',
            url: 'https://status.firebase.google.com/',
            type: ComponentType.database,
          ),
          ServiceComponent.initial(
            id: 'firebase-storage',
            name: 'Storage',
            url: 'https://status.firebase.google.com/',
            type: ComponentType.other,
          ),
        ];
      
      case 'aws':
        return [
          ServiceComponent.initial(
            id: 'aws-ec2',
            name: 'EC2',
            url: 'https://status.aws.amazon.com/',
            type: ComponentType.other,
          ),
          ServiceComponent.initial(
            id: 'aws-s3',
            name: 'S3',
            url: 'https://status.aws.amazon.com/',
            type: ComponentType.other,
          ),
          ServiceComponent.initial(
            id: 'aws-cloudfront',
            name: 'CloudFront',
            url: 'https://status.aws.amazon.com/',
            type: ComponentType.cdn,
          ),
          ServiceComponent.initial(
            id: 'aws-api-gateway',
            name: 'API Gateway',
            url: 'https://status.aws.amazon.com/',
            type: ComponentType.api,
          ),
          ServiceComponent.initial(
            id: 'aws-rds',
            name: 'RDS',
            url: 'https://status.aws.amazon.com/',
            type: ComponentType.database,
          ),
          ServiceComponent.initial(
            id: 'aws-lambda',
            name: 'Lambda',
            url: 'https://status.aws.amazon.com/',
            type: ComponentType.api,
          ),
        ];
      
      case 'apple':
        return [
          ServiceComponent.initial(
            id: 'apple-app-store-connect',
            name: 'App Store Connect',
            url: 'https://www.apple.com/support/systemstatus/',
            type: ComponentType.other,
          ),
          ServiceComponent.initial(
            id: 'apple-apns',
            name: 'Apple Push Notification Service',
            url: 'https://www.apple.com/support/systemstatus/',
            type: ComponentType.other,
          ),
          ServiceComponent.initial(
            id: 'apple-sign-in',
            name: 'Sign in with Apple',
            url: 'https://www.apple.com/support/systemstatus/',
            type: ComponentType.auth,
          ),
          ServiceComponent.initial(
            id: 'apple-testflight',
            name: 'TestFlight',
            url: 'https://www.apple.com/support/systemstatus/',
            type: ComponentType.other,
          ),
          ServiceComponent.initial(
            id: 'apple-icloud',
            name: 'iCloud',
            url: 'https://www.apple.com/support/systemstatus/',
            type: ComponentType.other,
          ),
        ];
      
      case 'discord':
        return [
          ServiceComponent.initial(
            id: 'discord-api',
            name: 'API',
            url: 'https://discordstatus.com/',
            type: ComponentType.api,
          ),
          ServiceComponent.initial(
            id: 'discord-gateway',
            name: 'Gateway',
            url: 'https://discordstatus.com/',
            type: ComponentType.other,
          ),
          ServiceComponent.initial(
            id: 'discord-media-proxy',
            name: 'Media Proxy',
            url: 'https://discordstatus.com/',
            type: ComponentType.cdn,
          ),
          ServiceComponent.initial(
            id: 'discord-voice',
            name: 'Voice',
            url: 'https://discordstatus.com/',
            type: ComponentType.other,
          ),
        ];
      
      case 'tiktok':
        return [
          ServiceComponent.initial(
            id: 'tiktok-api',
            name: 'API',
            url: 'https://www.tiktok.com/',
            type: ComponentType.api,
          ),
          ServiceComponent.initial(
            id: 'tiktok-live',
            name: 'LIVE',
            url: 'https://www.tiktok.com/',
            type: ComponentType.other,
          ),
          ServiceComponent.initial(
            id: 'tiktok-cdn',
            name: 'CDN',
            url: 'https://www.tiktok.com/',
            type: ComponentType.cdn,
          ),
        ];
      
      default:
        // For services without specific component definitions, return empty list
        // The main URL will still be checked as part of the service status
        return [];
    }
  }
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

