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

  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CLOSE', style: TextStyle(color: Provider.of<ThemeProvider>(context, listen: false).activeParty.primaryColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _updateProfilePhoto(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 70);
    if (pickedFile == null) return;

    final appState = Provider.of<AppState>(context, listen: false);
    appState.updateProfilePhotoLocally(pickedFile.path);

    setState(() => _isUploading = true);
    if (!mounted) return;
    final user = appState.currentUser;
    if (user != null) {
      String? cloudUrl;
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        cloudUrl = await SupabaseService.uploadProfileImageBytes(bytes, user.id);
      } else {
        cloudUrl = await SupabaseService.uploadProfileImage(File(pickedFile.path), user.id);
      }
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
                      _showInfoDialog(
                        'Change Password',
                        'Password reset instructions will be sent to your registered mobile number: ${user?.phoneNumber ?? ""}.',
                      );
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
                    onTap: () {
                      _showInfoDialog(
                        'Privacy Policy',
                        'This Smart Governance application respects citizen privacy. Image uploads, geographic locations, and contact details are encrypted and securely stored for the sole purpose of complaint management.',
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.description_outlined, color: themeConfig.accentColor),
                    title: const Text('Terms & Conditions', style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      _showInfoDialog(
                        'Terms & Conditions',
                        'By using this application, you agree to submit authentic complaints, provide correct contact numbers, and cooperate with mandal/ward officers to resolve municipal issues.',
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.help_outline, color: themeConfig.accentColor),
                    title: const Text('Help & Support', style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      _showInfoDialog(
                        'Help & Support',
                        'Need help? Contact the Smart Governance technical support team at support@smartgov.gov.in or call our helpline: 1800-425-1111.',
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.info_outline, color: themeConfig.accentColor),
                    title: const Text('About', style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      _showInfoDialog(
                        'About Application',
                        'Smart Governance Platform\nVersion: 1.2.0\nDeveloped to bridge the gap between citizens, ward administrators, and category officers for rapid municipal resolutions.',
                      );
                    },
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
              onPressed: () async {
                await appState.logout();
                if (context.mounted) {
                  Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
                }
              },
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }
}
