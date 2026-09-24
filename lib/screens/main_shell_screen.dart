// ==============================================================================
// COCOTUFT PRODUCTION MANAGEMENT SYSTEM - MAIN SHELL SCREEN
// ==============================================================================
// Section Purpose: Primary shell layout containing responsive sidebar navigation,
// top app header bar, system connection indicators, and dynamic tab switching.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_sidebar.dart';
import 'supervisor_dashboard.dart';
import 'production_entry_screen.dart';
import 'production_summary_screen.dart';
import 'excel_hub_screen.dart';
import 'admin_control_screen.dart';
import 'erp_status_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _selectedIndex = 0;

  String _getScreenTitle(int index) {
    switch (index) {
      case 0:
        return 'Daily Tufting Production Entry Workspace';
      case 1:
        return 'Supervisor Review & Confirmation Queue';
      case 2:
        return 'Tufting Production Summary Report';
      case 3:
        return 'Excel Data Import & Export Hub';
      case 4:
        return 'Admin Control Panel & Security Permissions';
      case 5:
        return 'ERP Integration & Synchronization Status';
      default:
        return 'COCOTUFT Production Management System';
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    Widget bodyWidget;
    switch (_selectedIndex) {
      case 0:
        bodyWidget = ProductionEntryScreen(onNavigate: (idx) => setState(() => _selectedIndex = idx));
        break;
      case 1:
        bodyWidget = SupervisorDashboard(onNavigate: (idx) => setState(() => _selectedIndex = idx));
        break;
      case 2:
        bodyWidget = const ProductionSummaryScreen();
        break;
      case 3:
        bodyWidget = const ExcelHubScreen();
        break;
      case 4:
        bodyWidget = const AdminControlScreen();
        break;
      case 5:
        bodyWidget = const ERPStatusScreen();
        break;
      default:
        bodyWidget = ProductionEntryScreen(onNavigate: (idx) => setState(() => _selectedIndex = idx));
    }


    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Row(
        children: [
          AppSidebar(
            selectedIndex: _selectedIndex,
            onItemSelected: (idx) => setState(() => _selectedIndex = idx),
          ),
          Expanded(
            child: Column(
              children: [
                // Top Header Bar
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceWhite,
                    border: Border(bottom: BorderSide(color: AppColors.borderLight, width: 1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Screen Title
                      Text(
                        _getScreenTitle(_selectedIndex),
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),

                      // System Status Badges & Profile
                      Row(
                        children: [
                          // Connection Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.successGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: AppColors.successGreen,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  kIsWeb && Uri.base.origin.contains('onrender.com')
                                      ? 'REST API Online • cocotuft.onrender.com'
                                      : 'REST API Online • 127.0.0.1:8000',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.successGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),

                          // ERP Sync Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.erpSyncedBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.erpSyncedText.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.sync, size: 12, color: AppColors.erpSyncedText),
                                const SizedBox(width: 4),
                                Text(
                                  'BizCare ERP Sync Ready',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.erpSyncedText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Vertical Divider
                          Container(height: 24, width: 1, color: AppColors.borderLight),
                          const SizedBox(width: 16),

                          // User Role Chip
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primaryNavy.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              user?.roleName ?? 'ROLE',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryNavy,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Main Content View
                Expanded(child: bodyWidget),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
