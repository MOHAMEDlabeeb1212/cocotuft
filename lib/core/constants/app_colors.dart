// ==============================================================================
// COCOTUFT PRODUCTION MANAGEMENT SYSTEM - DESIGN SYSTEM COLOR PALETTE
// ==============================================================================
// Section Purpose: Defines core color tokens for Material 3 enterprise UI theme,
// visual hierarchy, status badges, industrial control elements, and dark/light contrast.
// ==============================================================================

import 'package:flutter/material.dart';

class AppColors {
  // Primary Enterprise Palette
  static const Color primaryNavy = Color(0xFF0F172A);      // Slate Navy 900
  static const Color primaryNavyLight = Color(0xFF1E293B); // Slate Navy 800
  static const Color secondaryTeal = Color(0xFF0D9488);    // Industrial Teal 600
  static const Color emeraldTeal = Color(0xFF0D9488);      // Alias for secondaryTeal
  static const Color emeraldTealBright = Color(0xFF14B8A6);// Teal 500
  static const Color accentAmber = Color(0xFFF59E0B);      // Warm Amber
  static const Color warningAmber = Color(0xFFD97706);     // Amber 600
  static const Color successGreen = Color(0xFF059669);     // Emerald Green 600
  static const Color dangerRed = Color(0xFFDC2626);        // Red 600

  // Neutral Backgrounds & Surfaces
  static const Color backgroundLight = Color(0xFFF8FAFC);  // Cool Gray 50
  static const Color sidebarBackground = Color(0xFF0F172A); // Sidebar Background
  static const Color surfaceWhite = Color(0xFFFFFFFF);        // Card & Modal Surface
  static const Color surfaceMuted = Color(0xFFF1F5F9);        // Input Field Fill / Row Alt
  static const Color borderLight = Color(0xFFE2E8F0);         // Card & Input Border
  static const Color borderFocus = Color(0xFF0D9488);         // Active Input Border

  // Typography Colors
  static const Color textDark = Color(0xFF0F172A);         // Headings
  static const Color textBody = Color(0xFF334155);         // Standard Body Text
  static const Color textMedium = Color(0xFF64748B);       // Subtitles & Labels
  static const Color textMuted = Color(0xFF64748B);        // Captions
  static const Color textLight = Color(0xFF94A3B8);        // Muted Placeholders

  // Status Badges Colors
  static const Color statusDraftBg = Color(0xFFF1F5F9);
  static const Color statusDraftText = Color(0xFF475569);

  static const Color statusPendingBg = Color(0xFFFEF3C7);
  static const Color statusPendingText = Color(0xFFB45309);

  static const Color statusApprovedBg = Color(0xFFD1FAE5);
  static const Color statusApprovedText = Color(0xFF047857);

  static const Color statusRejectedBg = Color(0xFFFEE2E2);
  static const Color statusRejectedText = Color(0xFFB91C1C);

  static const Color erpSyncedBg = Color(0xFFE0F2FE);
  static const Color erpSyncedText = Color(0xFF0369A1);
}
