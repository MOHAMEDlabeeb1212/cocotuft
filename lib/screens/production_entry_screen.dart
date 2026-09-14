// ==============================================================================
// COCOTUFT PRODUCTION MANAGEMENT SYSTEM - DAILY TUFTING DETAILS ENTRY SCREEN
// ==============================================================================
// Section Purpose: Touch-friendly shop-floor entry screen designed specifically for
// Daily Tufting details, mirroring the BizCare ERP interface and paper form layout.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import '../providers/production_provider.dart';

class ProductionEntryScreen extends StatefulWidget {
  final Function(int) onNavigate;
  const ProductionEntryScreen({super.key, required this.onNavigate});

  @override
  State<ProductionEntryScreen> createState() => _ProductionEntryScreenState();
}

class _ProductionEntryScreenState extends State<ProductionEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  final DateTime _entryDate = DateTime.now();
  int? _selectedShiftId = 1;
  int? _selectedMachineId = 3;
  final int _selectedOrderId = 1;
  final int _selectedCustomerId = 1;

  final _baseCtrl = TextEditingController(text: 'Natural');
  final _pileHeightCtrl = TextEditingController(text: '15 MM');
  final _salesOrderCtrl = TextEditingController(text: 'PCT-298');
  final _custCodeCtrl = TextEditingController(text: 'TESCO');
  final _poNumberCtrl = TextEditingController(text: 'PRDOT-446');
  final _rollNumberCtrl = TextEditingController(text: 'TF-3/1113/N15/05-08-2026/F1');
  final _startTimeCtrl = TextEditingController(text: '06:00 AM');
  final _endTimeCtrl = TextEditingController(text: '07:20 AM');
  final _lengthCtrl = TextEditingController(text: '13.5');
  final _widthCtrl = TextEditingController(text: '1.95');
  final _targetQtyCtrl = TextEditingController(text: '500.0');

  final _defectsACtrl = TextEditingController(text: '0');
  final _defectsBCtrl = TextEditingController(text: '0');
  final _defectsCCtrl = TextEditingController(text: '0');
  final _defectsDCtrl = TextEditingController(text: '0');
  final _defectsECtrl = TextEditingController(text: '0');

  final _stopMinutesCtrl = TextEditingController(text: '0');
  final _stopReasonCtrl = TextEditingController();

  final _roundWeightLCtrl = TextEditingController(text: '0.0');
  final _roundWeightCCtrl = TextEditingController(text: '0.0');
  final _roundWeightRCtrl = TextEditingController(text: '0.0');

  final _factoryLaboursCtrl = TextEditingController(text: '1');
  final _contractLaboursCtrl = TextEditingController(text: '0');

  final _shiftInchargeCtrl = TextEditingController();
  final _qualityControllerCtrl = TextEditingController();
  final _supervisorNameCtrl = TextEditingController();
  final _tuftingHeadCtrl = TextEditingController();
  final _creelStandCtrl = TextEditingController();
  final _commentsCtrl = TextEditingController();

  double _calculatedActualSqm = 26.33;
  double _calculatedVariation = -473.67;
  double _calculatedBalance = 473.67;
  double _calculatedRunningMeter = 13.5;

  @override
  void initState() {
    super.initState();
    _recalculateMetrics();
    _lengthCtrl.addListener(_recalculateMetrics);
    _widthCtrl.addListener(_recalculateMetrics);
    _targetQtyCtrl.addListener(_recalculateMetrics);
  }

  void _recalculateMetrics() {
    final len = double.tryParse(_lengthCtrl.text) ?? 0.0;
    final wid = double.tryParse(_widthCtrl.text) ?? 0.0;
    final tgt = double.tryParse(_targetQtyCtrl.text) ?? 0.0;

    setState(() {
      _calculatedActualSqm = double.parse((len * wid).toStringAsFixed(2));
      _calculatedVariation = double.parse((_calculatedActualSqm - tgt).toStringAsFixed(2));
      _calculatedBalance = double.parse((tgt - _calculatedActualSqm).toStringAsFixed(2));
      _calculatedRunningMeter = double.parse(len.toStringAsFixed(2));
    });
  }

  Future<void> _submitEntry(bool isSubmit) async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<ProductionProvider>(context, listen: false);

    final payload = {
      'entry_date': DateFormat('yyyy-MM-dd').format(_entryDate),
      'tufted_date': DateFormat('yyyy-MM-dd').format(_entryDate),
      'shift_id': _selectedShiftId ?? 1,
      'process_id': 1, // Tufting Process ID
      'machine_id': _selectedMachineId ?? 3,
      'order_id': _selectedOrderId,
      'customer_id': _selectedCustomerId,
      'is_submit': isSubmit,
      'details': {
        'base': _baseCtrl.text.trim(),
        'pile_height': _pileHeightCtrl.text.trim(),
        'sales_order_no': _salesOrderCtrl.text.trim(),
        'customer_code': _custCodeCtrl.text.trim(),
        'po_number': _poNumberCtrl.text.trim(),
        'roll_number': _rollNumberCtrl.text.trim(),
        'start_time': _startTimeCtrl.text.trim(),
        'end_time': _endTimeCtrl.text.trim(),
        'length_meters': double.tryParse(_lengthCtrl.text) ?? 0.0,
        'width_meters': double.tryParse(_widthCtrl.text) ?? 0.0,
        'target_qty': double.tryParse(_targetQtyCtrl.text) ?? 500.0,
        'belt_speed': 'Normal',
        'defects_a_yarn': int.tryParse(_defectsACtrl.text) ?? 0,
        'defects_b_pvc': int.tryParse(_defectsBCtrl.text) ?? 0,
        'defects_c_tufting': int.tryParse(_defectsCCtrl.text) ?? 0,
        'defects_d_stripe': int.tryParse(_defectsDCtrl.text) ?? 0,
        'defects_e_others': int.tryParse(_defectsECtrl.text) ?? 0,
        'machine_stop_minutes': int.tryParse(_stopMinutesCtrl.text) ?? 0,
        'machine_stop_reason': _stopReasonCtrl.text.trim().isEmpty ? null : _stopReasonCtrl.text.trim(),
        'round_weight_left': double.tryParse(_roundWeightLCtrl.text) ?? 0.0,
        'round_weight_center': double.tryParse(_roundWeightCCtrl.text) ?? 0.0,
        'round_weight_right': double.tryParse(_roundWeightRCtrl.text) ?? 0.0,
        'factory_labour_count': int.tryParse(_factoryLaboursCtrl.text) ?? 1,
        'contract_labour_count': int.tryParse(_contractLaboursCtrl.text) ?? 0,
        'shift_machine_incharge': _shiftInchargeCtrl.text.trim(),
        'shift_quality_controller': _qualityControllerCtrl.text.trim(),
        'shift_supervisor_name': _supervisorNameCtrl.text.trim(),
        'tufting_head': _tuftingHeadCtrl.text.trim(),
        'creel_stand': _creelStandCtrl.text.trim(),
        'comments': _commentsCtrl.text.trim(),
      }
    };

    final success = await provider.createEntry(payload);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isSubmit
                  ? 'Daily Tufting Entry Submitted for Supervisor Confirmation!'
                  : 'Tufting Draft Saved Successfully!',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
            backgroundColor: isSubmit ? AppColors.emeraldTeal : AppColors.primaryNavy,
          ),
        );
        widget.onNavigate(0); // Return to dashboard
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Error saving entry.'),
            backgroundColor: AppColors.dangerRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProductionProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Banner Card
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
                    BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryTeal.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.precision_manufacturing_rounded, color: AppColors.emeraldTealBright, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'DAILY TUFTING DETAILS',
                                  style: GoogleFonts.manrope(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                Text(
                                  'BizCare ERP Synchronized Form',
                                  style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Text(
                            'SHOP-FLOOR ENTRY',
                            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Colors.white12, height: 1),
                    const SizedBox(height: 16),

                    // Header Controls Row
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _selectedMachineId,
                            dropdownColor: AppColors.primaryNavy,
                            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                            decoration: const InputDecoration(
                              labelText: 'Machine',
                              labelStyle: TextStyle(color: Colors.white70),
                              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
                              fillColor: Colors.white10,
                            ),
                            items: const [
                              DropdownMenuItem(value: 1, child: Text('Tufting Machine - 1')),
                              DropdownMenuItem(value: 2, child: Text('Tufting Machine - 2')),
                              DropdownMenuItem(value: 3, child: Text('Tufting Machine - 3')),
                            ],
                            onChanged: (v) => setState(() => _selectedMachineId = v),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _selectedShiftId,
                            dropdownColor: AppColors.primaryNavy,
                            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                            decoration: const InputDecoration(
                              labelText: 'Shift',
                              labelStyle: TextStyle(color: Colors.white70),
                              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
                              fillColor: Colors.white10,
                            ),
                            items: const [
                              DropdownMenuItem(value: 1, child: Text('Shift 1 (06:00 AM - 02:00 PM)')),
                              DropdownMenuItem(value: 2, child: Text('Shift 2 (02:00 PM - 10:00 PM)')),
                              DropdownMenuItem(value: 3, child: Text('Shift 3 (10:00 PM - 06:00 AM)')),
                            ],
                            onChanged: (v) => setState(() => _selectedShiftId = v),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            initialValue: DateFormat('dd-MM-yyyy').format(_entryDate),
                            readOnly: true,
                            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                            decoration: const InputDecoration(
                              labelText: 'Tufted Date',
                              labelStyle: TextStyle(color: Colors.white70),
                              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
                              fillColor: Colors.white10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Specifications Card
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
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _baseCtrl,
                              decoration: const InputDecoration(labelText: 'Base Material'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _pileHeightCtrl,
                              decoration: const InputDecoration(labelText: 'Pile Height (e.g. 15 MM)'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _salesOrderCtrl,
                              decoration: const InputDecoration(labelText: 'Sales Order No (S.O.)'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _custCodeCtrl,
                              decoration: const InputDecoration(labelText: 'Cust. Code'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _poNumberCtrl,
                              decoration: const InputDecoration(labelText: 'P.O. Number'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _rollNumberCtrl,
                              decoration: const InputDecoration(labelText: 'Roll No.'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _startTimeCtrl,
                              decoration: const InputDecoration(labelText: 'Start Time'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _endTimeCtrl,
                              decoration: const InputDecoration(labelText: 'End Time'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _targetQtyCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Target Qty'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _lengthCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Length (meters)'),
                              validator: (v) => v == null || v.isEmpty ? 'Enter length' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _widthCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Width (meters)'),
                              validator: (v) => v == null || v.isEmpty ? 'Enter width' : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Server Authoritative Formula Calculation Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.secondaryTeal.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.secondaryTeal.withValues(alpha: 0.3), width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetricPreview('ACTUAL AREA (SQM)', '$_calculatedActualSqm m²', AppColors.secondaryTeal, 'Length × Width'),
                    _buildMetricPreview('VARIATION', '$_calculatedVariation', _calculatedVariation < 0 ? AppColors.dangerRed : AppColors.successGreen, 'Actual - Target'),
                    _buildMetricPreview('BALANCE QTY', '$_calculatedBalance', AppColors.primaryNavy, 'Target - Actual'),
                    _buildMetricPreview('RUNNING METER', '$_calculatedRunningMeter m', AppColors.primaryNavy, 'Total Length'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Personnel & Remarks Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shift Personnel & Quality Remarks',
                        style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          Expanded(child: TextFormField(controller: _shiftInchargeCtrl, decoration: const InputDecoration(labelText: 'Shift Machine In-charge'))),
                          const SizedBox(width: 16),
                          Expanded(child: TextFormField(controller: _qualityControllerCtrl, decoration: const InputDecoration(labelText: 'Shift Quality Controller'))),
                          const SizedBox(width: 16),
                          Expanded(child: TextFormField(controller: _supervisorNameCtrl, decoration: const InputDecoration(labelText: 'Shift Supervisor Name'))),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: TextFormField(controller: _tuftingHeadCtrl, decoration: const InputDecoration(labelText: 'Tufting Head'))),
                          const SizedBox(width: 16),
                          Expanded(child: TextFormField(controller: _creelStandCtrl, decoration: const InputDecoration(labelText: 'Creel Stand'))),
                          const SizedBox(width: 16),
                          Expanded(child: TextFormField(controller: _factoryLaboursCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Factory Labours Count'))),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _commentsCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: 'Comments / Remarks'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Bottom Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: provider.isLoading ? null : () => _submitEntry(false),
                    child: const Text('SAVE DRAFT'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emeraldTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text('SUBMIT FOR SUPERVISOR CONFIRMATION'),
                    onPressed: provider.isLoading ? null : () => _submitEntry(true),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricPreview(String title, String value, Color color, String formula) {
    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.inter(color: AppColors.textMedium, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.manrope(color: color, fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          formula,
          style: GoogleFonts.inter(color: AppColors.textLight, fontSize: 10),
        ),
      ],
    );
  }
}
