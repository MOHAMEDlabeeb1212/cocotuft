// ==============================================================================
// COCOTUFT PRODUCTION MANAGEMENT SYSTEM - EXCEL DATA HUB SCREEN
// ==============================================================================
// Section Purpose: Excel Import & Export Workspace featuring filterable export,
// customizable column picker, template download, column header mapping,
// server-side validation dry-run with row error highlights, and atomic imports.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// Platform-aware web file download trigger support
import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/web_file_helper.dart';

import '../core/constants/app_colors.dart';
import '../core/config/app_config.dart';
import '../models/admin_models.dart';
import '../providers/production_provider.dart';
import '../providers/auth_provider.dart';

class ExcelHubScreen extends StatefulWidget {
  const ExcelHubScreen({super.key});

  @override
  State<ExcelHubScreen> createState() => _ExcelHubScreenState();
}

class _ExcelHubScreenState extends State<ExcelHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Export Filter State
  DateTime? _exportStartDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime? _exportEndDate = DateTime.now();
  final Set<int> _selectedShiftIds = {1, 2, 3};
  String _selectedExportStatus = 'ALL';
  int? _selectedWorkerId;
  final Set<String> _selectedColumns = {
    'entry_number', 'entry_date', 'shift_name', 'machine_name',
    'customer_name', 'order_number', 'roll_number', 'length_meters',
    'width_meters', 'actual_qty', 'status', 'worker_name'
  };

  // Import Wizard State
  int _importStep = 1; // 1: Upload, 2: Mapping & Defaults, 3: Validation Dry-Run, 4: Execute Result
  String? _tempFileId;
  List<String> _detectedSheets = [];
  String _selectedSheet = '';
  List<String> _detectedHeaders = [];
  String _importMode = 'CREATE_NEW'; // CREATE_NEW or UPDATE_EXISTING
  final Map<String, String> _columnMapping = {};
  final DateTime _defaultImportDate = DateTime.now();
  final int _defaultImportShiftId = 1;

  final Map<String, String> _appFieldTitles = {
    'entry_number': 'Entry No (Required for Update)',
    'entry_date': 'Entry Date *',
    'tufted_date': 'Tufted Date *',
    'shift_name': 'Shift *',
    'machine_name': 'Machine *',
    'customer_code': 'Cust. Code *',
    'order_number': 'S.O. Number *',
    'po_number': 'P.O. Number *',
    'roll_number': 'Roll Number *',
    'base': 'Base Material',
    'pile_height': 'Pile Height',
    'start_time': 'Start Time',
    'end_time': 'End Time',
    'length_meters': 'Length (m) *',
    'width_meters': 'Width (m) *',
    'target_qty': 'Target Qty',
    'comments': 'Comments',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerExportPreview();
    });
  }

  void _triggerExportPreview() {
    final provider = Provider.of<ProductionProvider>(context, listen: false);
    provider.fetchExportPreview({
      'start_date': _exportStartDate != null ? DateFormat('yyyy-MM-dd').format(_exportStartDate!) : null,
      'end_date': _exportEndDate != null ? DateFormat('yyyy-MM-dd').format(_exportEndDate!) : null,
      'shift_ids': _selectedShiftIds.toList(),
      'status': _selectedExportStatus,
      'worker_ids': _selectedWorkerId != null ? [_selectedWorkerId!] : null,
      'columns': _selectedColumns.toList(),
    });
  }

  void _downloadExportFile() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token ?? '';
    
    final payload = {
      'start_date': _exportStartDate != null ? DateFormat('yyyy-MM-dd').format(_exportStartDate!) : null,
      'end_date': _exportEndDate != null ? DateFormat('yyyy-MM-dd').format(_exportEndDate!) : null,
      'shift_ids': _selectedShiftIds.toList(),
      'status': _selectedExportStatus,
      'worker_ids': _selectedWorkerId != null ? [_selectedWorkerId!] : null,
      'columns': _selectedColumns.toList(),
    };

    if (kIsWeb) {
      downloadExportFile(
        url: '${AppConfig.apiBaseUrl}/excel/export/download',
        token: token,
        payload: payload,
        onError: (err) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Download failed: $err')));
          }
        },
      );
    }
  }

  void _downloadTemplateFile() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token ?? '';

    if (kIsWeb) {
      downloadTemplateFile(
        url: '${AppConfig.apiBaseUrl}/excel/import/template',
        token: token,
        onError: (err) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Download failed: $err')));
          }
        },
      );
    }
  }

  void _handleFileUpload() {
    if (kIsWeb) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token ?? '';

      uploadExcelFile(
        url: '${AppConfig.apiBaseUrl}/excel/import/upload',
        token: token,
        onSuccess: (jsonRes) {
          final result = ImportUploadResultModel.fromJson(jsonRes);
          if (!mounted) return;
          setState(() {
            _tempFileId = result.tempFileId;
            _detectedSheets = result.sheets;
            _selectedSheet = result.sheets.isNotEmpty ? result.sheets[0] : '';
            _detectedHeaders = result.detectedHeaders;
            _importStep = 2;

            // Auto-map column headers
            _columnMapping.clear();
            for (final key in _appFieldTitles.keys) {
              final title = _appFieldTitles[key]!.replaceAll(' *', '').replaceAll(' (Required for Update)', '').toLowerCase();
              for (final header in _detectedHeaders) {
                if (header.toLowerCase().contains(title) || title.contains(header.toLowerCase())) {
                  _columnMapping[key] = header;
                  break;
                }
              }
            }
          });
        },
        onError: (err) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Title Header
            Row(
              children: [
                const Icon(Icons.table_chart, size: 32, color: AppColors.primaryNavy),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Excel Data Hub', style: GoogleFonts.manrope(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
                    Text('Export Operational Records & Import Local Device Spreadsheets with Validation', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Tab Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primaryNavy,
                indicatorWeight: 3,
                labelColor: AppColors.primaryNavy,
                unselectedLabelColor: AppColors.textMuted,
                labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                tabs: const [
                  Tab(icon: Icon(Icons.download), text: 'Export Operational Records (.xlsx)'),
                  Tab(icon: Icon(Icons.upload_file), text: 'Import Spreadsheet Wizard (.xlsx)'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              height: 750,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildExportTab(),
                  _buildImportTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 1: EXCEL EXPORT
  // ===========================================================================
  Widget _buildExportTab() {
    return Consumer<ProductionProvider>(
      builder: (context, provider, child) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Controls Column
            Expanded(
              flex: 4,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Filters Card
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('1. Select Export Scope & Filters', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),

                            // Date Pickers Row
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.calendar_today, size: 16),
                                    label: Text(_exportStartDate != null ? DateFormat('yyyy-MM-dd').format(_exportStartDate!) : 'Start Date'),
                                    onPressed: () async {
                                      final picked = await showDatePicker(context: context, initialDate: _exportStartDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                                      if (picked != null) {
                                        setState(() => _exportStartDate = picked);
                                        _triggerExportPreview();
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.calendar_today, size: 16),
                                    label: Text(_exportEndDate != null ? DateFormat('yyyy-MM-dd').format(_exportEndDate!) : 'End Date'),
                                    onPressed: () async {
                                      final picked = await showDatePicker(context: context, initialDate: _exportEndDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                                      if (picked != null) {
                                        setState(() => _exportEndDate = picked);
                                        _triggerExportPreview();
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Shift checkboxes
                            Text('Shifts Scope:', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                            Row(
                              children: [1, 2, 3].map((sId) {
                                final isSelected = _selectedShiftIds.contains(sId);
                                return Row(
                                  children: [
                                    Checkbox(
                                      value: isSelected,
                                      onChanged: (val) {
                                         setState(() {
                                           if (val == true) {
                                             _selectedShiftIds.add(sId);
                                           } else if (_selectedShiftIds.length > 1) {
                                             _selectedShiftIds.remove(sId);
                                           }
                                         });
                                        _triggerExportPreview();
                                      },
                                    ),
                                    Text('Shift $sId'),
                                    const SizedBox(width: 12),
                                  ],
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 12),

                            // Status Dropdown
                            DropdownButtonFormField<String>(
                              initialValue: _selectedExportStatus,
                              decoration: const InputDecoration(labelText: 'Status Filter', isDense: true),
                              items: ['ALL', 'APPROVED', 'SUBMITTED', 'PENDING_APPROVAL', 'REJECTED', 'DRAFT'].map((st) {
                                return DropdownMenuItem(value: st, child: Text(st));
                              }).toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => _selectedExportStatus = v);
                                  _triggerExportPreview();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Column Selector Card
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('2. Select Export Columns', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold)),
                                Row(
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        setState(() => _selectedColumns.addAll(_appFieldTitles.keys));
                                        _triggerExportPreview();
                                      },
                                      child: const Text('Select All', style: TextStyle(fontSize: 12)),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        setState(() => _selectedColumns.clear());
                                        _triggerExportPreview();
                                      },
                                      child: const Text('Clear', style: TextStyle(fontSize: 12)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: _appFieldTitles.keys.map((key) {
                                final isSelected = _selectedColumns.contains(key);
                                return FilterChip(
                                  selected: isSelected,
                                  label: Text(_appFieldTitles[key]!.replaceAll(' *', ''), style: GoogleFonts.inter(fontSize: 11)),
                                  onSelected: (val) {
                                     setState(() {
                                       if (val) {
                                         _selectedColumns.add(key);
                                       } else {
                                         _selectedColumns.remove(key);
                                       }
                                     });
                                    _triggerExportPreview();
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 20),

            // Right Preview & Download Column
            Expanded(
              flex: 5,
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Export Preview', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold)),
                              if (provider.exportPreview != null)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: AppColors.secondaryTeal.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                                  child: Text('${provider.exportPreview!.totalMatchingCount} Records Match Selected Filters', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.secondaryTeal, fontSize: 12)),
                                ),
                            ],
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryNavy,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.download, color: Colors.white),
                            label: Text('Download .XLSX File', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                            onPressed: provider.exportPreview != null && provider.exportPreview!.totalMatchingCount > 0 ? _downloadExportFile : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      Expanded(
                        child: provider.isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : provider.exportPreview == null || provider.exportPreview!.previewRows.isEmpty
                                ? Center(child: Text('No records match selected export criteria.', style: GoogleFonts.inter(color: AppColors.textMuted)))
                                : SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: SingleChildScrollView(
                                      child: DataTable(
                                        headingRowColor: WidgetStateProperty.all(AppColors.backgroundLight),
                                        columns: provider.exportPreview!.columnsSelected.map((c) {
                                          return DataColumn(label: Text(c, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)));
                                        }).toList(),
                                        rows: provider.exportPreview!.previewRows.map((row) {
                                          return DataRow(
                                            cells: provider.exportPreview!.columnsSelected.map((colKey) {
                                              final val = row[colKey] ?? '';
                                              return DataCell(Text(val.toString(), style: GoogleFonts.inter(fontSize: 12)));
                                            }).toList(),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ===========================================================================
  // TAB 2: EXCEL IMPORT WIZARD
  // ===========================================================================
  Widget _buildImportTab() {
    return Consumer<ProductionProvider>(
      builder: (context, provider, child) {
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step Indicator Bar
                Row(
                  children: [
                    _buildStepBadge(1, 'Upload File', _importStep == 1, _importStep > 1),
                    const Expanded(child: Divider()),
                    _buildStepBadge(2, 'Column Mapping', _importStep == 2, _importStep > 2),
                    const Expanded(child: Divider()),
                    _buildStepBadge(3, 'Validation & Preview', _importStep == 3, _importStep > 3),
                  ],
                ),
                const SizedBox(height: 24),

                // Step Content Views
                Expanded(
                  child: _importStep == 1
                      ? _buildImportStep1Upload()
                      : _importStep == 2
                          ? _buildImportStep2Mapping(provider)
                          : _buildImportStep3Validation(provider),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepBadge(int stepNum, String title, bool isActive, bool isComplete) {
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: isComplete ? Colors.green : (isActive ? AppColors.primaryNavy : Colors.grey.shade300),
          child: isComplete
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : Text('$stepNum', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.inter(fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: isActive ? AppColors.primaryNavy : AppColors.textMuted)),
      ],
    );
  }

  // Step 1: Upload File & Download Template
  Widget _buildImportStep1Upload() {
    return Center(
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_upload_outlined, size: 64, color: AppColors.primaryNavy),
            const SizedBox(height: 16),
            Text('Select Excel Spreadsheet to Import', style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Upload standard .xlsx file containing production entry records.', style: GoogleFonts.inter(color: AppColors.textMuted)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryNavy, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
              icon: const Icon(Icons.file_present, color: Colors.white),
              label: Text('Browse & Upload File (.xlsx)', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
              onPressed: _handleFileUpload,
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            TextButton.icon(
              icon: const Icon(Icons.download, size: 18),
              label: Text('Download Standard Excel Import Template (.xlsx)', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              onPressed: _downloadTemplateFile,
            ),
          ],
        ),
      ),
    );
  }

  // Step 2: Worksheet & Column Mapping
  Widget _buildImportStep2Mapping(ProductionProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Configure Import Settings & Header Mapping', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Map your spreadsheet column headers to COCOTUFT database fields', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted)),
              ],
            ),
            Row(
              children: [
                OutlinedButton(onPressed: () => setState(() => _importStep = 1), child: const Text('Back')),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryNavy),
                  icon: const Icon(Icons.fact_check_outlined, color: Colors.white, size: 18),
                  label: Text('Run Server Validation Dry-Run', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    if (_tempFileId == null) return;
                    await provider.validateExcelImport({
                      'temp_file_id': _tempFileId,
                      'sheet_name': _selectedSheet,
                      'mode': _importMode,
                      'column_mapping': _columnMapping,
                      'default_date': DateFormat('yyyy-MM-dd').format(_defaultImportDate),
                      'default_shift_id': _defaultImportShiftId,
                    });
                    setState(() => _importStep = 3);
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Settings Bar (Sheet & Mode)
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade200)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedSheet,
                    decoration: const InputDecoration(labelText: 'Worksheet', isDense: true),
                    items: _detectedSheets.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => _selectedSheet = v ?? _selectedSheet),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _importMode,
                    decoration: const InputDecoration(labelText: 'Import Execution Mode', isDense: true),
                    items: const [
                      DropdownMenuItem(value: 'CREATE_NEW', child: Text('CREATE NEW RECORDS')),
                      DropdownMenuItem(value: 'UPDATE_EXISTING', child: Text('UPDATE EXISTING RECORDS (by Entry No)')),
                    ],
                    onChanged: (v) => setState(() => _importMode = v ?? 'CREATE_NEW'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Column Mapping List
        Expanded(
          child: ListView.separated(
            itemCount: _appFieldTitles.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final key = _appFieldTitles.keys.elementAt(index);
              final fieldTitle = _appFieldTitles[key]!;
              final currentMappedHeader = _columnMapping[key];

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(fieldTitle, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    const Icon(Icons.arrow_forward, size: 16, color: AppColors.textMuted),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 5,
                      child: DropdownButtonFormField<String>(
                        initialValue: _detectedHeaders.contains(currentMappedHeader) ? currentMappedHeader : null,
                        decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                        hint: const Text('Select Spreadsheet Column Header'),
                        items: [
                          const DropdownMenuItem<String>(value: null, child: Text('-- Not Mapped --', style: TextStyle(color: Colors.grey))),
                          ..._detectedHeaders.map((h) => DropdownMenuItem(value: h, child: Text(h))),
                        ],
                        onChanged: (v) {
                          setState(() {
                            if (v == null) {
                              _columnMapping.remove(key);
                            } else {
                              _columnMapping[key] = v;
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Step 3: Validation Dry-Run & Final Execution
  Widget _buildImportStep3Validation(ProductionProvider provider) {
    final result = provider.importValidateResult;
    if (result == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Validation Summary Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: result.isValid ? Colors.green.shade50 : AppColors.dangerRed.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: result.isValid ? Colors.green : AppColors.dangerRed),
          ),
          child: Row(
            children: [
              Icon(result.isValid ? Icons.check_circle : Icons.error, color: result.isValid ? Colors.green : AppColors.dangerRed, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.isValid
                          ? 'Validation Passed! Ready to Import ${result.recordsToCreateCount + result.recordsToUpdateCount} Record(s)'
                          : 'Validation Failed (${result.totalErrorsCount} Error(s) Found)',
                      style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold, color: result.isValid ? Colors.green.shade900 : AppColors.dangerRed),
                    ),
                    Text(
                      result.isValid
                          ? 'Mode: ${_importMode.replaceAll('_', ' ')} • Rows Processed: ${result.totalRowsProcessed}'
                          : 'Fix errors highlighted below in your spreadsheet before importing. Database is protected from partial writes.',
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textBody),
                    ),
                  ],
                ),
              ),
              if (result.isValid)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
                  icon: const Icon(Icons.save_alt, color: Colors.white),
                  label: Text('Execute Atomic Import', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                  onPressed: () async {
                    final ok = await provider.executeExcelImport({
                      'temp_file_id': _tempFileId,
                      'sheet_name': _selectedSheet,
                      'mode': _importMode,
                      'column_mapping': _columnMapping,
                      'default_date': DateFormat('yyyy-MM-dd').format(_defaultImportDate),
                      'default_shift_id': _defaultImportShiftId,
                    });
                    if (ok && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Excel Import Executed Successfully!')));
                      setState(() => _importStep = 1);
                    } else if (provider.errorMessage != null && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage!)));
                    }
                  },
                )
              else
                OutlinedButton(onPressed: () => setState(() => _importStep = 2), child: const Text('Back to Mapping')),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Error Log Table if any
        if (result.rowErrors.isNotEmpty) ...[
          Text('Row Validation Error Log:', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.dangerRed)),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              itemCount: result.rowErrors.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final err = result.rowErrors[i];
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 12,
                    backgroundColor: AppColors.dangerRed,
                    child: Text('${err.excelRowNumber}', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  title: Text('Row ${err.excelRowNumber} [Field: ${err.fieldCode}]', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.dangerRed)),
                  subtitle: Text(err.errorMessage, style: GoogleFonts.inter(fontSize: 12)),
                );
              },
            ),
          ),
        ] else ...[
          Text('Parsed Records Preview:', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(AppColors.backgroundLight),
                columns: const [
                  DataColumn(label: Text('Row #')),
                  DataColumn(label: Text('Entry Number')),
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Shift')),
                  DataColumn(label: Text('Roll Number')),
                  DataColumn(label: Text('Length (m)')),
                  DataColumn(label: Text('Width (m)')),
                ],
                rows: result.previewRecords.map((r) {
                  return DataRow(cells: [
                    DataCell(Text(r['row_number'].toString())),
                    DataCell(Text(r['entry_number'].toString())),
                    DataCell(Text(r['entry_date'].toString())),
                    DataCell(Text(r['shift'].toString())),
                    DataCell(Text(r['roll_number'].toString())),
                    DataCell(Text(r['length_meters'].toString())),
                    DataCell(Text(r['width_meters'].toString())),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
