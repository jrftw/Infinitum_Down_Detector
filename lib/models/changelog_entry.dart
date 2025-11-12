// Filename: changelog_entry.dart
// Purpose: Data model for changelog entries
// Author: Kevin Doyle Jr. / Infinitum Imagery LLC
// Last Modified: 2025-01-27
// Dependencies: None
// Platform Compatibility: Web, iOS, Android

// MARK: - Changelog Entry
// Represents a single changelog entry
class ChangelogEntry {
  final String version;
  final String build;
  final List<String> changes;

  ChangelogEntry({
    required this.version,
    required this.build,
    required this.changes,
  });
}

// MARK: - Changelog Data
// Contains all changelog entries
class ChangelogData {
  static List<ChangelogEntry> getEntries() {
    return [
      ChangelogEntry(
        version: '1.0.0',
        build: '1',
        changes: [
          'Initial release of Infinitum Down Detector',
          'Real-time monitoring of Infinitum services',
          'Third-party service status checks (Firebase, Google, Apple, Discord, TikTok)',
          'Service status cards with detailed information',
          'Issue reporting system with spam protection',
          'Automatic periodic health checks (every 60 seconds)',
          'Status overview dashboard',
          'CORS proxy integration for web platform health checks',
          'Data feed issue detection for iView/InfiniView',
          'Modern UI with dark mode support',
          'Responsive design for web, iOS, and Android',
        ],
      ),
    ];
  }
}

// Suggestions For Features and Additions Later:
// - Add change categories (Features, Bug Fixes, Improvements)
// - Implement change severity levels
// - Add change impact indicators
// - Create change filtering and search
// - Add change voting/feedback system

