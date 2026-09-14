// ==============================================================================
// COCOTUFT PRODUCTION MANAGEMENT SYSTEM - REUSABLE KPI CARD WIDGET
// ==============================================================================
// Section Purpose: Dashboard KPI Card widget displaying metric totals, icons,
// elevation, clean typography, and status color highlights.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';

class KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;
  final String? subtitle;
  final String? trendText;
  final bool isPositiveTrend;

  const KpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    Color? color,
    Color accentColor = AppColors.primaryNavy,
    this.subtitle,
    this.trendText,
    this.isPositiveTrend = true,
  })  : accentColor = color ?? accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMedium,
                    letterSpacing: 0.8,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          if (subtitle != null || trendText != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                if (trendText != null) ...[
                  Icon(
                    isPositiveTrend ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                    size: 14,
                    color: isPositiveTrend ? AppColors.successGreen : AppColors.dangerRed,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    trendText!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isPositiveTrend ? AppColors.successGreen : AppColors.dangerRed,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (subtitle != null)
                  Expanded(
                    child: Text(
                      subtitle!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textMedium,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ]
        ],
      ),
    );
  }
}
