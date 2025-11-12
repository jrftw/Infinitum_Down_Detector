// Filename: status_page.dart
// Purpose: Main status page displaying all service statuses with detailed information
// Author: Kevin Doyle Jr. / Infinitum Imagery LLC
// Last Modified: 2025-01-27
// Dependencies: flutter, providers/service_status_provider.dart, models/service_status.dart, widgets/service_status_card.dart, widgets/report_dialog.dart
// Platform Compatibility: Web, iOS, Android

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/service_status_provider.dart';
import '../models/service_status.dart';
import '../core/logger.dart';
import '../core/version.dart';
import '../widgets/service_status_card.dart';
import '../widgets/report_dialog.dart';
import 'changelog_screen.dart';

// MARK: - Status Page
// Main page displaying all service statuses with detailed information
class StatusPage extends StatefulWidget {
  const StatusPage({super.key});

  @override
  State<StatusPage> createState() => _StatusPageState();
}

class _StatusPageState extends State<StatusPage> {
  @override
  void initState() {
    super.initState();
    // Start periodic health checks when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ServiceStatusProvider>(context, listen: false);
      provider.startPeriodicChecks();
      // Perform initial check
      provider.checkAllServices();
    });
  }

  @override
  void dispose() {
    // Stop periodic checks when page is disposed
    final provider = Provider.of<ServiceStatusProvider>(context, listen: false);
    provider.stopPeriodicChecks();
    super.dispose();
  }

  // MARK: - UI Build Methods
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Infinitum Status'),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primaryContainer,
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              // Version info button
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () => _showVersionDialog(context),
                tooltip: 'Version Info',
              ),
              // Refresh button
              Consumer<ServiceStatusProvider>(
                builder: (context, provider, _) {
                  return IconButton(
                    icon: provider.isChecking
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    onPressed: provider.isChecking
                        ? null
                        : () {
                            provider.checkAllServices();
                            Logger.logInfo('Manual refresh triggered', 'status_page.dart', 'build');
                          },
                    tooltip: 'Refresh Status',
                  );
                },
              ),
            ],
          ),
          
          // Status Overview
          SliverToBoxAdapter(
            child: Consumer<ServiceStatusProvider>(
              builder: (context, provider, _) {
                return _buildStatusOverview(context, provider);
              },
            ),
          ),
          
          // Infinitum Services Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                'Infinitum Services',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
          
          Consumer<ServiceStatusProvider>(
            builder: (context, provider, _) {
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final service = provider.infinitumServices[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ServiceStatusCard(
                        service: service,
                        onTap: () => _showServiceDetails(context, service),
                        onReport: () => _showReportDialog(context, service),
                      ),
                    );
                  },
                  childCount: provider.infinitumServices.length,
                ),
              );
            },
          ),
          
          // Third-Party Services Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                'Third-Party Services',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
          
          Consumer<ServiceStatusProvider>(
            builder: (context, provider, _) {
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final service = provider.thirdPartyServices[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ServiceStatusCard(
                        service: service,
                        onTap: () => _showServiceDetails(context, service),
                        onReport: () => _showReportDialog(context, service),
                      ),
                    );
                  },
                  childCount: provider.thirdPartyServices.length,
                ),
              );
            },
          ),
          
          // Footer
          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final provider = Provider.of<ServiceStatusProvider>(context, listen: false);
          _showReportDialog(context, null, allServices: provider.allServices);
        },
        icon: const Icon(Icons.report_problem),
        label: const Text('Report Issue'),
      ),
    );
  }

  // MARK: - Status Overview Widget
  // Builds the overview section showing overall status statistics
  Widget _buildStatusOverview(BuildContext context, ServiceStatusProvider provider) {
    final allServices = provider.allServices;
    final operational = allServices.where((s) => s.isOperational).length;
    final degraded = allServices.where((s) => s.status == ServiceHealthStatus.degraded).length;
    final down = allServices.where((s) => s.status == ServiceHealthStatus.down).length;
    final unknown = allServices.where((s) => s.status == ServiceHealthStatus.unknown).length;
    
    final lastCheck = provider.lastCheckTime;
    final lastCheckText = lastCheck != null
        ? DateFormat('MMM d, y • h:mm a').format(lastCheck)
        : 'Never';
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.dashboard,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Status Overview',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  'Operational',
                  operational.toString(),
                  allServices.length.toString(),
                  const Color(0xFF10B981),
                  Icons.check_circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Degraded',
                  degraded.toString(),
                  allServices.length.toString(),
                  const Color(0xFFF59E0B),
                  Icons.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  'Down',
                  down.toString(),
                  allServices.length.toString(),
                  const Color(0xFFEF4444),
                  Icons.error,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Unknown',
                  unknown.toString(),
                  allServices.length.toString(),
                  const Color(0xFF6B7280),
                  Icons.help_outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'Last checked: $lastCheckText',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // MARK: - Stat Card Widget
  // Builds individual statistic cards
  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    String total,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$value / $total',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }

  // MARK: - Service Details Dialog
  // Shows detailed information about a specific service
  void _showServiceDetails(BuildContext context, ServiceStatus service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Color(service.statusColor),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(service.name)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Status', _getStatusText(service.status)),
              const SizedBox(height: 12),
              _buildDetailRow('URL', service.url),
              const SizedBox(height: 12),
              _buildDetailRow(
                'Response Time',
                service.responseTimeMs > 0
                    ? '${service.responseTimeMs}ms'
                    : 'N/A',
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                'Last Checked',
                DateFormat('MMM d, y • h:mm:ss a').format(service.lastChecked),
              ),
              if (service.lastUpTime != null) ...[
                const SizedBox(height: 12),
                _buildDetailRow(
                  'Last Up',
                  DateFormat('MMM d, y • h:mm:ss a').format(service.lastUpTime!),
                ),
              ],
              if (service.errorMessage != null) ...[
                const SizedBox(height: 12),
                _buildDetailRow('Error', service.errorMessage!),
              ],
              if (service.consecutiveFailures > 0) ...[
                const SizedBox(height: 12),
                _buildDetailRow(
                  'Consecutive Failures',
                  service.consecutiveFailures.toString(),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showReportDialog(context, service);
            },
            child: const Text('Report Issue'),
          ),
        ],
      ),
    );
  }

  // MARK: - Detail Row Widget
  // Builds a row for service details
  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  // MARK: - Status Text Helper
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

  // MARK: - Report Dialog
  // Shows dialog for reporting issues
  void _showReportDialog(
    BuildContext context,
    ServiceStatus? service, {
    List<ServiceStatus>? allServices,
  }) {
    showDialog(
      context: context,
      builder: (context) => ReportDialog(
        service: service,
        allServices: allServices ?? [],
      ),
    );
  }

  // MARK: - Version Dialog
  // Shows version information and changelog link
  void _showVersionDialog(BuildContext context) {
    final envName = getEnvironmentName();
    final versionText = getDisplayVersion();
    final statusText = getCurrentStatus();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline),
            SizedBox(width: 8),
            Text('Version Information'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Version display
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    versionText,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ],
                  ),
                  if (envName.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: envName == 'Dev'
                            ? Colors.orange.withOpacity(0.2)
                            : Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: envName == 'Dev'
                              ? Colors.orange
                              : Colors.blue,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        envName,
                        style: TextStyle(
                          color: envName == 'Dev' ? Colors.orange : Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Changelog button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ChangelogScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.history),
                label: const Text('View Changelog'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// Suggestions For Features and Additions Later:
// - Add historical status charts and graphs
// - Implement status change notifications
// - Add service uptime percentage calculations
// - Create status RSS feed
// - Add status API endpoints
// - Implement status export functionality
// - Add service maintenance scheduling
// - Create status change history timeline
// - Add service dependency visualization
// - Implement status filtering and search

