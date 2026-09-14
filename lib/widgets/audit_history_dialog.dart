// ==============================================================================
// COCOTUFT PRODUCTION MANAGEMENT SYSTEM - AUDIT HISTORY TIMELINE DIALOG
// ==============================================================================
// Section Purpose: Modal dialog rendering an immutable timeline of record creation,
// field-level supervisor edits, value changes (old -> new), approvals & rejections.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../models/production_models.dart';

class AuditHistoryDialog extends StatelessWidget {
  final String entryNumber;
  final List<AuditLogModel> logs;

  const AuditHistoryDialog({
    super.key,
    required this.entryNumber,
    required this.logs,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history_toggle_off, color: AppColors.secondaryTeal, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      'AUDIT HISTORY - #$entryNumber',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMedium),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Field-level modification trail & workflow approval events',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMedium),
            ),
            const Divider(height: 24),

            // Timeline Content
            Expanded(
              child: logs.isEmpty
                  ? Center(
                      child: Text(
                        'No audit history logs recorded for this entry.',
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMedium),
                      ),
                    )
                  : ListView.builder(
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        return _buildTimelineItem(log, index == logs.length - 1);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(AuditLogModel log, bool isLast) {
    Color actionColor = AppColors.primaryNavy;
    IconData actionIcon = Icons.info_outline;

    if (log.action == 'CREATED') {
      actionColor = AppColors.secondaryTeal;
      actionIcon = Icons.add_circle_outline;
    } else if (log.action == 'SUBMITTED') {
      actionColor = AppColors.accentAmber;
      actionIcon = Icons.send_outlined;
    } else if (log.action == 'EDITED') {
      actionColor = Colors.indigo;
      actionIcon = Icons.edit_outlined;
    } else if (log.action == 'APPROVED') {
      actionColor = AppColors.statusApprovedText;
      actionIcon = Icons.check_circle_outline;
    } else if (log.action == 'REJECTED') {
      actionColor = AppColors.statusRejectedText;
      actionIcon = Icons.cancel_outlined;
    }

    String formattedDate = log.createdAt;
    try {
      final dt = DateTime.parse(log.createdAt);
      formattedDate = DateFormat('dd-MMM-yyyy hh:mm a').format(dt);
    } catch (_) {}

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator line
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: actionColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(actionIcon, color: actionColor, size: 16),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.borderLight,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // Content Box
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        log.changedByFullname,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        formattedDate,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: actionColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          log.action,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: actionColor,
                          ),
                        ),
                      ),
                      if (log.fieldName != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          'Field: ${log.fieldName}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (log.oldValue != null || log.newValue != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Old: ${log.oldValue ?? "N/A"}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.statusRejectedText,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_forward, size: 14, color: AppColors.textMedium),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'New: ${log.newValue ?? "N/A"}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.statusApprovedText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
