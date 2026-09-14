// ==============================================================================
// COCOTUFT PRODUCTION MANAGEMENT SYSTEM - SUPERVISOR DASHBOARD SCREEN
// ==============================================================================
// Section Purpose: Dashboard view for Supervisors showing pending Daily Tufting details,
// confirmation queue, and review triggers.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import '../models/production_models.dart';
import '../providers/production_provider.dart';
import '../widgets/kpi_card.dart';
import 'supervisor_review_screen.dart';

class SupervisorDashboard extends StatefulWidget {
  final Function(int) onNavigate;
  const SupervisorDashboard({super.key, required this.onNavigate});

  @override
  State<SupervisorDashboard> createState() => _SupervisorDashboardState();
}

class _SupervisorDashboardState extends State<SupervisorDashboard> {
  ProductionEntryModel? _selectedEntryForReview;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ProductionProvider>(context, listen: false);
      provider.loadMasterData();
      provider.fetchEntries();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedEntryForReview != null) {
      return SupervisorReviewScreen(
        entry: _selectedEntryForReview!,
        onBack: () {
          setState(() => _selectedEntryForReview = null);
          Provider.of<ProductionProvider>(context, listen: false).fetchEntries();
        },
      );
    }

    final provider = Provider.of<ProductionProvider>(context);
    final entries = provider.entries;

    final pendingEntries = entries.where((e) => e.status == 'PENDING_APPROVAL' || e.status == 'SUBMITTED').toList();
    final approvedCount = entries.where((e) => e.status == 'APPROVED').length;
    final rejectedCount = entries.where((e) => e.status == 'REJECTED').length;
    final totalSqm = entries.fold<double>(0.0, (sum, e) => sum + (e.details?.actualQty ?? 0.0));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Supervisor Header Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryNavy, Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accentAmber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'SUPERVISOR REVIEW & CONFIRMATION PORTAL',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accentAmber,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Daily Tufting Confirmation Queue',
                        style: GoogleFonts.manrope(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Review worker production recordings, verify area calculations, inspect audit trails, and approve records.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white38),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    label: Text(
                      'REFRESH QUEUE',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                    onPressed: () => provider.fetchEntries(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // KPI Cards Row
            Row(
              children: [
                Expanded(
                  child: KpiCard(
                    title: "Pending Confirmation",
                    value: "${pendingEntries.length}",
                    icon: Icons.pending_actions_rounded,
                    color: AppColors.warningAmber,
                    subtitle: "Action required",
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: KpiCard(
                    title: "Confirmed & Approved",
                    value: "$approvedCount",
                    icon: Icons.check_circle_rounded,
                    color: AppColors.successGreen,
                    subtitle: "Approved & synced to ERP",
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: KpiCard(
                    title: "Rejected Records",
                    value: "$rejectedCount",
                    icon: Icons.cancel_rounded,
                    color: AppColors.dangerRed,
                    subtitle: "Sent back to worker",
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: KpiCard(
                    title: "Factory Total SQM",
                    value: "${totalSqm.toStringAsFixed(2)} m²",
                    icon: Icons.straighten_rounded,
                    color: AppColors.secondaryTeal,
                    subtitle: "Total shop-floor volume",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Pending Approvals Data Table
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.fact_check_rounded, color: AppColors.primaryNavy, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Daily Tufting Records Awaiting Review & Confirmation',
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    if (provider.isLoading)
                      const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()))
                    else if (pendingEntries.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Column(
                            children: [
                              const Icon(Icons.task_alt_rounded, size: 48, color: AppColors.successGreen),
                              const SizedBox(height: 12),
                              Text(
                                'All caught up! No pending Tufting entries awaiting confirmation.',
                                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(AppColors.surfaceMuted),
                          headingTextStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textDark),
                          dataRowMinHeight: 52,
                          dataRowMaxHeight: 56,
                          columns: const [
                            DataColumn(label: Text('ENTRY NO')),
                            DataColumn(label: Text('WORKER')),
                            DataColumn(label: Text('MACHINE')),
                            DataColumn(label: Text('S.O. (ORDER)')),
                            DataColumn(label: Text('ACTUAL (SQM)')),
                            DataColumn(label: Text('ACTION')),
                          ],
                          rows: pendingEntries.map((entry) {
                            return DataRow(cells: [
                              DataCell(
                                Text(entry.entryNumber, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
                              ),
                              DataCell(Text(entry.workerName ?? 'Worker', style: GoogleFonts.inter(fontSize: 13))),
                              DataCell(Text(entry.machineName ?? 'Tufting Machine', style: GoogleFonts.inter(fontSize: 13))),
                              DataCell(Text(entry.details?.salesOrderNo ?? 'PCT-298', style: GoogleFonts.inter(fontSize: 13))),
                              DataCell(
                                Text(
                                  '${entry.details?.actualQty ?? 0.0} m²',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.secondaryTeal, fontSize: 13),
                                ),
                              ),
                              DataCell(
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryNavy,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                  icon: const Icon(Icons.rate_review_rounded, size: 16),
                                  label: Text('REVIEW & CONFIRM', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                                  onPressed: () => setState(() => _selectedEntryForReview = entry),
                                ),
                              ),
                            ]);
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
