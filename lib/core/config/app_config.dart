// ==============================================================================
// COCOTUFT PRODUCTION MANAGEMENT SYSTEM - APP CONFIGURATION
// ==============================================================================
// Section Purpose: API endpoints configuration and application parameters.
// ==============================================================================

import 'package:flutter/foundation.dart';

class AppConfig {
  static const String appName = 'COCOTUFT Production Management System';
  static const String renderLiveUrl = 'https://cocotuft.onrender.com';
  
  static String get apiBaseUrl {
    if (kIsWeb) {
      final origin = Uri.base.origin;
      if (origin.contains('onrender.com')) {
        return '$origin/api';
      }
      // If running locally, point to local FastAPI backend
      if (origin.contains('localhost') || origin.contains('127.0.0.1')) {
        return 'http://127.0.0.1:8000/api';
      }
      // When deployed live, dynamically use the current domain host
      return '$origin/api';
    }
    return 'http://127.0.0.1:8000/api';
  }
}

