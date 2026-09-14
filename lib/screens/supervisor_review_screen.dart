// ==============================================================================
// COCOTUFT PRODUCTION MANAGEMENT SYSTEM - SUPERVISOR REVIEW & ADMIN OVERRIDE
// ==============================================================================
// Section Purpose: Supervisor confirmation workspace and Admin edit screen.
// Supervisors confirm submitted data; Administrators can edit and update ANY entry.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import '../models/production_models.dart';
import '../providers/production_provider.dart';
import '../widgets/audit_history_dialog.dart';

class SupervisorReviewScreen extends StatefulWidget {
  final ProductionEntryModel entry;
  final VoidCallback onBack;

  const SupervisorReviewScreen({
    super.key,
    required this.entry,
    required this.onBack,
  });

  @override
  State<SupervisorReviewScreen> createState() => _SupervisorReviewScreenState();
}

class _SupervisorReviewScreenState extends State<SupervisorReviewScreen> {
  late TextEditingController _lengthCtrl;
  late TextEditingController _widthCtrl;
  late TextEditingController _targetQtyCtrl;
  late TextEditingController _remarksCtrl;

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _lengthCtrl = TextEditingController(text: widget.entry.details?.lengthMeters.toString() ?? '0.0');
    _widthCtrl = TextEditingController(text: widget.entry.details?.widthMeters.toString() ?? '0.0');
    _targetQtyCtrl = TextEditingController(text: widget.entry.details?.targetQty.toString() ?? '500.0');
    _remarksCtrl = TextEditingController(text: widget.entry.supervisorRemarks ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProductionProvider>(context);
    final isApproved = widget.entry.status == 'APPROVED';


    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Review Tufting Record #${widget.entry.entryNumber}'),
        backgroundColor: AppColors.primaryNavy,
        foregroundColor: Colors.white,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'View Audit Trail',
            onPressed: () async {
              final logs = await provider.getAuditHistory(widget.entry.entryId);
              if (context.mounted) {
                showDialog(
                  context: context,
                  builder: (c) => AuditHistoryDialog(entryNumber: widget.entry.entryNumber, logs: logs),
                );
              }
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Banner Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Document No: ${widget.entry.entryNumber}',
                          style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Worker: ${widget.entry.workerName ?? 'Worker'}  |  Tufted Date: ${widget.entry.tuftedDate}',
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMedium),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isApproved ? AppColors.statusApprovedBg : AppColors.statusPendingBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.entry.status,
                        style: GoogleFonts.inter(
                          color: isApproved ? AppColors.statusApprovedText : AppColors.statusPendingText,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Edit Controls Toolbar
            if (!isApproved)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isEditing ? AppColors.textMedium : AppColors.primaryNavy,
                      foregroundColor: Colors.white,
                    ),
                    icon: Icon(_isEditing ? Icons.close : Icons.edit_rounded, size: 18),
                    label: Text(_isEditing ? 'CANCEL EDIT' : 'EDIT FIELDS'),
                    onPressed: () => setState(() => _isEditing = !_isEditing),
                  ),
                ],
              ),

            const SizedBox(height: 16),

            // Specs Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tufting Specifications & Dimensions',
                      style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                    ),
                    const Divider(height: 24),
                    ListTile(
                      title: Text('Machine', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMedium)),
                      subtitle: Text(widget.entry.machineName ?? 'Tufting Machine', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    ),
                    ListTile(
                      title: Text('Roll Number', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMedium)),
                      subtitle: Text(widget.entry.details?.rollNumber ?? 'N/A', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    ),
                    ListTile(
                      title: Text('Sales Order (S.O.) / Customer', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMedium)),
                      subtitle: Text('${widget.entry.details?.salesOrderNo} (${widget.entry.details?.customerCode})', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _lengthCtrl,
                            enabled: _isEditing,
                            decoration: const InputDecoration(labelText: 'Length (m)'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _widthCtrl,
                            enabled: _isEditing,
                            decoration: const InputDecoration(labelText: 'Width (m)'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _targetQtyCtrl,
                            enabled: _isEditing,
                            decoration: const InputDecoration(labelText: 'Target Qty'),
                          ),
                        ),
                      ],
                    ),
                    if (_isEditing) ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryNavy, foregroundColor: Colors.white),
                        icon: const Icon(Icons.save_rounded, size: 18),
                        label: const Text('SAVE FIELD EDITS'),
                        onPressed: () async {
                          final success = await provider.updateEntry(widget.entry.entryId, {
                            'details': {
                              'length_meters': double.tryParse(_lengthCtrl.text) ?? 0.0,
                              'width_meters': double.tryParse(_widthCtrl.text) ?? 0.0,
                              'target_qty': double.tryParse(_targetQtyCtrl.text) ?? 500.0,
                              'sales_order_no': widget.entry.details?.salesOrderNo ?? 'PCT-298',
                              'customer_code': widget.entry.details?.customerCode ?? 'TESCO',
                              'po_number': widget.entry.details?.poNumber ?? 'PRDOT-446',
                              'roll_number': widget.entry.details?.rollNumber ?? 'TF-1',
                            }
                          });
                          if (context.mounted) {
                            setState(() => _isEditing = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(success ? 'Record Updated!' : 'Error updating record')),
                            );
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Supervisor Remarks Input
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Supervisor Confirmation Remarks',
                      style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                    ),
                    const Divider(height: 24),
                    TextFormField(
                      controller: _remarksCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Supervisor Remarks / Confirmation Notes',
                        hintText: 'Enter confirmation remarks for audit history...',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Bottom Action Buttons
            if (!isApproved)
              Row(

                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.dangerRed,
                      side: const BorderSide(color: AppColors.dangerRed),
                    ),
                    icon: const Icon(Icons.cancel_rounded, size: 18),
                    label: const Text('REJECT ENTRY'),
                    onPressed: () async {
                      final success = await provider.rejectEntry(widget.entry.entryId, 'Entry details require correction.');
                      if (context.mounted && success) widget.onBack();
                    },
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emeraldTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: const Text('CONFIRM & APPROVE DATA'),
                    onPressed: () async {
                      final success = await provider.approveEntry(widget.entry.entryId, remarks: _remarksCtrl.text);
                      if (context.mounted && success) widget.onBack();
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
