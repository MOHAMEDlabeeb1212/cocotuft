// ==============================================================================
// COCOTUFT PRODUCTION MANAGEMENT SYSTEM - WORKER DASHBOARD SCREEN
// ==============================================================================
// Section Purpose: Dashboard view for shop-floor Workers showing recent Daily Tufting
// records, production status badges, and quick entry triggers.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import '../providers/production_provider.dart';
import '../widgets/kpi_card.dart';
import '../widgets/audit_history_dialog.dart';

class WorkerDashboard extends StatefulWidget {
  final Function(int) onNavigate;
  const WorkerDashboard({super.key, required this.onNavigate});

  @override
  State<WorkerDashboard> createState() => _WorkerDashboardState();
}

class _WorkerDashboardState extends State<WorkerDashboard> {
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
    final provider = Provider.of<ProductionProvider>(context);
    final entries = provider.entries;

    final totalEntries = entries.length;
    final pendingCount = entries.where((e) => e.status == 'PENDING_APPROVAL').length;
    final approvedCount = entries.where((e) => e.status == 'APPROVED').length;
    final totalSqm = entries.fold<double>(0.0, (sum, e) => sum + (e.details?.actualQty ?? 0.0));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Hero Banner
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.emeraldTealBright.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'SHOP-FLOOR RECORDING PORTAL',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.emeraldTealBright,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Daily Tufting Production Recording',
                        style: GoogleFonts.manrope(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Record daily mat manufacturing details, auto-calculate SQM area, and submit for supervisor approval.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emeraldTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 4,
                      shadowColor: AppColors.emeraldTeal.withValues(alpha: 0.4),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: Text(
                      'NEW TUFTING ENTRY',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                    onPressed: () => widget.onNavigate(1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // KPI Metrics Row
            Row(
              children: [
                Expanded(
                  child: KpiCard(
                    title: "My Tufting Records",
                    value: "$totalEntries",
                    icon: Icons.receipt_long_rounded,
                    color: AppColors.primaryNavy,
                    subtitle: "Total records created",
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: KpiCard(
                    title: "Pending Confirmation",
                    value: "$pendingCount",
                    icon: Icons.hourglass_top_rounded,
                    color: AppColors.warningAmber,
                    subtitle: "Awaiting supervisor review",
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
                    title: "Total SQM Produced",
                    value: "${totalSqm.toStringAsFixed(2)} m²",
                    icon: Icons.straighten_rounded,
                    color: AppColors.secondaryTeal,
                    subtitle: "Server-authoritative SQM",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recent Entries Table Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.table_chart_rounded, color: AppColors.primaryNavy, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Recent Daily Tufting Production Entries',
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('REFRESH'),
                          onPressed: () => provider.fetchEntries(),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    if (provider.isLoading)
                      const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()))
                    else if (entries.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              const Icon(Icons.inbox_rounded, size: 48, color: AppColors.textLight),
                              const SizedBox(height: 12),
                              Text(
                                'No production entries recorded yet.',
                                style: GoogleFonts.inter(color: AppColors.textMedium, fontWeight: FontWeight.w500),
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
                            DataColumn(label: Text('TUFTED DATE')),
                            DataColumn(label: Text('MACHINE')),
                            DataColumn(label: Text('ROLL NO')),
                            DataColumn(label: Text('ACTUAL (SQM)')),
                            DataColumn(label: Text('STATUS')),
                            DataColumn(label: Text('AUDIT TRAIL')),
                          ],
                          rows: entries.map((entry) {
                            final isApproved = entry.status == 'APPROVED';
                            final isRejected = entry.status == 'REJECTED';

                            Color statusBg = AppColors.statusPendingBg;
                            Color statusText = AppColors.statusPendingText;
                            if (isApproved) {
                              statusBg = AppColors.statusApprovedBg;
                              statusText = AppColors.statusApprovedText;
                            } else if (isRejected) {
                              statusBg = AppColors.statusRejectedBg;
                              statusText = AppColors.statusRejectedText;
                            }

                            return DataRow(cells: [
                              DataCell(
                                Text(entry.entryNumber, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
                              ),
                              DataCell(Text(entry.tuftedDate, style: GoogleFonts.inter(fontSize: 13))),
                              DataCell(Text(entry.machineName ?? 'Tufting Machine', style: GoogleFonts.inter(fontSize: 13))),
                              DataCell(Text(entry.details?.rollNumber ?? 'N/A', style: GoogleFonts.inter(fontSize: 13))),
                              DataCell(
                                Text(
                                  '${entry.details?.actualQty ?? 0.0} m²',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.secondaryTeal, fontSize: 13),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    entry.status,
                                    style: GoogleFonts.inter(color: statusText, fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                ),
                              ),
                              DataCell(
                                IconButton(
                                  icon: const Icon(Icons.history_rounded, color: AppColors.primaryNavy, size: 20),
                                  tooltip: 'View Audit History',
                                  onPressed: () async {
                                    final logs = await provider.getAuditHistory(entry.entryId);
                                    if (context.mounted) {
                                      showDialog(
                                        context: context,
                                        builder: (c) => AuditHistoryDialog(entryNumber: entry.entryNumber, logs: logs),
                                      );
                                    }
                                  },
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
