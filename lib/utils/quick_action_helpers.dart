import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

import '../services/app_state.dart';
import '../models/complaint.dart';
import '../themes/party_theme_config.dart';

class QuickActionHelpers {
  static void handleForward(BuildContext context, AppState appState, PartyThemeConfig themeConfig) {
    final pendingComplaints = appState.complaints.where((c) => c.status != ComplaintStatus.resolved).toList();
    if (pendingComplaints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No pending complaints to forward.')));
      return;
    }
    Complaint? selectedComplaint;
    String targetRole = 'Mandal Officer';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Forward Complaint'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<Complaint>(
                    isExpanded: true,
                    hint: const Text('Select Complaint'),
                    value: selectedComplaint,
                    items: pendingComplaints.map((c) => DropdownMenuItem(value: c, child: Text('${c.category} - ${c.id.substring(0,5)}'))).toList(),
                    onChanged: (val) => setState(() => selectedComplaint = val),
                  ),
                  const SizedBox(height: 16),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: targetRole,
                    items: const [
                      DropdownMenuItem(value: 'Mandal Officer', child: Text('Mandal Officer')),
                      DropdownMenuItem(value: 'Super Admin', child: Text('Super Admin')),
                    ],
                    onChanged: (val) => setState(() => targetRole = val!),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: themeConfig.primaryColor),
                  onPressed: selectedComplaint == null ? null : () {
                    appState.forwardComplaint(selectedComplaint!.id, targetRole);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complaint forwarded successfully.')));
                  },
                  child: const Text('Forward'),
                ),
              ],
            );
          }
        );
      }
    );
  }

  static void handleEscalate(BuildContext context, AppState appState, PartyThemeConfig themeConfig) {
    final pendingComplaints = appState.complaints.where((c) => c.status != ComplaintStatus.resolved).toList();
    if (pendingComplaints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No pending complaints to escalate.')));
      return;
    }
    Complaint? selectedComplaint;
    String targetRole = 'Super Admin';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Escalate Complaint'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<Complaint>(
                    isExpanded: true,
                    hint: const Text('Select Complaint'),
                    value: selectedComplaint,
                    items: pendingComplaints.map((c) => DropdownMenuItem(value: c, child: Text('${c.category} - ${c.id.substring(0,5)}'))).toList(),
                    onChanged: (val) => setState(() => selectedComplaint = val),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: selectedComplaint == null ? null : () {
                    appState.escalateComplaint(selectedComplaint!.id, targetRole);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complaint escalated successfully.')));
                  },
                  child: const Text('Escalate', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  static void handleClose(BuildContext context, AppState appState, PartyThemeConfig themeConfig) {
    final pendingComplaints = appState.complaints.where((c) => c.status != ComplaintStatus.resolved).toList();
    if (pendingComplaints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No pending complaints to close.')));
      return;
    }
    Complaint? selectedComplaint;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Close Complaint'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Are you sure you want to mark this complaint as resolved?'),
                  const SizedBox(height: 16),
                  DropdownButton<Complaint>(
                    isExpanded: true,
                    hint: const Text('Select Complaint'),
                    value: selectedComplaint,
                    items: pendingComplaints.map((c) => DropdownMenuItem(value: c, child: Text('${c.category} - ${c.id.substring(0,5)}'))).toList(),
                    onChanged: (val) => setState(() => selectedComplaint = val),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: selectedComplaint == null ? null : () {
                    appState.updateComplaintStatus(selectedComplaint!.id, ComplaintStatus.resolved);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complaint closed.')));
                  },
                  child: const Text('Close', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  static Future<void> handleCallCitizen(BuildContext context, AppState appState, PartyThemeConfig themeConfig) async {
    final pendingComplaints = appState.complaints.where((c) => c.status != ComplaintStatus.resolved).toList();
    if (pendingComplaints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No pending complaints to call.')));
      return;
    }
    Complaint? selectedComplaint;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Call Citizen'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<Complaint>(
                    isExpanded: true,
                    hint: const Text('Select Complaint'),
                    value: selectedComplaint,
                    items: pendingComplaints.map((c) => DropdownMenuItem(value: c, child: Text('${c.category} - ${c.id.substring(0,5)}'))).toList(),
                    onChanged: (val) => setState(() => selectedComplaint = val),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: themeConfig.primaryColor),
                  onPressed: selectedComplaint == null ? null : () async {
                    Navigator.pop(ctx);
                    final Uri url = Uri.parse('tel:${selectedComplaint!.citizenPhone}');
                    if (!await launchUrl(url)) {
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch dialer.')));
                    }
                  },
                  child: const Text('Call'),
                ),
              ],
            );
          }
        );
      }
    );
  }

  static Future<void> handleGenerateReport(BuildContext context, AppState appState, PartyThemeConfig themeConfig) async {
    final allComplaints = appState.complaints;
    if (allComplaints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No complaints to generate report.')));
      return;
    }
    
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/complaints_report_${DateTime.now().millisecondsSinceEpoch}.txt');
      
      String reportContent = 'COMPLAINTS REPORT\n=================\\n\\n';
      reportContent += 'Total Complaints: ${allComplaints.length}\n';
      reportContent += 'Resolved: ${allComplaints.where((c) => c.status == ComplaintStatus.resolved).length}\n';
      reportContent += 'Pending: ${allComplaints.where((c) => c.status == ComplaintStatus.submitted).length}\n\n';
      
      for (var c in allComplaints) {
        reportContent += 'ID: ${c.id}\n';
        reportContent += 'Category: ${c.category}\n';
        reportContent += 'Status: ${c.status.name}\n';
        reportContent += 'Citizen: ${c.citizenName}\n';
        reportContent += 'Ward: ${c.wardName}\n';
        reportContent += '------------------\n';
      }
      
      await file.writeAsString(reportContent);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report generated.')));
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            text: 'Complaint Report',
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to generate report: $e')));
      }
    }
  }
}
