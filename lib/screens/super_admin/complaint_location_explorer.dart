
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/app_state.dart';
import '../../services/translation_service.dart';
import '../../models/complaint.dart';
import '../../utils/mandal_mapping.dart';
import '../citizen/track_complaints.dart';

class ComplaintLocationExplorer extends StatefulWidget {
  const ComplaintLocationExplorer({super.key});

  @override
  State<ComplaintLocationExplorer> createState() => _ComplaintLocationExplorerState();
}

class _ComplaintLocationExplorerState extends State<ComplaintLocationExplorer> {
  String? _selectedMandal;
  String? _selectedPanchayat;
  String? _selectedVillage;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isTelugu = appState.isTelugu;
    
    // 1. Mandals
    final mandals = MandalMapping.mandals;
    
    // 2. Panchayats
    List<String> panchayats = [];
    if (_selectedMandal != null) {
      panchayats = MandalMapping.getPanchayatsForMandal(_selectedMandal!, appState.uniquePanchayats);
    }
    
    // 3. Villages
    List<String> villages = [];
    List<Complaint> panchayatComplaints = [];
    if (_selectedPanchayat != null) {
      // Fetch master list of villages for this panchayat
      villages = MandalMapping.getVillagesForPanchayat(_selectedPanchayat!);

      // Find complaints that belong to this panchayat
      panchayatComplaints = appState.complaints.where((c) {
        return villages.any((v) => v.toLowerCase() == c.villageName.trim().toLowerCase());
      }).toList();
      
      // Validation Log
      debugPrint('--- Validation Log ---');
      debugPrint('Selected Mandal: $_selectedMandal');
      debugPrint('Selected Panchayat: $_selectedPanchayat');
      debugPrint('Matched Mandal-Panchayat Relationship: ${_selectedMandal != null && MandalMapping.getPanchayatsForMandal(_selectedMandal!, appState.uniquePanchayats).contains(_selectedPanchayat)}');
      debugPrint('Village Count Loaded: ${villages.length}');
      debugPrint('----------------------');
    }
    
    // 4. Complaints List
    List<Complaint> villageComplaints = [];
    if (_selectedVillage != null) {
      villageComplaints = panchayatComplaints.where((c) {
        final vName = c.villageName.trim().isEmpty ? 'Unknown Village' : c.villageName.trim();
        return vName.toLowerCase() == _selectedVillage!.toLowerCase();
      }).toList();
      // Sort by latest
      villageComplaints.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isTelugu ? 'ఫిర్యాదు స్థాన విశ్లేషణ' : 'Complaint Location Explorer',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 4),
        Text(
          isTelugu 
            ? 'మండలం, పంచాయతీ మరియు గ్రామం వారీగా ఫిర్యాదులను ఫిల్టర్ చేయండి.' 
            : 'Filter and explore complaints down to the village level.',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        
        // Cascading Dropdowns
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Level 1: Mandal
                DropdownButtonFormField<String>(
                  key: ValueKey('mandal_$_selectedMandal'),
                  decoration: InputDecoration(
                    labelText: isTelugu ? 'మండలం ఎంచుకోండి' : 'Select Mandal',
                    prefixIcon: Icon(Icons.map_outlined, color: Theme.of(context).primaryColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  initialValue: _selectedMandal,
                  items: mandals.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedMandal = val;
                      _selectedPanchayat = null;
                      _selectedVillage = null;
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Level 2: Panchayat
                DropdownButtonFormField<String>(
                  key: ValueKey('panchayat_$_selectedPanchayat'),
                  decoration: InputDecoration(
                    labelText: isTelugu ? 'పంచాయతీ ఎంచుకోండి' : 'Select Panchayat',
                    prefixIcon: Icon(Icons.account_balance_outlined, color: _selectedMandal != null ? Theme.of(context).primaryColor : Colors.grey),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    filled: _selectedMandal == null,
                    fillColor: _selectedMandal == null ? Colors.grey.shade100 : Colors.transparent,
                  ),
                  initialValue: _selectedPanchayat,
                  items: panchayats.map((p) => DropdownMenuItem(value: p, child: Text(p, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: _selectedMandal == null ? null : (val) {
                    setState(() {
                      _selectedPanchayat = val;
                      _selectedVillage = null;
                    });
                  },
                  hint: Text(isTelugu ? 'ముందుగా మండలాన్ని ఎంచుకోండి' : 'Select Mandal first'),
                ),
                const SizedBox(height: 16),
                
                // Level 3: Village
                DropdownButtonFormField<String>(
                  key: ValueKey('village_$_selectedVillage'),
                  decoration: InputDecoration(
                    labelText: isTelugu ? 'గ్రామం ఎంచుకోండి' : 'Select Village',
                    prefixIcon: Icon(Icons.holiday_village_outlined, color: _selectedPanchayat != null ? Theme.of(context).primaryColor : Colors.grey),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    filled: _selectedPanchayat == null,
                    fillColor: _selectedPanchayat == null ? Colors.grey.shade100 : Colors.transparent,
                  ),
                  initialValue: _selectedVillage,
                  items: villages.map((v) => DropdownMenuItem(value: v, child: Text(v, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: _selectedPanchayat == null || villages.isEmpty ? null : (val) {
                    setState(() {
                      _selectedVillage = val;
                    });
                  },
                  hint: Text(_selectedPanchayat == null 
                      ? (isTelugu ? 'ముందుగా పంచాయతీని ఎంచుకోండి' : 'Select Panchayat first')
                      : (villages.isEmpty 
                          ? (isTelugu ? 'గ్రామాలు కనుగొనబడలేదు' : 'No villages found') 
                          : (isTelugu ? 'గ్రామాన్ని ఎంచుకోండి' : 'Select a village'))),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Level 4: Complaints List
        if (_selectedVillage != null) ...[
          Text(
            isTelugu ? '$_selectedVillage లో ఫిర్యాదులు' : 'Complaints in $_selectedVillage',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),
          if (villageComplaints.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 36),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    isTelugu ? 'ఈ గ్రామంలో ఫిర్యాదులు లేవు.' : 'No complaints found in this village.',
                    style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: villageComplaints.length,
              separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
              itemBuilder: (ctx, index) {
                final c = villageComplaints[index];
                return _buildComplaintCard(context, c, isTelugu);
              },
            ),
        ],
      ],
    );
  }

  Widget _buildComplaintCard(BuildContext context, Complaint c, bool isTelugu) {
    final appState = Provider.of<AppState>(context, listen: false);
    return InkWell(
      onTap: () {
        appState.setHighlightedComplaintId(c.id);
        Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackComplaintsScreen()));
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.receipt_long, size: 14, color: Theme.of(context).primaryColor),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          c.id,
                          style: const TextStyle(
                            fontSize: 12, 
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: c.statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: c.statusColor.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    c.statusText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: c.statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              Trans.t(c.category.toLowerCase().replaceAll(' & ', '_').replaceAll(' ', '_'), isTelugu) == 'Missing Translation' 
                ? c.category 
                : Trans.t(c.category.toLowerCase().replaceAll(' & ', '_').replaceAll(' ', '_'), isTelugu),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd MMM yyyy, hh:mm a').format(c.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const Spacer(),
                Icon(Icons.location_on_outlined, size: 12, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  c.wardName.split(' - ').first,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}

