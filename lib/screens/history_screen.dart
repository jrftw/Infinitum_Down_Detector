// Filename: history_screen.dart
// Purpose: Screen displaying service status history with graphs and statistics
// Author: Kevin Doyle Jr. / Infinitum Imagery LLC
// Last Modified: 2025-01-27
// Dependencies: flutter, fl_chart, models/service_status.dart, models/status_history.dart, services/history_service.dart, core/responsive.dart
// Platform Compatibility: Web, iOS, Android

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/service_status.dart';
import '../models/status_history.dart';
import '../services/history_service.dart';
import '../core/responsive.dart';
import '../core/logger.dart';

// MARK: - History Screen
// Displays service status history with graphs and statistics
class HistoryScreen extends StatefulWidget {
  final ServiceStatus service;

  const HistoryScreen({
    super.key,
    required this.service,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryService _historyService = HistoryService();
  List<StatusHistoryEntry> _historyEntries = [];
  StatusStatistics? _statistics;
  bool _isLoading = true;
  String _selectedTimeRange = '24h'; // '24h', '7d', '30d'
  String _selectedChartType = 'uptime'; // 'uptime', 'responseTime'

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  // MARK: - Data Loading
  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      DateTime startTime;
      switch (_selectedTimeRange) {
        case '24h':
          startTime = DateTime.now().subtract(const Duration(hours: 24));
          break;
        case '7d':
          startTime = DateTime.now().subtract(const Duration(days: 7));
          break;
        case '30d':
          startTime = DateTime.now().subtract(const Duration(days: 30));
          break;
        default:
          startTime = DateTime.now().subtract(const Duration(hours: 24));
      }

      final entries = await _historyService.getHistoryEntries(
        widget.service.id,
        startTime: startTime,
      );

      final stats = StatusStatistics.fromHistory(entries);

      setState(() {
        _historyEntries = entries;
        _statistics = stats;
        _isLoading = false;
      });
    } catch (e) {
      Logger.logError('Error loading history', 'history_screen.dart', '_loadHistory', e);
      setState(() {
        _isLoading = false;
      });
    }
  }

  // MARK: - UI Build Methods
  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.service.name} History'),
        actions: [
          // Time range selector
          PopupMenuButton<String>(
            icon: const Icon(Icons.access_time),
            tooltip: 'Time Range',
            onSelected: (value) {
              setState(() {
                _selectedTimeRange = value;
              });
              _loadHistory();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: '24h',
                child: Row(
                  children: [
                    Icon(Icons.today, size: 20),
                    SizedBox(width: 8),
                    Text('Last 24 Hours'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: '7d',
                child: Row(
                  children: [
                    Icon(Icons.date_range, size: 20),
                    SizedBox(width: 8),
                    Text('Last 7 Days'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: '30d',
                child: Row(
                  children: [
                    Icon(Icons.calendar_month, size: 20),
                    SizedBox(width: 8),
                    Text('Last 30 Days'),
                  ],
                ),
              ),
            ],
          ),
          // Chart type selector
          PopupMenuButton<String>(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Chart Type',
            onSelected: (value) {
              setState(() {
                _selectedChartType = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'uptime',
                child: Row(
                  children: [
                    Icon(Icons.trending_up, size: 20),
                    SizedBox(width: 8),
                    Text('Uptime'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'responseTime',
                child: Row(
                  children: [
                    Icon(Icons.speed, size: 20),
                    SizedBox(width: 8),
                    Text('Response Time'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _historyEntries.isEmpty
              ? _buildEmptyState(context)
              : SingleChildScrollView(
                  padding: EdgeInsets.all(responsive.isPhone ? 16 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Statistics cards
                      _buildStatisticsCards(context, responsive),
                      const SizedBox(height: 24),
                      // Chart
                      _buildChart(context, responsive),
                      const SizedBox(height: 24),
                      // History timeline
                      _buildHistoryTimeline(context, responsive),
                    ],
                  ),
                ),
    );
  }

  // MARK: - Statistics Cards
  Widget _buildStatisticsCards(BuildContext context, Responsive responsive) {
    if (_statistics == null) return const SizedBox.shrink();

    final stats = _statistics!;

    return responsive.isPhone
        ? Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Uptime',
                      '${stats.uptimePercentage.toStringAsFixed(1)}%',
                      const Color(0xFF10B981),
                      Icons.trending_up,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Avg Response',
                      stats.averageResponseTime > 0
                          ? '${stats.averageResponseTime.toStringAsFixed(0)}ms'
                          : 'N/A',
                      const Color(0xFF3B82F6),
                      Icons.speed,
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
                      'Total Checks',
                      stats.totalChecks.toString(),
                      const Color(0xFF6B7280),
                      Icons.check_circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Issues',
                      (stats.degradedCount + stats.downCount).toString(),
                      const Color(0xFFF59E0B),
                      Icons.warning,
                    ),
                  ),
                ],
              ),
            ],
          )
        : Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  'Uptime',
                  '${stats.uptimePercentage.toStringAsFixed(1)}%',
                  const Color(0xFF10B981),
                  Icons.trending_up,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Avg Response',
                  stats.averageResponseTime > 0
                      ? '${stats.averageResponseTime.toStringAsFixed(0)}ms'
                      : 'N/A',
                  const Color(0xFF3B82F6),
                  Icons.speed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Total Checks',
                  stats.totalChecks.toString(),
                  const Color(0xFF6B7280),
                  Icons.check_circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Issues',
                  (stats.degradedCount + stats.downCount).toString(),
                  const Color(0xFFF59E0B),
                  Icons.warning,
                ),
              ),
            ],
          );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              const SizedBox(width: 8),
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
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }

  // MARK: - Chart Widget
  Widget _buildChart(BuildContext context, Responsive responsive) {
    if (_historyEntries.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedChartType == 'uptime' ? 'Uptime Chart' : 'Response Time Chart',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: responsive.isPhone ? 200 : 300,
            child: _selectedChartType == 'uptime'
                ? _buildUptimeChart(context)
                : _buildResponseTimeChart(context),
          ),
        ],
      ),
    );
  }

  Widget _buildUptimeChart(BuildContext context) {
    if (_historyEntries.isEmpty) return const SizedBox.shrink();

    // Group entries by time intervals for better visualization
    final chartData = _prepareUptimeChartData();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: _getTimeInterval(),
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _formatChartTime(value),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 25,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}%',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        minX: 0,
        maxX: chartData.length.toDouble() - 1,
        minY: 0,
        maxY: 100,
        lineBarsData: [
          LineChartBarData(
            spots: chartData,
            isCurved: true,
            color: const Color(0xFF10B981),
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF10B981).withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseTimeChart(BuildContext context) {
    if (_historyEntries.isEmpty) return const SizedBox.shrink();

    final chartData = _prepareResponseTimeChartData();
    final maxResponseTime = chartData.isEmpty
        ? 1000.0
        : chartData.map((e) => e.y).reduce((a, b) => a > b ? a : b) * 1.1;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: _getTimeInterval(),
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _formatChartTime(value),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}ms',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        minX: 0,
        maxX: chartData.length.toDouble() - 1,
        minY: 0,
        maxY: maxResponseTime,
        lineBarsData: [
          LineChartBarData(
            spots: chartData,
            isCurved: true,
            color: const Color(0xFF3B82F6),
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF3B82F6).withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  // MARK: - Chart Data Preparation
  List<FlSpot> _prepareUptimeChartData() {
    if (_historyEntries.isEmpty) return [];

    // Group entries into time buckets
    final buckets = <int, List<StatusHistoryEntry>>{};
    final bucketSize = _getBucketSize();

    for (final entry in _historyEntries) {
      final bucketIndex = (entry.timestamp.millisecondsSinceEpoch / bucketSize).floor();
      buckets.putIfAbsent(bucketIndex, () => []).add(entry);
    }

    final spots = <FlSpot>[];
    final sortedBuckets = buckets.keys.toList()..sort();
    int xIndex = 0;

    for (final bucketIndex in sortedBuckets) {
      final entries = buckets[bucketIndex]!;
      final operationalCount = entries.where((e) => e.status == ServiceHealthStatus.operational).length;
      final uptimePercentage = entries.isEmpty ? 0.0 : (operationalCount / entries.length * 100);
      
      spots.add(FlSpot(xIndex.toDouble(), uptimePercentage));
      xIndex++;
    }

    return spots;
  }

  List<FlSpot> _prepareResponseTimeChartData() {
    if (_historyEntries.isEmpty) return [];

    final buckets = <int, List<StatusHistoryEntry>>{};
    final bucketSize = _getBucketSize();

    for (final entry in _historyEntries) {
      if (entry.responseTimeMs > 0) {
        final bucketIndex = (entry.timestamp.millisecondsSinceEpoch / bucketSize).floor();
        buckets.putIfAbsent(bucketIndex, () => []).add(entry);
      }
    }

    final spots = <FlSpot>[];
    final sortedBuckets = buckets.keys.toList()..sort();
    int xIndex = 0;

    for (final bucketIndex in sortedBuckets) {
      final entries = buckets[bucketIndex]!;
      if (entries.isEmpty) continue;
      
      final avgResponseTime = entries.map((e) => e.responseTimeMs).reduce((a, b) => a + b) / entries.length;
      spots.add(FlSpot(xIndex.toDouble(), avgResponseTime));
      xIndex++;
    }

    return spots;
  }

  int _getBucketSize() {
    switch (_selectedTimeRange) {
      case '24h':
        return 3600000; // 1 hour
      case '7d':
        return 86400000; // 1 day
      case '30d':
        return 86400000; // 1 day
      default:
        return 3600000;
    }
  }

  double _getTimeInterval() {
    switch (_selectedTimeRange) {
      case '24h':
        return 4.0; // Every 4 hours
      case '7d':
        return 1.0; // Every day
      case '30d':
        return 5.0; // Every 5 days
      default:
        return 4.0;
    }
  }

  String _formatChartTime(double value) {
    if (_historyEntries.isEmpty) return '';
    
    final index = value.toInt();
    final buckets = <int, List<StatusHistoryEntry>>{};
    final bucketSize = _getBucketSize();

    for (final entry in _historyEntries) {
      final bucketIndex = (entry.timestamp.millisecondsSinceEpoch / bucketSize).floor();
      buckets.putIfAbsent(bucketIndex, () => []).add(entry);
    }

    final sortedBuckets = buckets.keys.toList()..sort();
    if (index >= sortedBuckets.length) return '';

    final bucketIndex = sortedBuckets[index];
    final entries = buckets[bucketIndex]!;
    if (entries.isEmpty) return '';

    final timestamp = entries.first.timestamp;
    
    switch (_selectedTimeRange) {
      case '24h':
        return DateFormat('HH:mm').format(timestamp);
      case '7d':
      case '30d':
        return DateFormat('MMM d').format(timestamp);
      default:
        return DateFormat('HH:mm').format(timestamp);
    }
  }

  // MARK: - History Timeline
  Widget _buildHistoryTimeline(BuildContext context, Responsive responsive) {
    if (_historyEntries.isEmpty) return const SizedBox.shrink();

    // Show only recent entries in timeline (last 50)
    final recentEntries = _historyEntries.take(50).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent History',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          ...recentEntries.map((entry) => _buildHistoryEntry(context, entry)),
        ],
      ),
    );
  }

  Widget _buildHistoryEntry(BuildContext context, StatusHistoryEntry entry) {
    final statusColor = _getStatusColor(entry.status);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Color(statusColor),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _getStatusText(entry.status),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Color(statusColor),
                            ),
                      ),
                    ),
                    Text(
                      DateFormat('MMM d, HH:mm').format(entry.timestamp),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
                if (entry.responseTimeMs > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Response time: ${entry.responseTimeMs}ms',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
                if (entry.errorMessage != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    entry.errorMessage!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // MARK: - Helper Methods
  int _getStatusColor(ServiceHealthStatus status) {
    switch (status) {
      case ServiceHealthStatus.operational:
        return 0xFF10B981;
      case ServiceHealthStatus.degraded:
        return 0xFFF59E0B;
      case ServiceHealthStatus.partialOutage:
        return 0xFFF97316;
      case ServiceHealthStatus.majorOutage:
        return 0xFFDC2626;
      case ServiceHealthStatus.down:
        return 0xFFEF4444;
      case ServiceHealthStatus.maintenance:
        return 0xFF6366F1;
      case ServiceHealthStatus.unknown:
        return 0xFF6B7280;
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No History Available',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'History data will appear here once the service has been monitored for a while.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _historyService.dispose();
    super.dispose();
  }
}

// Suggestions For Features and Additions Later:
// - Add export history functionality
// - Implement history filtering by status
// - Add comparison between time periods
// - Create history alerts and notifications
// - Add history search functionality
// - Implement history sharing
// - Add history annotations and notes

