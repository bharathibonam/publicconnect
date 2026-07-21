import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';
import '../../themes/theme_provider.dart';
import 'app_config_tab.dart';
import 'admin_management.dart';

class SystemConfigurationScreen extends StatelessWidget {
  const SystemConfigurationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeConfig = Provider.of<ThemeProvider>(context).activeParty;
    final isTelugu = Provider.of<AppState>(context).isTelugu;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
        title: Text(isTelugu ? 'సిస్టమ్ కాన్ఫిగరేషన్' : 'System Configuration', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildConfigCard(
            context,
            icon: Icons.palette,
            title: isTelugu ? 'పార్టీ థీమ్' : 'Party Theme',
            subtitle: isTelugu ? 'పార్టీ రంగులు మరియు బ్రాండింగ్‌ను మార్చండి' : 'Change party colors and branding',
            color: Colors.blue,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppConfigTab())),
          ),
          _buildConfigCard(
            context,
            icon: Icons.manage_accounts,
            title: isTelugu ? 'వినియోగదారు & పాత్ర నిర్వహణ' : 'User & Role Management',
            subtitle: isTelugu ? 'అధికారులను మరియు వార్డు మెంబర్లను నిర్వహించండి' : 'Manage officers and ward members',
            color: Colors.orange,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminManagementTab())),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigCard(BuildContext context, {required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
