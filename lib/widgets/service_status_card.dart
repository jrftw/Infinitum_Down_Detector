// Filename: service_status_card.dart
// Purpose: Reusable card widget for displaying service status information
// Author: Kevin Doyle Jr. / Infinitum Imagery LLC
// Last Modified: 2025-01-27
// Dependencies: flutter, models/service_status.dart
// Platform Compatibility: Web, iOS, Android

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/service_status.dart';

// MARK: - Service Status Card
// Displays service status in a card format with status indicator and details
class ServiceStatusCard extends StatelessWidget {
  final ServiceStatus service;
  final VoidCallback? onTap;
  final VoidCallback? onReport;

  const ServiceStatusCard({
    super.key,
    required this.service,
    this.onTap,
    this.onReport,
  });

  // MARK: - UI Build Methods
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Status indicator
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Color(service.statusColor),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Service name
                  Expanded(
                    child: Text(
                      service.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(service.statusColor).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(service.status),
                      style: TextStyle(
                        color: Color(service.statusColor),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Service URL
              Row(
                children: [
                  Icon(
                    Icons.link,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      service.url,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Additional info row
              Row(
                children: [
                  if (service.responseTimeMs > 0) ...[
                    Icon(
                      Icons.speed,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${service.responseTimeMs}ms',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatLastChecked(service.lastChecked),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const Spacer(),
                  if (onReport != null)
                    TextButton.icon(
                      onPressed: onReport,
                      icon: const Icon(Icons.report_problem, size: 16),
                      label: const Text('Report'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                ],
              ),
              // Error message if present
              if (service.errorMessage != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          service.errorMessage!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // MARK: - Helper Methods
  // Converts status enum to readable text
  String _getStatusText(ServiceHealthStatus status) {
    switch (status) {
      case ServiceHealthStatus.operational:
        return 'Operational';
      case ServiceHealthStatus.degraded:
        return 'Degraded';
      case ServiceHealthStatus.down:
        return 'Down';
      case ServiceHealthStatus.unknown:
        return 'Unknown';
    }
  }

  // Formats last checked time to relative or absolute format
  String _formatLastChecked(DateTime lastChecked) {
    final now = DateTime.now();
    final difference = now.difference(lastChecked);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('MMM d, h:mm a').format(lastChecked);
    }
  }
}

// Suggestions For Features and Additions Later:
// - Add service type icon/badge
// - Implement animated status transitions
// - Add service uptime percentage display
// - Create compact and expanded card views
// - Add service tags and categories
// - Implement card swipe actions
// - Add service favorite/bookmark functionality

