import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_demo_app/l10n/app_localizations.dart';
import '../../services/app_state.dart';
import '../../themes/theme_provider.dart';
import '../../models/complaint.dart';
import '../../utils/category_mapping.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/shared_officer_widgets.dart';
import '../citizen/track_complaints.dart';
import '../citizen/new_complaint.dart';
import '../citizen/my_ward_screen.dart';
import '../announcements/create_announcement_screen.dart';
import '../announcements/broadcast_history_screen.dart';
import 'meetings/meetings_list_screen.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class SuperDashboardHome extends StatelessWidget {
  const SuperDashboardHome({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final themeConfig = themeProvider.activeParty;
    final l10n = AppLocalizations.of(context)!;
    final isTelugu = appState.isTelugu;

    final complaints = appState.complaints;
    final total = complaints.length;
    final resolved = complaints.where((c) => c.status == ComplaintStatus.resolved).length;
    final pending = complaints.where((c) => c.status == ComplaintStatus.submitted).length;
    final inReview = complaints.where((c) => c.status == ComplaintStatus.inProgress).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
            leading: IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
            titleSpacing: 0,
            centerTitle: false,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.mlaDashboard,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  l10n.constituencySuffix(themeConfig.getLocalizedConstituencyName(context)),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
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
            _buildUrgentBanner(context, appState, 'MLA', themeConfig, isTelugu),
            Container(
              width: double.infinity,
              height: 140, // Compact height
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [themeConfig.primaryColor, themeConfig.primaryColor.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 4)),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left Content Area: Welcome Text & Name
                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            l10n.welcome,
                            style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.welcomeGaru(themeConfig.getLocalizedMlaName(context)),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.constituencySuffix(themeConfig.getLocalizedConstituencyName(context)),
                            style: const TextStyle(color: Colors.black54, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    ),
                    // Right Content Area: MLA Photo & Watermark
                    Expanded(
                      flex: 5,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(bottomRight: Radius.circular(16)),
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.bottomRight,
                          children: [
                            // Background Watermark: Party Logo
                            if (themeConfig.id == 'tdp' && themeConfig.logoUrl != null)
                              Positioned(
                                right: 0,
                                top: 10,
                                width: 90,
                                height: 90,
                                child: Opacity(
                                  opacity: 0.15,
                                  child: themeConfig.logoUrl!.startsWith('http')
                                      ? Image.network(themeConfig.logoUrl!, fit: BoxFit.contain)
                                      : Image.asset(themeConfig.logoUrl!, fit: BoxFit.contain),
                                ),
                              ),
                            // MLA Photo
                            Positioned.fill(
                              child: Align(
                                alignment: Alignment.bottomRight,
                                child: (themeConfig.mlaPhotoUrl != null && themeConfig.mlaPhotoUrl!.isNotEmpty)
                                    ? (themeConfig.mlaPhotoUrl!.startsWith('http')
                                        ? Image.network(themeConfig.mlaPhotoUrl!, fit: BoxFit.contain, alignment: Alignment.bottomRight)
                                        : Image.asset(themeConfig.mlaPhotoUrl!, fit: BoxFit.contain, alignment: Alignment.bottomRight))
                                    : const SizedBox(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildOverviewCards(context, l10n, total, resolved, pending, inReview),
            const SizedBox(height: 24),
            _buildPrimaryServices(l10n, themeConfig, complaints, context),
            const SizedBox(height: 24),
            _buildRecentComplaints(context, appState, l10n, complaints, isTelugu),
            const SizedBox(height: 24),
            _buildTopMandals(l10n, complaints, context),
            const SizedBox(height: 24),
            _buildQuickActions(context, l10n, themeConfig),
            const SizedBox(height: 24),
            _buildBroadcastShortcuts(context, l10n, themeConfig),
            const SizedBox(height: 24),
            _buildEmergencySupport(context, l10n),
            const SizedBox(height: 24),
            _buildConstituencyGlance(l10n, themeConfig),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards(BuildContext context, AppLocalizations l10n, int total, int resolved, int pending, int inReview) {
    final appState = Provider.of<AppState>(context, listen: false);
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              _statCard(l10n.complaints, total.toString(), '+12%', Colors.blue, () {
                appState.setSuperAdminTabIndex(1, filter: 'all');
              }),
              const SizedBox(height: 12),
              _statCard(l10n.pending, pending.toString(), '+3%', Colors.orange, () {
                appState.setSuperAdminTabIndex(1, filter: 'pending');
              }),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              _statCard(l10n.resolved, resolved.toString(), '+16%', Colors.green, () {
                appState.setSuperAdminTabIndex(1, filter: 'resolved');
              }),
              const SizedBox(height: 12),
              _statCard(l10n.inReview, inReview.toString(), '+2%', Colors.red, () {
                appState.setSuperAdminTabIndex(1, filter: 'inProgress');
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, String trend, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.analytics, color: color, size: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_upward, color: Colors.green, size: 10),
                      Text(trend, style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            const Text('vs last month', style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryServices(AppLocalizations l10n, dynamic themeConfig, List<Complaint> complaints, BuildContext context) {
    final waterCount = complaints.where((c) => CategoryMapping.getCanonicalCategory(c.category) == 'Water Supply').length;
    final electricityCount = complaints.where((c) => CategoryMapping.getCanonicalCategory(c.category) == 'Electricity').length;
    final roadsCount = complaints.where((c) => CategoryMapping.getCanonicalCategory(c.category) == 'Roads & Infrastructure').length;
    final sanitationCount = complaints.where((c) => CategoryMapping.getCanonicalCategory(c.category) == 'Sanitation').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.primaryServicesStatus, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            GestureDetector(
              onTap: () {
                _showAllServicesSheet(context, complaints, l10n, themeConfig);
              },
              child: Text(l10n.viewAll, style: TextStyle(fontSize: 12, color: themeConfig.primaryColor, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            GestureDetector(
              onTap: () => _showAllServicesSheet(context, complaints, l10n, themeConfig),
              child: _serviceStatusItem(Icons.water_drop, 'Water Supply', '$waterCount Problems', Colors.blue),
            ),
            GestureDetector(
              onTap: () => _showAllServicesSheet(context, complaints, l10n, themeConfig),
              child: _serviceStatusItem(Icons.electric_bolt, 'Electricity', '$electricityCount Problems', Colors.orange),
            ),
            GestureDetector(
              onTap: () => _showAllServicesSheet(context, complaints, l10n, themeConfig),
              child: _serviceStatusItem(Icons.add_road, 'Roads & Infra', '$roadsCount Problems', Colors.red),
            ),
            GestureDetector(
              onTap: () => _showAllServicesSheet(context, complaints, l10n, themeConfig),
              child: _serviceStatusItem(Icons.cleaning_services, 'Sanitation', '$sanitationCount Problems', Colors.green),
            ),
          ],
        ),
      ],
    );
  }

  void _showAllServicesSheet(BuildContext context, List<Complaint> complaints, AppLocalizations l10n, dynamic themeConfig) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      backgroundColor: Colors.white,
      builder: (context) {
        final categories = CategoryMapping.getAllCategories();
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(l10n.primaryServicesStatus, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        final count = complaints.where((c) => CategoryMapping.getCanonicalCategory(c.category) == cat).length;
                        final icon = CategoryMapping.getIconForCategory(cat);
                        final color = CategoryMapping.getColorForCategory(cat);
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: color.withOpacity(0.1),
                            child: Icon(icon, color: color),
                          ),
                          title: Text(cat, style: const TextStyle(fontWeight: FontWeight.bold)),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$count Problems',
                              style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Provider.of<AppState>(context, listen: false).setSuperAdminTabIndex(1);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _serviceStatusItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        CircleAvatar(backgroundColor: color.withOpacity(0.1), radius: 24, child: Icon(icon, color: color)),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildRecentComplaints(BuildContext context, AppState appState, AppLocalizations l10n, List<Complaint> complaints, bool isTelugu) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.recentComplaints, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            GestureDetector(
              onTap: () {
                appState.setSuperAdminTabIndex(1);
              },
              child: Text(l10n.viewAll, style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (complaints.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('No complaints available', style: TextStyle(color: Colors.grey))),
          )
        else
          ...complaints.take(2).map((c) => Card(
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ComplaintListTile(
              complaint: c,
              isTelugu: isTelugu,
              onTap: () {
                appState.setHighlightedComplaintId(c.id);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackComplaintsScreen()));
              },
            ),
          )),
      ],
    );
  }

  Widget _buildTopMandals(AppLocalizations l10n, List<Complaint> complaints, BuildContext context) {
    final urbanCount = complaints.where((c) => c.mandalName == 'Part-Rajahmundry Urban Mandal / RMC' || c.mandalName.toLowerCase().contains('urban') || c.mandalName.toLowerCase().contains('rmc')).length;
    final ruralCount = complaints.where((c) => c.mandalName == 'Rajahmundry Rural' || c.mandalName.toLowerCase().contains('rural')).length;
    final kadiamCount = complaints.where((c) => c.mandalName == 'Kadiam' || c.mandalName.toLowerCase().contains('kadiam')).length;

    final mandalData = [
      {'name': 'Rajahmundry Urban', 'count': urbanCount},
      {'name': 'Rajahmundry Rural', 'count': ruralCount},
      {'name': 'Kadiam', 'count': kadiamCount},
    ]..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.topMandals, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            GestureDetector(
              onTap: () {
                Provider.of<AppState>(context, listen: false).setSuperAdminTabIndex(1);
              },
              child: Text(l10n.viewAll, style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
          child: Column(
            children: [
              _mandalRow('1', mandalData[0]['name'] as String, '${mandalData[0]['count']} Complaints'),
              const Divider(height: 24),
              _mandalRow('2', mandalData[1]['name'] as String, '${mandalData[1]['count']} Complaints'),
              const Divider(height: 24),
              _mandalRow('3', mandalData[2]['name'] as String, '${mandalData[2]['count']} Complaints'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _mandalRow(String index, String name, String count) {
    return Row(
      children: [
        Text(index, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(width: 16),
        Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600))),
        Text(count, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54)),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, AppLocalizations l10n, dynamic themeConfig) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.quickActions, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _actionBtn(context, Icons.edit_document, 'New\nComplaint', Colors.purple, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => NewComplaintScreen(onSubmissionSuccess: () => Navigator.pop(context))));
            }),
            _actionBtn(context, Icons.campaign, 'Broadcast', Colors.blue, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateAnnouncementScreen()));
            }),
            _actionBtn(context, Icons.update, 'Ward\nUpdates', Colors.orange, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MyWardScreen()));
            }),
            _actionBtn(context, Icons.groups, 'Meetings', Colors.green, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MeetingsListScreen()));
            }),
            _actionBtn(context, Icons.smart_toy, 'AI\nAssistant', themeConfig.primaryColor, () {}),
          ],
        ),
      ],
    );
  }

  Widget _actionBtn(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, height: 1.2)),
        ],
      ),
    );
  }

  Widget _buildBroadcastShortcuts(BuildContext context, AppLocalizations l10n, dynamic themeConfig) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.broadcastShortcuts, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateAnnouncementScreen())),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.shade200)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.campaign, color: Colors.orange, size: 16),
                      const SizedBox(width: 8),
                      Text(l10n.newAnnouncement, style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BroadcastHistoryScreen())),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.purple.shade200)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.history, color: Colors.purple, size: 16),
                      const SizedBox(width: 8),
                      Text(l10n.broadcastHistory, style: const TextStyle(color: Colors.purple, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmergencySupport(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.emergencyAndSupport, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Emergency SOS'),
                      content: const Text('Emergency services will be contacted immediately.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text('CALL NOW', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade200)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.sos, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Text(l10n.emergencySos, style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Officer Directory is coming soon')),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.shade200)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.contact_phone, color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Text(l10n.officerDirectory, style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConstituencyGlance(AppLocalizations l10n, dynamic themeConfig) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.constituencyAtAGlance, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(l10n.viewOnMap, style: TextStyle(fontSize: 12, color: themeConfig.primaryColor, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _glanceStat(l10n.mandal, '12'),
              _glanceStat(l10n.wardsAndPollingStations.split(' ')[0], '235'),
              _glanceStat(l10n.villages, '268'),
              _glanceStat(l10n.pollingBooths, '1,542'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _glanceStat(String label, String val) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildUrgentBanner(BuildContext context, AppState appState, String targetRole, dynamic themeConfig, bool isTelugu) {
    final urgentComplaints = appState.complaints.where((c) {
      return c.isPushed && c.pushedTo == targetRole && c.status != ComplaintStatus.resolved;
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
                          '${isTelugu ? "విభాగం" : "Category"}: ${c.category}',
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
                            isTelugu ? 'వెంటనే పరిష్కరించండి (ఫోటో అవసరం)' : 'Resolve Immediately (Photo Required)',
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
}
