import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../services/app_state.dart';
import '../../models/complaint.dart';
import '../../models/broadcast_alert.dart';
import '../../models/work_update.dart';
import '../../themes/party_theme_config.dart';
import '../../themes/theme_provider.dart';
import '../../widgets/notification_bell.dart';
import 'jobs_screen.dart';
import '../announcements/announcement_list_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'my_ward_screen.dart';
import 'citizen_services_screen.dart';
import 'welfare_schemes_screen.dart';

class CitizenHome extends StatelessWidget {
  final VoidCallback onFileComplaintPressed;
  final VoidCallback onTrackComplaintsPressed;
  final VoidCallback onGoToProfile;

  const CitizenHome({
    super.key,
    required this.onFileComplaintPressed,
    required this.onTrackComplaintsPressed,
    required this.onGoToProfile,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final activeParty = themeProvider.activeParty;
    final user = appState.currentUser;
    final loc = AppLocalizations.of(context)!;
    
    final complaints = appState.complaints.where((c) => c.userId == user?.id).toList();
    final citizenWardIds = complaints.map((c) => c.wardId).toSet();
    final filteredBroadcasts = appState.broadcasts.where((b) {
      final isCitizenAudience = b.targetAudience == 'citizens' || b.targetAudience.isEmpty;
      return isCitizenAudience && (b.wardId == 'global' || citizenWardIds.contains(b.wardId));
    }).toList();

    // Work Updates for the Citizen's Ward
    final citizenWardName = user?.wardName ?? '';
    final filteredWorkUpdates = appState.workUpdates.where((w) => w.wardName == citizenWardName).toList();

    final total = complaints.length;
    final submitted = complaints.where((c) => c.status == ComplaintStatus.submitted).length;
    final inProgress = complaints.where((c) => c.status == ComplaintStatus.inProgress).length;
    final resolved = complaints.where((c) => c.status == ComplaintStatus.resolved).length;
    // For statistics, "pending" could mean submitted + inProgress or just submitted. Let's use submitted + inProgress
    final pending = submitted + inProgress;

    return Scaffold(
      backgroundColor: activeParty.backgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(context, activeParty, appState, loc),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroCard(context, activeParty, appState, loc),
                    const SizedBox(height: 24),
                    _buildStatisticsSection(context, total, resolved, pending, 12450, loc),
                    const SizedBox(height: 28),
                    
                    if (filteredWorkUpdates.isNotEmpty) ...[
                      _buildSectionTitle(appState.isTelugu ? 'పూర్తయిన పనులు' : 'Development Works', activeParty),
                      const SizedBox(height: 16),
                      _buildWorkUpdatesList(filteredWorkUpdates, activeParty, appState.isTelugu),
                      const SizedBox(height: 28),
                    ],

                    if (filteredBroadcasts.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionTitle(loc.mlaAnnouncements, activeParty),
                          Text(
                            loc.viewAll,
                            style: TextStyle(color: activeParty.primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      BroadcastCarousel(broadcasts: filteredBroadcasts, activeParty: activeParty),
                      const SizedBox(height: 28),
                    ],

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionTitle(loc.complaintDashboard, activeParty),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildComplaintStatusSummary(submitted, pending, inProgress, resolved, loc),
                    const SizedBox(height: 16),
                    _buildComplaintList(complaints, activeParty, loc),
                    const SizedBox(height: 28),
                    
                    _buildSectionTitle(loc.supportSection, activeParty),
                    const SizedBox(height: 16),
                    _buildSupportSection(activeParty, loc),
                    
                    const SizedBox(height: 120), // Prevent FAB overlap
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AI Assistant coming soon')));
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.smart_toy, color: Colors.white, size: 28),
              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  radius: 4,
                  backgroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicImage(String? url, bool isLogo, {Alignment alignment = Alignment.center}) {
    if (url == null || url.isEmpty) {
      return Icon(isLogo ? Icons.flag : Icons.person, size: isLogo ? 40 : 220, color: Colors.white70);
    }
    if (url.startsWith('http')) {
      return Image.network(
        url, 
        fit: BoxFit.contain, 
        alignment: alignment,
        errorBuilder: (context, error, stackTrace) => Icon(isLogo ? Icons.flag : Icons.person, size: isLogo ? 40 : 220, color: Colors.white70),
      );
    }
    if (url.startsWith('assets/')) {
      return Image.asset(
        url, 
        fit: BoxFit.contain,
        alignment: alignment,
        errorBuilder: (context, error, stackTrace) => Icon(isLogo ? Icons.flag : Icons.person, size: isLogo ? 40 : 220, color: Colors.white70),
      );
    }
    if (kIsWeb) {
      return Icon(isLogo ? Icons.flag : Icons.person, size: isLogo ? 40 : 220, color: Colors.white70);
    }
    return Image.file(
      File(url), 
      fit: BoxFit.contain,
      alignment: alignment,
      errorBuilder: (context, error, stackTrace) => Icon(isLogo ? Icons.flag : Icons.person, size: isLogo ? 40 : 220, color: Colors.white70),
    );
  }

  Widget _buildAppBar(BuildContext context, PartyThemeConfig party, AppState appState, AppLocalizations loc) {
    return SliverAppBar(
      expandedHeight: kToolbarHeight,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [party.primaryColor, party.secondaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      leadingWidth: 56,
      leading: GestureDetector(
        onTap: onGoToProfile,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            backgroundImage: (appState.currentUser?.profilePhotoUrl != null && appState.currentUser!.profilePhotoUrl!.isNotEmpty)
                ? (kIsWeb || appState.currentUser!.profilePhotoUrl!.startsWith('http')
                    ? NetworkImage(appState.currentUser!.profilePhotoUrl!) as ImageProvider
                    : FileImage(File(appState.currentUser!.profilePhotoUrl!)))
                : null,
            child: (appState.currentUser?.profilePhotoUrl == null || appState.currentUser!.profilePhotoUrl!.isEmpty)
                ? const Icon(Icons.person, color: Colors.white, size: 22)
                : null,
          ),
        ),
      ),
      titleSpacing: 8,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.home,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            '${party.getLocalizedConstituencyName(context)} ${loc.constituency}',
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
                    color: !appState.isTelugu ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'English',
                    style: TextStyle(
                      color: !appState.isTelugu ? party.primaryColor : Colors.white,
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
                    color: appState.isTelugu ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'తెలుగు',
                    style: TextStyle(
                      color: appState.isTelugu ? party.primaryColor : Colors.white,
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
    );
  }

  Widget _buildHeroCard(BuildContext context, PartyThemeConfig party, AppState appState, AppLocalizations loc) {
    return Container(
      width: double.infinity,
      height: 150, // Slightly taller to fit all citizen text
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [party.primaryColor, party.primaryColor.withValues(alpha: 0.8)],
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
            // Left Content Area
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Small Party Logo Above Party Name
                    SizedBox(
                      height: 20, 
                      child: _buildDynamicImage(party.logoUrl, true, alignment: Alignment.centerLeft),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      party.getLocalizedPartyName(context), 
                      style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      party.getLocalizedMlaName(context),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${party.getLocalizedConstituencyName(context)} ${loc.constituency}',
                          style: TextStyle(
                            color: party.primaryColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      loc.tagline,
                      style: const TextStyle(color: Colors.black87, fontSize: 10, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      loc.appName,
                      style: const TextStyle(color: Colors.black87, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
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
                    if (party.id == 'tdp' && party.logoUrl != null)
                      Positioned(
                        right: 0,
                        top: 10,
                        width: 90,
                        height: 90,
                        child: Opacity(
                          opacity: 0.15,
                          child: _buildDynamicImage(party.logoUrl, true, alignment: Alignment.center),
                        ),
                      ),
                    // MLA Photo
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: _buildDynamicImage(party.mlaPhotoUrl, false, alignment: Alignment.bottomRight),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, PartyThemeConfig party) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: Colors.black87,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildStatisticsSection(BuildContext context, int total, int resolved, int pending, int served, AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildQuickServicesGrid(context, loc, Provider.of<ThemeProvider>(context, listen: false).activeParty),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Constituency Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
                letterSpacing: 0.5,
              ),
            ),
            const Text(
              'Updated just now',
              style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatItem('Citizens', served.toString(), const Color(0xFF22C55E)),
            _buildStatItem('Complaints Today', '128', const Color(0xFF3B82F6)),
            _buildStatItem('Resolved Today', '96', const Color(0xFF22C55E)),
            _buildStatItem('Pending', pending.toString(), const Color(0xFFF97316)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(String title, String count, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black54),
            maxLines: 2,
          ),
          const SizedBox(height: 4),
          Text(
            count,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickServicesGrid(BuildContext context, AppLocalizations loc, PartyThemeConfig party) {
    final appState = Provider.of<AppState>(context);
    final unreadAnnouncementsCount = appState.notifications.where((n) => n.isAnnouncementNotification && !n.isRead).length;

    final services = [
      {'icon': Icons.assignment, 'label': loc.fileComplaint, 'color': const Color(0xFFF97316), 'bg': const Color(0xFFFFF7ED), 'onTap': onFileComplaintPressed},
      {'icon': Icons.mic, 'label': loc.voiceComplaint, 'color': const Color(0xFF3B82F6), 'bg': const Color(0xFFEFF6FF), 'onTap': () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming soon'))); }},
      {'icon': Icons.account_balance, 'label': loc.myWard, 'color': const Color(0xFF8B5CF6), 'bg': const Color(0xFFF5F3FF), 'onTap': () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MyWardScreen()));
      }},
      {'icon': Icons.track_changes, 'label': loc.trackComplaint, 'color': const Color(0xFF8B5CF6), 'bg': const Color(0xFFF5F3FF), 'onTap': onTrackComplaintsPressed},
      {'icon': Icons.location_city, 'label': loc.services, 'color': const Color(0xFF06B6D4), 'bg': const Color(0xFFECFEFF), 'onTap': () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CitizenServicesScreen()));
      }},
      {'icon': Icons.people, 'label': loc.welfareSchemes, 'color': const Color(0xFFEC4899), 'bg': const Color(0xFFFDF2F8), 'onTap': () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const WelfareSchemesScreen()));
      }},
      {'icon': Icons.work, 'label': loc.jobs, 'color': const Color(0xFF3B82F6), 'bg': const Color(0xFFEFF6FF), 'onTap': () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const JobsScreen()));
      }},
      {'icon': Icons.campaign, 'label': loc.announcements, 'color': const Color(0xFFEF4444), 'bg': const Color(0xFFFEF2F2), 'onTap': () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AnnouncementListScreen()));
      }},
    ];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              loc.quickServices,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              loc.viewAll,
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemCount: services.length,
          itemBuilder: (context, index) {
            final service = services[index];
            return GestureDetector(
              onTap: service['onTap'] as VoidCallback,
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: service['bg'] as Color,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: service['label'] == loc.announcements && unreadAnnouncementsCount > 0
                        ? Badge(
                            label: Text(unreadAnnouncementsCount.toString()),
                            child: Icon(service['icon'] as IconData, color: service['color'] as Color, size: 24),
                          )
                        : Icon(service['icon'] as IconData, color: service['color'] as Color, size: 24),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Text(
                      service['label'] as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black87, height: 1.2),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildComplaintStatusSummary(int submitted, int pending, int inProgress, int resolved, AppLocalizations loc) {
    return Row(
      children: [
        Expanded(child: _buildStatusSummaryCard(loc.submitted, submitted, const Color(0xFF22C55E))),
        const SizedBox(width: 8),
        Expanded(child: _buildStatusSummaryCard(loc.pending, pending, const Color(0xFFF59E0B))),
        const SizedBox(width: 8),
        Expanded(child: _buildStatusSummaryCard(loc.inProgress, inProgress, const Color(0xFF3B82F6))),
        const SizedBox(width: 8),
        Expanded(child: _buildStatusSummaryCard(loc.resolved, resolved, const Color(0xFF22C55E))),
      ],
    );
  }

  Widget _buildStatusSummaryCard(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black54),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintList(List<Complaint> complaints, PartyThemeConfig party, AppLocalizations loc) {
    if (complaints.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.assignment_turned_in_outlined, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            Text(
              loc.noComplaints,
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Column(
      children: complaints.take(3).map((comp) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.04),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: comp.statusColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.description, color: comp.statusColor, size: 24),
            ),
            title: Text(
              comp.category,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
            ),
            subtitle: Text(
              comp.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: comp.statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                comp.statusText,
                style: TextStyle(
                  color: comp.statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap: onTrackComplaintsPressed,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSupportSection(PartyThemeConfig party, AppLocalizations loc) {
    final isJsp = party.id == 'jsp';
    return Column(
      children: [
        _buildSupportCard(
          loc.helpline, loc.callTollFree, Icons.phone,
          isJsp ? party.primaryColor : const Color(0xFFEF4444),
          onTap: () => launchUrl(Uri.parse('tel:100')),
        ),
        const SizedBox(height: 12),
        _buildSupportCard(
          loc.whatsappSupport, loc.chatWithUs, Icons.wechat,
          const Color(0xFF22C55E),
          onTap: () => launchUrl(Uri.parse('https://wa.me/918309741822')),
        ),
      ],
    );
  }

  Widget _buildSupportCard(String title, String subtitle, IconData icon, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 16)
          ],
        ),
      ),
    );
  }

  Widget _buildWorkUpdatesList(List<WorkUpdate> updates, PartyThemeConfig party, bool isTelugu) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: updates.length,
        itemBuilder: (context, index) {
          final w = updates[index];
          return Container(
            width: 280,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    color: Colors.grey.shade200,
                    child: w.imageUrls.isNotEmpty
                        ? Image.network(w.imageUrls.first, fit: BoxFit.cover)
                        : Icon(Icons.image_not_supported, color: Colors.grey.shade400, size: 40),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              w.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Completed', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        w.description,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}

class BroadcastCarousel extends StatefulWidget {
  final List<BroadcastAlert> broadcasts;
  final PartyThemeConfig activeParty;

  const BroadcastCarousel({
    super.key,
    required this.broadcasts,
    required this.activeParty,
  });

  @override
  State<BroadcastCarousel> createState() => _BroadcastCarouselState();
}

class _BroadcastCarouselState extends State<BroadcastCarousel> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 150,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: widget.broadcasts.length,
            itemBuilder: (context, index) {
              final alert = widget.broadcasts[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                      child: Container(
                        width: 120,
                        height: double.infinity,
                        color: Colors.grey.shade200,
                        child: widget.activeParty.mlaPhotoUrl != null 
                            ? Image.asset(widget.activeParty.mlaPhotoUrl!, fit: BoxFit.cover, alignment: Alignment.topCenter)
                            : Icon(Icons.campaign, size: 50, color: Colors.grey.shade400),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.volume_up, color: widget.activeParty.primaryColor, size: 16),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    alert.title,
                                    style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Expanded(
                              child: Text(
                                alert.description,
                                style: const TextStyle(color: Colors.black54, fontSize: 11, height: 1.4),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Just now',
                              style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        if (widget.broadcasts.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.broadcasts.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentIndex == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentIndex == index ? widget.activeParty.primaryColor : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
