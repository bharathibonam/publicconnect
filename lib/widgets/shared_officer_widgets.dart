import 'package:intl/intl.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/complaint.dart';
import '../models/user.dart';
import '../themes/party_theme_config.dart';
import '../utils/mandal_mapping.dart';
import '../screens/chat_screen.dart';
import '../screens/ward_admin/create_work_update_screen.dart';
import '../utils/category_mapping.dart';

class OfficerAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String subtitle;
  final bool showLanguageToggle;
  final bool showNotification;
  final VoidCallback? onLanguageToggle;
  final bool isTelugu;
  final Widget? trailingWidget;
  final VoidCallback? onProfileTap;
  final bool centerTitle;

  const OfficerAppBar({
    super.key,
    required this.title,
    required this.subtitle,
    this.showLanguageToggle = true,
    this.showNotification = true,
    this.onLanguageToggle,
    required this.isTelugu,
    this.trailingWidget,
    this.onProfileTap,
    this.centerTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    // Build the language toggle widget as request: only see Telugu / EN simple button
    Widget? leadingWidget;
    if (showLanguageToggle) {
      leadingWidget = GestureDetector(
        onTap: () {
          if (onLanguageToggle != null) {
            onLanguageToggle!();
          } else {
            appState.setLanguage(!appState.isTelugu);
          }
        },
        child: Container(
          margin: const EdgeInsets.only(left: 12, top: 12, bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
          ),
          alignment: Alignment.center,
          child: Text(
            isTelugu ? 'EN' : 'తెలుగు',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ),
      );
    } else if (onProfileTap != null) {
      leadingWidget = Padding(
        padding: const EdgeInsets.all(8.0),
        child: GestureDetector(
          onTap: onProfileTap,
          child: CircleAvatar(
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            backgroundImage: appState.currentUser?.profilePhotoUrl != null && appState.currentUser!.profilePhotoUrl!.isNotEmpty
                ? (appState.currentUser!.profilePhotoUrl!.startsWith('http') || kIsWeb
                    ? NetworkImage(appState.currentUser!.profilePhotoUrl!) as ImageProvider
                    : FileImage(File(appState.currentUser!.profilePhotoUrl!)))
                : null,
            child: (appState.currentUser?.profilePhotoUrl == null || appState.currentUser!.profilePhotoUrl!.isEmpty)
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          ),
        ),
      );
    }

    return AppBar(
      centerTitle: centerTitle,
      elevation: 0,
      backgroundColor: Colors.transparent,
      leadingWidth: showLanguageToggle ? 75 : 56,
      leading: leadingWidget,
      title: Column(
        crossAxisAlignment: centerTitle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle.isNotEmpty)
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      actions: [
        if (showNotification)
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {
              // Notifications
            },
          ),
        ...?trailingWidget == null ? null : [trailingWidget!],
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// For backward compatibility
typedef PartyThemedAppBar = OfficerAppBar;

class OfficerProfileCard extends StatelessWidget {
  final User? user;
  final String location;
  final String? roleBadge;
  final PartyThemeConfig themeConfig;
  final VoidCallback? onProfileTap;

  const OfficerProfileCard({
    super.key,
    required this.user,
    required this.location,
    this.roleBadge,
    required this.themeConfig,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            GestureDetector(
              onTap: onProfileTap,
              child: CircleAvatar(
                radius: 30,
                backgroundColor: themeConfig.primaryColor.withValues(alpha: 0.1),
                backgroundImage: user?.profilePhotoUrl != null && user!.profilePhotoUrl!.isNotEmpty
                    ? (user!.profilePhotoUrl!.startsWith('http') || kIsWeb
                        ? NetworkImage(user!.profilePhotoUrl!) as ImageProvider
                        : FileImage(File(user!.profilePhotoUrl!)))
                    : null,
                child: (user?.profilePhotoUrl == null || user!.profilePhotoUrl!.isEmpty)
                    ? Icon(Icons.person, size: 30, color: themeConfig.primaryColor)
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.name ?? 'Officer Name',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (roleBadge != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: themeConfig.accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: themeConfig.accentColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        roleBadge!,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: themeConfig.accentColor),
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InlineStatRow extends StatelessWidget {
  final int total;
  final int resolved;
  final int pending;
  final int inReview;
  final bool isTelugu;
  final PartyThemeConfig themeConfig;

  const InlineStatRow({
    super.key,
    required this.total,
    required this.resolved,
    required this.pending,
    required this.inReview,
    required this.isTelugu,
    required this.themeConfig,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem(Icons.group, isTelugu ? 'మొత్తం' : 'Total', total, themeConfig.primaryColor),
            _buildStatItem(Icons.check_circle, isTelugu ? 'పరిష్కారం' : 'Resolved', resolved, Colors.green),
            _buildStatItem(Icons.hourglass_empty, isTelugu ? 'పెండింగ్' : 'Pending', pending, Colors.red),
            _buildStatItem(Icons.autorenew, isTelugu ? 'పరిశీలనలో' : 'In Review', inReview, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, int value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '$value',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}

class ServiceStatusGrid extends StatelessWidget {
  final Map<String, double> departmentStats;
  final bool isTelugu;
  final PartyThemeConfig themeConfig;

  const ServiceStatusGrid({
    super.key,
    required this.departmentStats,
    required this.isTelugu,
    required this.themeConfig,
  });

  @override
  Widget build(BuildContext context) {
    final defaultStats = {
      'Water Supply': departmentStats['Water Supply'] ?? 0.0,
      'Electricity': departmentStats['Electricity'] ?? 0.0,
      'Roads & Infrastructure': departmentStats['Roads & Infrastructure'] ?? 0.0,
      'Sanitation': departmentStats['Sanitation'] ?? 0.0,
    };

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGridItem(Icons.water_drop, isTelugu ? 'తాగునీరు' : 'Water Supply', defaultStats['Water Supply']!, themeConfig),
            _buildGridItem(Icons.electric_bolt, isTelugu ? 'విద్యుత్' : 'Electricity', defaultStats['Electricity']!, themeConfig),
            _buildGridItem(Icons.add_road, isTelugu ? 'రోడ్లు & మార్గాలు' : 'Roads & Infra', defaultStats['Roads & Infrastructure']!, themeConfig),
            _buildGridItem(Icons.cleaning_services, isTelugu ? 'పరిశుభత' : 'Sanitation', defaultStats['Sanitation']!, themeConfig),
          ],
        ),
      ),
    );
  }

  Widget _buildGridItem(IconData icon, String label, double percentage, PartyThemeConfig themeConfig) {
    Color getProgressColor() {
      if (percentage >= 80) return Colors.green.shade500;
      if (percentage >= 50) return Colors.orange.shade500;
      return Colors.red.shade500;
    }
    
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: themeConfig.primaryColor),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            '${percentage.toStringAsFixed(0)}%',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: getProgressColor()),
          ),
        ],
      ),
    );
  }
}

class ComplaintListTile extends StatelessWidget {
  final Complaint complaint;
  final VoidCallback onTap;
  final bool isTelugu;
  final bool showPriority;
  final bool showSLABadge;
  final int slaHours;

  const ComplaintListTile({
    super.key,
    required this.complaint,
    required this.onTap,
    required this.isTelugu,
    this.showPriority = false,
    this.showSLABadge = false,
    this.slaHours = 72,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final ageHours = now.difference(complaint.createdAt).inHours;
    final hoursRemaining = slaHours - ageHours;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.description_outlined, size: 20, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (showPriority) ...[
                        PriorityDot(priority: complaint.priority),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          CategoryMapping.getLocalizedCategory(context, complaint.category),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          complaint.villageName.isNotEmpty ? complaint.villageName : complaint.wardName,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '#${complaint.id.length > 8 ? complaint.id.substring(0,8) : complaint.id} • ${complaint.createdAt.day}/${complaint.createdAt.month}/${complaint.createdAt.year}',
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                      ),
                    ],
                  )
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusChip(status: complaint.status, isTelugu: isTelugu),
                if (showSLABadge && complaint.status != ComplaintStatus.resolved) ...[
                  const SizedBox(height: 6),
                  SLABadge(hoursRemaining: hoursRemaining, isTelugu: isTelugu),
                ]
              ],
            )
          ],
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final ComplaintStatus status;
  final bool isTelugu;

  const StatusChip({super.key, required this.status, required this.isTelugu});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case ComplaintStatus.submitted:
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
        label = isTelugu ? 'పెండింగ్' : 'Pending';
        break;
      case ComplaintStatus.inProgress:
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        label = isTelugu ? 'పరిశీలనలో' : 'In Review';
        break;
      case ComplaintStatus.resolved:
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        label = isTelugu ? 'పరిష్కరించినవి' : 'Resolved';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textColor),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? onViewAll;
  final VoidCallback? onTapViewAll;

  const SectionHeader({
    super.key,
    required this.title,
    this.onViewAll,
    this.onTapViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (onViewAll != null && onTapViewAll != null)
          TextButton(
            onPressed: onTapViewAll,
            child: Text(
              onViewAll!,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
            ),
          ),
      ],
    );
  }
}

class PriorityDot extends StatelessWidget {
  final ComplaintPriority priority;
  
  const PriorityDot({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (priority) {
      case ComplaintPriority.high: color = Colors.red; break;
      case ComplaintPriority.medium: color = Colors.orange; break;
      case ComplaintPriority.low: color = Colors.green; break;
    }
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class SLABadge extends StatelessWidget {
  final int hoursRemaining;
  final bool isTelugu;
  
  const SLABadge({super.key, required this.hoursRemaining, required this.isTelugu});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String label;

    if (hoursRemaining < 0) {
      bgColor = Colors.red.shade50;
      textColor = Colors.red.shade700;
      label = isTelugu ? 'గడువు మించినవి' : 'Overdue';
    } else if (hoursRemaining <= 24) {
      bgColor = Colors.red.shade50;
      textColor = Colors.red.shade700;
      label = isTelugu ? '$hoursRemaining గంటలు మిగిలివున్నవి' : '${hoursRemaining}h left';
    } else if (hoursRemaining <= 48) {
      bgColor = Colors.orange.shade50;
      textColor = Colors.orange.shade700;
      label = isTelugu ? '$hoursRemaining గంటలు మిగిలివున్నవి' : '${hoursRemaining}h left';
    } else {
      bgColor = Colors.green.shade50;
      textColor = Colors.green.shade700;
      label = isTelugu ? '$hoursRemaining గంటలు మిగిలివున్నవి' : '${hoursRemaining}h left';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: textColor),
      ),
    );
  }
}

class LoadingShimmerCard extends StatelessWidget {
  final double height;
  const LoadingShimmerCard({super.key, this.height = 100});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        // A simple visual placeholder, could add a shimmer animation package if available
      ),
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  final String message;
  final IconData icon;

  const EmptyStateWidget({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class ComplaintDetailsModal {
  // Level 5: Complaint Details Page (Modal)
  static void show(BuildContext context, Complaint c, bool isTelugu, {String? panchayat, String? mandal}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isTelugu ? 'ఫిర్యాదు వివరాలు' : 'Complaint Details',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status & Timeline Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: c.statusColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: c.statusColor.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                c.status == ComplaintStatus.resolved ? Icons.check_circle : 
                                (c.status == ComplaintStatus.inProgress ? Icons.refresh : Icons.hourglass_empty),
                                color: c.statusColor,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                c.statusText.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: c.statusColor,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                          _buildTimelineRow(
                            isTelugu ? 'సృష్టించబడిన తేదీ' : 'Created Date', 
                            DateFormat('dd MMM yyyy, hh:mm a').format(c.createdAt),
                            true,
                          ),
                          if (c.resolvedAt != null) ...[
                            const SizedBox(height: 8),
                            _buildTimelineRow(
                              isTelugu ? 'చివరి నవీకరణ' : 'Last Updated Date', 
                              DateFormat('dd MMM yyyy, hh:mm a').format(c.resolvedAt!),
                              true,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Key Information Grid
                    Text(
                      isTelugu ? 'ప్రాథమిక సమాచారం' : 'Primary Information',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(Icons.tag, isTelugu ? 'ఫిర్యాదు ID' : 'Complaint ID', c.id),
                    _buildDetailRow(Icons.category_outlined, isTelugu ? 'వర్గం' : 'Category', CategoryMapping.getLocalizedCategory(context, c.category)),
                    _buildDetailRow(Icons.person_outline, isTelugu ? 'పౌరుని పేరు' : 'Citizen Name', c.citizenName),
                    _buildDetailRow(Icons.phone_outlined, isTelugu ? 'మొబైల్ నంబర్' : 'Mobile Number', c.citizenPhone),
                    _buildDetailRow(Icons.admin_panel_settings_outlined, isTelugu ? 'కేటాయించిన అధికారి' : 'Assigned Officer', c.assignedOfficerId != null ? 'Officer ID: ${c.assignedOfficerId}' : 'Unassigned'),
                    
                    const SizedBox(height: 24),

                    // Location Grid
                    Text(
                      isTelugu ? 'స్థల వివరాలు' : 'Location Details',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(Icons.map_outlined, isTelugu ? 'వార్డు నంబర్' : 'Ward Number', c.wardName),
                    _buildDetailRow(Icons.holiday_village_outlined, isTelugu ? 'గ్రామం' : 'Village', c.villageName.trim().isEmpty ? 'Unknown' : c.villageName),
                    _buildDetailRow(Icons.account_balance_outlined, isTelugu ? 'పంచాయతీ' : 'Panchayat', panchayat ?? MandalMapping.getPanchayatForVillage(c.villageName)),
                    _buildDetailRow(Icons.public, isTelugu ? 'మండలం' : 'Mandal', mandal ?? c.mandalName),
                    _buildDetailRow(Icons.location_on_outlined, isTelugu ? 'చిరునామా' : 'Location', c.address),

                    const SizedBox(height: 24),

                    // Description
                    Text(
                      isTelugu ? 'వివరణ' : 'Description',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        c.description,
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Images
                    if (c.imageUrl != null || c.resolvedImageUrl != null) ...[
                      Text(
                        isTelugu ? 'చిత్రాలు' : 'Uploaded Images',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (c.imageUrl != null)
                            Expanded(child: SizedBox(height: 200, child: _buildImageTile(c.imageUrl!, isTelugu ? 'సమస్య సాక్ష్యం' : 'Issue Evidence'))),
                          if (c.imageUrl != null && c.resolvedImageUrl != null)
                            const SizedBox(width: 12),
                          if (c.resolvedImageUrl != null)
                            Expanded(child: SizedBox(height: 200, child: _buildImageTile(c.resolvedImageUrl!, isTelugu ? 'పరిష్కార సాక్ష్యం' : 'Resolution Evidence'))),
                        ],
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    _buildActionButtons(context, c, isTelugu),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildActionButtons(BuildContext context, Complaint c, bool isTelugu) {
    if (c.status == ComplaintStatus.resolved) return const SizedBox();

    final appState = Provider.of<AppState>(context, listen: false);
    final user = appState.currentUser;
    if (user == null) return const SizedBox();

    int requiredSlaHours = 0;
    if (user.role == UserRole.categoryOfficer) {
      requiredSlaHours = 0; // Immediate
    } else if (user.role == UserRole.wardAdmin) {
      requiredSlaHours = 24;
    } else if (user.role == UserRole.mandalOfficer) {
      requiredSlaHours = 48;
    } else if (user.role == UserRole.superAdmin) {
      requiredSlaHours = 72;
    }

    final hoursSinceCreated = DateTime.now().difference(c.createdAt).inHours;
    final canResolve = hoursSinceCreated >= requiredSlaHours;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context); // Close modal
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(complaint: c)));
                },
                icon: const Icon(Icons.chat, size: 18),
                label: Text(isTelugu ? 'చాట్' : 'Chat', style: const TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
              ),
            ),
            if (user.role != UserRole.superAdmin) ...[
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isTelugu ? 'ఫిర్యాదు ఉన్నతాధికారికి నివేదించబడింది.' : 'Complaint Escalated to higher authority.')));
                  },
                  icon: const Icon(Icons.arrow_upward, size: 18),
                  label: Text(isTelugu ? 'నివేదించండి' : 'Escalate', style: const TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                ),
              ),
            ],
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: canResolve
                    ? () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CreateWorkUpdateScreen(complaint: c),
                          ),
                        );
                      }
                    : null,
                icon: const Icon(Icons.check_circle, size: 18),
                label: Text(isTelugu ? 'పరిష్కరించండి' : 'Resolve', style: const TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
              ),
            ),
          ],
        ),
        if (!canResolve && requiredSlaHours > 0) ...[
          const SizedBox(height: 8),
          Text(
            isTelugu ? 'పరిష్కరించడానికి $requiredSlaHours గంటలు వేచి ఉండాలి' : 'Must wait $requiredSlaHours hours before resolving',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ],
    );
  }

  static Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildTimelineRow(String label, String time, bool isDone) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.bold),
        ),
        Text(
          time,
          style: const TextStyle(fontSize: 12, color: Colors.black87),
        ),
      ],
    );
  }

  static Widget _buildImageTile(String url, String label) {
    final bool isLocal = url.startsWith('local:');
    final String cleanUrl = isLocal ? url.substring(6) : url;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              color: Colors.grey.shade200,
              child: isLocal
                  ? (kIsWeb
                      ? const Icon(Icons.image_not_supported, size: 40, color: Colors.grey)
                      : Image.file(File(cleanUrl), fit: BoxFit.cover))
                  : Image.network(cleanUrl, fit: BoxFit.cover),
            ),
          ),
        ),
      ],
    );
  }
}

