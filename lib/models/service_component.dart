// Filename: service_component.dart
// Purpose: Data model for individual service components/endpoints (auth, API, main page, etc.)
// Author: Kevin Doyle Jr. / Infinitum Imagery LLC
// Last Modified: 2025-01-27
// Dependencies: None
// Platform Compatibility: Web, iOS, Android

import 'service_status.dart';

// MARK: - Service Component Model
// Represents an individual component/endpoint of a service (e.g., auth endpoint, API endpoint)
class ServiceComponent {
  final String id;
  final String name;
  final String url;
  final ComponentType type;
  final ServiceHealthStatus status;
  final DateTime lastChecked;
  final int responseTimeMs;
  final String? errorMessage;
  final int? statusCode;

  ServiceComponent({
    required this.id,
    required this.name,
    required this.url,
    required this.type,
    required this.status,
    required this.lastChecked,
    this.responseTimeMs = 0,
    this.errorMessage,
    this.statusCode,
  });

  // MARK: - Factory Constructors
  // Creates a ServiceComponent instance with default values
  factory ServiceComponent.initial({
    required String id,
    required String name,
    required String url,
    required ComponentType type,
  }) {
    return ServiceComponent(
      id: id,
      name: name,
      url: url,
      type: type,
      status: ServiceHealthStatus.unknown,
      lastChecked: DateTime.now(),
    );
  }

  // MARK: - Copy With Method
  // Creates a copy of the ServiceComponent with updated fields
  ServiceComponent copyWith({
    String? id,
    String? name,
    String? url,
    ComponentType? type,
    ServiceHealthStatus? status,
    DateTime? lastChecked,
    int? responseTimeMs,
    String? errorMessage,
    int? statusCode,
  }) {
    return ServiceComponent(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      type: type ?? this.type,
      status: status ?? this.status,
      lastChecked: lastChecked ?? this.lastChecked,
      responseTimeMs: responseTimeMs ?? this.responseTimeMs,
      errorMessage: errorMessage ?? this.errorMessage,
      statusCode: statusCode ?? this.statusCode,
    );
  }

  // MARK: - Helper Methods
  // Checks if the component is currently operational
  bool get isOperational => status == ServiceHealthStatus.operational;
  
  // Checks if the component is experiencing issues
  bool get hasIssues => status == ServiceHealthStatus.degraded || status == ServiceHealthStatus.down;
  
  // Gets the status color for UI display
  int get statusColor {
    switch (status) {
      case ServiceHealthStatus.operational:
        return 0xFF10B981; // Green
      case ServiceHealthStatus.degraded:
        return 0xFFF59E0B; // Amber
      case ServiceHealthStatus.partialOutage:
        return 0xFFF97316; // Orange
      case ServiceHealthStatus.majorOutage:
        return 0xFFDC2626; // Dark Red
      case ServiceHealthStatus.down:
        return 0xFFEF4444; // Red
      case ServiceHealthStatus.maintenance:
        return 0xFF6366F1; // Indigo
      case ServiceHealthStatus.unknown:
        return 0xFF6B7280; // Gray
    }
  }

  // Gets icon for component type
  String get typeIcon {
    switch (type) {
      case ComponentType.main:
        return '🌐';
      case ComponentType.auth:
        return '🔐';
      case ComponentType.api:
        return '⚙️';
      case ComponentType.database:
        return '💾';
      case ComponentType.cdn:
        return '📡';
      case ComponentType.other:
        return '🔗';
    }
  }
}

// MARK: - Component Type Enum
// Represents the type of component/endpoint
enum ComponentType {
  main,      // Main website/page
  auth,      // Authentication endpoint
  api,       // API endpoint
  database,  // Database connection
  cdn,       // CDN/static assets
  other,     // Other endpoint
}

// Suggestions For Features and Additions Later:
// - Add component dependency relationships
// - Implement component health history tracking
// - Add custom health check logic per component type
// - Create component tags and metadata
// - Add component maintenance windows
// - Implement component SLA tracking
// - Add component response validation

