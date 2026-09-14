// ==============================================================================
// COCOTUFT PRODUCTION MANAGEMENT SYSTEM - TUFTING PRODUCTION SUMMARY SCREEN
// ==============================================================================
// Section Purpose: Dynamic Tufting Production Summary report view matching exact
// paper report columns (Order No, Machine, Pile, Width, Length, Target, Actual,
// Variation, Balance Qty, and Running Meter).
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import '../providers/production_provider.dart';

class ProductionSummaryScreen extends StatefulWidget {
  const ProductionSummaryScreen({super.key});

  @override
  State<ProductionSummaryScreen> createState() => _ProductionSummaryScreenState();
}

class _ProductionSummaryScreenState extends State<ProductionSummaryScreen> {
  String _selectedMachine = 'All';
  String _selectedShift = 'All';
  final String _selectedStatus = 'APPROVED';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSummary();
    });
  }

  void _loadSummary() {
    Provider.of<ProductionProvider>(context, listen: false).fetchTuftingSummary(
      machine: _selectedMachine,
      shift: _selectedShift,
      status: _selectedStatus,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProductionProvider>(context);
    final report = provider.summaryReport;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Report Header Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryNavy, Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryTeal.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.summarize_rounded, color: AppColors.emeraldTealBright, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TUFTING PRODUCTION SUMMARY REPORT',
                        style: GoogleFonts.manrope(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                      ),
                      Text(
                        'Calculated dynamically from confirmed database records matching paper report columns.',
                        style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Filter Bar Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedMachine,
                        decoration: const InputDecoration(labelText: 'Machine Filter'),
                        items: const [
                          DropdownMenuItem(value: 'All', child: Text('All Machines')),
                          DropdownMenuItem(value: 'Tufting Machine - 1', child: Text('Tufting Machine - 1')),
                          DropdownMenuItem(value: 'Tufting Machine - 2', child: Text('Tufting Machine - 2')),
                          DropdownMenuItem(value: 'Tufting Machine - 3', child: Text('Tufting Machine - 3')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedMachine = val);
                            _loadSummary();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedShift,
                        decoration: const InputDecoration(labelText: 'Shift Filter'),
                        items: const [
                          DropdownMenuItem(value: 'All', child: Text('All Shifts')),
                          DropdownMenuItem(value: 'Shift 1', child: Text('Shift 1')),
                          DropdownMenuItem(value: 'Shift 2', child: Text('Shift 2')),
                          DropdownMenuItem(value: 'Shift 3', child: Text('Shift 3')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedShift = val);
                            _loadSummary();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryNavy,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('REFRESH REPORT'),
                      onPressed: _loadSummary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Grand Totals Summary Cards
            if (report != null)
              Row(
                children: [
                  Expanded(
                    child: _buildMetricBox('Total Running Meter', '${report.grandTotalRunningMeter} m', AppColors.primaryNavy),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricBox('Total Target Qty', '${report.grandTotalTargetQty}', Colors.indigo),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricBox('Total Actual Qty', '${report.grandTotalActualQty} m²', AppColors.secondaryTeal),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricBox('Total Variation', '${report.grandTotalVariation}', report.grandTotalVariation < 0 ? AppColors.dangerRed : AppColors.successGreen),
                  ),
                ],
              ),
            const SizedBox(height: 24),

            // Data Table Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tufting Production Summary Data Table',
                      style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                    ),
                    const Divider(height: 24),

                    if (provider.isLoading)
                      const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()))
                    else if (report == null || report.rows.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            'No confirmed Tufting summary data found.',
                            style: GoogleFonts.inter(color: AppColors.textMedium),
                          ),
                        ),
                      )
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(AppColors.surfaceMuted),
                          dataRowMinHeight: 52,
                          dataRowMaxHeight: 52,
                          columns: const [
                            DataColumn(label: Text('S.O. / ORDER NO')),
                            DataColumn(label: Text('MACHINE')),
                            DataColumn(label: Text('PILE')),
                            DataColumn(label: Text('WIDTH (m)')),
                            DataColumn(label: Text('LENGTH (m)')),
                            DataColumn(label: Text('TARGET QTY')),
                            DataColumn(label: Text('ACTUAL (SQM)')),
                            DataColumn(label: Text('VARIATION')),
                            DataColumn(label: Text('BALANCE QTY')),
                            DataColumn(label: Text('RUNNING METER')),
                          ],
                          rows: report.rows.map((row) {
                            return DataRow(cells: [
                              DataCell(Text(row.salesOrderNo, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.primaryNavy))),
                              DataCell(Text(row.machineName, style: GoogleFonts.inter(fontSize: 13))),
                              DataCell(Text(row.pileHeight, style: GoogleFonts.inter(fontSize: 13))),
                              DataCell(Text('${row.widthMeters} m', style: GoogleFonts.inter(fontSize: 13))),
                              DataCell(Text('${row.lengthMeters} m', style: GoogleFonts.inter(fontSize: 13))),
                              DataCell(Text('${row.targetQty}', style: GoogleFonts.inter(fontSize: 13))),
                              DataCell(Text('${row.actualQty} m²', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.secondaryTeal, fontSize: 13))),
                              DataCell(Text('${row.variation}', style: GoogleFonts.inter(color: row.variation < 0 ? AppColors.dangerRed : AppColors.successGreen, fontWeight: FontWeight.bold, fontSize: 13))),
                              DataCell(Text('${row.balanceQty}', style: GoogleFonts.inter(fontSize: 13))),
                              DataCell(Text('${row.runningMeter} m', style: GoogleFonts.inter(fontSize: 13))),
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

  Widget _buildMetricBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.manrope(color: color, fontSize: 20, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
