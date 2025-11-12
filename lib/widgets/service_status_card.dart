// Filename: service_status_card.dart
// Purpose: Reusable card widget for displaying service status information
// Author: Kevin Doyle Jr. / Infinitum Imagery LLC
// Last Modified: 2025-01-27
// Dependencies: flutter, models/service_status.dart
// Platform Compatibility: Web, iOS, Android

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/service_status.dart';
import '../core/config.dart';
import '../core/responsive.dart';

// MARK: - Service Status Card
// Displays service status in a card format with status indicator and details
class ServiceStatusCard extends StatelessWidget {
  final ServiceStatus service;
  final VoidCallback? onTap;
  final VoidCallback? onReport;
  final VoidCallback? onRecheck;
  final bool isChecking;

  const ServiceStatusCard({
    super.key,
    required this.service,
    this.onTap,
    this.onReport,
    this.onRecheck,
    this.isChecking = false,
  });

  // MARK: - UI Build Methods
  @override
  Widget build(BuildContext context) {
    final statusColor = Color(service.statusColor);
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: statusColor.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.surface,
                Theme.of(context).colorScheme.surface.withOpacity(0.95),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Enhanced status indicator with pulse animation
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Service name
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                          ),
                          if (service.type == ServiceType.infinitum)
                            Text(
                              'Infinitum Service',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontSize: 10,
                                  ),
                            )
                          else
                            Text(
                              'Third-Party Service',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.secondary,
                                    fontSize: 10,
                                  ),
                            ),
                        ],
                      ),
                    ),
                    // Enhanced status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            statusColor.withOpacity(0.2),
                            statusColor.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: statusColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(service.status),
                            size: 14,
                            color: statusColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getStatusText(service.status),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 14),
              // Service URL (hidden for certain services)
              if (!shouldHideServiceUrl(service.id))
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.link,
                        size: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          service.url,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontFamily: 'monospace',
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              if (!shouldHideServiceUrl(service.id)) const SizedBox(height: 12),
              // Metrics row with better visuals - responsive layout
              Builder(
                builder: (context) {
                  final responsive = context.responsive;
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: responsive.isPhone
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (service.responseTimeMs > 0)
                                    _buildMetricChip(
                                      context,
                                      Icons.speed,
                                      '${service.responseTimeMs}ms',
                                      _getResponseTimeColor(service.responseTimeMs),
                                    ),
                                  _buildMetricChip(
                                    context,
                                    Icons.access_time,
                                    _formatLastChecked(service.lastChecked),
                                    Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                  if (service.lastUpTime != null)
                                    _buildMetricChip(
                                      context,
                                      Icons.timer_outlined,
                                      _formatUptime(service.lastUpTime!),
                                      const Color(0xFF10B981),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (onRecheck != null)
                                    _buildActionButton(
                                      context,
                                      icon: isChecking 
                                          ? SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(
                                                  Theme.of(context).colorScheme.primary,
                                                ),
                                              ),
                                            )
                                          : Icon(Icons.refresh, size: 16, color: Theme.of(context).colorScheme.primary),
                                      label: 'Re-Run',
                                      onPressed: isChecking ? null : onRecheck,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  if (onReport != null)
                                    _buildActionButton(
                                      context,
                                      icon: Icon(Icons.report_problem, size: 16, color: Theme.of(context).colorScheme.error),
                                      label: 'Report',
                                      onPressed: onReport,
                                      color: Theme.of(context).colorScheme.error,
                                    ),
                                ],
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Flexible(
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    if (service.responseTimeMs > 0)
                                      _buildMetricChip(
                                        context,
                                        Icons.speed,
                                        '${service.responseTimeMs}ms',
                                        _getResponseTimeColor(service.responseTimeMs),
                                      ),
                                    _buildMetricChip(
                                      context,
                                      Icons.access_time,
                                      _formatLastChecked(service.lastChecked),
                                      Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                    if (service.lastUpTime != null)
                                      _buildMetricChip(
                                        context,
                                        Icons.timer_outlined,
                                        _formatUptime(service.lastUpTime!),
                                        const Color(0xFF10B981),
                                      ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              // Action buttons
                              if (onRecheck != null)
                                _buildActionButton(
                                  context,
                                  icon: isChecking 
                                      ? SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              Theme.of(context).colorScheme.primary,
                                            ),
                                          ),
                                        )
                                      : Icon(Icons.refresh, size: 16, color: Theme.of(context).colorScheme.primary),
                                  label: 'Re-Run',
                                  onPressed: isChecking ? null : onRecheck,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              if (onRecheck != null && onReport != null)
                                const SizedBox(width: 6),
                              if (onReport != null)
                                _buildActionButton(
                                  context,
                                  icon: Icon(Icons.report_problem, size: 16, color: Theme.of(context).colorScheme.error),
                                  label: 'Report',
                                  onPressed: onReport,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                            ],
                          ),
                  );
                },
              ),
              // Error message if present
              if (service.errorMessage != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
                        Theme.of(context).colorScheme.errorContainer.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.error_outline,
                          size: 16,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          service.errorMessage!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.w500,
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
  
  // Gets icon for status
  IconData _getStatusIcon(ServiceHealthStatus status) {
    switch (status) {
      case ServiceHealthStatus.operational:
        return Icons.check_circle;
      case ServiceHealthStatus.degraded:
        return Icons.warning;
      case ServiceHealthStatus.down:
        return Icons.error;
      case ServiceHealthStatus.unknown:
        return Icons.help_outline;
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
  
  // Formats uptime since last up
  String _formatUptime(DateTime lastUpTime) {
    final now = DateTime.now();
    final difference = now.difference(lastUpTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d uptime';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h uptime';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m uptime';
    } else {
      return 'Just up';
    }
  }
  
  // Gets color for response time
  Color _getResponseTimeColor(int responseTimeMs) {
    if (responseTimeMs < 200) {
      return const Color(0xFF10B981); // Green - fast
    } else if (responseTimeMs < 500) {
      return const Color(0xFFF59E0B); // Amber - moderate
    } else {
      return const Color(0xFFEF4444); // Red - slow
    }
  }
  
  // Builds a metric chip widget
  Widget _buildMetricChip(BuildContext context, IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
          ),
        ],
      ),
    );
  }
  
  // Builds an action button
  Widget _buildActionButton(
    BuildContext context, {
    required Widget icon,
    required String label,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: icon,
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: color.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
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

