// ==============================================================================
// COCOTUFT PRODUCTION MANAGEMENT SYSTEM - ERP INTEGRATION SCREEN
// ==============================================================================
// Section Purpose: Interface showing company ERP synchronization queue,
// ERP reference codes, sync statuses (ERP_SYNCED, ERP_SYNC_PENDING, ERP_SYNC_FAILED),
// error diagnostics, and manual retry options.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import '../providers/production_provider.dart';

class ERPStatusScreen extends StatefulWidget {
  const ERPStatusScreen({super.key});

  @override
  State<ERPStatusScreen> createState() => _ERPStatusScreenState();
}

class _ERPStatusScreenState extends State<ERPStatusScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductionProvider>(context, listen: false).fetchEntries();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prod = Provider.of<ProductionProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connection Status Banner Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.secondaryTeal.withValues(alpha: 0.4)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryTeal.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.sync_outlined, color: AppColors.secondaryTeal, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'COCOTUFT BizCare ERP Synchronization Interface',
                          style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Approved shop-floor production entries are automatically formatted and synced to BizCare ERP via REST API.',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMedium),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.statusApprovedBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'INTERFACE ACTIVE',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.statusApprovedText),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Queue Table Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Approved Production Sync Queue & Transaction Logs',
                  style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('REFRESH LOGS'),
                  onPressed: () => prod.fetchEntries(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Data Table Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(AppColors.surfaceMuted),
                    dataRowMinHeight: 52,
                    dataRowMaxHeight: 52,
                    columns: const [
                      DataColumn(label: Text('ENTRY #')),
                      DataColumn(label: Text('TUFTED DATE')),
                      DataColumn(label: Text('PROCESS')),
                      DataColumn(label: Text('WORKER')),
                      DataColumn(label: Text('ACTUAL SQM')),
                      DataColumn(label: Text('APPROVAL STATUS')),
                      DataColumn(label: Text('ERP SYNC STATUS')),
                      DataColumn(label: Text('ERP REF CODE')),
                    ],
                    rows: prod.entries.map((entry) {
                      final det = entry.details;
                      return DataRow(
                        cells: [
                          DataCell(Text(entry.entryNumber, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.primaryNavy))),
                          DataCell(Text(entry.entryDate, style: GoogleFonts.inter(fontSize: 13))),
                          DataCell(Text(entry.processName ?? 'Tufting', style: GoogleFonts.inter(fontSize: 13))),
                          DataCell(Text(entry.workerName ?? 'Worker', style: GoogleFonts.inter(fontSize: 13))),
                          DataCell(Text('${det?.actualQty ?? 0} m²', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.secondaryTeal, fontSize: 13))),
                          DataCell(Text(entry.status, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold))),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: AppColors.erpSyncedBg, borderRadius: BorderRadius.circular(4)),
                              child: Text(
                                entry.erpSyncStatus,
                                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.erpSyncedText),
                              ),
                            ),
                          ),
                          DataCell(Text(entry.erpReferenceNo ?? 'ERP-REF-20260808-0001', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600))),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
