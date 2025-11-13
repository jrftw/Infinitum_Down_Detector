// Filename: incident.dart
// Purpose: Data model for service incidents and events
// Author: Kevin Doyle Jr. / Infinitum Imagery LLC
// Last Modified: 2025-01-27
// Dependencies: models/service_status.dart
// Platform Compatibility: Web, iOS, Android


// MARK: - Incident Model
// Represents a service incident or event (outage, maintenance, etc.)
class Incident {
  final String id;
  final String serviceId;
  final String serviceName;
  final IncidentType type;
  final IncidentStatus status;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime? endTime;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<IncidentUpdate> updates;
  final List<String> affectedComponents;

  Incident({
    required this.id,
    required this.serviceId,
    required this.serviceName,
    required this.type,
    required this.status,
    required this.title,
    required this.description,
    required this.startTime,
    this.endTime,
    required this.createdAt,
    this.updatedAt,
    this.updates = const [],
    this.affectedComponents = const [],
  });

  // MARK: - Factory Constructors
  // Creates an Incident from a Map (e.g., from Firestore)
  factory Incident.fromMap(Map<String, dynamic> map, String id) {
    return Incident(
      id: id,
      serviceId: map['serviceId'] as String? ?? '',
      serviceName: map['serviceName'] as String? ?? '',
      type: _parseIncidentType(map['type'] as String?),
      status: _parseIncidentStatus(map['status'] as String?),
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      startTime: (map['startTime'] as DateTime?) ?? DateTime.now(),
      endTime: map['endTime'] as DateTime?,
      createdAt: (map['createdAt'] as DateTime?) ?? DateTime.now(),
      updatedAt: map['updatedAt'] as DateTime?,
      updates: (map['updates'] as List<dynamic>?)
              ?.map((u) => IncidentUpdate.fromMap(u as Map<String, dynamic>))
              .toList() ?? [],
      affectedComponents: (map['affectedComponents'] as List<dynamic>?)
              ?.map((c) => c as String)
              .toList() ?? [],
    );
  }

  // MARK: - Copy With Method
  Incident copyWith({
    String? id,
    String? serviceId,
    String? serviceName,
    IncidentType? type,
    IncidentStatus? status,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<IncidentUpdate>? updates,
    List<String>? affectedComponents,
  }) {
    return Incident(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      serviceName: serviceName ?? this.serviceName,
      type: type ?? this.type,
      status: status ?? this.status,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updates: updates ?? this.updates,
      affectedComponents: affectedComponents ?? this.affectedComponents,
    );
  }

  // MARK: - Helper Methods
  // Checks if the incident is currently active
  bool get isActive => status == IncidentStatus.investigating || 
                      status == IncidentStatus.identified || 
                      status == IncidentStatus.monitoring;

  // Gets the duration of the incident
  Duration? get duration {
    final end = endTime ?? (isActive ? DateTime.now() : null);
    if (end == null) return null;
    return end.difference(startTime);
  }

  // Gets the status color for UI display
  int get statusColor {
    switch (status) {
      case IncidentStatus.investigating:
        return 0xFFF59E0B; // Amber
      case IncidentStatus.identified:
        return 0xFFF97316; // Orange
      case IncidentStatus.monitoring:
        return 0xFF3B82F6; // Blue
      case IncidentStatus.resolved:
        return 0xFF10B981; // Green
      case IncidentStatus.postmortem:
        return 0xFF6B7280; // Gray
    }
  }

  // MARK: - Helper Functions
  static IncidentType _parseIncidentType(String? typeString) {
    if (typeString == null) return IncidentType.outage;
    
    switch (typeString.toLowerCase()) {
      case 'outage':
        return IncidentType.outage;
      case 'degraded':
        return IncidentType.degraded;
      case 'maintenance':
        return IncidentType.maintenance;
      case 'security':
        return IncidentType.security;
      default:
        return IncidentType.outage;
    }
  }

  static IncidentStatus _parseIncidentStatus(String? statusString) {
    if (statusString == null) return IncidentStatus.investigating;
    
    switch (statusString.toLowerCase()) {
      case 'investigating':
        return IncidentStatus.investigating;
      case 'identified':
        return IncidentStatus.identified;
      case 'monitoring':
        return IncidentStatus.monitoring;
      case 'resolved':
        return IncidentStatus.resolved;
      case 'postmortem':
        return IncidentStatus.postmortem;
      default:
        return IncidentStatus.investigating;
    }
  }
}

// MARK: - Incident Update
// Represents an update to an incident
class IncidentUpdate {
  final DateTime timestamp;
  final String message;
  final IncidentStatus? status;

  IncidentUpdate({
    required this.timestamp,
    required this.message,
    this.status,
  });

  factory IncidentUpdate.fromMap(Map<String, dynamic> map) {
    return IncidentUpdate(
      timestamp: (map['timestamp'] as DateTime?) ?? DateTime.now(),
      message: map['message'] as String? ?? '',
      status: map['status'] != null 
          ? Incident._parseIncidentStatus(map['status'] as String)
          : null,
    );
  }
}

// MARK: - Incident Type Enum
// Represents the type of incident
enum IncidentType {
  outage,
  degraded,
  maintenance,
  security,
}

// MARK: - Incident Status Enum
// Represents the status of an incident
enum IncidentStatus {
  investigating,
  identified,
  monitoring,
  resolved,
  postmortem,
}

// Suggestions For Features and Additions Later:
// - Add incident severity levels
// - Implement incident notifications
// - Add incident impact metrics
// - Create incident templates
// - Add incident collaboration features
// - Implement incident analytics
// - Add incident export functionality

