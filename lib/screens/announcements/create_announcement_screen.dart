import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../../../models/announcement.dart';
import '../../../models/user.dart';
import '../../../services/app_state.dart';
import '../../../services/supabase_service.dart';

class CreateAnnouncementScreen extends StatefulWidget {
  const CreateAnnouncementScreen({super.key});

  @override
  State<CreateAnnouncementScreen> createState() =>
      _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends State<CreateAnnouncementScreen>
    with SingleTickerProviderStateMixin {
  final _titleController   = TextEditingController();
  final _messageController = TextEditingController();
  final _formKey           = GlobalKey<FormState>();

  String? _selectedAudience;
  bool    _isPublishing = false;

  // Media state
  Uint8List? _imageBytes;
  Uint8List? _pdfBytes;
  Uint8List? _voiceBytes;

  // Voice recording
  AudioRecorder? _recorder;
  bool           _isRecording = false;
  bool           _hasRecorded = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _recorder?.dispose();
    super.dispose();
  }

  // ─── Role-based audience options ──────────────────────────────
  List<_AudienceOption> _getAudienceOptions(User user) {
    const all = [
      _AudienceOption('Mandal Officers', 'mandalOfficer', Icons.business_center),
      _AudienceOption('Category Officers', 'categoryOfficer', Icons.category),
      _AudienceOption('Ward Members', 'wardAdmin', Icons.location_city),
      _AudienceOption('Citizens', 'citizen', Icons.people),
      _AudienceOption('All', null, Icons.public),
    ];

    switch (user.role) {
      case UserRole.superAdmin:
        return all;
      case UserRole.mandalOfficer:
        return all.where((o) => o.targetId != 'mandalOfficer').toList();
      case UserRole.categoryOfficer:
        return all.where((o) =>
          o.targetId != 'mandalOfficer' &&
          o.targetId != 'categoryOfficer'
        ).toList();
      case UserRole.wardAdmin:
        return [const _AudienceOption('Citizens', 'citizen', Icons.people)];
      default:
        return [];
    }
  }

  // ─── Image picker ──────────────────────────────────────────────
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Camera'),
            onTap: () async {
              Navigator.pop(ctx);
              final img = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
              if (img != null) {
                final bytes = await img.readAsBytes();
                if (mounted) setState(() => _imageBytes = bytes);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Gallery'),
            onTap: () async {
              Navigator.pop(ctx);
              final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
              if (img != null) {
                final bytes = await img.readAsBytes();
                if (mounted) setState(() => _imageBytes = bytes);
              }
            },
          ),
        ]),
      ),
    );
  }

  // ─── PDF picker ────────────────────────────────────────────────
  Future<void> _pickPdf() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result != null && result.files.single.bytes != null && mounted) {
      setState(() {
        _pdfBytes = result.files.single.bytes;
      });
    }
  }

  // ─── Voice recorder ───────────────────────────────────────────
  Future<void> _toggleRecording() async {
    _recorder ??= AudioRecorder();

    if (_isRecording) {
      final path = await _recorder!.stop();
      if (path != null && mounted) {
        Uint8List? bytes;
        if (kIsWeb) {
          try {
            final res = await http.get(Uri.parse(path));
            bytes = res.bodyBytes;
          } catch (e) {
            debugPrint('Failed to fetch blob for audio: $e');
          }
        } else {
          bytes = await File(path).readAsBytes();
        }

        if (bytes != null) {
          setState(() {
            _isRecording = false;
            _voiceBytes = bytes;
            _hasRecorded = true;
          });
        } else {
          setState(() => _isRecording = false);
        }
      }
    } else {
      final hasPermission = await _recorder!.hasPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission is required.')),
          );
        }
        return;
      }
      String path = '';
      if (!kIsWeb) {
        final dir = await getTemporaryDirectory();
        path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      }
      await _recorder!.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
      if (mounted) setState(() => _isRecording = true);
    }
  }

  // ─── Publish logic ─────────────────────────────────────────────
  Future<void> _publish(AppState appState) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAudience == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a target audience.')),
      );
      return;
    }

    if (_isRecording) await _toggleRecording();

    final user = appState.currentUser;
    if (user == null) return;

    setState(() => _isPublishing = true);

    try {
      final announcementId = 'ann_${DateTime.now().millisecondsSinceEpoch}';

      // Upload media files if present
      String? imageUrl, voiceUrl, pdfUrl;

      if (_imageBytes != null) {
        imageUrl = await SupabaseService.uploadAnnouncementImageBytes(_imageBytes!, announcementId);
      }
      if (_voiceBytes != null) {
        voiceUrl = await SupabaseService.uploadAnnouncementVoiceBytes(_voiceBytes!, announcementId);
      }
      if (_pdfBytes != null) {
        pdfUrl = await SupabaseService.uploadAnnouncementPdfBytes(_pdfBytes!, announcementId);
      }

      // Resolve target_type / target_id from selected audience
      final options = _getAudienceOptions(user);
      final selected = options.firstWhere(
        (o) => o.label == _selectedAudience,
        orElse: () => options.first,
      );

      final announcement = Announcement(
        id:             announcementId,
        title:          _titleController.text.trim(),
        message:        _messageController.text.trim(),
        imageUrl:       imageUrl,
        voiceUrl:       voiceUrl,
        attachmentUrl:  pdfUrl,
        createdById:    user.id,
        createdByRole:  user.role.toString().split('.').last,
        createdByName:  user.name,
        categoryScope:  user.role == UserRole.categoryOfficer ? user.officerRole : null,
        targetAudience: _selectedAudience!,
        targetType:     selected.targetId == null ? 'all' : 'role',
        targetId:       selected.targetId,
        targetMandal:   user.mandalName,
        targetPanchayat: user.role == UserRole.categoryOfficer ? user.wardId : null,
        targetWard:     user.role == UserRole.wardAdmin ? user.wardName : null,
        totalSent:      0,
        createdAt:      DateTime.now().toUtc(),
      );

      // DB trigger auto-creates notifications — no manual Flutter insertion needed
      await SupabaseService.createAnnouncement(announcement);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Text('Announcement published! Notifications sent automatically.'),
              ],
            ),
            backgroundColor: Color(0xFF2E7D32),
            duration: Duration(seconds: 4),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to publish: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user     = appState.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    final options = _getAudienceOptions(user);
    if (options.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('New Announcement')),
        body: const Center(child: Text('You are not authorized to broadcast.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('New Announcement', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: _isPublishing
          ? _buildPublishingOverlay()
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Audience selector ───────────────────────────
                    _sectionLabel('Target Audience', Icons.group, required: true),
                    const SizedBox(height: 8),
                    _buildAudienceSelector(options),
                    const SizedBox(height: 20),

                    // ── Title field ─────────────────────────────────
                    _sectionLabel('Announcement Title', Icons.title, required: true),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      decoration: _inputDecoration('Enter announcement title', Icons.short_text),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 20),

                    // ── Message field ───────────────────────────────
                    _sectionLabel('Message', Icons.message_outlined, required: true),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _messageController,
                      maxLines: 5,
                      decoration: _inputDecoration('Write your announcement message here...', Icons.notes),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Message is required' : null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 24),

                    // ── Media attachments ───────────────────────────
                    _sectionLabel('Attachments', Icons.attach_file, required: false),
                    const SizedBox(height: 10),
                    _buildMediaRow(),
                    const SizedBox(height: 32),

                    // ── Publish button ──────────────────────────────
                    _buildPublishButton(appState),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAudienceSelector(List<_AudienceOption> options) {
    // If only one option (Ward Member → Citizens), pre-select it
    if (options.length == 1 && _selectedAudience == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedAudience = options.first.label);
      });
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedAudience,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          prefixIcon: Icon(Icons.people_outline, color: Color(0xFF1565C0)),
        ),
        hint: const Text('Select target audience'),
        isExpanded: true,
        items: options.map((opt) {
          return DropdownMenuItem<String>(
            value: opt.label,
            child: Row(
              children: [
                Icon(opt.icon, size: 18, color: const Color(0xFF1565C0)),
                const SizedBox(width: 10),
                Text(opt.label),
              ],
            ),
          );
        }).toList(),
        onChanged: (val) => setState(() => _selectedAudience = val),
        validator: (v) => v == null ? 'Select an audience' : null,
      ),
    );
  }

  Widget _buildMediaRow() {
    return Row(
      children: [
        // Image
        Expanded(child: _mediaButton(
          icon:    _imageBytes != null ? Icons.check_circle : Icons.image_outlined,
          label:   _imageBytes != null ? 'Image Added' : 'Add Image',
          color:   _imageBytes != null ? Colors.green : const Color(0xFF1565C0),
          onTap:   _pickImage,
          canClear: _imageBytes != null,
          onClear: () => setState(() => _imageBytes = null),
        )),
        const SizedBox(width: 8),
        // PDF
        Expanded(child: _mediaButton(
          icon:    _pdfBytes != null ? Icons.check_circle : Icons.picture_as_pdf_outlined,
          label:   _pdfBytes != null ? 'PDF Added' : 'Add PDF',
          color:   _pdfBytes != null ? Colors.green : Colors.red.shade700,
          onTap:   _pickPdf,
          canClear: _pdfBytes != null,
          onClear: () => setState(() => _pdfBytes = null),
        )),
        const SizedBox(width: 8),
        // Voice
        Expanded(child: _mediaButton(
          icon:    _isRecording ? Icons.stop_circle : (_voiceBytes != null || _hasRecorded ? Icons.check_circle : Icons.mic_none),
          label:   _isRecording ? 'Stop Recording' : (_voiceBytes != null || _hasRecorded ? 'Voice Added' : 'Record Voice'),
          color:   _isRecording ? Colors.red : (_voiceBytes != null || _hasRecorded ? Colors.green : Colors.purple.shade700),
          onTap:   _toggleRecording,
          canClear: _voiceBytes != null && !_isRecording,
          onClear: () => setState(() { _voiceBytes = null; _hasRecorded = false; }),
        )),
      ],
    );
  }

  Widget _mediaButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool canClear,
    required VoidCallback onClear,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 26),
                const SizedBox(height: 6),
                Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
        if (canClear)
          Positioned(
            top: -6,
            right: -6,
            child: GestureDetector(
              onTap: onClear,
              child: Container(
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPublishButton(AppState appState) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFF1565C0).withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: ElevatedButton.icon(
        onPressed: () => _publish(appState),
        icon: const Icon(Icons.send_rounded, size: 22),
        label: const Text('Publish Announcement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildPublishingOverlay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(strokeWidth: 3),
          const SizedBox(height: 24),
          const Text('Publishing announcement...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text('Notifications are being sent automatically.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      prefixIcon: Icon(icon, color: const Color(0xFF1565C0)),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.red)),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }

  Widget _sectionLabel(String label, IconData icon, {required bool required}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1565C0)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A237E))),
        if (required) ...[
          const SizedBox(width: 4),
          const Text('*', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ],
      ],
    );
  }
}

// ── Simple data class for audience options ─────────────────────────
class _AudienceOption {
  final String label;
  final String? targetId; // null means 'all'
  final IconData icon;
  const _AudienceOption(this.label, this.targetId, this.icon);
}
