// Filename: responsive.dart
// Purpose: Responsive design utilities for handling different screen sizes
// Author: Kevin Doyle Jr. / Infinitum Imagery LLC
// Last Modified: 2025-01-27
// Dependencies: flutter
// Platform Compatibility: Web, iOS, Android

import 'package:flutter/material.dart';

// MARK: - Responsive Breakpoints
// Breakpoint definitions for different device types
class ResponsiveBreakpoints {
  // Phone breakpoint (up to 600px)
  static const double phone = 600;
  
  // Tablet breakpoint (600px to 1200px)
  static const double tablet = 1200;
  
  // Desktop breakpoint (above 1200px)
  // No upper limit needed
}

// MARK: - Responsive Utilities
// Helper class for responsive design calculations
class Responsive {
  final BuildContext context;
  
  Responsive(this.context);
  
  // Get screen width
  double get width => MediaQuery.of(context).size.width;
  
  // Get screen height
  double get height => MediaQuery.of(context).size.height;
  
  // Check if device is phone
  bool get isPhone => width < ResponsiveBreakpoints.phone;
  
  // Check if device is tablet
  bool get isTablet => width >= ResponsiveBreakpoints.phone && width < ResponsiveBreakpoints.tablet;
  
  // Check if device is desktop
  bool get isDesktop => width >= ResponsiveBreakpoints.tablet;
  
  // Get responsive padding
  EdgeInsets get padding => EdgeInsets.symmetric(
    horizontal: isPhone ? 16.0 : isTablet ? 24.0 : 32.0,
    vertical: isPhone ? 8.0 : 12.0,
  );
  
  // Get responsive margin
  EdgeInsets get margin => EdgeInsets.all(
    isPhone ? 8.0 : isTablet ? 12.0 : 16.0,
  );
  
  // Get number of columns for grid layout
  int get gridColumns {
    if (isPhone) return 1;
    if (isTablet) return 2;
    return 3; // Desktop
  }
  
  // Get responsive font size multiplier
  double get fontSizeMultiplier {
    if (isPhone) return 1.0;
    if (isTablet) return 1.1;
    return 1.2; // Desktop
  }
  
  // Get max width for content containers
  double get maxContentWidth {
    if (isPhone) return double.infinity;
    if (isTablet) return 1200;
    return 1400; // Desktop
  }
  
  // Get dialog width
  double get dialogWidth {
    if (isPhone) return width * 0.9;
    if (isTablet) return 600;
    return 700; // Desktop
  }
}

// MARK: - Responsive Widget Extensions
// Extension methods for easier responsive design
extension ResponsiveExtension on BuildContext {
  Responsive get responsive => Responsive(this);
}

// Suggestions For Features and Additions Later:
// - Add orientation-specific breakpoints
// - Implement responsive typography scale
// - Add responsive spacing system
// - Create responsive image sizing utilities
// - Add device-specific feature detection

