import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_demo_app/l10n/app_localizations.dart';
import '../../themes/theme_provider.dart';

class SuperPollingTab extends StatelessWidget {
  const SuperPollingTab({super.key});

  @override
  Widget build(BuildContext context) {
    final themeConfig = Provider.of<ThemeProvider>(context).activeParty;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Icon(Icons.arrow_back, color: Colors.black87),
        title: Text(l10n.wardsAndPollingStations, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list, color: Colors.black87), onPressed: (){}),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: '2', // Mock
                      items: [
                        DropdownMenuItem(value: '2', child: Text('8. Amalapuram (SC)')),
                      ],
                      onChanged: (v){},
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: '1', // Mock
                      items: [
                        DropdownMenuItem(value: '1', child: Text(l10n.allWardStrength('309'))),
                      ],
                      onChanged: (v){},
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(l10n.showingRecords('239', '239'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                  columnSpacing: 20,
                  columns: [
                    DataColumn(label: Text('S.NO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                    DataColumn(label: Text(l10n.pollingStationName, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                    DataColumn(label: Text(l10n.voters, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                    DataColumn(label: Text(l10n.votesPolled, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                    DataColumn(label: Text(l10n.percent, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                    DataColumn(label: Text(l10n.actions, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                  ],
                  rows: [
                    _buildDataRow('1', 'PART 1', '904', '904', '100', themeConfig.primaryColor),
                    _buildDataRow('2', 'PART 2', '742', '742', '100', themeConfig.primaryColor),
                    _buildDataRow('3', 'PART 3', '500', '500', '100', themeConfig.primaryColor),
                    _buildDataRow('4', 'PART 4', '582', '582', '100', themeConfig.primaryColor),
                    _buildDataRow('5', 'PART 5', '623', '623', '100', themeConfig.primaryColor),
                    _buildDataRow('6', 'PART 6', '600', '600', '100', themeConfig.primaryColor),
                    _buildDataRow('7', 'PART 7', '512', '512', '100', themeConfig.primaryColor),
                    _buildDataRow('8', 'PART 8', '645', '645', '100', themeConfig.primaryColor),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: (){},
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

  DataRow _buildDataRow(String sno, String name, String voters, String polled, String percent, Color primaryColor) {
    return DataRow(
      cells: [
        DataCell(Text(sno, style: const TextStyle(fontSize: 12))),
        DataCell(Text(name, style: TextStyle(fontSize: 12, color: primaryColor, fontWeight: FontWeight.bold))),
        DataCell(Text(voters, style: const TextStyle(fontSize: 12))),
        DataCell(Text(polled, style: const TextStyle(fontSize: 12))),
        DataCell(Text(percent, style: const TextStyle(fontSize: 12))),
        DataCell(Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(border: Border.all(color: Colors.blue), borderRadius: BorderRadius.circular(4)),
          child: const Text('Audit', style: TextStyle(color: Colors.blue, fontSize: 10)),
        )),
      ]
    );
  }
}
