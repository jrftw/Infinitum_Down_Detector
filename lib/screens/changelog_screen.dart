// Filename: changelog_screen.dart
// Purpose: Screen displaying application changelog
// Author: Kevin Doyle Jr. / Infinitum Imagery LLC
// Last Modified: 2025-01-27
// Dependencies: flutter, models/changelog_entry.dart
// Platform Compatibility: Web, iOS, Android

import 'package:flutter/material.dart';
import '../models/changelog_entry.dart';

// MARK: - Changelog Screen
// Displays the application changelog
class ChangelogScreen extends StatelessWidget {
  const ChangelogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = ChangelogData.getEntries();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Changelog'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[index];
          return _buildChangelogEntry(context, entry);
        },
      ),
    );
  }

  // MARK: - Changelog Entry Widget
  // Builds a single changelog entry card
  Widget _buildChangelogEntry(BuildContext context, ChangelogEntry entry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Version header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Version ${entry.version}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Build ${entry.build}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Changes list
            ...entry.changes.map((change) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          change,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

// Suggestions For Features and Additions Later:
// - Add search functionality for changelog
// - Implement changelog filtering by version
// - Add changelog export functionality
// - Create changelog RSS feed
// - Add changelog sharing options

