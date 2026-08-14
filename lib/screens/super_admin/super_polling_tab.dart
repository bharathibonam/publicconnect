import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_demo_app/l10n/app_localizations.dart';
import '../../themes/theme_provider.dart';
import '../../services/supabase_service.dart';
import '../../services/app_state.dart';
import 'dart:convert';
import '../../data/election_data_fallback.dart';


class SuperPollingTab extends StatefulWidget {
  const SuperPollingTab({super.key});

  @override
  State<SuperPollingTab> createState() => _SuperPollingTabState();
}

class _SuperPollingTabState extends State<SuperPollingTab> {
  String _selectedSegment = 'ALL';
  String _selectedLeadFilter = 'ALL';
  String _searchQuery = '';
  bool _isLoading = true;
  bool _showDetails = false;
  List<Map<String, dynamic>> _rawElectionData = [];

  final List<Map<String, String>> _assemblySegments = [
    {'code': 'ALL', 'name': '8. Rajahmundry Parliamentary Constituency', 'desc': 'All 1,557 Booths', 'icon': '🗳️'},
    {'code': '70 Rajahmundry Rural', 'name': '70 Rajahmundry Rural', 'desc': '264 Booths', 'icon': '🚜'},
    {'code': '40 Anaparthy', 'name': '40 Anaparthy', 'desc': '228 Booths', 'icon': '🌾'},
    {'code': '49 Rajanagaram', 'name': '49 Rajanagaram', 'desc': '216 Booths', 'icon': '🏭'},
    {'code': '50 Rajahmundry City', 'name': '50 Rajahmundry City', 'desc': '237 Booths', 'icon': '🏢'},
    {'code': '55 Nidadavole', 'name': '55 Nidadavole', 'desc': '205 Booths', 'icon': '🌳'},
    {'code': '66 Gopalapuram', 'name': '66 Gopalapuram SC', 'desc': '238 Booths', 'icon': '🏞️'},
    {'code': '67 Kovvur', 'name': '67 Kovvur', 'desc': '169 Booths', 'icon': '🌉'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.getElectionResults(
        assemblySegment: _selectedSegment == 'ALL' ? null : _selectedSegment,
      );
      if (data.isNotEmpty) {
        setState(() {
          _rawElectionData = data;
          _isLoading = false;
        });
      } else {
        _useFallbackData();
      }
    } catch (e) {
      _useFallbackData();
    }
  }

  void _useFallbackData() {
    List<Map<String, dynamic>> filtered = kAllElectionRecords;
    if (_selectedSegment != 'ALL') {
      final cleanFilter = _selectedSegment.replaceAll(RegExp(r'^\d+\s*'), '').toLowerCase().trim();
      filtered = kAllElectionRecords.where((r) {
        final seg = (r['assembly_segment'] ?? '').toString().toLowerCase();
        final code = (r['assembly_segment_code'] ?? '').toString().toLowerCase();
        return seg.contains(cleanFilter) || code.contains(cleanFilter) || cleanFilter.contains(seg);
      }).toList();
    }

    setState(() {
      _rawElectionData = filtered;
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredRecords {
    return _rawElectionData.where((rec) {
      final int guduri = rec['dr_guduri_srinivas'] ?? 0;
      final int puran = rec['daggubati_purandheshwari'] ?? 0;
      final String psName = "PART ${rec['polling_station_number'] ?? rec['serial_number'] ?? ''}";

      // Filter by Search Query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchPs = psName.toLowerCase().contains(query);
        final matchSeg = (rec['assembly_segment'] ?? '').toString().toLowerCase().contains(query);
        if (!matchPs && !matchSeg) return false;
      }

      // Filter by Ward Strength / Lead Filter
      if (_selectedLeadFilter == 'PURANDHESHWARI') {
        if (puran <= guduri) return false;
      } else if (_selectedLeadFilter == 'GUDURI') {
        if (guduri <= puran) return false;
      } else if (_selectedLeadFilter == 'TIED') {
        if (guduri != puran) return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final themeConfig = Provider.of<ThemeProvider>(context).activeParty;
    final l10n = AppLocalizations.of(context)!;
    final records = _filteredRecords;

    if (!_showDetails) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Provider.of<AppState>(context, listen: false).setSuperAdminTabIndex(0);
              }
            },
          ),
          title: Text(
            l10n.wardsAndPollingStations,
            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Text(
                  "Select Constituency",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Choose an assembly segment to view detailed polling booth records, ward strength, and lead analysis.",
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ),
              const SizedBox(height: 16),
               Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.1,
                  ),
                  itemCount: _assemblySegments.length,
                  itemBuilder: (context, index) {
                    final seg = _assemblySegments[index];
                    final isAll = seg['code'] == 'ALL';
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isAll ? themeConfig.primaryColor : Colors.grey.shade200,
                          width: isAll ? 2.0 : 1.5,
                        ),
                      ),
                      color: isAll ? themeConfig.primaryColor.withOpacity(0.04) : Colors.white,
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedSegment = seg['code']!;
                            _showDetails = true;
                          });
                          _fetchData();
                        },
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  seg['name']!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isAll ? themeConfig.primaryColor : Colors.black87,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  seg['desc']!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isAll ? themeConfig.primaryColor.withOpacity(0.8) : Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Ensure selected dropdown value exists in options
    final dropdownValue = _assemblySegments.any((element) => element['code'] == _selectedSegment)
        ? _selectedSegment
        : 'ALL';

    final selectedSegmentName = _assemblySegments.firstWhere((element) => element['code'] == _selectedSegment)['name'];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => setState(() => _showDetails = false),
        ),
        title: Text(
          selectedSegmentName ?? l10n.wardsAndPollingStations,
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 15),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: _fetchData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Controls Card
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Select Ward Strength / Lead Filter Dropdown
                const Text("Ward Strength / Lead Filter", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black54)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedLeadFilter,
                      items: [
                        DropdownMenuItem(
                          value: 'ALL',
                          child: Text('All Ward Strength (${_rawElectionData.length} Booths)', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        ),
                        const DropdownMenuItem(
                          value: 'PURANDHESHWARI',
                          child: Text('Daggubati Purandheshwari Leading (BJP)', style: TextStyle(fontSize: 13, color: Color(0xFFD97706), fontWeight: FontWeight.bold)),
                        ),
                        const DropdownMenuItem(
                          value: 'GUDURI',
                          child: Text('Dr. Guduri Srinivas Leading (YSRCP)', style: TextStyle(fontSize: 13, color: Color(0xFF1E40AF), fontWeight: FontWeight.bold)),
                        ),
                        const DropdownMenuItem(
                          value: 'TIED',
                          child: Text('Equal / Tied Booths', style: TextStyle(fontSize: 13, color: Colors.grey)),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedLeadFilter = val);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 2. Search Bar
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search polling station or ward...',
                    hintStyle: const TextStyle(fontSize: 12),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                  ),
                ),
                const SizedBox(height: 12),

                // Record count indicator
                Text(
                  'Showing ${records.length} of ${_rawElectionData.length} Records',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
                ),
              ],
            ),
          ),

          // Data Table View
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : records.isEmpty
                    ? const Center(child: Text("No polling stations found", style: TextStyle(color: Colors.black54)))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(12),
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
                              ],
                            ),
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(Colors.amber.shade50),
                              columnSpacing: 12,
                              horizontalMargin: 8,
                              columns: const [
                                DataColumn(label: Text('S.No', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87))),
                                DataColumn(label: Text('Booth', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87))),
                                DataColumn(label: Text('Votes', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87))),
                                DataColumn(label: Text('Guduri (Y)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)))),
                                DataColumn(label: Text('Puran (B)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD97706)))),
                                DataColumn(label: Text('Lead Margin', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87))),
                              ],
                              rows: records.asMap().entries.map((entry) {
                                final int index = entry.key + 1;
                                final Map<String, dynamic> row = entry.value;

                                final int psNo = row['polling_station_number'] ?? row['serial_number'] ?? index;
                                final int polled = row['total_votes'] ?? 0;
                                final int guduri = row['dr_guduri_srinivas'] ?? 0;
                                final int puran = row['daggubati_purandheshwari'] ?? 0;

                                // Compute Ward Strength Lead
                                String leadText;
                                Color leadBgColor;
                                Color leadTextColor;

                                if (puran > guduri) {
                                  final margin = puran - guduri;
                                  leadText = 'Purandheshwari (+$margin)';
                                  leadBgColor = const Color(0xFFFEF3C7);
                                  leadTextColor = const Color(0xFFB45309);
                                } else if (guduri > puran) {
                                  final margin = guduri - puran;
                                  leadText = 'Guduri Srinivas (+$margin)';
                                  leadBgColor = const Color(0xFFDBEAFE);
                                  leadTextColor = const Color(0xFF1E40AF);
                                } else {
                                  leadText = 'Tied';
                                  leadBgColor = Colors.grey.shade200;
                                  leadTextColor = Colors.black87;
                                }

                                return DataRow(
                                  cells: [
                                    DataCell(Text('$index', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
                                    DataCell(Text(
                                      'PART $psNo',
                                      style: TextStyle(fontSize: 12, color: themeConfig.primaryColor, fontWeight: FontWeight.bold),
                                    )),
                                    DataCell(Text('$polled', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                                    DataCell(Text('$guduri', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E40AF)))),
                                    DataCell(Text('$puran', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFD97706)))),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: leadBgColor,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          leadText,
                                          style: TextStyle(color: leadTextColor, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
          ),

          // Export Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Exporting ${records.length} Polling Station records to Excel...')),
                );
              },
              icon: Icon(Icons.download, color: themeConfig.primaryColor),
              label: Text(l10n.exportExcel, style: TextStyle(color: themeConfig.primaryColor, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                side: BorderSide(color: themeConfig.primaryColor),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
