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

import '../citizen/track_complaints.dart';
import '../announcements/create_announcement_screen.dart';
import '../announcements/broadcast_history_screen.dart';


class AdminNavHolder extends StatefulWidget {
  const AdminNavHolder({super.key});

  @override
  State<AdminNavHolder> createState() => _AdminNavHolderState();
}

class _AdminNavHolderState extends State<AdminNavHolder> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final themeConfig = Provider.of<ThemeProvider>(context).activeParty;
    final l10n = AppLocalizations.of(context)!;

    final List<Widget> screens = [
      const AdminDashboardTab(),
      const AdminComplaintsTab(),
      const AdminReportsTab(),
      AdminProfileTab(
        onProfileSaved: () {
          setState(() {
            _currentIndex = 0; // Go to Home tab
          });
        },
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: themeConfig.primaryColor,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard_outlined),
            activeIcon: const Icon(Icons.dashboard),
            label: l10n.home, // Or "Dashboard"
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.list_alt_outlined),
            activeIcon: const Icon(Icons.list_alt),
            label: l10n.complaint,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bar_chart_outlined),
            activeIcon: const Icon(Icons.bar_chart),
            label: l10n.reports,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: l10n.profile,
          ),
        ],
      ),
    );
  }
}

class AdminDashboardTab extends StatelessWidget {
  const AdminDashboardTab({super.key});

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      debugPrint('Could not launch $urlString');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final themeConfig = Provider.of<ThemeProvider>(context).activeParty;
    final l10n = AppLocalizations.of(context)!;
    final isTelugu = appState.isTelugu;
    final user = appState.currentUser;

    final myWardName = user?.wardName ?? '';
    final allComplaints = appState.complaints.where((c) => c.wardName == myWardName || (user?.wardId != null && c.wardId == user!.wardId)).toList();
    
    final total = allComplaints.length;
    final resolved = allComplaints.where((c) => c.status == ComplaintStatus.resolved).length;
    final pending = allComplaints.where((c) => c.status == ComplaintStatus.submitted).length;
    final inProgress = allComplaints.where((c) => c.status == ComplaintStatus.inProgress).length;
    final newComplaints = pending; // Just for labels

    // Recent requests
    final sortedComplaints = List<Complaint>.from(allComplaints)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final recentComplaints = sortedComplaints.take(5).toList();

    return Scaffold(
      backgroundColor: themeConfig.backgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [themeConfig.primaryColor, themeConfig.secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leadingWidth: 0,
            leading: const SizedBox.shrink(),
            titleSpacing: 16,
            centerTitle: false,
            title: Text(
              l10n.wardMemberDashboard,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            actions: [
              const NotificationBell(color: Colors.white),
              // Language Toggle
              Container(
                margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => appState.setLanguage(false),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 40,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: !isTelugu ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'English',
                          style: TextStyle(
                            color: !isTelugu ? themeConfig.primaryColor : Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => appState.setLanguage(true),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 40,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isTelugu ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'తెలుగు',
                          style: TextStyle(
                            color: isTelugu ? themeConfig.primaryColor : Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUrgentBanner(context, appState, 'Ward Officer', themeConfig, isTelugu, myWardName),
            OfficerProfileCard(
              user: user,
              location: isTelugu ? '$myWardName గ్రామ పంచాయతీ' : '$myWardName GP',
              roleBadge: user?.role.toString().split('.').last,
              themeConfig: themeConfig,
              onProfileTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminProfileTab(isPushed: true)));
              },
            ),
            const SizedBox(height: 24),

            // Statistics Grid (2x2)
            SectionHeader(title: l10n.wardSummary),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.5,
              children: [
                _buildStatCard(l10n.newComplaints, newComplaints, Colors.blue),
                _buildStatCard(l10n.pending, pending, Colors.orange),
                _buildStatCard(l10n.inProgress, inProgress, Colors.cyan),
                _buildStatCard(l10n.resolved, resolved, Colors.green),
              ],
            ),
            const SizedBox(height: 24),

            // Quick Actions
            SectionHeader(title: l10n.quickActions),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickActionBtn(Icons.fact_check, isTelugu ? 'ఫిర్యాదు పరిశీలన' : 'Verify Complaint', themeConfig.primaryColor, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackComplaintsScreen()));
                  }),
                  _buildQuickActionBtn(Icons.camera_alt, isTelugu ? 'ఫోటో అప్‌లోడ్' : 'Photo Upload', themeConfig.primaryColor, () {
                    _handleUploadWork(context, appState, themeConfig);
                  }),
                  _buildQuickActionBtn(Icons.assignment_turned_in, isTelugu ? 'పూర్తయిన పనులు' : 'Completed Work', themeConfig.primaryColor, () {
                    // Navigate to complaints list so they can select one to resolve
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackComplaintsScreen()));
                  }),

                  _buildQuickActionBtn(Icons.campaign, l10n.publicNotify, themeConfig.primaryColor, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateAnnouncementScreen()));
                  }),
                  _buildQuickActionBtn(Icons.history, 'Broadcast History', themeConfig.primaryColor, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const BroadcastHistoryScreen()));
                  }),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Layout for Analytics & Queue
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Analytics Donut Chart
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.complaintAnalytics, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: SizedBox(
                            height: 180,
                            child: total == 0 
                                ? Center(child: Text(l10n.noComplaints, style: const TextStyle(fontSize: 12, color: Colors.grey)))
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            PieChart(
                                              PieChartData(
                                                sectionsSpace: 2,
                                                centerSpaceRadius: 35,
                                                sections: [
                                                  PieChartSectionData(color: Colors.green, value: resolved.toDouble(), showTitle: false, radius: 14),
                                                  PieChartSectionData(color: Colors.cyan, value: inProgress.toDouble(), showTitle: false, radius: 14),
                                                  PieChartSectionData(color: Colors.orange, value: pending.toDouble(), showTitle: false, radius: 14),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(isTelugu ? 'మొత్తం' : 'Total', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                                Text('$total', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                              ],
                                            )
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _buildLegend(l10n.resolved, Colors.green, resolved, total),
                                          const SizedBox(height: 2),
                                          _buildLegend(l10n.inProgress, Colors.cyan, inProgress, total),
                                          const SizedBox(height: 2),
                                          _buildLegend(l10n.pending, Colors.orange, pending, total),
                                        ],
                                      )
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Today's Queue
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isTelugu ? 'ఇటీవలి సమస్యలు' : 'Recent Problems', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: SizedBox(
                            height: 180,
                            child: recentComplaints.isEmpty
                                ? Center(child: Text(l10n.noComplaints, style: const TextStyle(fontSize: 12, color: Colors.grey)))
                                : ListView.builder(
                                    itemCount: recentComplaints.length,
                                    itemBuilder: (context, index) {
                                      final c = recentComplaints[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 8.0),
                                        child: Row(
                                          children: [
                                            Icon(Icons.circle, size: 8, color: themeConfig.primaryColor),
                                            const SizedBox(width: 8),
                                            Expanded(child: Text(c.category, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recent Activities Timeline
            SectionHeader(title: l10n.recentActivityTimeline),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: allComplaints.isEmpty 
                  ? Center(child: Text(l10n.noComplaints, style: const TextStyle(fontSize: 12, color: Colors.grey)))
                  : Column(
                      children: allComplaints.take(3).map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                Icon(Icons.circle, size: 10, color: themeConfig.primaryColor),
                                Container(width: 2, height: 30, color: Colors.grey.shade300),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${l10n.complaint} #${c.id.substring(0, 5)} updated', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text('${c.category} - ${c.status.name}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                            )
                          ],
                        ),
                      )).toList(),
                    ),
              ),
            ),
            const SizedBox(height: 24),

            // Work Updates Summary
            SectionHeader(title: isTelugu ? 'పూర్తయిన పనుల సారాంశం' : 'Completed Work Summary'),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Builder(
                  builder: (context) {
                    final allWorkUpdates = appState.workUpdates.where((w) => w.wardName == myWardName).toList();
                    final thisMonth = allWorkUpdates.where((w) => w.createdAt.month == DateTime.now().month && w.createdAt.year == DateTime.now().year).length;
                    final lastPublished = allWorkUpdates.isNotEmpty ? '${allWorkUpdates.first.createdAt.day}/${allWorkUpdates.first.createdAt.month}/${allWorkUpdates.first.createdAt.year}' : 'N/A';
                    return Column(
                      children: [
                        _buildInfoRow(Icons.check_circle, isTelugu ? 'మొత్తం పనులు' : 'Total Work Updates', '${allWorkUpdates.length}', themeConfig.primaryColor),
                        const Divider(height: 24),
                        _buildInfoRow(Icons.calendar_today, isTelugu ? 'ఈ నెల పనులు' : 'This Month', '$thisMonth', themeConfig.primaryColor),
                        const Divider(height: 24),
                        _buildInfoRow(Icons.history, isTelugu ? 'చివరి ప్రచురణ' : 'Last Published', lastPublished, themeConfig.primaryColor),
                      ],
                    );
                  }
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Ward Information
            SectionHeader(title: isTelugu ? 'వార్డు సమాచారం' : 'Ward Information'),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: themeConfig.backgroundColor,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildInfoRow(Icons.assignment, isTelugu ? 'మొత్తం ఫిర్యాదులు' : 'Total Complaints', '$total', themeConfig.primaryColor),
                    const Divider(height: 24),
                    _buildInfoRow(Icons.check_circle, isTelugu ? 'పరిష్కరించబడినవి' : 'Resolved Complaints', '$resolved', themeConfig.primaryColor),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Emergency Contacts
            SectionHeader(title: isTelugu ? 'అత్యవసర పరిచయాలు' : 'Emergency Contacts'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _launchUrl('tel:100'),
                    icon: const Icon(Icons.local_police),
                    label: Text(isTelugu ? 'పోలీస్' : 'Police', style: const TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red.shade900,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _launchUrl('tel:101'),
                    icon: const Icon(Icons.fire_truck),
                    label: Text(isTelugu ? 'అగ్నిమాపక' : 'Fire', style: const TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _launchUrl('tel:108'),
                    icon: const Icon(Icons.local_hospital),
                    label: Text(isTelugu ? 'అంబులెన్స్' : 'Ambulance', style: const TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, int value, Color color) {
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
            Text('$value', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        width: 75,
        child: Column(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(String label, Color color, int value, int total) {
    final pct = total > 0 ? (value / total * 100).toStringAsFixed(0) : '0';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 8, color: color),
        const SizedBox(width: 4),
        Text('$label ($pct%)', style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
      ],
    );
  }

  Future<void> _handleUploadWork(BuildContext context, AppState appState, PartyThemeConfig themeConfig) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt, color: themeConfig.primaryColor),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndResolve(context, appState, themeConfig, ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: themeConfig.primaryColor),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndResolve(context, appState, themeConfig, ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      }
    );
  }

  Future<void> _pickAndResolve(BuildContext context, AppState appState, PartyThemeConfig themeConfig, ImageSource source) async {
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
            return AlertDialog(
              title: const Text('Resolve Complaint'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Select a complaint to attach this photo and resolve.'),
                  const SizedBox(height: 16),
                  DropdownButton<Complaint>(
                    isExpanded: true,
                    hint: const Text('Select Complaint'),
                    value: selectedComplaint,
                    items: pendingComplaints.map((c) {
                      return DropdownMenuItem(
                        value: c,
                        child: Text('${c.category} - ${c.id.substring(0,5)}', overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => selectedComplaint = val),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: themeConfig.primaryColor),
                  onPressed: selectedComplaint == null ? null : () {
                    appState.updateComplaintStatus(selectedComplaint!.id, ComplaintStatus.resolved, resolvedImageUrl: image.path);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Complaint #${selectedComplaint!.id.substring(0, 5)} resolved!')),
                    );
                  },
                  child: const Text('Upload & Resolve'),
                ),
              ],
            );
          }
        );
      }
    );
  }
}

class AdminComplaintsTab extends StatelessWidget {
  const AdminComplaintsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final themeConfig = Provider.of<ThemeProvider>(context).activeParty;
    final l10n = AppLocalizations.of(context)!;
    final myWardName = appState.currentUser?.wardName ?? '';
    final complaints = appState.complaints.where((c) => c.wardName == myWardName).toList();

    return Scaffold(
      backgroundColor: themeConfig.backgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [themeConfig.primaryColor, themeConfig.secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: OfficerAppBar(
            title: '${l10n.complaint.toLowerCase()} $myWardName',
            subtitle: '',
            isTelugu: appState.isTelugu,
            showNotification: false,
            showLanguageToggle: false,
            centerTitle: false,
          ),
        ),
      ),
      body: complaints.isEmpty
          ? Center(child: EmptyStateWidget(message: l10n.noComplaints))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: complaints.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    color: Colors.white,
                    child: ComplaintListTile(
                      complaint: complaints[index],
                      isTelugu: appState.isTelugu,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackComplaintsScreen()));
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class AdminReportsTab extends StatelessWidget {
  const AdminReportsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final themeConfig = Provider.of<ThemeProvider>(context).activeParty;
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [themeConfig.primaryColor, themeConfig.secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: OfficerAppBar(
            title: l10n.reports,
            subtitle: '',
            isTelugu: appState.isTelugu,
            showNotification: false,
            showLanguageToggle: false,
            centerTitle: false,
          ),
        ),
      ),
      body: const Center(child: Text('Reports coming soon')),
    );
  }
}

class AdminProfileTab extends StatefulWidget {
  final VoidCallback? onProfileSaved;
  final bool isPushed;

  const AdminProfileTab({super.key, this.onProfileSaved, this.isPushed = false});

  @override
  State<AdminProfileTab> createState() => _AdminProfileTabState();
}

class _AdminProfileTabState extends State<AdminProfileTab> {
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  Future<void> _pickImage() async {
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final isTelugu = appState.isTelugu;
      final userId = appState.currentUser?.id ?? 'user';
      final name = appState.currentUser?.name ?? '';
      final phone = appState.currentUser?.phoneNumber ?? '';

      final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (pickedFile != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final destPath = '${appDir.path}/profile_${userId}_$timestamp.jpg';
        final destFile = await File(pickedFile.path).copy(destPath);
        
        setState(() => _isSaving = true);
        await appState.updateUserProfile(
          name,
          phone,
          destFile.path,
        );
        setState(() => _isSaving = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isTelugu ? 'ప్రొఫైల్ చిత్రం నవీకరించబడింది!' : 'Profile picture updated!'),
              backgroundColor: Theme.of(context).primaryColor,
            ),
          );
          if (widget.isPushed) {
            Navigator.pop(context);
          } else if (widget.onProfileSaved != null) {
            widget.onProfileSaved!();
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking profile image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final themeConfig = Provider.of<ThemeProvider>(context).activeParty;
    final user = appState.currentUser;
    final l10n = AppLocalizations.of(context)!;
    final isTelugu = appState.isTelugu;

    return Scaffold(
      backgroundColor: themeConfig.backgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [themeConfig.primaryColor, themeConfig.secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: OfficerAppBar(
            title: l10n.profile,
            subtitle: '',
            isTelugu: appState.isTelugu,
            showNotification: false,
            showLanguageToggle: false,
            centerTitle: false,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Officer Info & Profile Pic edit
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage: user?.profilePhotoUrl != null && user!.profilePhotoUrl!.isNotEmpty
                              ? (user.profilePhotoUrl!.startsWith('http') || kIsWeb
                                  ? NetworkImage(user.profilePhotoUrl!) as ImageProvider
                                  : FileImage(File(user.profilePhotoUrl!)))
                              : null,
                          child: (user?.profilePhotoUrl == null || user!.profilePhotoUrl!.isEmpty)
                              ? const Icon(Icons.person, size: 50, color: Colors.grey)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: themeConfig.primaryColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: _isSaving 
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.name ?? 'Officer Name',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isTelugu ? '${user?.wardName} గ్రామ పంచాయతీ వార్డు సభ్యులు' : 'Ward Officer - ${user?.wardName}',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const Divider(height: 32),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined, size: 20, color: Colors.grey),
                        const SizedBox(width: 12),
                        Text(user?.phoneNumber ?? '', style: const TextStyle(fontSize: 15)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeConfig.primaryColor,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                appState.logout();
              },
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildUrgentBanner(BuildContext context, AppState appState, String targetRole, PartyThemeConfig themeConfig, bool isTelugu, String myWardName) {
  final urgentComplaints = appState.complaints.where((c) {
    if (!c.isPushed || c.pushedTo != targetRole || c.status == ComplaintStatus.resolved) return false;
    return c.wardName == myWardName;
  }).toList();

  if (urgentComplaints.isEmpty) return const SizedBox();

  final count = urgentComplaints.length;

  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    child: InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (ctx) {
            return StatefulBuilder(
              builder: (ctx, setSheetState) {
                final currentList = Provider.of<AppState>(context).complaints;
                final index = currentList.indexWhere((c) => c.id == urgentComplaints.first.id);
                if (index == -1 || currentList[index].status == ComplaintStatus.resolved) {
                  return const SizedBox();
                }
                final c = currentList[index];

                return Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isTelugu ? 'అత్యవసర ఫిర్యాదు' : 'URGENT COMPLAINT',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${isTelugu ? "వర్గం" : "Category"}: ${c.category}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        c.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final picker = ImagePicker();
                          final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
                          if (picked != null) {
                            await appState.updateComplaintStatus(c.id, ComplaintStatus.resolved, resolvedImageUrl: picked.path);
                            if (context.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(isTelugu ? 'ఫిర్యాదు విజయవంతంగా పరిష్కరించబడింది!' : 'Complaint Resolved!'),
                              ));
                            }
                          }
                        },
                        icon: const Icon(Icons.camera_alt, size: 18),
                        label: Text(
                          isTelugu ? 'వెంటనే పరిష్కరించండి (ఫోటో తప్పనిసరి)' : 'Resolve Immediately (Photo Required)',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade900,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isTelugu ? 'అత్యవసర ఫిర్యాదులు: $count' : 'URGENT COMPLAINTS: $count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isTelugu 
                        ? 'అధికారి ద్వారా బదిలీ చేయబడింది. వెంటనే పరిష్కరించడానికి క్లిక్ చేయండి.' 
                        : 'Pushed by Category Officer. Click to resolve immediately.',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white, size: 20),
          ],
        ),
      ),
    ),
  );
}



