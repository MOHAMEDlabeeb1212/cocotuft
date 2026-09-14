// ==============================================================================
// COCOTUFT PRODUCTION MANAGEMENT SYSTEM - USER MODEL
// ==============================================================================
// Section Purpose: Data model for User accounts including Admin status flags (isBlocked).
// ==============================================================================

class UserModel {
  final int userId;
  final String username;
  final String fullName;
  final String roleName; // WORKER, SUPERVISOR, ADMIN
  final String? email;
  final bool isActive;
  final bool isBlocked;
  final String? createdAt;

  UserModel({
    required this.userId,
    required this.username,
    required this.fullName,
    required this.roleName,
    this.email,
    this.isActive = true,
    this.isBlocked = false,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'] ?? 0,
      username: json['username'] ?? '',
      fullName: json['full_name'] ?? json['username'] ?? '',
      roleName: json['role_name'] ?? 'WORKER',
      email: json['email'],
      isActive: json['is_active'] ?? true,
      isBlocked: json['is_blocked'] ?? false,
      createdAt: json['created_at'],
    );
  }

  bool get isWorker => roleName.toUpperCase() == 'WORKER';
  bool get isSupervisor => roleName.toUpperCase() == 'SUPERVISOR';
  bool get isAdmin => roleName.toUpperCase() == 'ADMIN';
}

