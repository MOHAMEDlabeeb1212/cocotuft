// ==============================================================================
// COCOTUFT PRODUCTION MANAGEMENT SYSTEM - ADMIN & EXCEL DART MODELS
// ==============================================================================
// Section Purpose: Data models for Roles, Permissions, System Activity Audit Logs,
// Excel Export previews, and Excel Import validation dry-run reports.
// ==============================================================================

class PermissionModel {
  final int permissionId;
  final String code;
  final String name;
  final String? description;
  final String category;

  PermissionModel({
    required this.permissionId,
    required this.code,
    required this.name,
    this.description,
    required this.category,
  });

  factory PermissionModel.fromJson(Map<String, dynamic> json) {
    return PermissionModel(
      permissionId: json['permission_id'] ?? 0,
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      category: json['category'] ?? 'GENERAL',
    );
  }
}


class RoleModel {
  final int roleId;
  final String roleName;
  final String? description;
  final int userCount;
  final List<PermissionModel> permissions;

  RoleModel({
    required this.roleId,
    required this.roleName,
    this.description,
    required this.userCount,
    required this.permissions,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      roleId: json['role_id'] ?? 0,
      roleName: json['role_name'] ?? '',
      description: json['description'],
      userCount: json['user_count'] ?? 0,
      permissions: (json['permissions'] as List? ?? [])
          .map((x) => PermissionModel.fromJson(x))
          .toList(),
    );
  }
}


class SystemAuditLogModel {
  final int logId;
  final int? userId;
  final String username;
  final String roleName;
  final String action;
  final String? resource;
  final String? details;
  final String? ipAddress;
  final String timestamp;

  SystemAuditLogModel({
    required this.logId,
    this.userId,
    required this.username,
    required this.roleName,
    required this.action,
    this.resource,
    this.details,
    this.ipAddress,
    required this.timestamp,
  });

  factory SystemAuditLogModel.fromJson(Map<String, dynamic> json) {
    return SystemAuditLogModel(
      logId: json['log_id'] ?? 0,
      userId: json['user_id'],
      username: json['username'] ?? '',
      roleName: json['role_name'] ?? '',
      action: json['action'] ?? '',
      resource: json['resource'],
      details: json['details'],
      ipAddress: json['ip_address'],
      timestamp: json['timestamp'] ?? '',
    );
  }
}


class ExportPreviewModel {
  final int totalMatchingCount;
  final List<Map<String, dynamic>> previewRows;
  final List<String> columnsSelected;

  ExportPreviewModel({
    required this.totalMatchingCount,
    required this.previewRows,
    required this.columnsSelected,
  });

  factory ExportPreviewModel.fromJson(Map<String, dynamic> json) {
    return ExportPreviewModel(
      totalMatchingCount: json['total_matching_count'] ?? 0,
      previewRows: List<Map<String, dynamic>>.from(json['preview_rows'] ?? []),
      columnsSelected: List<String>.from(json['columns_selected'] ?? []),
    );
  }
}


class ImportUploadResultModel {
  final String tempFileId;
  final List<String> sheets;
  final List<String> detectedHeaders;
  final List<Map<String, dynamic>> sampleRows;

  ImportUploadResultModel({
    required this.tempFileId,
    required this.sheets,
    required this.detectedHeaders,
    required this.sampleRows,
  });

  factory ImportUploadResultModel.fromJson(Map<String, dynamic> json) {
    return ImportUploadResultModel(
      tempFileId: json['temp_file_id'] ?? '',
      sheets: List<String>.from(json['sheets'] ?? []),
      detectedHeaders: List<String>.from(json['detected_headers'] ?? []),
      sampleRows: List<Map<String, dynamic>>.from(json['sample_rows'] ?? []),
    );
  }
}


class ImportRowErrorModel {
  final int excelRowNumber;
  final String fieldCode;
  final String errorMessage;

  ImportRowErrorModel({
    required this.excelRowNumber,
    required this.fieldCode,
    required this.errorMessage,
  });

  factory ImportRowErrorModel.fromJson(Map<String, dynamic> json) {
    return ImportRowErrorModel(
      excelRowNumber: json['excel_row_number'] ?? 0,
      fieldCode: json['field_code'] ?? '',
      errorMessage: json['error_message'] ?? '',
    );
  }
}


class ImportValidateResultModel {
  final String tempFileId;
  final bool isValid;
  final int totalRowsProcessed;
  final int totalErrorsCount;
  final int recordsToCreateCount;
  final int recordsToUpdateCount;
  final List<ImportRowErrorModel> rowErrors;
  final List<Map<String, dynamic>> previewRecords;

  ImportValidateResultModel({
    required this.tempFileId,
    required this.isValid,
    required this.totalRowsProcessed,
    required this.totalErrorsCount,
    required this.recordsToCreateCount,
    required this.recordsToUpdateCount,
    required this.rowErrors,
    required this.previewRecords,
  });

  factory ImportValidateResultModel.fromJson(Map<String, dynamic> json) {
    return ImportValidateResultModel(
      tempFileId: json['temp_file_id'] ?? '',
      isValid: json['is_valid'] ?? false,
      totalRowsProcessed: json['total_rows_processed'] ?? 0,
      totalErrorsCount: json['total_errors_count'] ?? 0,
      recordsToCreateCount: json['records_to_create_count'] ?? 0,
      recordsToUpdateCount: json['records_to_update_count'] ?? 0,
      rowErrors: (json['row_errors'] as List? ?? [])
          .map((x) => ImportRowErrorModel.fromJson(x))
          .toList(),
      previewRecords: List<Map<String, dynamic>>.from(json['preview_records'] ?? []),
    );
  }
}
