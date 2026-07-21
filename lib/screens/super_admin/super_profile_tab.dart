import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_demo_app/l10n/app_localizations.dart';
import '../../services/app_state.dart';
import '../../themes/theme_provider.dart';
import '../../services/supabase_service.dart';

class SuperProfileTab extends StatefulWidget {
  const SuperProfileTab({super.key});

  @override
  State<SuperProfileTab> createState() => _SuperProfileTabState();
}

class _SuperProfileTabState extends State<SuperProfileTab> {
  bool _isUploading = false;

  Future<void> _updateProfilePhoto(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 70);
    if (pickedFile == null) return;

    setState(() => _isUploading = true);
    if (!mounted) return;
    final appState = Provider.of<AppState>(context, listen: false);
    final user = appState.currentUser;
    if (user != null) {
      final cloudUrl = await SupabaseService.uploadProfileImage(File(pickedFile.path), user.id);
      if (cloudUrl != null) {
        appState.updateUserProfile(user.name, user.phoneNumber, cloudUrl);
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.profileUpdated)));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload photo')));
        }
      }
    }
    if (mounted) {
      setState(() => _isUploading = false);
    }
  }

  void _showImageSourceActionSheet(BuildContext context, dynamic themeConfig) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt, color: themeConfig.primaryColor),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(ctx);
                _updateProfilePhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: themeConfig.primaryColor),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _updateProfilePhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final themeConfig = themeProvider.activeParty;
    final user = appState.currentUser;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(l10n.profile, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: themeConfig.primaryColor.withValues(alpha: 0.2),
                  backgroundImage: user != null && user.profilePhotoUrl != null && user.profilePhotoUrl!.isNotEmpty
                      ? (user.profilePhotoUrl!.startsWith('http') || kIsWeb
                          ? NetworkImage(user.profilePhotoUrl!) as ImageProvider
                          : FileImage(File(user.profilePhotoUrl!)))
                      : null,
                  child: (user == null || user.profilePhotoUrl == null || user.profilePhotoUrl!.isEmpty)
                      ? Icon(Icons.person, size: 50, color: themeConfig.primaryColor)
                      : null,
                ),
                if (_isUploading)
                  const CircularProgressIndicator(),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => _showImageSourceActionSheet(context, themeConfig),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: themeConfig.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(user?.name ?? 'Super Admin', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(user?.phoneNumber ?? '', style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 32),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: Colors.white,
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.phone, color: themeConfig.accentColor),
                    title: const Text('Phone Number', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(user?.phoneNumber ?? 'Not provided'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.email, color: themeConfig.accentColor),
                    title: const Text('Email Address', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('user@example.com'), // Add actual email if available
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.language, color: themeConfig.accentColor),
                    title: Text(l10n.language, style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: Switch(
                      value: appState.isTelugu,
                      onChanged: (val) => appState.setLanguage(val),
                      activeTrackColor: themeConfig.primaryColor.withValues(alpha: 0.5),
                      activeColor: themeConfig.primaryColor,
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.lock, color: themeConfig.accentColor),
                    title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Navigate to change password
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.notifications, color: themeConfig.accentColor),
                    title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: Switch(
                      value: true,
                      onChanged: (val) {},
                      activeTrackColor: themeConfig.primaryColor.withValues(alpha: 0.5),
                      activeColor: themeConfig.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: Colors.white,
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.privacy_tip_outlined, color: themeConfig.accentColor),
                    title: const Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.description_outlined, color: themeConfig.accentColor),
                    title: const Text('Terms & Conditions', style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.help_outline, color: themeConfig.accentColor),
                    title: const Text('Help & Support', style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.info_outline, color: themeConfig.accentColor),
                    title: const Text('About', style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: Text(l10n.logout),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                appState.logout();
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
