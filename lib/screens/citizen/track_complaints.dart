import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../chat_screen.dart';
import '../../services/app_state.dart';
import '../../services/translation_service.dart';
import '../../models/complaint.dart';
import '../../models/user.dart';
import '../../widgets/video_preview.dart';
import '../../utils/category_mapping.dart';
import '../../utils/mandal_mapping.dart';

class TrackComplaintsScreen extends StatefulWidget {
  const TrackComplaintsScreen({super.key});

  @override
  State<TrackComplaintsScreen> createState() => _TrackComplaintsScreenState();
}

class _TrackComplaintsScreenState extends State<TrackComplaintsScreen> {
  String _statusFilterKey = 'all'; // 'all', 'pending', 'active', 'done'
  String? _selectedFeedbackRating; // 'poor', 'good', 'excellent'

  final Map<String, String> _filterKeyLabels = {
    'all': 'all',
    'pending': 'pending',
    'active': 'active',
    'done': 'done',
  };

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isTelugu = appState.isTelugu;
    final user = appState.currentUser;

    final allComplaints = appState.complaints.where((c) {
      if (user?.role == UserRole.wardAdmin) {
        return c.wardName == user?.wardName;
      } else if (user?.role == UserRole.categoryOfficer) {
        return CategoryMapping.getOfficerRoleForCategory(c.category) == user?.officerRole;
      } else if (user?.role == UserRole.mandalOfficer) {
        String cMandal = c.mandalName.isNotEmpty && c.mandalName != 'Unknown' 
            ? c.mandalName 
            : MandalMapping.getMandalForVillage(c.villageName);
        String normC = cMandal.toLowerCase().replaceAll(' mandal', '').trim();
        String normU = (user?.mandalName ?? '').toLowerCase().replaceAll(' mandal', '').trim();
        if (normU.isEmpty) return true;
        return normC.contains(normU) || normU.contains(normC);
      } else if (user?.role == UserRole.superAdmin) {
        return true;
      }
      // Default to citizen view
      return c.userId == user?.id;
    }).toList();

    final complaints = allComplaints.where((c) {
      if (_statusFilterKey == 'all') return true;
      if (_statusFilterKey == 'pending') {
        return c.status == ComplaintStatus.submitted;
      }
      if (_statusFilterKey == 'active') {
        return c.status == ComplaintStatus.inProgress;
      }
      if (_statusFilterKey == 'done') {
        return c.status == ComplaintStatus.resolved;
      }
      return true;
    }).toList();

    if (appState.highlightedComplaintId != null) {
      final index = complaints.indexWhere((c) => c.id == appState.highlightedComplaintId);
      if (index != -1) {
        final item = complaints.removeAt(index);
        complaints.add(item); // Added to end so it renders at top
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (Navigator.canPop(context)) ...[
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
                    onPressed: () {
                      appState.setHighlightedComplaintId(null);
                      Navigator.pop(context);
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Trans.t('track_history', isTelugu),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        isTelugu 
                            ? 'మీ ఫిర్యాదుల పరిష్కార పురోగతిని పర్యవేక్షించండి.' 
                            : 'Monitor resolution progress of your complaints.',
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                // Live sync status
                GestureDetector(
                  onTap: () {
                    if (!appState.isSupabaseConnected) {
                      appState.retryConnection();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isTelugu ? 'డేటాబేస్కి సింక్ చేయబడుతోంది...' : 'Retrying Database Sync...'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: appState.isSupabaseConnected
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: appState.isSupabaseConnected
                            ? const Color(0xFF86EFAC)
                            : const Color(0xFFFDE047),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          appState.isSupabaseConnected ? Icons.sensors : Icons.sensors_off,
                          size: 12,
                          color: appState.isSupabaseConnected
                              ? const Color(0xFF15803D)
                              : const Color(0xFFB45309),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          appState.isSupabaseConnected 
                              ? (isTelugu ? 'లైవ్' : 'Live') 
                              : (isTelugu ? 'సింక్ చేయడానికి నొక్కండి' : 'Tap to Sync'),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: appState.isSupabaseConnected
                                ? const Color(0xFF15803D)
                                : const Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
            const SizedBox(height: 20),

            // Count summary chips row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _countSummaryChip(
                    Trans.t('all', isTelugu),
                    allComplaints.length,
                    const Color(0xFF0F172A),
                  ),
                  const SizedBox(width: 8),
                  _countSummaryChip(
                    Trans.t('pending', isTelugu),
                    allComplaints.where((c) => c.status == ComplaintStatus.submitted).length,
                    Colors.purple.shade700,
                  ),
                  const SizedBox(width: 8),
                  _countSummaryChip(
                    Trans.t('active', isTelugu),
                    allComplaints.where((c) => c.status == ComplaintStatus.inProgress).length,
                    Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  _countSummaryChip(
                    Trans.t('done', isTelugu),
                    allComplaints.where((c) => c.status == ComplaintStatus.resolved).length,
                    Colors.green.shade700,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Filter chips
            Row(
              children: ['all', 'pending', 'active', 'done'].map((filterKey) {
                final bool isSelected = _statusFilterKey == filterKey;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(
                      Trans.t(_filterKeyLabels[filterKey]!, isTelugu),
                      style: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF0F172A),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: Theme.of(context).primaryColor,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
                    ),
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _statusFilterKey = filterKey;
                        });
                      }
                    },
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Complaints list
            Expanded(
              child: complaints.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_open_outlined, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                            Trans.t('no_complaints', isTelugu),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: complaints.length,
                      itemBuilder: (context, index) {
                        // Render newest first
                        final comp = complaints[complaints.length - 1 - index];
                        return _buildComplaintCard(context, comp);
                      },
                    ),
            ),
            const SizedBox(height: 70),
          ],
        ),
      ),
    );
  }

  Widget _countSummaryChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        '$count $label',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildComplaintCard(BuildContext context, Complaint complaint) {
    final appState = Provider.of<AppState>(context);
    final user = appState.currentUser;
    final isTelugu = appState.isTelugu;
    final isHighlighted = complaint.id == appState.highlightedComplaintId;

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      shadowColor: Colors.black.withValues(alpha: 0.05),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: isHighlighted,
          tilePadding: EdgeInsets.zero,
          trailing: const SizedBox.shrink(),
          title: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)], // Purple gradient
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: const Color(0xFF7C3AED).withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 6))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Complaint ID', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(
                            'PC/${complaint.id.toUpperCase().substring(0, 8)}',
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: complaint.status == ComplaintStatus.resolved ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        complaint.statusText.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Reported On', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 2),
                          Text(
                            _formatDate(complaint.createdAt),
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Category', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 2),
                          Text(
                            _getTranslatedCategory(complaint.category, isTelugu),
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        Trans.t('res_timeline', isTelugu),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (complaint.status == ComplaintStatus.resolved ? const Color(0xFF22C55E) : const Color(0xFF3B82F6)).withValues(alpha: 0.1), 
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.analytics, size: 12, color: complaint.status == ComplaintStatus.resolved ? const Color(0xFF22C55E) : const Color(0xFF3B82F6)),
                            const SizedBox(width: 4),
                            Text(
                              complaint.status == ComplaintStatus.resolved ? '100% Complete' : (complaint.status == ComplaintStatus.inProgress ? '65% Complete' : '25% Complete'),
                              style: TextStyle(color: complaint.status == ComplaintStatus.resolved ? const Color(0xFF22C55E) : const Color(0xFF3B82F6), fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildTimelineStepper(complaint, isTelugu),

                  // Officer Contact Card (If Assigned or In Progress)
                  if (complaint.status != ComplaintStatus.submitted) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                            child: Icon(Icons.person, color: Theme.of(context).primaryColor),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(isTelugu ? 'కేటాయించిన అధికారి' : 'Assigned Officer', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 2),
                                Text(isTelugu ? 'వార్డు స్పెషలిస్ట్' : 'Ward Specialist', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              ],
                            ),
                          ),
                          IconButton.filledTonal(
                            icon: const Icon(Icons.call, size: 20),
                            onPressed: () {}, // Action intact for real implementation
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  
                  // Identity Summary metadata block
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Column(
                      children: [
                        _detailRow(Icons.person_outline, isTelugu ? 'రిపోర్టర్' : 'Reporter', complaint.citizenName),
                        const SizedBox(height: 6),
                        _detailRow(Icons.phone_outlined, isTelugu ? 'మొబైల్ సంఖ్య' : 'Phone', complaint.citizenPhone),
                        if (complaint.wardName.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          _detailRow(Icons.map_outlined, isTelugu ? 'వార్డు' : 'Ward', isTelugu ? complaint.wardName.replaceAll('Ward', 'వార్డు') : complaint.wardName),
                        ],
                        if (complaint.address.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          _detailRow(Icons.location_on_outlined, isTelugu ? 'చిరునామా' : 'Location', complaint.address),
                        ],
                        const SizedBox(height: 6),
                        _detailRow(
                          Icons.gps_fixed,
                          'GPS',
                          '${complaint.latitude.toStringAsFixed(6)}, ${complaint.longitude.toStringAsFixed(6)}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Details Description
                  Text(
                    Trans.t('details', isTelugu),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    complaint.description,
                    style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
                  ),
                  const SizedBox(height: 16),

                  _buildEvidenceImagesSection(context, complaint, isTelugu),

                  // Citizen Feedback section
                  if (complaint.status == ComplaintStatus.resolved) ...[
                    const Divider(height: 24),
                    _buildFeedbackSection(complaint, isTelugu, user),
                  ],

                  if (user != null && user.role != UserRole.citizen) ...[
                    const SizedBox(height: 16),
                    _buildOfficerActions(context, complaint, isTelugu, user, appState),
                  ],
                  
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _actionButton(Icons.visibility_outlined, 'View Details', () {}),
                      _actionButton(Icons.chat_bubble_outline, 'Contact Officer', () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(complaint: complaint)));
                      }),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildOfficerActions(BuildContext context, Complaint c, bool isTelugu, User user, AppState appState) {
    if (c.status == ComplaintStatus.resolved) return const SizedBox();

    int requiredSlaHours = 0;
    if (user.role == UserRole.categoryOfficer) {
      requiredSlaHours = 0; // Immediate
    } else if (user.role == UserRole.wardAdmin) {
      requiredSlaHours = 24;
    } else if (user.role == UserRole.mandalOfficer) {
      requiredSlaHours = 48;
    } else if (user.role == UserRole.superAdmin) {
      requiredSlaHours = 72;
    }

    final hoursSinceCreated = DateTime.now().difference(c.createdAt).inHours;
    final canResolve = requiredSlaHours == 0 || hoursSinceCreated >= requiredSlaHours;

    void showPushDialog() {
      String? selectedTarget = 'Mandal Officer';
      showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text(isTelugu ? 'అధికారికి బదిలీ చేయండి' : 'Push Complaint to Officer'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isTelugu ? 'అధికారిని ఎంచుకోండి:' : 'Select Target Officer:'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedTarget,
                      items: [
                        DropdownMenuItem(value: 'Ward Officer', child: Text(isTelugu ? 'వార్డు అధికారి (Ward Officer)' : 'Ward Officer')),
                        DropdownMenuItem(value: 'Mandal Officer', child: Text(isTelugu ? 'మండల అధికారి (Mandal Officer)' : 'Mandal Officer')),
                        DropdownMenuItem(value: 'MLA', child: Text(isTelugu ? 'ఎమ్మెల్యే (MLA)' : 'MLA')),
                      ],
                      onChanged: (val) {
                        setState(() {
                          selectedTarget = val;
                        });
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(isTelugu ? 'రద్దు చేయి' : 'Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (selectedTarget != null) {
                        await appState.escalateComplaint(c.id, selectedTarget!);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(isTelugu 
                              ? 'ఫిర్యాదు విజయవంతంగా బదిలీ చేయబడింది!' 
                              : 'Complaint successfully pushed!'),
                          ));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                    child: Text(isTelugu ? 'బదిలీ చేయి' : 'Push'),
                  ),
                ],
              );
            },
          );
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canResolve) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(complaint: c)));
                  },
                  icon: const Icon(Icons.chat, size: 18),
                  label: Text(isTelugu ? 'చాట్' : 'Chat'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: showPushDialog,
                  icon: const Icon(Icons.arrow_upward, size: 18),
                  label: Text(isTelugu ? 'నివేదించండి' : 'Push'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () async {
              if (c.status == ComplaintStatus.submitted) {
                await appState.updateComplaintStatus(c.id, ComplaintStatus.inProgress);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(isTelugu 
                        ? 'ఫిర్యాదు పురోగతిలోకి మార్చబడింది.' 
                        : 'Complaint status changed to In Progress.'),
                  ));
                }
              } else if (c.status == ComplaintStatus.inProgress) {
                final picker = ImagePicker();
                final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
                if (picked != null) {
                  await appState.updateComplaintStatus(c.id, ComplaintStatus.resolved, resolvedImageUrl: picked.path);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(isTelugu ? 'ఫిర్యాదు పరిష్కరించబడింది!' : 'Complaint Resolved!'),
                    ));
                  }
                }
              }
            },
            icon: const Icon(Icons.camera_alt, size: 18),
            label: Text(
              isTelugu 
                  ? 'వెంటనే పరిష్కరించండి (ఫోటో అవసరం)' 
                  : 'Resolve Immediately (Photo Required)',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green, 
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_clock, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isTelugu 
                        ? 'చర్య నిలిపివేయబడింది. $requiredSlaHours గంటల తర్వాత మీరు దీన్ని పరిష్కరించవచ్చు.' 
                        : 'Action locked. Escalated to you in $requiredSlaHours hours limit.',
                    style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEvidenceImagesSection(BuildContext context, Complaint comp, bool isTelugu) {
    final hasBefore = comp.imageUrl != null;
    final hasAfter = comp.resolvedImageUrl != null;

    if (!hasBefore && !hasAfter) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            if (hasBefore)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Trans.t('before_photo', isTelugu),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        height: 130,
                        width: double.infinity,
                        child: _buildImageWidget(context, comp.imageUrl!, isVideo: comp.isVideoEvidence),
                      ),
                    ),
                  ],
                ),
              ),
            if (hasBefore && hasAfter) const SizedBox(width: 12),
            if (hasAfter)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Trans.t('after_photo', isTelugu),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        height: 130,
                        width: double.infinity,
                        child: _buildImageWidget(context, comp.resolvedImageUrl!, isVideo: comp.isResolvedVideoEvidence),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildImageWidget(BuildContext context, String path, {bool isVideo = false}) {
    if (isVideo) {
      return VideoPreviewWidget(videoUrl: path);
    }
    Widget imageWidget;
    if (path.startsWith('local:') || path.startsWith('file://') || path.startsWith('/')) {
      if (kIsWeb) {
        imageWidget = Container(
          color: Colors.grey.shade100,
          child: const Center(
            child: Icon(Icons.image, color: Colors.grey, size: 28),
          ),
        );
      } else {
        String filePath = path;
        if (path.startsWith('local:')) {
          filePath = path.substring(6);
        } else if (path.startsWith('file://')) {
          filePath = path.replaceFirst('file://', '');
        }

        
        final file = File(filePath);
        if (file.existsSync()) {
          imageWidget = Image.file(file, fit: BoxFit.cover);
        } else {
          imageWidget = Container(
            color: Colors.grey.shade100,
            child: Center(
              child: Icon(Icons.broken_image, color: Colors.grey.shade400, size: 28),
            ),
          );
        }
      }
    } else {
      imageWidget = Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          color: Colors.grey.shade100,
          child: const Center(
            child: Icon(Icons.broken_image, color: Colors.grey, size: 28),
          ),
        ),
      );
    }
    
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(10),
            child: Stack(
              alignment: Alignment.center,
              children: [
                InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4,
                  child: _buildInteractiveImage(path),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 30),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: imageWidget,
    );
  }

  Widget _buildInteractiveImage(String path) {
    if (path.startsWith('local:') || path.startsWith('file://') || path.startsWith('/')) {
      if (kIsWeb) return const Icon(Icons.image, color: Colors.white, size: 50);
      String filePath = path;
      if (path.startsWith('local:')) {
        filePath = path.substring(6);
      } else if (path.startsWith('file://')) {
        filePath = path.replaceFirst('file://', '');
      }

      
      final file = File(filePath);
      return file.existsSync() ? Image.file(file) : const Icon(Icons.broken_image, color: Colors.white, size: 50);
    }
    return Image.network(path);
  }

  Widget _buildFeedbackSection(Complaint comp, bool isTelugu, User? user) {
    final appState = Provider.of<AppState>(context, listen: false);

    if (comp.feedbackRating != null && comp.feedbackRating!.isNotEmpty) {
      String ratingEmoji = '😐';
      String ratingLabel = Trans.t(comp.feedbackRating!, isTelugu);
      if (comp.feedbackRating == 'poor') ratingEmoji = '🙁';
      if (comp.feedbackRating == 'good') ratingEmoji = '😐';
      if (comp.feedbackRating == 'excellent') ratingEmoji = '🙂';

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.rate_review, color: Colors.green, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isTelugu ? 'మీ అభిప్రాయం సమర్పించబడింది' : 'Feedback Submitted',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(ratingEmoji, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 6),
                      Text(
                        ratingLabel,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (user != null && user.role != UserRole.citizen) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey.shade600, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isTelugu ? 'ఇంకా అభిప్రాయం సమర్పించబడలేదు.' : 'No feedback submitted yet.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.rate_review_outlined, color: Theme.of(context).primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                Trans.t('give_feedback', isTelugu),
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            Trans.t('rate_resolution', isTelugu),
            style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _feedbackOptionButton('poor', '🙁', Trans.t('poor', isTelugu)),
              _feedbackOptionButton('good', '😐', Trans.t('good', isTelugu)),
              _feedbackOptionButton('excellent', '🙂', Trans.t('excellent', isTelugu)),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _selectedFeedbackRating == null
                ? null
                : () async {
                    await appState.submitComplaintFeedback(comp.id, _selectedFeedbackRating!);

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isTelugu ? 'ధన్యవాదాలు! మీ అభిప్రాయం సమర్పించబడింది మరియు ఫిర్యాదు మూసివేయబడింది.' : 'Thank you! Your feedback has been registered and the complaint closed.',
                        ),
                        backgroundColor: Theme.of(context).primaryColor,
                      ),
                    );
                    setState(() {
                      _selectedFeedbackRating = null;
                    });
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(
              Trans.t('submit_feedback', isTelugu),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _feedbackOptionButton(String ratingKey, String emoji, String label) {
    final isSelected = _selectedFeedbackRating == ratingKey;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFeedbackRating = ratingKey;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: Theme.of(context).primaryColor),
        const SizedBox(width: 6),
        Text('$label: ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        Expanded(
          child: Text(
            value.isEmpty ? '—' : value,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTimelineStepper(Complaint comp, bool isTelugu) {
    int currentStepIndex = 1;
    switch (comp.status) {
      case ComplaintStatus.submitted:
        currentStepIndex = 1;
        break;
      case ComplaintStatus.inProgress:
        currentStepIndex = 3;
        break;
      case ComplaintStatus.resolved:
        currentStepIndex = 5; // All completed
        break;
    }

    return Column(
      children: [
        _timelineStep(
          title: isTelugu ? 'ఫిర్యాదు సమర్పించబడింది' : 'Complaint Submitted',
          description: isTelugu ? 'ఫిర్యాదు మున్సిపల్ డేటాబేస్లో నమోదు చేయబడింది.' : 'Your complaint has been successfully registered.',
          time: _formatDate(comp.createdAt),
          isCompleted: currentStepIndex > 1,
          isActive: currentStepIndex == 1,
          isLast: false,
        ),
        _timelineStep(
          title: isTelugu ? 'అధికారికి కేటాయించబడింది' : 'Assigned to Officer',
          description: isTelugu ? 'అధికారి సమస్యను సమీక్షిస్తున్నారు.' : 'Officer is reviewing your complaint.',
          time: currentStepIndex > 1 ? _formatDate(comp.createdAt.add(const Duration(minutes: 30))) : '', 
          isCompleted: currentStepIndex > 2,
          isActive: currentStepIndex == 2,
          isLast: false,
        ),
        _timelineStep(
          title: isTelugu ? 'పురోగతిలో ఉంది' : 'In Progress',
          description: isTelugu ? 'క్షేత్రస్థాయిలో సమస్య పరిష్కార పనులు జరుగుతున్నాయి.' : 'Field correction works currently underway.',
          time: currentStepIndex > 3 ? (comp.resolvedAt != null ? _formatDate(comp.resolvedAt!) : '') : '',
          isCompleted: currentStepIndex > 3,
          isActive: currentStepIndex == 3,
          isLast: false,
        ),
        _timelineStep(
          title: isTelugu ? 'పరిష్కరించబడింది' : 'Resolved',
          description: isTelugu ? 'సమస్య పరిష్కరించబడింది, పరిష్కార ఫోటో అప్‌లోడ్ చేయబడింది.' : 'Issue resolved. Ward admin uploaded resolution photo.',
          time: currentStepIndex > 4 
              ? (comp.resolvedAt != null ? _formatDate(comp.resolvedAt!) : (isTelugu ? 'పరిష్కరించబడింది' : 'Resolved')) 
              : '',
          isCompleted: currentStepIndex > 4, 
          isActive: currentStepIndex == 4, 
          isLast: true,
        ),
      ],
    );
  }

  Widget _timelineStep({
    required String title,
    required String description,
    required String time,
    required bool isCompleted,
    required bool isActive,
    required bool isLast,
  }) {
    final color = isCompleted ? const Color(0xFF22C55E) : (isActive ? const Color(0xFFEAB308) : Colors.grey.shade300);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted ? const Color(0xFF22C55E) : (isActive ? const Color(0xFFEAB308) : Colors.transparent),
                border: Border.all(color: color, width: 2),
                shape: BoxShape.circle,
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : (isActive ? null : const SizedBox.shrink()),
            ),
            if (!isLast)
              Container(width: 2, height: 48, color: isCompleted ? const Color(0xFF22C55E) : Colors.grey.shade300),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isActive || isCompleted ? const Color(0xFF0F172A) : Colors.grey,
                      ),
                    ),
                  ),
                  if (time.isNotEmpty)
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: isActive || isCompleted ? Colors.grey.shade700 : Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Pothole & Road Repair':
        return Icons.edit_road;
      case 'Waste Management':
        return Icons.delete_outline;
      case 'Streetlight Issues':
        return Icons.lightbulb_outline;
      case 'Water Leakage':
        return Icons.water_drop_outlined;
      case 'Drainage & Sewerage':
        return Icons.plumbing;
      case 'Electricity & Power Issues':
        return Icons.bolt;
      case 'Public Sanitation':
        return Icons.cleaning_services;
      case 'Agriculture & Irrigation':
        return Icons.agriculture;
      default:
        return Icons.warning_amber_rounded;
    }
  }

  String _getTranslatedCategory(String category, bool isTelugu) {
    switch (category) {
      case 'Pothole & Road Repair':
        return Trans.t('pothole', isTelugu);
      case 'Waste Management':
        return Trans.t('waste', isTelugu);
      case 'Streetlight Issues':
        return Trans.t('streetlight', isTelugu);
      case 'Water Leakage':
        return Trans.t('water', isTelugu);
      case 'Drainage & Sewerage':
        return Trans.t('drainage', isTelugu);
      case 'Electricity & Power Issues':
        return Trans.t('electricity', isTelugu);
      case 'Public Sanitation':
        return Trans.t('sanitation', isTelugu);
      case 'Agriculture & Irrigation':
        return Trans.t('agriculture', isTelugu);
      default:
        return Trans.t('others', isTelugu);
    }
  }


  String _getTranslatedStatus(String statusText, bool isTelugu) {
    switch (statusText) {
      case 'Submitted':
        return Trans.t('submitted', isTelugu);
      case 'Verified':
        return Trans.t('verified', isTelugu);
      case 'Assigned':
        return Trans.t('assigned', isTelugu);
      case 'In Progress':
        return Trans.t('in_progress', isTelugu);
      case 'Resolved':
        return Trans.t('resolved', isTelugu);
      case 'Feedback':
        return Trans.t('feedback', isTelugu);
      case 'Closed':
        return Trans.t('closed', isTelugu);
      default:
        return statusText;
    }
  }

  String _getTranslatedPriority(String priorityText, bool isTelugu) {
    switch (priorityText) {
      case 'Low':
        return isTelugu ? 'తక్కువ' : 'Low';
      case 'Medium':
        return isTelugu ? 'మధ్యమ' : 'Medium';
      case 'High':
        return isTelugu ? 'ఎక్కువ' : 'High';
      default:
        return priorityText;
    }
  }
}
