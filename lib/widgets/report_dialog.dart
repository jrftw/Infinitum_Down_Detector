// Filename: report_dialog.dart
// Purpose: Dialog widget for users to report service issues
// Author: Kevin Doyle Jr. / Infinitum Imagery LLC
// Last Modified: 2025-01-27
// Dependencies: flutter, models/service_status.dart, services/report_service.dart, core/logger.dart
// Platform Compatibility: Web, iOS, Android

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/service_status.dart';
import '../services/report_service.dart';
import '../core/logger.dart';

// MARK: - Report Dialog
// Allows users to report issues with services
class ReportDialog extends StatefulWidget {
  final ServiceStatus? service;
  final List<ServiceStatus> allServices;

  const ReportDialog({
    super.key,
    this.service,
    required this.allServices,
  });

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  ServiceStatus? _selectedService;
  String _reportType = 'down';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedService = widget.service;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // MARK: - Form Submission
  /// Handles form submission and sends the report
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a service')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final reportService = Provider.of<ReportService>(context, listen: false);
      
      await reportService.submitReport(
        serviceId: _selectedService!.id,
        serviceName: _selectedService!.name,
        reportType: _reportType,
        reporterName: _nameController.text.trim(),
        reporterEmail: _emailController.text.trim(),
        description: _descriptionController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report submitted successfully. Thank you!'),
            backgroundColor: Colors.green,
          ),
        );
        Logger.logInfo('Report submitted for ${_selectedService!.name}', 
            'report_dialog.dart', '_handleSubmit');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting report: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        Logger.logError('Error submitting report', 'report_dialog.dart', '_handleSubmit', e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // MARK: - UI Build Methods
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.report_problem),
          SizedBox(width: 8),
          Text('Report Issue'),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Service selection
              DropdownButtonFormField<ServiceStatus>(
                value: _selectedService,
                decoration: const InputDecoration(
                  labelText: 'Service',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.cloud),
                ),
                items: widget.allServices.map((service) {
                  return DropdownMenuItem(
                    value: service,
                    child: Text(service.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedService = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a service';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Report type
              DropdownButtonFormField<String>(
                value: _reportType,
                decoration: const InputDecoration(
                  labelText: 'Issue Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'down',
                    child: Text('Service is Down'),
                  ),
                  DropdownMenuItem(
                    value: 'slow',
                    child: Text('Service is Slow'),
                  ),
                  DropdownMenuItem(
                    value: 'error',
                    child: Text('Error Messages'),
                  ),
                  DropdownMenuItem(
                    value: 'other',
                    child: Text('Other Issue'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _reportType = value ?? 'down';
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Your Name (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              
              // Email field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Your Email (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty && !value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Description field
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Please describe the issue you\'re experiencing...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please describe the issue';
                  }
                  if (value.trim().length < 10) {
                    return 'Please provide more details (at least 10 characters)';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _handleSubmit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit Report'),
        ),
      ],
    );
  }
}

// Suggestions For Features and Additions Later:
// - Add screenshot/image upload capability
// - Implement report status tracking
// - Add report history for users
// - Create report categories and tags
// - Add report priority levels
// - Implement report follow-up notifications
// - Add report analytics dashboard
// - Create report export functionality

