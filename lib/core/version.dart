// Filename: version.dart
// Purpose: Version and build information configuration
// Author: Kevin Doyle Jr. / Infinitum Imagery LLC
// Last Modified: 2025-01-27
// Dependencies: None
// Platform Compatibility: Web, iOS, Android

// MARK: - Version Configuration
// Centralized version and build information

/// Application version
const String APP_VERSION = '1.0.1';

/// Build number
const int BUILD_NUMBER = 1;

/// Environment type
enum Environment {
  development,
  beta,
  production,
}

/// Current environment
// Change this to switch between environments
const Environment CURRENT_ENVIRONMENT = Environment.production;

/// Gets the environment display name
String getEnvironmentName() {
  switch (CURRENT_ENVIRONMENT) {
    case Environment.development:
      return 'Dev';
    case Environment.beta:
      return 'Beta';
    case Environment.production:
      return '';
  }
}

/// Gets the full version string
String getVersionString() {
  final envName = getEnvironmentName();
  final envPrefix = envName.isNotEmpty ? '$envName ' : '';
  return 'Version $APP_VERSION Build $BUILD_NUMBER $envPrefix'.trim();
}

/// Gets the version string for display
String getDisplayVersion() {
  final envName = getEnvironmentName();
  final envPrefix = envName.isNotEmpty ? '$envName ' : '';
  final status = getCurrentStatus();
  return '$envPrefix Version $APP_VERSION Build $BUILD_NUMBER $status'.trim();
}

/// Gets the current status text
String getCurrentStatus() {
  return 'Current';
}

// Suggestions For Features and Additions Later:
// - Add version comparison logic
// - Implement automatic version bumping
// - Add version history tracking
// - Create version update notifications
// - Add build timestamp tracking

