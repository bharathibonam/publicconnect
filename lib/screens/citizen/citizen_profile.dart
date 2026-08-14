import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:path_provider/path_provider.dart';
import '../../services/app_state.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../services/translation_service.dart';
import '../../models/complaint.dart';
import '../../utils/camera_helper.dart';
import 'dart:convert';


class CitizenProfileScreen extends StatefulWidget {
  final VoidCallback? onBackPressed;
  const CitizenProfileScreen({super.key, this.onBackPressed});

  @override
  State<CitizenProfileScreen> createState() => _CitizenProfileScreenState();
}

class _CitizenProfileScreenState extends State<CitizenProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  File? _profileImage;
  Uint8List? _profileImageBytes;
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AppState>(context, listen: false).currentUser;
    _nameController = TextEditingController(text: user?.name);
    _phoneController = TextEditingController(text: user?.phoneNumber);
  }

  Future<void> _pickImage(ImageSource source) async {
    final appState = Provider.of<AppState>(context, listen: false);
    try {
      if (kIsWeb && source == ImageSource.camera) {
        final bytes = await CameraHelper.pickImageFromCamera();
        if (bytes != null) {
          if (mounted) {
            setState(() {
              _profileImageBytes = bytes;
            });
            // Convert to data URI for instant preview in other views
            final base64Url = 'data:image/jpeg;base64,${base64.encode(bytes)}';
            appState.updateProfilePhotoLocally(base64Url);
          }
        }
        return;
      }

      final pickedFile = await _picker.pickImage(source: source, imageQuality: 85);
      if (pickedFile != null) {
        appState.updateProfilePhotoLocally(pickedFile.path);
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          if (mounted) {
            setState(() {
              _profileImageBytes = bytes;
            });
          }
        } else {
          // Copy to permanent app documents directory so it survives cache clears
          final appDir = await getApplicationDocumentsDirectory();
          // Capture userId before async gap
          final userId = mounted
              ? (Provider.of<AppState>(context, listen: false).currentUser?.id ?? 'user')
              : 'user';
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final destPath = '${appDir.path}/profile_${userId}_$timestamp.jpg';
          final destFile = await File(pickedFile.path).copy(destPath);
          if (mounted) {
            setState(() {
              _profileImage = destFile;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select Profile Photo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isTelugu = appState.isTelugu;
    final user = appState.currentUser;
    final complaints = appState.complaints.where((c) => c.userId == user?.id).toList();

    final int pending = complaints.where((c) => c.status == ComplaintStatus.submitted).length;
    final int inProgress = complaints.where((c) => c.status == ComplaintStatus.inProgress).length;
    final int resolved = complaints.where((c) => c.status == ComplaintStatus.resolved).length;
    final int total = complaints.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: ModalRoute.of(context)?.canPop == true || widget.onBackPressed != null
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else if (widget.onBackPressed != null) {
                    widget.onBackPressed!();
                  }
                },
              ),
            )
          : null,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    Trans.t('my_profile', isTelugu),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              Trans.t('profile_desc', isTelugu),
              style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
            ),
            const SizedBox(height: 20),

            // Profile Photo Upload
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () {
                      final ImageProvider? img = _profileImageBytes != null
                          ? MemoryImage(_profileImageBytes!) as ImageProvider
                          : (_profileImage != null
                              ? (kIsWeb ? NetworkImage(_profileImage!.path) as ImageProvider : FileImage(_profileImage!))
                              : (user?.profilePhotoUrl != null && user!.profilePhotoUrl!.isNotEmpty
                                  ? (user.profilePhotoUrl!.startsWith('http') || kIsWeb
                                      ? NetworkImage(user.profilePhotoUrl!) as ImageProvider
                                      : FileImage(File(user.profilePhotoUrl!)))
                                  : null));
                      if (img != null) {
                        _showFullScreenImage(img);
                      }
                    },
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: _profileImageBytes != null
                          ? MemoryImage(_profileImageBytes!) as ImageProvider
                          : (_profileImage != null
                              ? (kIsWeb ? NetworkImage(_profileImage!.path) as ImageProvider : FileImage(_profileImage!))
                              : (user?.profilePhotoUrl != null && user!.profilePhotoUrl!.isNotEmpty
                                  ? (user.profilePhotoUrl!.startsWith('http') || kIsWeb
                                      ? NetworkImage(user.profilePhotoUrl!) as ImageProvider
                                      : FileImage(File(user.profilePhotoUrl!)))
                                  : null)),
                      child: (_profileImageBytes == null && _profileImage == null && (user?.profilePhotoUrl == null || user!.profilePhotoUrl!.isEmpty))
                          ? const Icon(Icons.person, size: 50, color: Colors.grey)
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _showImageSourceSheet,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Profile info card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            Trans.t('personal_info', isTelugu),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nameController,
                        enabled: true,
                        style: const TextStyle(fontSize: 15, color: Colors.black87),
                        decoration: InputDecoration(
                          labelText: Trans.t('name', isTelugu),
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: const Color(0xFFF1F5F9), // Sleek disabled background
                        ),
                        validator: (v) => v == null || v.isEmpty 
                            ? (isTelugu ? 'పేరును నమోదు చేయండి' : 'Enter name') 
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        enabled: false,
                        style: const TextStyle(fontSize: 15, color: Colors.black87),
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: Trans.t('phone_number', isTelugu),
                          prefixIcon: const Icon(Icons.phone_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: const Color(0xFFF1F5F9), // Sleek disabled background
                        ),
                        validator: (v) => v == null || v.length < 10 
                            ? (isTelugu ? 'సరైన నంబరు నమోదు చేయండి' : 'Enter valid number') 
                            : null,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _isSaving ? null : () async {
                            if (_formKey.currentState!.validate()) {
                              setState(() => _isSaving = true);
                              await appState.updateUserProfile(
                                _nameController.text.trim(),
                                _phoneController.text.trim(),
                                _profileImage?.path,
                                profilePhotoBytes: _profileImageBytes,
                              );
                              setState(() => _isSaving = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(Trans.t('save_profile', isTelugu)),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: Theme.of(context).primaryColor,
                                  ),
                                );
                                 if (Navigator.canPop(context)) {
                                  Navigator.pop(context);
                                } else if (widget.onBackPressed != null) {
                                  widget.onBackPressed!();
                                }
                              }
                            }
                          },
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20, width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  isTelugu ? 'ప్రొఫైల్ సేవ్ చేయండి' : 'Save Profile',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Resolution breakdown chart
            if (total > 0) ...[
              Text(
                isTelugu ? 'పరిష్కార విశ్లేషణ' : 'Resolution Breakdown',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 180,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 4,
                            centerSpaceRadius: 40,
                            sections: [
                              if (pending > 0)
                                PieChartSectionData(
                                  color: Colors.purple.shade400,
                                  value: pending.toDouble(),
                                  title: '$pending',
                                  radius: 40,
                                  titleStyle: const TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              if (inProgress > 0)
                                PieChartSectionData(
                                  color: Theme.of(context).primaryColor,
                                  value: inProgress.toDouble(),
                                  title: '$inProgress',
                                  radius: 40,
                                  titleStyle: const TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              if (resolved > 0)
                                PieChartSectionData(
                                  color: Colors.green.shade500,
                                  value: resolved.toDouble(),
                                  title: '$resolved',
                                  radius: 40,
                                  titleStyle: const TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Legend row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildLegendItem(Trans.t('pending', isTelugu), Colors.purple.shade400),
                          _buildLegendItem(Trans.t('in_progress', isTelugu), Theme.of(context).primaryColor),
                          _buildLegendItem(Trans.t('resolved', isTelugu), Colors.green.shade500),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 28),

            // Log out button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 1,
                ),
                icon: const Icon(Icons.logout),
                label: Text(
                  Trans.t('logout', isTelugu),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  await appState.logout();
                  if (context.mounted) {
                    Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
                  }
                },
              ),
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ],
    );
  }

  void _showFullScreenImage(ImageProvider imageProvider) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (ctx) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: InteractiveViewer(
            child: Image(image: imageProvider),
          ),
        ),
      ),
    ));
  }
}
