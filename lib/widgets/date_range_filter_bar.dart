// ==============================================================================
// COCOTUFT PRODUCTION MANAGEMENT SYSTEM - DATE RANGE FILTER BAR WIDGET
// ==============================================================================
// Section Purpose: Reusable, responsive date range filter component enabling
// Supervisors and Admins to effortlessly filter data between "From Date" and
// "To Date" with quick presets (Today, Yesterday, Last 7 Days, This Month, All Time).
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';

enum DateRangePreset {
  today,
  yesterday,
  last7Days,
  thisMonth,
  allTime,
  custom,
}

class DateRangeFilterBar extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final String title;
  final String? subtitle;
  final Function(DateTime? startDate, DateTime? endDate) onApply;
  final VoidCallback? onClear;
  final bool autoApplyOnPreset;

  const DateRangeFilterBar({
    super.key,
    this.initialStartDate,
    this.initialEndDate,
    this.title = 'Date Range Filter',
    this.subtitle,
    required this.onApply,
    this.onClear,
    this.autoApplyOnPreset = true,
  });

  @override
  State<DateRangeFilterBar> createState() => _DateRangeFilterBarState();
}

class _DateRangeFilterBarState extends State<DateRangeFilterBar> {
  DateTime? _startDate;
  DateTime? _endDate;
  DateRangePreset _currentPreset = DateRangePreset.allTime;

  final DateFormat _displayFormat = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
    _detectInitialPreset();
  }

  void _detectInitialPreset() {
    if (_startDate == null && _endDate == null) {
      _currentPreset = DateRangePreset.allTime;
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (_startDate != null && _endDate != null) {
      final s = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
      final e = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);

      if (s == today && e == today) {
        _currentPreset = DateRangePreset.today;
      } else if (s == yesterday && e == yesterday) {
        _currentPreset = DateRangePreset.yesterday;
      } else if (s == today.subtract(const Duration(days: 6)) && e == today) {
        _currentPreset = DateRangePreset.last7Days;
      } else if (s == DateTime(now.year, now.month, 1) && e == today) {
        _currentPreset = DateRangePreset.thisMonth;
      } else {
        _currentPreset = DateRangePreset.custom;
      }
    } else {
      _currentPreset = DateRangePreset.custom;
    }
  }

  void _applyPreset(DateRangePreset preset) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    DateTime? newStart;
    DateTime? newEnd;

    switch (preset) {
      case DateRangePreset.today:
        newStart = today;
        newEnd = today;
        break;
      case DateRangePreset.yesterday:
        final yest = today.subtract(const Duration(days: 1));
        newStart = yest;
        newEnd = yest;
        break;
      case DateRangePreset.last7Days:
        newStart = today.subtract(const Duration(days: 6));
        newEnd = today;
        break;
      case DateRangePreset.thisMonth:
        newStart = DateTime(now.year, now.month, 1);
        newEnd = today;
        break;
      case DateRangePreset.allTime:
        newStart = null;
        newEnd = null;
        break;
      case DateRangePreset.custom:
        return;
    }

    setState(() {
      _currentPreset = preset;
      _startDate = newStart;
      _endDate = newEnd;
    });

    if (widget.autoApplyOnPreset) {
      widget.onApply(_startDate, _endDate);
    }
  }

  Future<void> _pickStartDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryNavy,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = picked;
        }
        _currentPreset = DateRangePreset.custom;
      });
      if (widget.autoApplyOnPreset) {
        widget.onApply(_startDate, _endDate);
      }
    }
  }

  Future<void> _pickEndDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? (_startDate ?? now),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryNavy,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _endDate = picked;
        _currentPreset = DateRangePreset.custom;
      });
      if (widget.autoApplyOnPreset) {
        widget.onApply(_startDate, _endDate);
      }
    }
  }

  void _clearFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _currentPreset = DateRangePreset.allTime;
    });
    if (widget.onClear != null) {
      widget.onClear!();
    } else {
      widget.onApply(null, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasActiveFilter = _startDate != null || _endDate != null;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Title, Subtitle, and Active Filter Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryNavy.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        color: AppColors.primaryNavy,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        if (widget.subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle!,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textMedium,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                if (hasActiveFilter)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryTeal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.secondaryTeal.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.filter_alt_rounded,
                          size: 14,
                          color: AppColors.secondaryTeal,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getFilterBadgeText(),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondaryTeal,
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: _clearFilter,
                          borderRadius: BorderRadius.circular(10),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: AppColors.secondaryTeal,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Text(
                    'All dates included',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textLight,
                    ),
                  ),
              ],
            ),
            const Divider(height: 20),

            // Controls Row: Preset Pills & Date Picker Selectors
            Wrap(
              spacing: 8,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Preset Chips
                _buildPresetChip('All Time', DateRangePreset.allTime),
                _buildPresetChip('Today', DateRangePreset.today),
                _buildPresetChip('Yesterday', DateRangePreset.yesterday),
                _buildPresetChip('Last 7 Days', DateRangePreset.last7Days),
                _buildPresetChip('This Month', DateRangePreset.thisMonth),

                const SizedBox(width: 8),

                // From Date Selector
                _buildDateSelector(
                  label: 'FROM DATE',
                  date: _startDate,
                  placeholder: 'Select Start Date',
                  onTap: () => _pickStartDate(context),
                  icon: Icons.event_available_rounded,
                ),

                const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.textLight),

                // To Date Selector
                _buildDateSelector(
                  label: 'TO DATE',
                  date: _endDate,
                  placeholder: 'Select End Date',
                  onTap: () => _pickEndDate(context),
                  icon: Icons.event_busy_rounded,
                ),

                const SizedBox(width: 8),

                // Apply Filter Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: Text(
                    'APPLY',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  onPressed: () => widget.onApply(_startDate, _endDate),
                ),

                // Reset Button
                if (hasActiveFilter)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textMedium,
                      side: const BorderSide(color: AppColors.borderLight),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: Text(
                      'CLEAR',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    onPressed: _clearFilter,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, DateRangePreset preset) {
    final bool isSelected = _currentPreset == preset;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _applyPreset(preset),
      selectedColor: AppColors.primaryNavy,
      backgroundColor: AppColors.surfaceMuted,
      labelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? Colors.white : AppColors.textDark,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.primaryNavy : AppColors.borderLight,
        ),
      ),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    );
  }

  Widget _buildDateSelector({
    required String label,
    required DateTime? date,
    required String placeholder,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    final bool hasValue = date != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: hasValue ? AppColors.primaryNavy.withValues(alpha: 0.04) : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasValue ? AppColors.primaryNavy.withValues(alpha: 0.3) : AppColors.borderLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: hasValue ? AppColors.primaryNavy : AppColors.textMedium,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textLight,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  hasValue ? _displayFormat.format(date) : placeholder,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
                    color: hasValue ? AppColors.textDark : AppColors.textMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_drop_down, size: 18, color: AppColors.textMedium),
          ],
        ),
      ),
    );
  }

  String _getFilterBadgeText() {
    if (_startDate != null && _endDate != null) {
      if (DateFormat('yyyy-MM-dd').format(_startDate!) == DateFormat('yyyy-MM-dd').format(_endDate!)) {
        return _displayFormat.format(_startDate!);
      }
      return '${_displayFormat.format(_startDate!)} → ${_displayFormat.format(_endDate!)}';
    } else if (_startDate != null) {
      return 'From ${_displayFormat.format(_startDate!)}';
    } else if (_endDate != null) {
      return 'Until ${_displayFormat.format(_endDate!)}';
    }
    return 'All Dates';
  }
}
