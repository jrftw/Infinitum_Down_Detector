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
import '../core/version.dart';
import '../core/config.dart';
import '../widgets/service_status_card.dart';
import '../widgets/report_dialog.dart';
import '../core/responsive.dart';
import 'changelog_screen.dart';
import 'history_screen.dart';

// MARK: - Status Page
// Main page displaying all service statuses with detailed information
class StatusPage extends StatefulWidget {
  const StatusPage({super.key});

  @override
  State<StatusPage> createState() => _StatusPageState();
}

class _StatusPageState extends State<StatusPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'name'; // 'name', 'status', 'responseTime'
  bool _showOnlyIssues = false;
  
  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
    // Health checks are performed server-side by scheduled Firebase Function
    // Real-time listener will automatically update the UI when Firestore is updated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ServiceStatusProvider>(context, listen: false);
      provider.startPeriodicChecks();
    });
  }
  

  @override
  void dispose() {
    // Dispose search controller
    _searchController.dispose();
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
            expandedHeight: 180,
            floating: false,
            pinned: true,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Infinitum Status',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primaryContainer,
                      Theme.of(context).colorScheme.secondaryContainer,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      top: -50,
                      right: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -30,
                      left: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              // Filter button
              Consumer<ServiceStatusProvider>(
                builder: (context, provider, _) {
                  final hasIssues = provider.issuesCount > 0;
                  return IconButton(
                    icon: Stack(
                      children: [
                        Icon(
                          _showOnlyIssues ? Icons.filter_alt : Icons.filter_alt_outlined,
                          color: _showOnlyIssues ? Theme.of(context).colorScheme.primary : null,
                        ),
                        if (hasIssues && !_showOnlyIssues)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1),
                              ),
                            ),
                          ),
                      ],
                    ),
                    onPressed: () {
                      setState(() {
                        _showOnlyIssues = !_showOnlyIssues;
                      });
                    },
                    tooltip: _showOnlyIssues ? 'Show All Services' : 'Show Only Issues',
                  );
                },
              ),
              // Sort button
              PopupMenuButton<String>(
                icon: const Icon(Icons.sort),
                tooltip: 'Sort Services',
                onSelected: (value) {
                  setState(() {
                    _sortBy = value;
                  });
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'name',
                    child: Row(
                      children: [
                        Icon(Icons.sort_by_alpha, size: 20),
                        SizedBox(width: 8),
                        Text('Sort by Name'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'status',
                    child: Row(
                      children: [
                        Icon(Icons.priority_high, size: 20),
                        SizedBox(width: 8),
                        Text('Sort by Status'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'responseTime',
                    child: Row(
                      children: [
                        Icon(Icons.speed, size: 20),
                        SizedBox(width: 8),
                        Text('Sort by Response Time'),
                      ],
                    ),
                  ),
                ],
              ),
              // Version info button
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () => _showVersionDialog(context),
                tooltip: 'Version Info',
              ),
            ],
          ),
          
          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search services...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),
          ),
          
          // Status Overview - Infinitum Services
          SliverToBoxAdapter(
            child: Consumer<ServiceStatusProvider>(
              builder: (context, provider, _) {
                return _buildStatusOverview(
                  context, 
                  provider, 
                  services: provider.infinitumServices,
                  title: 'Infinitum Services Overview',
                  icon: Icons.business,
                );
              },
            ),
          ),
          
          // Status Overview - Third-Party Services
          SliverToBoxAdapter(
            child: Consumer<ServiceStatusProvider>(
              builder: (context, provider, _) {
                return _buildStatusOverview(
                  context, 
                  provider, 
                  services: provider.thirdPartyServices,
                  title: 'Third-Party Services Overview',
                  icon: Icons.cloud,
                );
              },
            ),
          ),
          
          // Infinitum Services Section
          Consumer<ServiceStatusProvider>(
            builder: (context, provider, _) {
              final services = _filterAndSortServices(provider.infinitumServices);
              if (services.isEmpty && (_searchQuery.isNotEmpty || _showOnlyIssues)) {
                return const SliverToBoxAdapter(
                  child: SizedBox.shrink(),
                );
              }
              final responsive = context.responsive;
              return SliverMainAxisGroup(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        responsive.isPhone ? 16 : 24,
                        24,
                        responsive.isPhone ? 16 : 24,
                        8,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.business,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Infinitum Services',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (services.length != provider.infinitumServices.length)
                                  Text(
                                    '${services.length} of ${provider.infinitumServices.length} shown',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Use list layout for all screen sizes (original design)
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: responsive.isPhone ? 16 : 24,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final service = services[index];
                          return Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: responsive.isPhone ? 0 : 8,
                              vertical: 8,
                            ),
                            child: ServiceStatusCard(
                              service: service,
                              onTap: () => _showServiceDetails(context, service),
                              onReport: () => _showReportDialog(context, service),
                              onHistory: () => _showHistory(context, service),
                            ),
                          );
                        },
                        childCount: services.length,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          
          // Third-Party Services Section
          Consumer<ServiceStatusProvider>(
            builder: (context, provider, _) {
              final services = _filterAndSortServices(provider.thirdPartyServices);
              if (services.isEmpty && (_searchQuery.isNotEmpty || _showOnlyIssues)) {
                return const SliverToBoxAdapter(
                  child: SizedBox.shrink(),
                );
              }
              final responsive = context.responsive;
              return SliverMainAxisGroup(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        responsive.isPhone ? 16 : 24,
                        24,
                        responsive.isPhone ? 16 : 24,
                        8,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.cloud,
                              color: Theme.of(context).colorScheme.onSecondaryContainer,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Third-Party Services',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (services.length != provider.thirdPartyServices.length)
                                  Text(
                                    '${services.length} of ${provider.thirdPartyServices.length} shown',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Use list layout for all screen sizes (original design)
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: responsive.isPhone ? 16 : 24,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final service = services[index];
                          return Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: responsive.isPhone ? 0 : 8,
                              vertical: 8,
                            ),
                            child: ServiceStatusCard(
                              service: service,
                              onTap: () => _showServiceDetails(context, service),
                              onReport: () => _showReportDialog(context, service),
                              onHistory: () => _showHistory(context, service),
                            ),
                          );
                        },
                        childCount: services.length,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          
          // Empty state message
          Consumer<ServiceStatusProvider>(
            builder: (context, provider, _) {
              final infinitumFiltered = _filterAndSortServices(provider.infinitumServices);
              final thirdPartyFiltered = _filterAndSortServices(provider.thirdPartyServices);
              final hasResults = infinitumFiltered.isNotEmpty || thirdPartyFiltered.isNotEmpty;
              final hasFilters = _searchQuery.isNotEmpty || _showOnlyIssues;
              
              if (!hasResults && hasFilters) {
                return SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(32),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No services found',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your search or filter settings',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _showOnlyIssues = false;
                            });
                          },
                          icon: const Icon(Icons.clear_all),
                          label: const Text('Clear Filters'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            },
          ),
          
          // Footer
          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
        ],
      ),
      floatingActionButton: Consumer<ServiceStatusProvider>(
        builder: (context, provider, _) {
          return FloatingActionButton.extended(
            onPressed: () {
              _showReportDialog(context, null, allServices: provider.allServices);
            },
            icon: const Icon(Icons.report_problem),
            label: const Text('Report Issue'),
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
            elevation: 4,
          );
        },
      ),
    );
  }

  // MARK: - Filter and Sort Methods
  /// Filters and sorts services based on current search and filter settings
  /// [services] - List of services to filter and sort
  /// Returns filtered and sorted list
  List<ServiceStatus> _filterAndSortServices(List<ServiceStatus> services) {
    var filtered = services.where((service) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final matchesSearch = service.name.toLowerCase().contains(_searchQuery) ||
            service.url.toLowerCase().contains(_searchQuery);
        if (!matchesSearch) return false;
      }
      
      // Issues filter
      if (_showOnlyIssues && !service.hasIssues) {
        return false;
      }
      
      return true;
    }).toList();
    
    // Sort
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'status':
          // Sort by status priority: down > majorOutage > partialOutage > degraded > maintenance > unknown > operational
          final statusPriority = {
            ServiceHealthStatus.down: 0,
            ServiceHealthStatus.majorOutage: 1,
            ServiceHealthStatus.partialOutage: 2,
            ServiceHealthStatus.degraded: 3,
            ServiceHealthStatus.maintenance: 4,
            ServiceHealthStatus.unknown: 5,
            ServiceHealthStatus.operational: 6,
          };
          final aPriority = statusPriority[a.status] ?? 3;
          final bPriority = statusPriority[b.status] ?? 3;
          if (aPriority != bPriority) {
            return aPriority.compareTo(bPriority);
          }
          return a.name.compareTo(b.name);
        case 'responseTime':
          if (a.responseTimeMs == b.responseTimeMs) {
            return a.name.compareTo(b.name);
          }
          if (a.responseTimeMs == 0) return 1;
          if (b.responseTimeMs == 0) return -1;
          return a.responseTimeMs.compareTo(b.responseTimeMs);
        case 'name':
        default:
          return a.name.compareTo(b.name);
      }
    });
    
    return filtered;
  }
  
  // MARK: - Status Overview Widget
  // Builds the overview section showing overall status statistics for a specific set of services
  Widget _buildStatusOverview(
    BuildContext context, 
    ServiceStatusProvider provider, {
    required List<ServiceStatus> services,
    required String title,
    required IconData icon,
  }) {
    final operational = services.where((s) => s.isOperational).length;
    final degraded = services.where((s) => s.status == ServiceHealthStatus.degraded).length;
    final partialOutage = services.where((s) => s.status == ServiceHealthStatus.partialOutage).length;
    final majorOutage = services.where((s) => s.status == ServiceHealthStatus.majorOutage).length;
    final down = services.where((s) => s.status == ServiceHealthStatus.down).length;
    final maintenance = services.where((s) => s.status == ServiceHealthStatus.maintenance).length;
    final unknown = services.where((s) => s.status == ServiceHealthStatus.unknown).length;
    final total = services.length;
    
    // Calculate uptime percentage (operational / total)
    final uptimePercentage = total > 0 ? (operational / total * 100) : 0.0;
    
    // Calculate average response time
    final servicesWithResponseTime = services.where((s) => s.responseTimeMs > 0).toList();
    final avgResponseTime = servicesWithResponseTime.isEmpty
        ? 0
        : (servicesWithResponseTime.map((s) => s.responseTimeMs).reduce((a, b) => a + b) /
            servicesWithResponseTime.length).round();
    
    final lastCheck = provider.lastCheckTime;
    final lastCheckText = lastCheck != null
        ? DateFormat('MMM d, y • h:mm a').format(lastCheck)
        : 'Never';
    
    final responsive = context.responsive;
    return Container(
      margin: EdgeInsets.all(responsive.isPhone ? 16 : 20),
      padding: EdgeInsets.all(responsive.isPhone ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surfaceContainerHighest,
            Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Stat cards - responsive layout (2x2 on mobile, single row on larger screens)
          if (responsive.isPhone)
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Operational',
                        operational.toString(),
                        total.toString(),
                        const Color(0xFF10B981),
                        Icons.check_circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Issues',
                        (degraded + partialOutage + majorOutage + down).toString(),
                        total.toString(),
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
                        total.toString(),
                        const Color(0xFFEF4444),
                        Icons.error,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Other',
                        (maintenance + unknown).toString(),
                        total.toString(),
                        const Color(0xFF6B7280),
                        Icons.help_outline,
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Operational',
                    operational.toString(),
                    total.toString(),
                    const Color(0xFF10B981),
                    Icons.check_circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Issues',
                    (degraded + partialOutage + majorOutage + down).toString(),
                    total.toString(),
                    const Color(0xFFF59E0B),
                    Icons.warning,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Down',
                    down.toString(),
                    total.toString(),
                    const Color(0xFFEF4444),
                    Icons.error,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Other',
                    (maintenance + unknown).toString(),
                    total.toString(),
                    const Color(0xFF6B7280),
                    Icons.help_outline,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          Divider(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
          const SizedBox(height: 12),
          // Uptime percentage
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF10B981).withOpacity(0.1),
                  const Color(0xFF10B981).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF10B981).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.trending_up,
                    color: Color(0xFF10B981),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Uptime',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      Text(
                        '${uptimePercentage.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF10B981),
                            ),
                      ),
                    ],
                  ),
                ),
                if (avgResponseTime > 0)
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Avg Response',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${avgResponseTime}ms',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Last checked: $lastCheckText',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (lastCheck != null)
                Flexible(
                  child: Text(
                    _formatTimeSince(lastCheck),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                    overflow: TextOverflow.ellipsis,
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
    final responsive = context.responsive;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: EdgeInsets.all(responsive.isPhone ? 16 : 24),
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
            Expanded(
              child: Text(
                service.name,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: responsive.dialogWidth,
            maxHeight: responsive.height * 0.8,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Status with color indicator
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Color(service.statusColor),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDetailRow('Status', _getStatusText(service.status)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildDetailRow('Service Type', service.type == ServiceType.infinitum ? 'Infinitum Service' : 'Third-Party Service'),
              const SizedBox(height: 12),
              if (!shouldHideServiceUrl(service.id)) ...[
                _buildDetailRow('URL', service.url),
                const SizedBox(height: 12),
              ],
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
              const SizedBox(height: 12),
              _buildDetailRow(
                'Time Since Last Check',
                _formatTimeSince(service.lastChecked),
              ),
              if (service.lastUpTime != null) ...[
                const SizedBox(height: 12),
                _buildDetailRow(
                  'Last Up',
                  DateFormat('MMM d, y • h:mm:ss a').format(service.lastUpTime!),
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  'Uptime Since Last Up',
                  _formatTimeSince(service.lastUpTime!),
                ),
              ],
              if (service.errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 16,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Error Message',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        service.errorMessage!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
              if (service.consecutiveFailures > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildDetailRow(
                          'Consecutive Failures',
                          service.consecutiveFailures.toString(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // Component statuses if available
              if (service.components.isNotEmpty) ...[
                const SizedBox(height: 12),
                Divider(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
                const SizedBox(height: 12),
                Text(
                  'Service Components',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                ...service.components.map((component) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Color(component.statusColor).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Color(component.statusColor),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              component.typeIcon,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                component.name,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Color(component.statusColor).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getStatusText(component.status),
                                style: TextStyle(
                                  color: Color(component.statusColor),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildDetailRow('URL', component.url),
                        if (component.responseTimeMs > 0) ...[
                          const SizedBox(height: 4),
                          _buildDetailRow('Response Time', '${component.responseTimeMs}ms'),
                        ],
                        if (component.statusCode != null) ...[
                          const SizedBox(height: 4),
                          _buildDetailRow('Status Code', '${component.statusCode}'),
                        ],
                        if (component.errorMessage != null) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 14,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    component.errorMessage!,
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
                )),
              ],
              const SizedBox(height: 12),
              // Service health summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Health Summary',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow('Is Operational', service.isOperational ? 'Yes' : 'No'),
                    const SizedBox(height: 4),
                    _buildDetailRow('Has Issues', service.hasIssues ? 'Yes' : 'No'),
                    const SizedBox(height: 4),
                    _buildDetailRow('Status Code', service.status.name.toUpperCase()),
                    if (service.components.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _buildDetailRow('Components', '${service.operationalComponentsCount}/${service.components.length} operational'),
                      if (service.componentsWithIssuesCount > 0) ...[
                        const SizedBox(height: 4),
                        _buildDetailRow('Components with Issues', service.componentsWithIssuesCount.toString()),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
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
    final responsive = context.responsive;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: responsive.isPhone
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.visible,
                  softWrap: true,
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: responsive.isTablet ? 140 : 160,
                  child: Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.visible,
                    softWrap: true,
                  ),
                ),
              ],
            ),
    );
  }

  // MARK: - Status Text Helper
  // Converts status enum to readable text
  // Formats time since a given DateTime
  String _formatTimeSince(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} seconds ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return '$months month${months == 1 ? '' : 's'} ago';
    }
  }
  
  String _getStatusText(ServiceHealthStatus status) {
    switch (status) {
      case ServiceHealthStatus.operational:
        return 'Operational';
      case ServiceHealthStatus.degraded:
        return 'Degraded';
      case ServiceHealthStatus.partialOutage:
        return 'Partial Outage';
      case ServiceHealthStatus.majorOutage:
        return 'Major Outage';
      case ServiceHealthStatus.down:
        return 'Down';
      case ServiceHealthStatus.maintenance:
        return 'Maintenance';
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

  // MARK: - History Navigation
  // Navigates to history screen for a service
  void _showHistory(BuildContext context, ServiceStatus service) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HistoryScreen(service: service),
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

