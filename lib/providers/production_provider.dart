// ==============================================================================
// COCOTUFT PRODUCTION MANAGEMENT SYSTEM - PRODUCTION & ADMIN PROVIDER
// ==============================================================================
// Section Purpose: State manager handling Tufting entries, Supervisor approvals,
// Tufting Production Summary report state, and Admin user account management.
// ==============================================================================

import 'package:flutter/material.dart';
import '../core/services/api_service.dart';
import '../models/master_models.dart';
import '../models/production_models.dart';
import '../models/user_model.dart';

import '../models/admin_models.dart';

class ProductionProvider with ChangeNotifier {
  final ApiService _apiService;

  ProductionProvider([ApiService? apiService]) : _apiService = apiService ?? ApiService();

  List<ProcessModel> processes = [];
  List<MachineModel> machines = [];
  List<ShiftModel> shifts = [];
  List<CustomerModel> customers = [];
  List<OrderModel> orders = [];
  List<ProductModel> products = [];

  List<ProductionEntryModel> entries = [];
  List<UserModel> userList = [];
  List<RoleModel> rolesList = [];
  List<PermissionModel> permissionsList = [];
  List<SystemAuditLogModel> activityLogs = [];

  TuftingSummaryReportModel? summaryReport;
  ExportPreviewModel? exportPreview;
  ImportUploadResultModel? importUploadResult;
  ImportValidateResultModel? importValidateResult;

  bool isLoading = false;
  String? errorMessage;

  Future<void> loadMasterData() async {
    isLoading = true;
    notifyListeners();
    try {
      final prRes = await _apiService.get('/processes');
      processes = (prRes as List).map((x) => ProcessModel.fromJson(x)).toList();

      final mcRes = await _apiService.get('/machines');
      machines = (mcRes as List).map((x) => MachineModel.fromJson(x)).toList();

      final shRes = await _apiService.get('/shifts');
      shifts = (shRes as List).map((x) => ShiftModel.fromJson(x)).toList();

      final cuRes = await _apiService.get('/customers');
      customers = (cuRes as List).map((x) => CustomerModel.fromJson(x)).toList();

      final ordRes = await _apiService.get('/orders');
      orders = (ordRes as List).map((x) => OrderModel.fromJson(x)).toList();

      final prdRes = await _apiService.get('/products');
      products = (prdRes as List).map((x) => ProductModel.fromJson(x)).toList();

      errorMessage = null;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String? currentFromDate;
  String? currentToDate;
  String? currentStatus;

  Future<void> fetchEntries({String? status, String? fromDate, String? toDate}) async {
    isLoading = true;
    notifyListeners();
    try {
      currentStatus = status ?? currentStatus;
      currentFromDate = fromDate;
      currentToDate = toDate;
      
      final queryParams = <String>[];
      if (status != null && status.isNotEmpty && status != 'All') {
        queryParams.add('status=$status');
      }
      if (fromDate != null && fromDate.isNotEmpty) {
        queryParams.add('from_date=$fromDate');
      }
      if (toDate != null && toDate.isNotEmpty) {
        queryParams.add('to_date=$toDate');
      }
      final queryString = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
      final res = await _apiService.get('/production$queryString');
      entries = (res as List).map((x) => ProductionEntryModel.fromJson(x)).toList();
      errorMessage = null;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createEntry(Map<String, dynamic> payload) async {
    isLoading = true;
    notifyListeners();
    try {
      await _apiService.post('/production', payload);
      await fetchEntries(status: currentStatus, fromDate: currentFromDate, toDate: currentToDate);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateEntry(int entryId, Map<String, dynamic> payload) async {
    isLoading = true;
    notifyListeners();
    try {
      await _apiService.put('/production/$entryId', payload);
      await fetchEntries(status: currentStatus, fromDate: currentFromDate, toDate: currentToDate);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> approveEntry(int entryId, {String? remarks}) async {
    isLoading = true;
    notifyListeners();
    try {
      await _apiService.post('/production/$entryId/approve', {
        'supervisor_remarks': remarks ?? 'Confirmed and approved by supervisor.',
      });
      await fetchEntries(status: currentStatus, fromDate: currentFromDate, toDate: currentToDate);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> rejectEntry(int entryId, String reason) async {
    isLoading = true;
    notifyListeners();
    try {
      await _apiService.post('/production/$entryId/reject', {
        'rejection_reason': reason,
      });
      await fetchEntries(status: currentStatus, fromDate: currentFromDate, toDate: currentToDate);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<List<AuditLogModel>> getAuditHistory(int entryId) async {
    try {
      final res = await _apiService.get('/production/$entryId/history');
      return (res as List).map((x) => AuditLogModel.fromJson(x)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> fetchTuftingSummary({
    String? date,
    String? fromDate,
    String? toDate,
    String? machine,
    String? shift,
    String? status,
  }) async {
    isLoading = true;
    notifyListeners();
    try {
      final queryParams = <String>[];
      if (fromDate != null && fromDate.isNotEmpty) {
        queryParams.add('from_date=$fromDate');
      }
      if (toDate != null && toDate.isNotEmpty) {
        queryParams.add('to_date=$toDate');
      }
      if (date != null && date.isNotEmpty && (fromDate == null || fromDate.isEmpty)) {
        queryParams.add('filter_date=$date');
      }
      if (machine != null && machine.isNotEmpty && machine != 'All') {
        queryParams.add('filter_machine=$machine');
      }
      if (shift != null && shift.isNotEmpty && shift != 'All') {
        queryParams.add('filter_shift=$shift');
      }
      if (status != null && status.isNotEmpty && status != 'All') {
        queryParams.add('filter_status=$status');
      }

      final queryString = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
      final res = await _apiService.get('/summary$queryString');
      summaryReport = TuftingSummaryReportModel.fromJson(res);
      errorMessage = null;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ----------------------------------------------------------------------------
  // Admin User & Role Management
  // ----------------------------------------------------------------------------
  Future<void> fetchAdminUsers() async {
    isLoading = true;
    notifyListeners();
    try {
      final res = await _apiService.get('/admin/users');
      userList = (res as List).map((x) => UserModel.fromJson(x)).toList();
      errorMessage = null;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createAdminUser(Map<String, dynamic> payload) async {
    isLoading = true;
    notifyListeners();
    try {
      await _apiService.post('/admin/users', payload);
      await fetchAdminUsers();
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateAdminUser(int userId, Map<String, dynamic> payload) async {
    isLoading = true;
    notifyListeners();
    try {
      await _apiService.put('/admin/users/$userId', payload);
      await fetchAdminUsers();
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleBlockAdminUser(int userId) async {
    isLoading = true;
    notifyListeners();
    try {
      await _apiService.put('/admin/users/$userId/block', {});
      await fetchAdminUsers();
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteAdminUser(int userId) async {
    isLoading = true;
    notifyListeners();
    try {
      await _apiService.delete('/admin/users/$userId');
      await fetchAdminUsers();
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchRoles() async {
    isLoading = true;
    notifyListeners();
    try {
      final res = await _apiService.get('/admin/roles');
      rolesList = (res as List).map((x) => RoleModel.fromJson(x)).toList();
      errorMessage = null;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPermissions() async {
    try {
      final res = await _apiService.get('/admin/permissions');
      permissionsList = (res as List).map((x) => PermissionModel.fromJson(x)).toList();
    } catch (e) {
      errorMessage = e.toString();
    }
  }

  Future<bool> createRole(Map<String, dynamic> payload) async {
    isLoading = true;
    notifyListeners();
    try {
      await _apiService.post('/admin/roles', payload);
      await fetchRoles();
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateRole(int roleId, Map<String, dynamic> payload) async {
    isLoading = true;
    notifyListeners();
    try {
      await _apiService.put('/admin/roles/$roleId', payload);
      await fetchRoles();
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteRole(int roleId) async {
    isLoading = true;
    notifyListeners();
    try {
      await _apiService.delete('/admin/roles/$roleId');
      await fetchRoles();
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSystemActivity({String? search, String? roleName, String? action, String? startDate, String? endDate}) async {
    isLoading = true;
    notifyListeners();
    try {
      String query = '/admin/activity?limit=100&';
      if (search != null && search.isNotEmpty) query += 'search=$search&';
      if (roleName != null && roleName != 'ALL') query += 'role_name=$roleName&';
      if (action != null && action != 'ALL') query += 'action=$action&';
      if (startDate != null) query += 'start_date=$startDate&';
      if (endDate != null) query += 'end_date=$endDate&';

      final res = await _apiService.get(query);
      activityLogs = (res as List).map((x) => SystemAuditLogModel.fromJson(x)).toList();
      errorMessage = null;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ----------------------------------------------------------------------------
  // Excel Export & Import Methods
  // ----------------------------------------------------------------------------
  Future<void> fetchExportPreview(Map<String, dynamic> params) async {
    isLoading = true;
    notifyListeners();
    try {
      final res = await _apiService.post('/excel/export/preview', params);
      exportPreview = ExportPreviewModel.fromJson(res);
      errorMessage = null;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> validateExcelImport(Map<String, dynamic> mappingPayload) async {
    isLoading = true;
    notifyListeners();
    try {
      final res = await _apiService.post('/excel/import/validate', mappingPayload);
      importValidateResult = ImportValidateResultModel.fromJson(res);
      errorMessage = null;
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> executeExcelImport(Map<String, dynamic> executePayload) async {
    isLoading = true;
    notifyListeners();
    try {
      await _apiService.post('/excel/import/execute', executePayload);
      await fetchEntries();
      errorMessage = null;
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
