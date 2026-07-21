import '../../themes/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_demo_app/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import '../../services/app_state.dart';
import '../../themes/party_theme_config.dart';
import '../../models/complaint.dart';
import '../../widgets/shared_officer_widgets.dart';
import '../../widgets/notification_bell.dart';

import '../announcements/create_announcement_screen.dart';
import '../announcements/broadcast_history_screen.dart';
import 'create_work_update_screen.dart';
import '../super_admin/meetings/meetings_list_screen.dart';
import '../citizen/my_ward_screen.dart';
import '../citizen/notifications_screen.dart';
class AppColors {
  static const primary = Color(0xFF2563EB);
  static const primaryDark = Color(0xFF1D4ED8);
  static const primaryLight = Color(0xFFDBEAFE);
  static const accent = Color(0xFF60A5FA);
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);
  static const background = Color(0xFFF8FAFC);
  static const card = Color(0xFFFFFFFF);
  static const border = Color(0xFFE8EDF3);
}

class AppStyles {
  static const heading = TextStyle(fontSize: 26, fontWeight: FontWeight.w800, fontFamily: 'Inter', color: Color(0xFF0F172A), letterSpacing: -0.5);
  static const sectionTitle = TextStyle(fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'Inter', color: Color(0xFF1E293B));
  static const body = TextStyle(fontSize: 15, fontFamily: 'Inter', color: Color(0xFF475569), height: 1.5);
  static const caption = TextStyle(fontSize: 13, fontFamily: 'Inter', color: Color(0xFF64748B), fontWeight: FontWeight.w500);
}

class AdminNavHolder extends StatefulWidget {
  const AdminNavHolder({super.key});

  @override
  State<AdminNavHolder> createState() => _AdminNavHolderState();
}

class _AdminNavHolderState extends State<AdminNavHolder> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _navigateToComplaints() {
    setState(() {
      _currentIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      AdminDashboardTab(onNavigateToComplaints: _navigateToComplaints),
      const AdminComplaintsTab(),
      const AdminServicesTab(),
      const AdminPollingTab(),
      const AdminProfileScreen(),
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: const AdminDrawer(),
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: _buildCustomBottomNav(),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomBottomNav() {
    final l10n = AppLocalizations.of(context)!;
    final items = [
      {'icon': Icons.home_outlined, 'activeIcon': Icons.home, 'label': l10n.home},
      {'icon': Icons.assignment_outlined, 'activeIcon': Icons.assignment, 'label': l10n.complaints},
      {'icon': Icons.grid_view_outlined, 'activeIcon': Icons.grid_view, 'label': l10n.services},
      {'icon': Icons.how_to_vote_outlined, 'activeIcon': Icons.how_to_vote, 'label': l10n.polling},
      {'icon': Icons.person_outline, 'activeIcon': Icons.person, 'label': l10n.profile},
    ];

    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 12)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(items.length, (index) {
          final isActive = _currentIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _currentIndex = index),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutQuint,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primaryLight.withValues(alpha: 0.6) : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Icon(isActive ? items[index]['activeIcon'] as IconData : items[index]['icon'] as IconData, 
                       color: isActive ? AppColors.primary : const Color(0xFF94A3B8), size: 24),
                  if (isActive) ...[
                    const SizedBox(width: 8),
                    Text(items[index]['label'] as String, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Inter')),
                  ]
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

Widget _buildPremiumHeader(String title, {IconData icon = Icons.apps}) {
  return Container(
    padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 8))],
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        const SizedBox(width: 16),
        Text(title, style: AppStyles.heading.copyWith(fontSize: 24)),
      ],
    ),
  );
}

class AdminDashboardTab extends StatelessWidget {
  final VoidCallback onNavigateToComplaints;

  const AdminDashboardTab({super.key, required this.onNavigateToComplaints});

  Future<void> _handleUploadWork(BuildContext context, AppState appState) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      backgroundColor: Colors.white,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Wrap(
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 32),
                Text('Upload Work Photo', style: AppStyles.sectionTitle),
                const SizedBox(height: 24),
                _buildActionTile('Camera', Icons.camera_alt, () {
                  Navigator.pop(ctx);
                  _pickAndResolve(context, appState, ImageSource.camera);
                }),
                const SizedBox(height: 12),
                _buildActionTile('Gallery', Icons.photo_library, () {
                  Navigator.pop(ctx);
                  _pickAndResolve(context, appState, ImageSource.gallery);
                }),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildActionTile(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.primaryLight.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: AppColors.primary)),
            const SizedBox(width: 16),
            Text(title, style: AppStyles.body.copyWith(fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndResolve(BuildContext context, AppState appState, ImageSource source) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source, imageQuality: 70);
    
    if (image == null) return;
    if (!context.mounted) return;
    
    final pendingComplaints = appState.complaints.where((c) => c.status != ComplaintStatus.resolved && c.wardName == appState.currentUser?.wardName).toList();
    
    if (pendingComplaints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No pending complaints to resolve.')));
      return;
    }
    
    Complaint? selectedComplaint;
    
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Resolve Complaint', style: AppStyles.sectionTitle),
                    const SizedBox(height: 12),
                    Text('Select a complaint to attach this photo and resolve.', style: AppStyles.body),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Complaint>(
                          isExpanded: true,
                          hint: const Text('Select Complaint', style: AppStyles.body),
                          value: selectedComplaint,
                          items: pendingComplaints.map((c) {
                            return DropdownMenuItem(
                              value: c,
                              child: Text('${c.category} - ${c.id.substring(0,5)}', overflow: TextOverflow.ellipsis, style: AppStyles.body.copyWith(fontWeight: FontWeight.w600)),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => selectedComplaint = val),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16)),
                              child: Text('Cancel', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: selectedComplaint == null ? null : () {
                              appState.updateComplaintStatus(selectedComplaint!.id, ComplaintStatus.resolved, resolvedImageUrl: image.path);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Complaint #${selectedComplaint!.id.substring(0, 5)} resolved!')));
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))]),
                              child: const Text('Resolve', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildTopAppBar(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 120),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeCard(context),
                  const SizedBox(height: 24),
                  _buildAlertStrip(context),
                  const SizedBox(height: 32),
                  const SizedBox(height: 32),
                  Text(l10n.overview, style: AppStyles.sectionTitle),
                  const SizedBox(height: 16),
                  _buildOverviewSection(context, l10n),
                  const SizedBox(height: 32),
                  Text(l10n.quickActions, style: AppStyles.sectionTitle),
                  const SizedBox(height: 16),
                  _buildQuickServices(context, l10n),
                  const SizedBox(height: 32),
                  Text(l10n.recentComplaints, style: AppStyles.sectionTitle),
                  const SizedBox(height: 16),
                  _buildRecentComplaints(context, l10n),
                  const SizedBox(height: 32),
                  Text(l10n.wardAtAGlance, style: AppStyles.sectionTitle),
                  const SizedBox(height: 16),
                  _buildWardAtAGlance(context, l10n),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopAppBar(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.currentUser;
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.only(top: 54, left: 24, right: 24, bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
               Scaffold.of(context).openDrawer();
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
              child: const Icon(Icons.menu_rounded, color: Color(0xFF1E293B), size: 22),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l10n.wardMemberDashboard, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Inter', color: Color(0xFF64748B), letterSpacing: 0.5)),
                Text(user?.wardName ?? l10n.ward, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Inter', color: AppColors.primary)),
              ],
            ),
          ),
          const NotificationBell(color: Color(0xFF1E293B)),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminProfileScreen())),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryLight, width: 2),
              ),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.background,
                backgroundImage: user?.profilePhotoUrl != null && user!.profilePhotoUrl!.isNotEmpty
                    ? (user.profilePhotoUrl!.startsWith('http') || kIsWeb
                        ? NetworkImage(user.profilePhotoUrl!) as ImageProvider
                        : FileImage(File(user.profilePhotoUrl!)))
                    : null,
                child: (user?.profilePhotoUrl == null || user!.profilePhotoUrl!.isEmpty)
                    ? const Icon(Icons.person, color: AppColors.primary)
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.currentUser;
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.welcomeBack, style: AppStyles.body.copyWith(color: AppColors.primaryLight)),
                    const SizedBox(height: 4),
                    Text(user?.name ?? 'Officer Name', style: AppStyles.heading.copyWith(color: Colors.white, fontSize: 24)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: 0.2))),
                      child: Text('Ward Member - ${user?.wardName ?? "Ward"}', style: AppStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.phone, color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Text(user?.phoneNumber ?? 'N/A', style: AppStyles.caption.copyWith(color: Colors.white70)),
                      ],
                    )
                  ],
                ),
              ),
              Container(
                width: 70, height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 3),
                ),
                child: CircleAvatar(
                  radius: 35,
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage: user?.profilePhotoUrl != null && user!.profilePhotoUrl!.isNotEmpty
                      ? (user.profilePhotoUrl!.startsWith('http') || kIsWeb
                          ? NetworkImage(user.profilePhotoUrl!) as ImageProvider
                          : FileImage(File(user.profilePhotoUrl!)))
                      : null,
                  child: (user?.profilePhotoUrl == null || user!.profilePhotoUrl!.isEmpty)
                      ? const Icon(Icons.person, color: AppColors.primary, size: 35)
                      : null,
                ),
              ),
            ],
          ),
          Positioned(
            right: -10, top: -40,
            child: Icon(Icons.circle, size: 100, color: Colors.white.withValues(alpha: 0.05)),
          ),
          Positioned(
            left: 50, bottom: -50,
            child: Icon(Icons.circle, size: 80, color: Colors.white.withValues(alpha: 0.05)),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertStrip(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: onNavigateToComplaints,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.danger.withValues(alpha: 0.2))),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
              child: const Icon(Icons.priority_high, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(l10n.pendingApprovalsUrgent, style: AppStyles.caption.copyWith(color: AppColors.danger, fontWeight: FontWeight.w700))),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.danger),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewSection(BuildContext context, AppLocalizations l10n) {
    final appState = Provider.of<AppState>(context);
    final myWardName = appState.currentUser?.wardName ?? '';
    final allComplaints = appState.complaints.where((c) => c.wardName == myWardName).toList();
    
    final total = allComplaints.length;
    final resolved = allComplaints.where((c) => c.status == ComplaintStatus.resolved).length;
    final pending = allComplaints.where((c) => c.status == ComplaintStatus.submitted).length;
    final inReview = allComplaints.where((c) => c.status == ComplaintStatus.inProgress).length;
    
    final completedToday = allComplaints.where((c) => c.status == ComplaintStatus.resolved && c.resolvedAt != null && c.resolvedAt!.day == DateTime.now().day).length;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.15,
      children: [
        _buildStatCard(l10n.total, total.toString(), '+${completedToday > 0 ? completedToday : 1}', AppColors.primary, Icons.assignment_outlined),
        _buildStatCard(l10n.resolved, resolved.toString(), '+${completedToday > 0 ? completedToday : 2}', AppColors.success, Icons.check_circle_outline),
        _buildStatCard(l10n.pending, pending.toString(), '-1', AppColors.warning, Icons.pending_actions),
        _buildStatCard(l10n.inReview, inReview.toString(), '+0', AppColors.info, Icons.rate_review_outlined),
      ],
    );
  }

  Widget _buildStatCard(String title, String count, String growth, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                child: Icon(icon, color: color, size: 24),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(growth, style: AppStyles.caption.copyWith(color: AppColors.success, fontWeight: FontWeight.w800, fontSize: 11)),
              )
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(count, style: AppStyles.heading.copyWith(fontSize: 28)),
              const SizedBox(height: 2),
              Text(title, style: AppStyles.caption),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentComplaints(BuildContext context, AppLocalizations l10n) {
    final appState = Provider.of<AppState>(context);
    final myWardName = appState.currentUser?.wardName ?? '';
    final complaints = appState.complaints.where((c) => c.wardName == myWardName).toList();
    complaints.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final recentComplaints = complaints.take(3).toList();

    if (recentComplaints.isEmpty) {
      return Center(child: Text(l10n.noComplaintsYet, style: AppStyles.body.copyWith(color: const Color(0xFF94A3B8))));
    }

    return Column(
      children: recentComplaints.map((c) {
        Color badgeColor = AppColors.warning;
        if (c.status == ComplaintStatus.resolved) badgeColor = AppColors.success;
        if (c.status == ComplaintStatus.inProgress) badgeColor = AppColors.info;
        
        return GestureDetector(
          onTap: () => ComplaintDetailsModal.show(context, c, appState.isTelugu),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                  child: Icon(Icons.assignment_outlined, color: badgeColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.category, style: AppStyles.sectionTitle.copyWith(fontSize: 16, color: const Color(0xFF1E293B))),
                      const SizedBox(height: 4),
                      Text('ID: ${c.id.substring(0, 8).toUpperCase()}', style: AppStyles.caption.copyWith(fontFamily: 'monospace', color: const Color(0xFF94A3B8))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                  child: Text(c.status.name.toUpperCase(), style: AppStyles.caption.copyWith(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 10)),
                )
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuickServices(BuildContext context, AppLocalizations l10n) {
    final appState = Provider.of<AppState>(context, listen: false);
    final services = [
      {'icon': Icons.add_a_photo, 'title': l10n.uploadWork, 'color1': const Color(0xFF60A5FA), 'color2': const Color(0xFF2563EB), 'action': () => _handleUploadWork(context, appState)},
      {'icon': Icons.campaign, 'title': l10n.broadcast, 'color1': const Color(0xFF34D399), 'color2': const Color(0xFF059669), 'action': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateAnnouncementScreen()))},
      {'icon': Icons.update, 'title': l10n.wardUpdates, 'color1': const Color(0xFFFBBF24), 'color2': const Color(0xFFD97706), 'action': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyWardScreen()))},
      {'icon': Icons.groups, 'title': l10n.meetingsEvents.split(' ').first, 'color1': const Color(0xFFA78BFA), 'color2': const Color(0xFF7C3AED), 'action': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MeetingsListScreen()))},
      {'icon': Icons.construction, 'title': l10n.developmentWorks, 'color1': const Color(0xFF2DD4BF), 'color2': const Color(0xFF0D9488), 'action': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyWardScreen()))},
      {'icon': Icons.contacts, 'title': l10n.citizens, 'color1': const Color(0xFFF87171), 'color2': const Color(0xFFDC2626), 'action': () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming Soon')))},
      {'icon': Icons.how_to_vote, 'title': l10n.polling, 'color1': const Color(0xFF818CF8), 'color2': const Color(0xFF4F46E5), 'action': () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming Soon')))},
      {'icon': Icons.list_alt, 'title': l10n.taskList, 'color1': const Color(0xFFF472B6), 'color2': const Color(0xFFDB2777), 'action': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminTasksScreen()))},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final s = services[index];
        return GestureDetector(
          onTap: s['action'] as VoidCallback,
          child: Column(
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [s['color1'] as Color, s['color2'] as Color], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [BoxShadow(color: (s['color2'] as Color).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))],
                ),
                child: Icon(s['icon'] as IconData, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 10),
              Text(s['title'] as String, style: AppStyles.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF334155), height: 1.2), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWardAtAGlance(BuildContext context, AppLocalizations l10n) {
    final appState = Provider.of<AppState>(context);
    final broadcasts = appState.broadcasts.where((b) => b.wardId == appState.currentUser?.wardName || b.wardId == 'global').length;
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildGlanceCard(l10n.broadcast, broadcasts.toString(), Icons.campaign_outlined, AppColors.primary)),
            const SizedBox(width: 16),
            Expanded(child: _buildGlanceCard(l10n.population, '12,800', Icons.people_outline, AppColors.warning)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildGlanceCard(l10n.voters, '8,400', Icons.how_to_vote_outlined, AppColors.success)),
            const SizedBox(width: 16),
            Expanded(child: _buildGlanceCard(l10n.pollingBooths, '14', Icons.how_to_vote_outlined, AppColors.info)),
          ],
        ),
      ],
    );
  }

  Widget _buildGlanceCard(String title, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(count, style: AppStyles.heading.copyWith(fontSize: 24)),
          const SizedBox(height: 4),
          Text(title, style: AppStyles.caption),
        ],
      ),
    );
  }
}

class AdminComplaintsTab extends StatefulWidget {
  const AdminComplaintsTab({super.key});

  @override
  State<AdminComplaintsTab> createState() => _AdminComplaintsTabState();
}

class _AdminComplaintsTabState extends State<AdminComplaintsTab> {
  String _selectedStatus = 'All';
  final List<String> _statuses = ['All', 'Pending', 'In Review', 'Resolved'];

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final myWardName = appState.currentUser?.wardName ?? '';
    var complaints = appState.complaints.where((c) => c.wardName == myWardName).toList();
    
    if (_selectedStatus == 'Pending') {
      complaints = complaints.where((c) => c.status == ComplaintStatus.submitted).toList();
    } else if (_selectedStatus == 'In Review') {
      complaints = complaints.where((c) => c.status == ComplaintStatus.inProgress).toList();
    } else if (_selectedStatus == 'Resolved') {
      complaints = complaints.where((c) => c.status == ComplaintStatus.resolved).toList();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Column(
            children: [
              _buildPremiumHeader('Complaints', icon: Icons.assignment_outlined),
              Expanded(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.border), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 4))]),
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Search by ID or Category...',
                                  hintStyle: AppStyles.body.copyWith(color: const Color(0xFF94A3B8)),
                                  border: InputBorder.none,
                                  icon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))]),
                            child: const Icon(Icons.tune, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 48,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _statuses.length,
                        itemBuilder: (context, index) {
                          final status = _statuses[index];
                          final isSelected = status == _selectedStatus;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedStatus = status),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                                boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
                              ),
                              child: Center(
                                child: Text(status, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF64748B), fontWeight: FontWeight.bold, fontFamily: 'Inter')),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: complaints.isEmpty
                          ? Center(child: Text('No Complaints Found', style: AppStyles.body.copyWith(color: const Color(0xFF94A3B8))))
                          : ListView.builder(
                              padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 120),
                              physics: const BouncingScrollPhysics(),
                              itemCount: complaints.length,
                              itemBuilder: (context, index) {
                                final c = complaints[index];
                                Color badgeColor = AppColors.warning;
                                if (c.status == ComplaintStatus.resolved) badgeColor = AppColors.success;
                                if (c.status == ComplaintStatus.inProgress) badgeColor = AppColors.info;
                                
                                return GestureDetector(
                                  onTap: () => ComplaintDetailsModal.show(context, c, appState.isTelugu),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(color: AppColors.border),
                                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 8))],
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                                          child: Icon(Icons.assignment_outlined, color: badgeColor, size: 28),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(c.category, style: AppStyles.sectionTitle.copyWith(fontSize: 18, color: const Color(0xFF1E293B))),
                                              const SizedBox(height: 6),
                                              Text('ID: ${c.id.substring(0, 8).toUpperCase()}', style: AppStyles.caption.copyWith(fontFamily: 'monospace', color: const Color(0xFF94A3B8))),
                                              const SizedBox(height: 12),
                                              Row(
                                                children: [
                                                  const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF94A3B8)),
                                                  const SizedBox(width: 4),
                                                  Expanded(child: Text(c.wardName, style: AppStyles.caption, overflow: TextOverflow.ellipsis)),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                                          child: Text(c.status.name.toUpperCase(), style: AppStyles.caption.copyWith(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5)),
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AdminServicesTab extends StatelessWidget {
  const AdminServicesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final services = [
      {'title': 'Water Supply', 'count': '1,240', 'icon': Icons.water_drop_outlined, 'color': Colors.blue},
      {'title': 'Sanitation', 'count': '850', 'icon': Icons.cleaning_services_outlined, 'color': Colors.green},
      {'title': 'Street Lights', 'count': '420', 'icon': Icons.lightbulb_outline, 'color': Colors.orange},
      {'title': 'Road Repair', 'count': '310', 'icon': Icons.add_road, 'color': Colors.brown},
      {'title': 'Public Parks', 'count': '150', 'icon': Icons.park_outlined, 'color': Colors.teal},
      {'title': 'Health Centers', 'count': '95', 'icon': Icons.local_hospital_outlined, 'color': Colors.red},
      {'title': 'Schools', 'count': '210', 'icon': Icons.school_outlined, 'color': Colors.indigo},
      {'title': 'Waste Mgt', 'count': '630', 'icon': Icons.delete_outline, 'color': Colors.blueGrey},
      {'title': 'Drainage', 'count': '480', 'icon': Icons.waves, 'color': Colors.cyan},
      {'title': 'Electricity', 'count': '520', 'icon': Icons.electrical_services_outlined, 'color': Colors.amber},
      {'title': 'Certificates', 'count': '1,120', 'icon': Icons.description_outlined, 'color': Colors.purple},
      {'title': 'Pension', 'count': '890', 'icon': Icons.elderly, 'color': Colors.pink},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildPremiumHeader('Services', icon: Icons.grid_view_outlined),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 120),
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: services.length,
              itemBuilder: (context, index) {
                final s = services[index];
                final color = s['color'] as Color;
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 6))],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                        child: Icon(s['icon'] as IconData, color: color, size: 28),
                      ),
                      const SizedBox(height: 12),
                      Text(s['title'] as String, style: AppStyles.caption.copyWith(fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)), textAlign: TextAlign.center),
                      const SizedBox(height: 4),
                      Text('${s['count']} Req', style: AppStyles.caption.copyWith(fontSize: 10, color: const Color(0xFF94A3B8))),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AdminPollingTab extends StatelessWidget {
  const AdminPollingTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildPremiumHeader('Polling Dashboard', icon: Icons.how_to_vote_outlined),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 120),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildPollStat('Total Voters', '8,400', AppColors.primary)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildPollStat('Booths', '14', AppColors.info)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildPollStat('Turnout', '72%', AppColors.success)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 8))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Party Summary', style: AppStyles.sectionTitle),
                        const SizedBox(height: 24),
                        _buildPartyRow('Party A', 45, AppColors.primary),
                        const SizedBox(height: 16),
                        _buildPartyRow('Party B', 35, AppColors.warning),
                        const SizedBox(height: 16),
                        _buildPartyRow('Party C', 15, AppColors.success),
                        const SizedBox(height: 16),
                        _buildPartyRow('Others', 5, const Color(0xFF94A3B8)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text('Quick Actions', style: AppStyles.sectionTitle),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 6))],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.download, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text('Export', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Inter')),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.border),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 6))],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.list_alt, color: AppColors.primary, size: 20),
                              SizedBox(width: 8),
                              Text('Directory', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Inter')),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPollStat(String title, String count, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(24), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Column(
        children: [
          Text(count, style: AppStyles.heading.copyWith(color: color, fontSize: 24)),
          const SizedBox(height: 8),
          Text(title, style: AppStyles.caption.copyWith(color: color, fontWeight: FontWeight.w800, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildPartyRow(String name, int percent, Color color) {
    return Row(
      children: [
        SizedBox(width: 60, child: Text(name, style: AppStyles.body.copyWith(fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)))),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            height: 12,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                Expanded(
                  flex: percent,
                  child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10))),
                ),
                Expanded(flex: 100 - percent, child: const SizedBox()),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(width: 45, child: Text('$percent%', style: AppStyles.caption.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF64748B)), textAlign: TextAlign.right)),
      ],
    );
  }
}

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.currentUser;
    final l10n = AppLocalizations.of(context)!;
    
    return Drawer(
      backgroundColor: AppColors.background,
      child: Column(
        children: [
          _buildDrawerHeader(context, user, appState, l10n),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    _buildDrawerItem(context, l10n.dashboard, Icons.home_rounded, () => Navigator.pop(context)),
                    _buildDrawerItem(context, l10n.meetingsEvents, Icons.groups, () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const MeetingsListScreen()));
                    }),
                    _buildDrawerItem(context, l10n.tasksFollowUps, Icons.task_alt, () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminTasksScreen()));
                    }),
                    _buildDrawerItem(context, l10n.broadcastCenter, Icons.campaign, () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const BroadcastHistoryScreen()));
                    }),
                    _buildDrawerItem(context, l10n.reportsAnalytics, Icons.analytics, () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminReportsScreen()));
                    }),
                    _buildDrawerItem(context, l10n.developmentWorks, Icons.construction, () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const MyWardScreen()));
                    }),
                    _buildDrawerItem(context, l10n.officerDirectory, Icons.badge, () {
                      Navigator.pop(context);
                    }),
                    _buildDrawerItem(context, l10n.notifications, Icons.notifications, () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                    }),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(color: AppColors.border),
                    ),
                    _buildDrawerItem(context, l10n.language, Icons.translate, () {
                      appState.setLanguage(!appState.isTelugu);
                    }),
                    _buildDrawerItem(context, l10n.settings, Icons.settings, () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminProfileScreen()));
                    }),
                    _buildDrawerItem(context, l10n.helpSupport, Icons.support_agent, () {
                      Navigator.pop(context);
                    }),
                    _buildDrawerItem(context, l10n.privacyPolicy, Icons.shield, () {
                      Navigator.pop(context);
                    }),
                    _buildDrawerItem(context, l10n.logout, Icons.logout, () {
                      Navigator.pop(context);
                      appState.logout();
                    }, isDanger: true),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context, dynamic user, AppState appState, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 3),
                ),
                child: CircleAvatar(
                  radius: 35,
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage: user?.profilePhotoUrl != null && user!.profilePhotoUrl!.isNotEmpty
                      ? (user.profilePhotoUrl!.startsWith('http') || kIsWeb
                          ? NetworkImage(user.profilePhotoUrl!) as ImageProvider
                          : FileImage(File(user.profilePhotoUrl!)))
                      : null,
                  child: (user?.profilePhotoUrl == null || user!.profilePhotoUrl!.isEmpty)
                      ? const Icon(Icons.person, color: AppColors.primary, size: 35)
                      : null,
                ),
              ),
              _buildLanguageToggle(appState, l10n),
            ],
          ),
          const SizedBox(height: 20),
          Text(user?.name ?? 'Officer Name', style: AppStyles.heading.copyWith(color: Colors.white, fontSize: 22)),
          const SizedBox(height: 4),
          Text(user?.phoneNumber ?? 'Phone', style: AppStyles.body.copyWith(color: Colors.white70)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: 0.2))),
            child: Text('${l10n.wardMember} - ${user?.wardName ?? l10n.ward}', style: AppStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageToggle(AppState appState, AppLocalizations l10n) {
    final isTelugu = appState.isTelugu;
    return GestureDetector(
      onTap: () => appState.setLanguage(!isTelugu),
      child: Container(
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: 0.2))),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLangPill('EN', !isTelugu),
            _buildLangPill('తెలుగు', isTelugu),
          ],
        ),
      ),
    );
  }

  Widget _buildLangPill(String text, bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(text, style: TextStyle(color: isActive ? AppColors.primary : Colors.white70, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Inter')),
    );
  }

  Widget _buildDrawerItem(BuildContext context, String title, IconData icon, VoidCallback onTap, {bool isDanger = false}) {
    final color = isDanger ? AppColors.danger : const Color(0xFF1E293B);
    final bgColor = isDanger ? AppColors.danger.withValues(alpha: 0.1) : Colors.transparent;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tileColor: bgColor,
        leading: Icon(icon, color: isDanger ? AppColors.danger : const Color(0xFF64748B), size: 24),
        title: Text(title, style: AppStyles.body.copyWith(fontWeight: FontWeight.w600, color: color)),
        trailing: isDanger ? null : const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 20),
      ),
    );
  }
}

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reports & Analytics', style: AppStyles.sectionTitle),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: AppColors.border),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 8))],
              ),
              child: Column(
                children: [
                  const Text('Complaint Distribution', style: AppStyles.sectionTitle),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 220,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 4,
                        centerSpaceRadius: 60,
                        sections: [
                          PieChartSectionData(color: AppColors.success, value: 45, title: '45%', radius: 35, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          PieChartSectionData(color: AppColors.warning, value: 30, title: '30%', radius: 35, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          PieChartSectionData(color: AppColors.info, value: 25, title: '25%', radius: 35, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegend('Resolved', AppColors.success),
                      const SizedBox(width: 20),
                      _buildLegend('Pending', AppColors.warning),
                      const SizedBox(width: 20),
                      _buildLegend('In Review', AppColors.info),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(width: 14, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 8),
        Text(label, style: AppStyles.caption.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class AdminTasksScreen extends StatelessWidget {
  const AdminTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tasks', style: AppStyles.sectionTitle),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
      ),
      body: Center(child: Text('Tasks & Follow Ups Screen', style: AppStyles.body.copyWith(color: const Color(0xFF94A3B8)))),
    );
  }
}

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  Future<void> _pickImage() async {
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final userId = appState.currentUser?.id ?? 'user';
      final name = appState.currentUser?.name ?? '';
      final phone = appState.currentUser?.phoneNumber ?? '';

      final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (pickedFile != null) {
        String finalPath = pickedFile.path;
        
        if (!kIsWeb) {
          final appDir = await getApplicationDocumentsDirectory();
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final destPath = '${appDir.path}/profile_${userId}_$timestamp.jpg';
          final destFile = await File(pickedFile.path).copy(destPath);
          finalPath = destFile.path;
        }
        
        setState(() => _isSaving = true);
        await appState.updateUserProfile(name, phone, finalPath);
        setState(() => _isSaving = false);

        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.profileUpdated), backgroundColor: AppColors.primary),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking profile image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.currentUser;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.profile, style: AppStyles.sectionTitle),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: AppColors.border),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 8))],
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.primaryLight, width: 4)),
                        child: CircleAvatar(
                          radius: 56,
                          backgroundColor: AppColors.background,
                          backgroundImage: user?.profilePhotoUrl != null && user!.profilePhotoUrl!.isNotEmpty
                              ? (user.profilePhotoUrl!.startsWith('http') || kIsWeb
                                  ? NetworkImage(user.profilePhotoUrl!) as ImageProvider
                                  : FileImage(File(user.profilePhotoUrl!)))
                              : null,
                          child: (user?.profilePhotoUrl == null || user!.profilePhotoUrl!.isEmpty)
                              ? const Icon(Icons.person, size: 56, color: AppColors.primary)
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 4))],
                            ),
                            child: _isSaving 
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(user?.name ?? 'Officer Name', style: AppStyles.heading.copyWith(fontSize: 26)),
                  const SizedBox(height: 8),
                  Text('${l10n.wardMember} - ${user?.wardName ?? l10n.ward}', style: AppStyles.body.copyWith(color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
                  const SizedBox(height: 32),
                  Container(height: 1, color: AppColors.border),
                  const SizedBox(height: 32),
                  _buildProfileRow(Icons.phone_outlined, l10n.phoneNumber, user?.phoneNumber ?? ''),
                  const SizedBox(height: 16),
                  _buildProfileRow(Icons.location_on_outlined, l10n.ward, user?.wardName ?? ''),
                  const SizedBox(height: 16),
                  _buildProfileRow(Icons.account_balance_outlined, l10n.departmentPerformance, 'Ward Secretariat'), // Default dept
                  const SizedBox(height: 24),
                  _buildActionTile(context, l10n.editProfile, Icons.edit, () {}),
                  _buildActionTile(context, l10n.changePassword, Icons.lock_outline, () {}),
                  _buildActionTile(context, l10n.notificationSettings, Icons.notifications_active_outlined, () {}),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.translate, color: Color(0xFF64748B)),
                            const SizedBox(width: 16),
                            Text(l10n.language, style: AppStyles.body.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Switch(
                          value: appState.isTelugu,
                          activeColor: AppColors.primary,
                          onChanged: (val) => appState.setLanguage(val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context); // Optional, but usually profile handles it
                      appState.logout();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
                      ),
                      alignment: Alignment.center,
                      child: Text(l10n.logout, style: AppStyles.body.copyWith(color: AppColors.danger, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: const Color(0xFF94A3B8))),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppStyles.caption.copyWith(color: const Color(0xFF94A3B8))),
            const SizedBox(height: 4),
            Text(value, style: AppStyles.body.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
          ],
        ),
      ],
    );
  }

  Widget _buildActionTile(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF64748B)),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: AppStyles.body.copyWith(fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)))),
            const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}
