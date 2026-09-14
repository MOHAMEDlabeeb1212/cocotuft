// ==============================================================================
// COCOTUFT PRODUCTION MANAGEMENT SYSTEM - MASTER DATA MODELS
// ==============================================================================
// Section Purpose: Dart data models for DB-driven master data (Processes, Machines,
// Shifts, Orders, Customers, Products) used in form dropdowns and headers.
// ==============================================================================

class ProcessModel {
  final int processId;
  final String processCode;
  final String processName;
  final String? description;

  ProcessModel({
    required this.processId,
    required this.processCode,
    required this.processName,
    this.description,
  });

  factory ProcessModel.fromJson(Map<String, dynamic> json) {
    return ProcessModel(
      processId: json['process_id'],
      processCode: json['process_code'],
      processName: json['process_name'],
      description: json['description'],
    );
  }
}

class MachineModel {
  final int machineId;
  final int processId;
  final String machineCode;
  final String machineName;

  MachineModel({
    required this.machineId,
    required this.processId,
    required this.machineCode,
    required this.machineName,
  });

  factory MachineModel.fromJson(Map<String, dynamic> json) {
    return MachineModel(
      machineId: json['machine_id'],
      processId: json['process_id'],
      machineCode: json['machine_code'],
      machineName: json['machine_name'],
    );
  }
}

class ShiftModel {
  final int shiftId;
  final String shiftName;
  final String startTime;
  final String endTime;

  ShiftModel({
    required this.shiftId,
    required this.shiftName,
    required this.startTime,
    required this.endTime,
  });

  factory ShiftModel.fromJson(Map<String, dynamic> json) {
    return ShiftModel(
      shiftId: json['shift_id'],
      shiftName: json['shift_name'],
      startTime: json['start_time'],
      endTime: json['end_time'],
    );
  }
}

class CustomerModel {
  final int customerId;
  final String customerCode;
  final String customerName;
  final String country;

  CustomerModel({
    required this.customerId,
    required this.customerCode,
    required this.customerName,
    required this.country,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      customerId: json['customer_id'],
      customerCode: json['customer_code'],
      customerName: json['customer_name'],
      country: json['country'] ?? 'India',
    );
  }
}

class OrderModel {
  final int orderId;
  final String orderNumber; // S.O.
  final String? poNumber;    // P.O.
  final int customerId;
  final String baseMaterial;
  final double pileHeightMm;
  final int targetQuantity;

  OrderModel({
    required this.orderId,
    required this.orderNumber,
    this.poNumber,
    required this.customerId,
    required this.baseMaterial,
    required this.pileHeightMm,
    required this.targetQuantity,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      orderId: json['order_id'],
      orderNumber: json['order_number'],
      poNumber: json['po_number'],
      customerId: json['customer_id'],
      baseMaterial: json['base_material'] ?? 'Coir / PVC',
      pileHeightMm: (json['pile_height_mm'] as num?)?.toDouble() ?? 15.0,
      targetQuantity: json['target_quantity'] ?? 100,
    );
  }
}

class ProductModel {
  final int productId;
  final String productCode;
  final String productName;

  ProductModel({
    required this.productId,
    required this.productCode,
    required this.productName,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      productId: json['product_id'],
      productCode: json['product_code'],
      productName: json['product_name'],
    );
  }
}
