// ==============================================================================
// COCOTUFT PRODUCTION MANAGEMENT SYSTEM - PRODUCTION DATA MODELS
// ==============================================================================
// Section Purpose: Models representing Daily Tufting Details, Audit History,
// and Tufting Production Summary report rows.
// ==============================================================================

class ProductionDetailModel {
  final int detailId;
  final int entryId;
  final String base;
  final String pileHeight;
  final String salesOrderNo;
  final String customerCode;
  final String poNumber;
  final String rollNumber;
  final String startTime;
  final String endTime;
  final double lengthMeters;
  final double widthMeters;
  final double targetQty;
  final double actualQty;
  final double variation;
  final double balanceQty;
  final String beltSpeed;

  final int defectsAYarn;
  final int defectsBPvc;
  final int defectsCTufting;
  final int defectsDStripe;
  final int defectsEOthers;

  final int machineStopMinutes;
  final String? machineStopReason;

  final double roundWeightLeft;
  final double roundWeightCenter;
  final double roundWeightRight;

  final String? qualityRemarks;
  final int factoryLabourCount;
  final int contractLabourCount;

  final String? shiftMachineIncharge;
  final String? shiftQualityController;
  final String? shiftSupervisorName;
  final String? tuftingHead;
  final String? creelStand;

  final double totalRunningMeter;
  final double totalSqm;
  final String? comments;

  ProductionDetailModel({
    required this.detailId,
    required this.entryId,
    required this.base,
    required this.pileHeight,
    required this.salesOrderNo,
    required this.customerCode,
    required this.poNumber,
    required this.rollNumber,
    required this.startTime,
    required this.endTime,
    required this.lengthMeters,
    required this.widthMeters,
    required this.targetQty,
    required this.actualQty,
    required this.variation,
    required this.balanceQty,
    this.beltSpeed = 'Normal',
    this.defectsAYarn = 0,
    this.defectsBPvc = 0,
    this.defectsCTufting = 0,
    this.defectsDStripe = 0,
    this.defectsEOthers = 0,
    this.machineStopMinutes = 0,
    this.machineStopReason,
    this.roundWeightLeft = 0.0,
    this.roundWeightCenter = 0.0,
    this.roundWeightRight = 0.0,
    this.qualityRemarks,
    this.factoryLabourCount = 1,
    this.contractLabourCount = 0,
    this.shiftMachineIncharge,
    this.shiftQualityController,
    this.shiftSupervisorName,
    this.tuftingHead,
    this.creelStand,
    this.totalRunningMeter = 0.0,
    this.totalSqm = 0.0,
    this.comments,
  });

  factory ProductionDetailModel.fromJson(Map<String, dynamic> json) {
    return ProductionDetailModel(
      detailId: json['detail_id'] ?? 0,
      entryId: json['entry_id'] ?? 0,
      base: json['base'] ?? 'Natural',
      pileHeight: json['pile_height'] ?? '15 MM',
      salesOrderNo: json['sales_order_no'] ?? 'PCT-298',
      customerCode: json['customer_code'] ?? 'TESCO',
      poNumber: json['po_number'] ?? 'PRDOT-446',
      rollNumber: json['roll_number'] ?? '',
      startTime: json['start_time'] ?? '06:00 AM',
      endTime: json['end_time'] ?? '07:20 AM',
      lengthMeters: (json['length_meters'] ?? 0.0).toDouble(),
      widthMeters: (json['width_meters'] ?? 0.0).toDouble(),
      targetQty: (json['target_qty'] ?? 500.0).toDouble(),
      actualQty: (json['actual_qty'] ?? 0.0).toDouble(),
      variation: (json['variation'] ?? 0.0).toDouble(),
      balanceQty: (json['balance_qty'] ?? 0.0).toDouble(),
      beltSpeed: json['belt_speed'] ?? 'Normal',
      defectsAYarn: json['defects_a_yarn'] ?? 0,
      defectsBPvc: json['defects_b_pvc'] ?? 0,
      defectsCTufting: json['defects_c_tufting'] ?? 0,
      defectsDStripe: json['defects_d_stripe'] ?? 0,
      defectsEOthers: json['defects_e_others'] ?? 0,
      machineStopMinutes: json['machine_stop_minutes'] ?? 0,
      machineStopReason: json['machine_stop_reason'],
      roundWeightLeft: (json['round_weight_left'] ?? 0.0).toDouble(),
      roundWeightCenter: (json['round_weight_center'] ?? 0.0).toDouble(),
      roundWeightRight: (json['round_weight_right'] ?? 0.0).toDouble(),
      qualityRemarks: json['quality_remarks'],
      factoryLabourCount: json['factory_labour_count'] ?? 1,
      contractLabourCount: json['contract_labour_count'] ?? 0,
      shiftMachineIncharge: json['shift_machine_incharge'],
      shiftQualityController: json['shift_quality_controller'],
      shiftSupervisorName: json['shift_supervisor_name'],
      tuftingHead: json['tufting_head'],
      creelStand: json['creel_stand'],
      totalRunningMeter: (json['total_running_meter'] ?? 0.0).toDouble(),
      totalSqm: (json['total_sqm'] ?? 0.0).toDouble(),
      comments: json['comments'],
    );
  }
}

class ProductionEntryModel {
  final int entryId;
  final String entryNumber;
  final String entryDate;
  final String tuftedDate;
  final int shiftId;
  final String? shiftName;
  final int processId;
  final String? processName;
  final int machineId;
  final String? machineName;
  final int orderId;
  final String? orderNumber;
  final int customerId;
  final String? customerName;
  final int? productId;
  final String? productName;
  final int workerId;
  final String? workerName;
  final String status; // DRAFT, PENDING_APPROVAL, APPROVED, REJECTED
  final String erpSyncStatus;
  final String? erpReferenceNo;
  final String? rejectionReason;
  final String? supervisorRemarks;
  final String? approvedByName;
  final String? approvedAt;
  final String? lastEditedByName;
  final String createdAt;
  final ProductionDetailModel? details;

  ProductionEntryModel({
    required this.entryId,
    required this.entryNumber,
    required this.entryDate,
    required this.tuftedDate,
    required this.shiftId,
    this.shiftName,
    required this.processId,
    this.processName,
    required this.machineId,
    this.machineName,
    required this.orderId,
    this.orderNumber,
    required this.customerId,
    this.customerName,
    this.productId,
    this.productName,
    required this.workerId,
    this.workerName,
    required this.status,
    required this.erpSyncStatus,
    this.erpReferenceNo,
    this.rejectionReason,
    this.supervisorRemarks,
    this.approvedByName,
    this.approvedAt,
    this.lastEditedByName,
    required this.createdAt,
    this.details,
  });

  factory ProductionEntryModel.fromJson(Map<String, dynamic> json) {
    return ProductionEntryModel(
      entryId: json['entry_id'] ?? 0,
      entryNumber: json['entry_number'] ?? '',
      entryDate: json['entry_date'] ?? '',
      tuftedDate: json['tufted_date'] ?? json['entry_date'] ?? '',
      shiftId: json['shift_id'] ?? 0,
      shiftName: json['shift_name'],
      processId: json['process_id'] ?? 0,
      processName: json['process_name'],
      machineId: json['machine_id'] ?? 0,
      machineName: json['machine_name'],
      orderId: json['order_id'] ?? 0,
      orderNumber: json['order_number'],
      customerId: json['customer_id'] ?? 0,
      customerName: json['customer_name'],
      productId: json['product_id'],
      productName: json['product_name'],
      workerId: json['worker_id'] ?? 0,
      workerName: json['worker_name'],
      status: json['status'] ?? 'DRAFT',
      erpSyncStatus: json['erp_sync_status'] ?? 'ERP_SYNC_PENDING',
      erpReferenceNo: json['erp_reference_no'],
      rejectionReason: json['rejection_reason'],
      supervisorRemarks: json['supervisor_remarks'],
      approvedByName: json['approved_by_name'],
      approvedAt: json['approved_at'],
      lastEditedByName: json['last_edited_by_name'],
      createdAt: json['created_at'] ?? '',
      details: json['details'] != null
          ? ProductionDetailModel.fromJson(json['details'])
          : null,
    );
  }
}

class TuftingSummaryRowModel {
  final String salesOrderNo;
  final String machineName;
  final String pileHeight;
  final double widthMeters;
  final double lengthMeters;
  final double targetQty;
  final double actualQty;
  final double variation;
  final double balanceQty;
  final double runningMeter;

  TuftingSummaryRowModel({
    required this.salesOrderNo,
    required this.machineName,
    required this.pileHeight,
    required this.widthMeters,
    required this.lengthMeters,
    required this.targetQty,
    required this.actualQty,
    required this.variation,
    required this.balanceQty,
    required this.runningMeter,
  });

  factory TuftingSummaryRowModel.fromJson(Map<String, dynamic> json) {
    return TuftingSummaryRowModel(
      salesOrderNo: json['sales_order_no'] ?? '',
      machineName: json['machine_name'] ?? '',
      pileHeight: json['pile_height'] ?? '15 MM',
      widthMeters: (json['width_meters'] ?? 0.0).toDouble(),
      lengthMeters: (json['length_meters'] ?? 0.0).toDouble(),
      targetQty: (json['target_qty'] ?? 0.0).toDouble(),
      actualQty: (json['actual_qty'] ?? 0.0).toDouble(),
      variation: (json['variation'] ?? 0.0).toDouble(),
      balanceQty: (json['balance_qty'] ?? 0.0).toDouble(),
      runningMeter: (json['running_meter'] ?? 0.0).toDouble(),
    );
  }
}

class TuftingSummaryReportModel {
  final List<TuftingSummaryRowModel> rows;
  final int totalEntries;
  final double grandTotalTargetQty;
  final double grandTotalActualQty;
  final double grandTotalVariation;
  final double grandTotalBalanceQty;
  final double grandTotalRunningMeter;

  TuftingSummaryReportModel({
    required this.rows,
    required this.totalEntries,
    required this.grandTotalTargetQty,
    required this.grandTotalActualQty,
    required this.grandTotalVariation,
    required this.grandTotalBalanceQty,
    required this.grandTotalRunningMeter,
  });

  factory TuftingSummaryReportModel.fromJson(Map<String, dynamic> json) {
    var rawRows = json['rows'] as List? ?? [];
    List<TuftingSummaryRowModel> parsedRows =
        rawRows.map((r) => TuftingSummaryRowModel.fromJson(r)).toList();

    return TuftingSummaryReportModel(
      rows: parsedRows,
      totalEntries: json['total_entries'] ?? 0,
      grandTotalTargetQty: (json['grand_total_target_qty'] ?? 0.0).toDouble(),
      grandTotalActualQty: (json['grand_total_actual_qty'] ?? 0.0).toDouble(),
      grandTotalVariation: (json['grand_total_variation'] ?? 0.0).toDouble(),
      grandTotalBalanceQty: (json['grand_total_balance_qty'] ?? 0.0).toDouble(),
      grandTotalRunningMeter: (json['grand_total_running_meter'] ?? 0.0).toDouble(),
    );
  }
}

class AuditLogModel {
  final int logId;
  final int entryId;
  final String changedByUsername;
  final String changedByFullname;
  final String action;
  final String? fieldName;
  final String? oldValue;
  final String? newValue;
  final String createdAt;

  AuditLogModel({
    required this.logId,
    required this.entryId,
    required this.changedByUsername,
    required this.changedByFullname,
    required this.action,
    this.fieldName,
    this.oldValue,
    this.newValue,
    required this.createdAt,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      logId: json['log_id'] ?? 0,
      entryId: json['entry_id'] ?? 0,
      changedByUsername: json['changed_by_username'] ?? 'Unknown',
      changedByFullname: json['changed_by_fullname'] ?? 'Unknown',
      action: json['action'] ?? '',
      fieldName: json['field_name'],
      oldValue: json['old_value'],
      newValue: json['new_value'],
      createdAt: json['created_at'] ?? '',
    );
  }
}
