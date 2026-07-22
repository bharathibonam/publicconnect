import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../themes/party_theme_config.dart';

class OfficerInteractiveDialogs {
  static void showQuickActionsModal(BuildContext context, PartyThemeConfig themeConfig, {bool isCategoryOfficer = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Quick Actions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: isCategoryOfficer ? 3 : 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
              children: [
                _buildActionItem(ctx, Icons.person_add_alt_1_outlined, 'Assign Work', Colors.green, () {
                  Navigator.pop(ctx);
                  showAssignWorkDialog(context, themeConfig);
                }),
                _buildActionItem(ctx, Icons.shortcut_outlined, 'Forward', Colors.green, () {
                  Navigator.pop(ctx);
                  showForwardDialog(context, themeConfig);
                }),
                _buildActionItem(ctx, Icons.warning_amber_rounded, 'Escalate', Colors.red, () {
                  Navigator.pop(ctx);
                  showEscalateDialog(context, themeConfig);
                }),
                _buildActionItem(ctx, Icons.check_circle_outline, 'Close Complaint', Colors.green, () {
                  Navigator.pop(ctx);
                  showCloseComplaintDialog(context, themeConfig);
                }),
                _buildActionItem(ctx, Icons.phone_outlined, 'Call Citizen', Colors.green, () {
                  Navigator.pop(ctx);
                  showCallCitizenDialog(context, themeConfig);
                }),
                _buildActionItem(ctx, Icons.location_on_outlined, 'Navigate', Colors.purple, () {
                  Navigator.pop(ctx);
                  showNavigateDialog(context);
                }),
                if (!isCategoryOfficer)
                  _buildActionItem(ctx, Icons.camera_alt_outlined, 'Upload Photo', Colors.blue, () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Photo uploaded successfully!')),
                    );
                  }),
                if (!isCategoryOfficer)
                  _buildActionItem(ctx, Icons.mic_outlined, 'Voice Note', Colors.purple, () {
                    Navigator.pop(ctx);
                    showVoiceNoteDialog(context, themeConfig);
                  }),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  showBroadcastDialog(context, themeConfig);
                },
                icon: const Icon(Icons.campaign, color: Colors.purple),
                label: const Text('Broadcast Message', style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade50,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.purple.shade200),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildActionItem(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  static void showAssignWorkDialog(BuildContext context, PartyThemeConfig themeConfig) {
    final officers = ['S. Prakash (AE Water)', 'M. Ravi Kumar (JE Drainage)', 'K. Santhosh (AE Roads)', 'P. Anusha (Sanitary Inspector)'];
    String selectedOfficer = officers.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Assign Work'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select Officer to Assign Task:'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedOfficer,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: officers.map((o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (val) => setState(() => selectedOfficer = val!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: themeConfig.primaryColor),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Work assigned to $selectedOfficer successfully!')),
                );
              },
              child: const Text('Assign', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  static void showForwardDialog(BuildContext context, PartyThemeConfig themeConfig) {
    final depts = ['District Collectorate', 'Superintending Engineer', 'Municipal Commissioner', 'Zilla Parishad'];
    String selectedDept = depts.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Forward Complaint'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select Department / Authority to Forward:'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedDept,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: depts.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (val) => setState(() => selectedDept = val!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: themeConfig.primaryColor),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Complaint forwarded to $selectedDept')),
                );
              },
              child: const Text('Forward', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  static void showEscalateDialog(BuildContext context, PartyThemeConfig themeConfig) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Escalate Complaint'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('State reason for high-priority escalation:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g. Unresolved SLA breach, major public disruption...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Complaint escalated to Higher Authority!'), backgroundColor: Colors.red),
              );
            },
            child: const Text('Escalate', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  static void showCloseComplaintDialog(BuildContext context, PartyThemeConfig themeConfig) {
    final remarkController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Close Complaint'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter resolution remark:'),
            const SizedBox(height: 12),
            TextField(
              controller: remarkController,
              decoration: const InputDecoration(
                hintText: 'Work completed verified on site',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Complaint marked as Closed & Resolved.')),
              );
            },
            child: const Text('Close Complaint', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  static void showCallCitizenDialog(BuildContext context, PartyThemeConfig themeConfig) {
    final phoneController = TextEditingController(text: '+91 9876543210');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Call Citizen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Citizen Phone Number:'),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton.icon(
            icon: const Icon(Icons.call, color: Colors.white),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              final Uri telLaunchUri = Uri(scheme: 'tel', path: phoneController.text.trim());
              try {
                if (await canLaunchUrl(telLaunchUri)) {
                  await launchUrl(telLaunchUri);
                } else {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Calling ${phoneController.text.trim()}...')),
                  );
                }
              } catch (_) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('Calling ${phoneController.text.trim()}...')),
                );
              }
            },
            label: const Text('Call Now', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  static void showNavigateDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening Google Maps location navigation...')),
    );
  }

  static void showVoiceNoteDialog(BuildContext context, PartyThemeConfig themeConfig) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Record Voice Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.mic, size: 60, color: Colors.purple),
            SizedBox(height: 16),
            Text('Tap Record to capture site voice memo:'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Voice note recorded & attached!')),
              );
            },
            child: const Text('Start Recording', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  static void showBroadcastDialog(BuildContext context, PartyThemeConfig themeConfig) {
    final msgController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Broadcast Message'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Send alert announcement to all citizens in GP/Mandal:'),
            const SizedBox(height: 12),
            TextField(
              controller: msgController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g. Pipeline maintenance tonight from 10 PM to 4 AM',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton.icon(
            icon: const Icon(Icons.send, color: Colors.white, size: 16),
            style: ElevatedButton.styleFrom(backgroundColor: themeConfig.primaryColor),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Broadcast message sent to all citizens!')),
              );
            },
            label: const Text('Send Broadcast', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  static void showAddFeedbackSheet(BuildContext context, PartyThemeConfig themeConfig) {
    final textController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Official Feedback', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Enter feedback or observation regarding this complaint...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeConfig.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Feedback saved successfully!')),
                  );
                },
                child: const Text('Submit Feedback', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
