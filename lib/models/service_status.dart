// Filename: service_status.dart
// Purpose: Data models for service status information
// Author: Kevin Doyle Jr. / Infinitum Imagery LLC
// Last Modified: 2025-01-27
// Dependencies: None
// Platform Compatibility: Web, iOS, Android

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
  });

  // MARK: - Factory Constructors
  // Creates a ServiceStatus instance with default values
  factory ServiceStatus.initial({
    required String id,
    required String name,
    required String url,
    required ServiceType type,
  }) {
    return ServiceStatus(
      id: id,
      name: name,
      url: url,
      type: type,
      status: ServiceHealthStatus.unknown,
      lastChecked: DateTime.now(),
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
    );
  }

  // MARK: - Helper Methods
  // Checks if the service is currently operational
  bool get isOperational => status == ServiceHealthStatus.operational;
  
  // Checks if the service is experiencing issues
  bool get hasIssues => status == ServiceHealthStatus.degraded || status == ServiceHealthStatus.down;
  
  // Gets the status color for UI display
  int get statusColor {
    switch (status) {
      case ServiceHealthStatus.operational:
        return 0xFF10B981; // Green
      case ServiceHealthStatus.degraded:
        return 0xFFF59E0B; // Amber
      case ServiceHealthStatus.down:
        return 0xFFEF4444; // Red
      case ServiceHealthStatus.unknown:
        return 0xFF6B7280; // Gray
    }
  }
}

// MARK: - Service Health Status Enum
// Represents the possible health states of a service
enum ServiceHealthStatus {
  operational,
  degraded,
  down,
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

