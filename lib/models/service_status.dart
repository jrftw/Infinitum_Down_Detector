// Filename: service_status.dart
// Purpose: Data models for service status information
// Author: Kevin Doyle Jr. / Infinitum Imagery LLC
// Last Modified: 2025-01-27
// Dependencies: service_component.dart
// Platform Compatibility: Web, iOS, Android

import 'service_component.dart';

// MARK: - Service Status Model
// Represents the status of a monitored service
class ServiceStatus {
  final String id;
  final String name;
  final String url;
  final ServiceType type;
  final ServiceHealthStatus status;
  final DateTime lastChecked;
  final DateTime? lastUpTime;
  final int responseTimeMs;
  final String? errorMessage;
  final int consecutiveFailures;
  final List<ServiceComponent> components;

  ServiceStatus({
    required this.id,
    required this.name,
    required this.url,
    required this.type,
    required this.status,
    required this.lastChecked,
    this.lastUpTime,
    this.responseTimeMs = 0,
    this.errorMessage,
    this.consecutiveFailures = 0,
    this.components = const [],
  });

  // MARK: - Factory Constructors
  // Creates a ServiceStatus instance with default values
  factory ServiceStatus.initial({
    required String id,
    required String name,
    required String url,
    required ServiceType type,
    List<ServiceComponent>? components,
  }) {
    return ServiceStatus(
      id: id,
      name: name,
      url: url,
      type: type,
      status: ServiceHealthStatus.unknown,
      lastChecked: DateTime.now(),
      components: components ?? [],
    );
  }

  // MARK: - Copy With Method
  // Creates a copy of the ServiceStatus with updated fields
  ServiceStatus copyWith({
    String? id,
    String? name,
    String? url,
    ServiceType? type,
    ServiceHealthStatus? status,
    DateTime? lastChecked,
    DateTime? lastUpTime,
    int? responseTimeMs,
    String? errorMessage,
    int? consecutiveFailures,
    List<ServiceComponent>? components,
  }) {
    return ServiceStatus(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      type: type ?? this.type,
      status: status ?? this.status,
      lastChecked: lastChecked ?? this.lastChecked,
      lastUpTime: lastUpTime ?? this.lastUpTime,
      responseTimeMs: responseTimeMs ?? this.responseTimeMs,
      errorMessage: errorMessage ?? this.errorMessage,
      consecutiveFailures: consecutiveFailures ?? this.consecutiveFailures,
      components: components ?? this.components,
    );
  }

  // MARK: - Helper Methods
  // Checks if the service is currently operational
  bool get isOperational => status == ServiceHealthStatus.operational;
  
  // Checks if the service is experiencing issues
  bool get hasIssues => status == ServiceHealthStatus.degraded || 
                       status == ServiceHealthStatus.partialOutage ||
                       status == ServiceHealthStatus.majorOutage ||
                       status == ServiceHealthStatus.down;
  
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

  // Gets overall status based on component statuses if available
  // If components exist, determines status from component health
  ServiceHealthStatus get overallStatus {
    if (components.isEmpty) {
      return status;
    }
    
    // Check if any component is down
    final hasDown = components.any((c) => c.status == ServiceHealthStatus.down);
    if (hasDown) {
      return ServiceHealthStatus.down;
    }
    
    // Check if any component is degraded
    final hasDegraded = components.any((c) => c.status == ServiceHealthStatus.degraded);
    if (hasDegraded) {
      return ServiceHealthStatus.degraded;
    }
    
    // Check if all components are operational
    final allOperational = components.every((c) => c.status == ServiceHealthStatus.operational);
    if (allOperational) {
      return ServiceHealthStatus.operational;
    }
    
    // Default to unknown if components have unknown status
    return ServiceHealthStatus.unknown;
  }

  // Gets count of operational components
  int get operationalComponentsCount => components.where((c) => c.isOperational).length;

  // Gets count of components with issues
  int get componentsWithIssuesCount => components.where((c) => c.hasIssues).length;
}

// MARK: - Service Health Status Enum
// Represents the possible health states of a service
enum ServiceHealthStatus {
  operational,
  degraded,
  partialOutage,
  majorOutage,
  down,
  maintenance,
  unknown,
}

// MARK: - Service Type Enum
// Categorizes services by type
enum ServiceType {
  infinitum,
  thirdParty,
}

// Suggestions For Features and Additions Later:
// - Add service metadata (version, region, etc.)
// - Implement service dependency relationships
// - Add historical status tracking
// - Create service tags and categories
// - Add custom status messages per service
// - Implement service maintenance windows
// - Add service SLA tracking

