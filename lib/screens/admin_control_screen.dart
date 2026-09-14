// ==============================================================================
// COCOTUFT PRODUCTION MANAGEMENT SYSTEM - ADMIN CONTROL PANEL SCREEN
// ==============================================================================
// Section Purpose: Comprehensive Admin Workspace for User Account Management,
// Role & Granular Permission Matrix Configuration, and System Activity Audit Logging.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/constants/app_colors.dart';
import '../models/user_model.dart';
import '../models/admin_models.dart';
import '../providers/production_provider.dart';
import '../providers/auth_provider.dart';

class AdminControlScreen extends StatefulWidget {
  const AdminControlScreen({super.key});

  @override
  State<AdminControlScreen> createState() => _AdminControlScreenState();
}

class _AdminControlScreenState extends State<AdminControlScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _userSearchCtrl = TextEditingController();
  final TextEditingController _logSearchCtrl = TextEditingController();
  String _selectedRoleFilter = 'ALL';
  String _selectedActionFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAllData();
    });
  }

  void _refreshAllData() {
    final provider = Provider.of<ProductionProvider>(context, listen: false);
    provider.fetchAdminUsers();
    provider.fetchRoles();
    provider.fetchPermissions();
    provider.fetchSystemActivity();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _userSearchCtrl.dispose();
    _logSearchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    if (!authProvider.hasPermission('admin_user_mgmt') && !authProvider.currentUser!.isAdmin) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.security, size: 64, color: AppColors.dangerRed),
              const SizedBox(height: 16),
              Text('Access Forbidden', style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(height: 8),
              Text('You do not have Administrator permissions to view this control panel.', style: GoogleFonts.inter(color: AppColors.textMuted)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Control Panel',
                      style: GoogleFonts.manrope(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage User Accounts, Security Roles, Permission Matrix & System Audit Logs',
                      style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppColors.primaryNavy),
                  onPressed: _refreshAllData,
                  tooltip: 'Refresh Admin Data',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Tab Navigation Bar
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
                  Tab(icon: Icon(Icons.people_alt_outlined), text: 'User Management'),
                  Tab(icon: Icon(Icons.admin_panel_settings_outlined), text: 'Role & Permissions'),
                  Tab(icon: Icon(Icons.history_toggle_off), text: 'System Activity Logs'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tab Views Container
            SizedBox(
              height: 700,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildUserManagementTab(),
                  _buildRoleManagementTab(),
                  _buildSystemActivityTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 1: USER MANAGEMENT
  // ===========================================================================
  Widget _buildUserManagementTab() {
    return Consumer<ProductionProvider>(
      builder: (context, provider, child) {
        final query = _userSearchCtrl.text.trim().toLowerCase();
        final users = provider.userList.where((u) {
          final matchesSearch = query.isEmpty ||
              u.fullName.toLowerCase().contains(query) ||
              u.username.toLowerCase().contains(query) ||
              (u.email ?? '').toLowerCase().contains(query);
          final matchesRole = _selectedRoleFilter == 'ALL' || u.roleName.toUpperCase() == _selectedRoleFilter;
          return matchesSearch && matchesRole;
        }).toList();

        return Column(
          children: [
            // Filter & Action Toolbar
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _userSearchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Search user by name, username, or email...',
                          prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      value: _selectedRoleFilter,
                      underline: const SizedBox(),
                      items: ['ALL', 'WORKER', 'SUPERVISOR', 'ADMIN'].map((r) {
                        return DropdownMenuItem(value: r, child: Text('Role: $r', style: GoogleFonts.inter(fontWeight: FontWeight.w600)));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedRoleFilter = val);
                      },
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryNavy,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.person_add, color: Colors.white, size: 18),
                      label: Text('Create New User', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: () => _showCreateUserModal(context),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Users List Grid/Table
            Expanded(
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : users.isEmpty
                        ? Center(child: Text('No user accounts found.', style: GoogleFonts.inter(color: AppColors.textMuted)))
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: users.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (context, index) {
                              final user = users[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: user.isAdmin
                                      ? AppColors.primaryNavy
                                      : user.isSupervisor
                                          ? AppColors.secondaryTeal
                                          : Colors.blueGrey,
                                  child: Text(user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                                title: Row(
                                  children: [
                                    Text(user.fullName, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(width: 8),
                                    _buildRoleBadge(user.roleName),
                                    if (user.isBlocked) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                         decoration: BoxDecoration(color: AppColors.dangerRed.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                        child: Text('BLOCKED', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.dangerRed)),
                                      ),
                                    ],
                                  ],
                                ),
                                subtitle: Text('@${user.username} • ${user.email ?? "No email"}', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: AppColors.primaryNavy),
                                      tooltip: 'Edit Profile & Password',
                                      onPressed: () => _showEditUserModal(context, user),
                                    ),
                                    IconButton(
                                      icon: Icon(user.isBlocked ? Icons.lock_open : Icons.block, color: user.isBlocked ? Colors.green : Colors.orange),
                                      tooltip: user.isBlocked ? 'Unblock User' : 'Block User',
                                       onPressed: () async {
                                         final messenger = ScaffoldMessenger.of(context);
                                         final ok = await provider.toggleBlockAdminUser(user.userId);
                                         if (!ok && provider.errorMessage != null) {
                                           messenger.showSnackBar(SnackBar(content: Text(provider.errorMessage!)));
                                         }
                                       },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: AppColors.dangerRed),
                                      tooltip: 'Remove User Account',
                                      onPressed: () => _confirmDeleteUser(context, user),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRoleBadge(String roleName) {
    Color bg = Colors.blue.shade100;
    Color fg = Colors.blue.shade900;
    if (roleName.toUpperCase() == 'ADMIN') {
      bg = AppColors.primaryNavy.withValues(alpha: 0.15);
      fg = AppColors.primaryNavy;
    } else if (roleName.toUpperCase() == 'SUPERVISOR') {
      bg = AppColors.secondaryTeal.withValues(alpha: 0.2);
      fg = AppColors.secondaryTeal;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(roleName.toUpperCase(), style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: fg)),
    );
  }

  // ===========================================================================
  // TAB 2: ROLE & PERMISSION MANAGEMENT
  // ===========================================================================
  Widget _buildRoleManagementTab() {
    return Consumer<ProductionProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Role Permissions Matrix', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryNavy),
                  icon: const Icon(Icons.add_moderator, color: Colors.white, size: 18),
                  label: Text('Create Custom Role', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                  onPressed: () => _showCreateRoleModal(context, provider),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 500,
                        mainAxisExtent: 260,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: provider.rolesList.length,
                      itemBuilder: (context, index) {
                        final role = provider.rolesList[index];
                        final isSystemDefault = ['ADMIN', 'SUPERVISOR', 'WORKER'].contains(role.roleName.toUpperCase());

                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    _buildRoleBadge(role.roleName),
                                    const SizedBox(width: 8),
                                    Text('${role.userCount} Assigned Users', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 20, color: AppColors.primaryNavy),
                                      onPressed: () => _showEditRoleModal(context, provider, role),
                                      tooltip: 'Edit Permission Matrix',
                                    ),
                                    if (!isSystemDefault)
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.dangerRed),
                                        onPressed: () => _confirmDeleteRole(context, provider, role),
                                        tooltip: 'Delete Role',
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(role.description ?? 'No description provided.', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textBody)),
                                const SizedBox(height: 12),
                                const Divider(),
                                Text('Granted Permissions (${role.permissions.length}):', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: role.permissions.map((p) {
                                        return Chip(
                                          label: Text(p.name, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600)),
                                          backgroundColor: AppColors.backgroundLight,
                                          visualDensity: VisualDensity.compact,
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  // ===========================================================================
  // TAB 3: SYSTEM ACTIVITY AUDIT LOGS
  // ===========================================================================
  Widget _buildSystemActivityTab() {
    return Consumer<ProductionProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            // Filter Bar
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _logSearchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Search audit log by actor, action, resource...',
                          prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      value: _selectedActionFilter,
                      underline: const SizedBox(),
                      items: ['ALL', 'LOGIN', 'USER_CREATE', 'USER_UPDATE', 'USER_BLOCK', 'USER_DELETE', 'ROLE_CREATE', 'ROLE_UPDATE', 'EXCEL_EXPORT', 'EXCEL_IMPORT'].map((a) {
                        return DropdownMenuItem(value: a, child: Text('Action: $a', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedActionFilter = val);
                      },
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryNavy),
                      icon: const Icon(Icons.filter_list, color: Colors.white, size: 18),
                      label: Text('Apply Filter', style: GoogleFonts.inter(color: Colors.white)),
                      onPressed: () {
                        provider.fetchSystemActivity(
                          search: _logSearchCtrl.text.trim(),
                          action: _selectedActionFilter,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Audit Table
            Expanded(
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : provider.activityLogs.isEmpty
                        ? Center(child: Text('No system activity logs recorded.', style: GoogleFonts.inter(color: AppColors.textMuted)))
                        : ListView.separated(
                            itemCount: provider.activityLogs.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final log = provider.activityLogs[index];
                              return ListTile(
                                dense: true,
                                title: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                         color: log.action.contains('DELETE') || log.action.contains('BLOCK')
                                             ? AppColors.dangerRed.withValues(alpha: 0.1)
                                             : Colors.blue.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(log.action, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 12),
                                    Text('${log.username} (${log.roleName})', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                                    const Spacer(),
                                    Text(log.timestamp.replaceAll('T', ' ').split('.')[0], style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(log.details ?? 'No details provided.', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textBody)),
                                ),
                              );
                            },
                          ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ===========================================================================
  // MODALS & ACTIONS
  // ===========================================================================
  void _showCreateUserModal(BuildContext context) {
    final usernameCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    String roleVal = 'WORKER';

    showDialog(
      context: context,
      builder: (dlgContext) {
        return AlertDialog(
          title: Text('Create New User Account', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: usernameCtrl, decoration: const InputDecoration(labelText: 'Username *')),
                const SizedBox(height: 12),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name *')),
                const SizedBox(height: 12),
                TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email Address')),
                const SizedBox(height: 12),
                TextField(controller: passwordCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password *')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: roleVal,
                  decoration: const InputDecoration(labelText: 'Assign Role *'),
                  items: ['WORKER', 'SUPERVISOR', 'ADMIN'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (v) => roleVal = v ?? 'WORKER',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dlgContext), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryNavy),
              onPressed: () async {
                if (usernameCtrl.text.isEmpty || nameCtrl.text.isEmpty || passwordCtrl.text.isEmpty) return;
                final provider = Provider.of<ProductionProvider>(context, listen: false);
                final ok = await provider.createAdminUser({
                  'username': usernameCtrl.text.trim(),
                  'full_name': nameCtrl.text.trim(),
                  'email': emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                  'password': passwordCtrl.text,
                  'role_name': roleVal,
                });
                if (ok) {
                  if (dlgContext.mounted) Navigator.pop(dlgContext);
                } else if (provider.errorMessage != null) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage!)));
                  }
                }
              },
              child: const Text('Create User', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showEditUserModal(BuildContext context, UserModel user) {
    final nameCtrl = TextEditingController(text: user.fullName);
    final emailCtrl = TextEditingController(text: user.email ?? '');
    final passwordCtrl = TextEditingController();
    String roleVal = user.roleName.toUpperCase();

    showDialog(
      context: context,
      builder: (dlgContext) {
        return AlertDialog(
          title: Text('Edit User: @${user.username}', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
                const SizedBox(height: 12),
                TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email Address')),
                const SizedBox(height: 12),
                TextField(controller: passwordCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Reset Password (leave empty to keep current)')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: roleVal,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: ['WORKER', 'SUPERVISOR', 'ADMIN'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (v) => roleVal = v ?? roleVal,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dlgContext), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryNavy),
              onPressed: () async {
                final provider = Provider.of<ProductionProvider>(context, listen: false);
                final payload = <String, dynamic>{
                  'full_name': nameCtrl.text.trim(),
                  'email': emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                  'role_name': roleVal,
                };
                if (passwordCtrl.text.isNotEmpty) payload['password'] = passwordCtrl.text;

                final ok = await provider.updateAdminUser(user.userId, payload);
                if (ok) {
                  if (dlgContext.mounted) Navigator.pop(dlgContext);
                } else if (provider.errorMessage != null) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage!)));
                  }
                }
              },
              child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteUser(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (dlgContext) {
        return AlertDialog(
          title: Text('Delete User Account?', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: AppColors.dangerRed)),
          content: Text('Are you sure you want to remove user @${user.username} (${user.fullName})? Historical production entries will be preserved via soft-deletion.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dlgContext), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.dangerRed),
              onPressed: () async {
                final provider = Provider.of<ProductionProvider>(context, listen: false);
                final ok = await provider.deleteAdminUser(user.userId);
                if (ok) {
                  if (dlgContext.mounted) Navigator.pop(dlgContext);
                } else if (provider.errorMessage != null) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage!)));
                  }
                }
              },
              child: const Text('Confirm Remove', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showCreateRoleModal(BuildContext context, ProductionProvider provider) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final selectedPermIds = <int>{};

    showDialog(
      context: context,
      builder: (dlgContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text('Create Custom Security Role', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: 550,
                height: 450,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Role Name (e.g. QUALITY_INSPECTOR) *')),
                    const SizedBox(height: 12),
                    TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
                    const SizedBox(height: 16),
                    Text('Select Permissions Matrix:', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: provider.permissionsList.length,
                        itemBuilder: (context, i) {
                          final p = provider.permissionsList[i];
                          final isChecked = selectedPermIds.contains(p.permissionId);
                          return CheckboxListTile(
                            dense: true,
                            title: Text('${p.name} [${p.category}]', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                            subtitle: Text(p.description ?? p.code, style: GoogleFonts.inter(fontSize: 11)),
                            value: isChecked,
                            onChanged: (val) {
                              setModalState(() {
                                if (val == true) {
                                  selectedPermIds.add(p.permissionId);
                                } else {
                                  selectedPermIds.remove(p.permissionId);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dlgContext), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryNavy),
                  onPressed: () async {
                    if (nameCtrl.text.isEmpty) return;
                    final ok = await provider.createRole({
                      'role_name': nameCtrl.text.trim(),
                      'description': descCtrl.text.trim(),
                      'permission_ids': selectedPermIds.toList(),
                    });
                    if (ok) {
                      if (dlgContext.mounted) Navigator.pop(dlgContext);
                    } else if (provider.errorMessage != null) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage!)));
                      }
                    }
                  },
                  child: const Text('Create Role', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditRoleModal(BuildContext context, ProductionProvider provider, RoleModel role) {
    final descCtrl = TextEditingController(text: role.description ?? '');
    final selectedPermIds = role.permissions.map((p) => p.permissionId).toSet();

    showDialog(
      context: context,
      builder: (dlgContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text('Edit Role: ${role.roleName}', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: 550,
                height: 450,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
                    const SizedBox(height: 16),
                    Text('Configure Permission Matrix:', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: provider.permissionsList.length,
                        itemBuilder: (context, i) {
                          final p = provider.permissionsList[i];
                          final isChecked = selectedPermIds.contains(p.permissionId);
                          return CheckboxListTile(
                            dense: true,
                            title: Text('${p.name} [${p.category}]', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                            subtitle: Text(p.description ?? p.code, style: GoogleFonts.inter(fontSize: 11)),
                            value: isChecked,
                            onChanged: (val) {
                              setModalState(() {
                                if (val == true) {
                                  selectedPermIds.add(p.permissionId);
                                } else {
                                  selectedPermIds.remove(p.permissionId);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dlgContext), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryNavy),
                  onPressed: () async {
                    final ok = await provider.updateRole(role.roleId, {
                      'description': descCtrl.text.trim(),
                      'permission_ids': selectedPermIds.toList(),
                    });
                    if (ok) {
                      if (dlgContext.mounted) Navigator.pop(dlgContext);
                    } else if (provider.errorMessage != null) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage!)));
                      }
                    }
                  },
                  child: const Text('Save Permission Matrix', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteRole(BuildContext context, ProductionProvider provider, RoleModel role) {
    showDialog(
      context: context,
      builder: (dlgContext) {
        return AlertDialog(
          title: Text('Delete Custom Role?', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: AppColors.dangerRed)),
          content: Text('Are you sure you want to delete custom role "${role.roleName}"?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dlgContext), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.dangerRed),
              onPressed: () async {
                final ok = await provider.deleteRole(role.roleId);
                if (ok) {
                  if (dlgContext.mounted) Navigator.pop(dlgContext);
                } else if (provider.errorMessage != null) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage!)));
                  }
                }
              },
              child: const Text('Delete Role', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
