import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:excel/excel.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../models/complaint.dart';
import '../../services/app_state.dart';
import '../../services/translation_service.dart';

class AdminReportsTab extends StatefulWidget {
  final List<Complaint> complaints;

  const AdminReportsTab({super.key, required this.complaints});

  @override
  State<AdminReportsTab> createState() => _AdminReportsTabState();
}

class _AdminReportsTabState extends State<AdminReportsTab> {
  bool _isExporting = false;

  Future<void> _exportToExcel(bool isTelugu) async {
    setState(() => _isExporting = true);
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Ward Complaints'];

      // Header row
      final headers = ['#', 'Category', 'Description', 'Status', 'Citizen Name', 'Phone', 'Ward', 'Date', 'Priority'];
      for (int col = 0; col < headers.length; col++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
        cell.value = TextCellValue(headers[col]);
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#0F766E'),
          fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        );
      }

      // Data rows
      for (int i = 0; i < widget.complaints.length; i++) {
        final c = widget.complaints[i];
        final row = i + 1;
        final cells = [
          '${i + 1}',
          c.category,
          c.description,
          c.isClosed ? 'Closed' : c.status.toString().split('.').last,
          c.citizenName,
          c.citizenPhone,
          c.wardName,
          '${c.createdAt.day}/${c.createdAt.month}/${c.createdAt.year}',
          c.priority.toString().split('.').last,
        ];
        for (int col = 0; col < cells.length; col++) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row)).value = TextCellValue(cells[col]);
        }
      }

      // Save file
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/ward_complaints_report.xlsx';
      final fileBytes = excel.save();
      if (fileBytes == null) return;
      final file = File(filePath);
      await file.writeAsBytes(fileBytes);

      // Share file
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath)],
          text: isTelugu ? 'వార్డు ఫిర్యాదుల నివేదిక' : 'Ward Complaints Report',
        ),
      );
    } catch (e) {
      debugPrint('Excel export error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isTelugu ? 'ఎగుమతి విఫలమైంది' : 'Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isTelugu = appState.isTelugu;
    final complaints = widget.complaints;
    final total = complaints.length;
    // Map completed status: resolved
    final resolved = complaints.where((c) => 
        c.status == ComplaintStatus.resolved).length;

    // Calculate Resolution Rate
    final double resolutionRate = total == 0 ? 0.0 : (resolved / total) * 100;

    // Category count statistics
    final categories = [
      'Pothole & Road Repair',
      'Waste Management',
      'Streetlight Issues',
      'Water Leakage',
      'Drainage & Sewerage',
      'Electricity & Power Issues',
      'Public Sanitation',
      'Agriculture & Irrigation',
      'Others',
    ];
    final Map<String, int> totalByCat = {};
    final Map<String, int> resolvedByCat = {};

    for (var cat in categories) {
      totalByCat[cat] = complaints.where((c) => c.category == cat).length;
      resolvedByCat[cat] = complaints.where((c) => 
          c.category == cat && 
          c.status == ComplaintStatus.resolved).length;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isTelugu ? 'వార్డు పనితీరు నివేదికలు' : 'Ward Performance Reports',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    Text(
                      isTelugu 
                          ? 'ఫిర్యాదుల పంపిణీ మరియు పరిష్కార విశ్లేషణ.' 
                          : 'Complaint distribution and resolution analytics.',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              _isExporting
                  ? SizedBox(
                      width: 28, height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).primaryColor),
                    )
                  : ElevatedButton.icon(
                      onPressed: () => _exportToExcel(isTelugu),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF166534),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.download_outlined, size: 16),
                      label: Text(
                        isTelugu ? 'Excel' : 'Excel',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
            ],
          ),
          const SizedBox(height: 16),

          Card(
            color: Theme.of(context).primaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTelugu ? 'పరిష్కార సామర్థ్యం' : 'RESOLUTION EFFICIENCY',
                          style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${resolutionRate.toStringAsFixed(1)}%',
                          style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isTelugu 
                              ? 'మీ వార్డులో మొత్తం $total ఫిర్యాదులలో $resolved పరిష్కరించబడ్డాయి.' 
                              : 'Resolved $resolved out of $total total complaints in your ward.',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.bolt, color: Colors.white, size: 36),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Chart Section
          Text(
            isTelugu ? 'వర్గం వారీగా పరిష్కారాల పోలిక' : 'Resolution Comparison by Category',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          Text(
            isTelugu 
                ? 'సమర్పించిన మొత్తం ఫిర్యాదులు వర్సెస్ పరిష్కరించబడిన ఫిర్యాదుల పోలిక (ఎడమ = మొత్తం, కుడి = పరిష్కరించబడింది).' 
                : 'Compare Total Complaints filed vs Resolved Complaints (Left rod = Total, Right rod = Resolved).',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 16),

          // Bar Chart container
          if (total > 0)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  height: 240,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _getMaxValue(totalByCat.values) + 1,
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              String text = '';
                              switch (value.toInt()) {
                                case 0:
                                  text = isTelugu ? 'రోడ్లు' : 'Roads';
                                  break;
                                case 1:
                                  text = isTelugu ? 'చెత్త' : 'Waste';
                                  break;
                                case 2:
                                  text = isTelugu ? 'దీపాలు' : 'Lights';
                                  break;
                                case 3:
                                  text = isTelugu ? 'నీరు' : 'Water';
                                  break;
                                case 4:
                                  text = isTelugu ? 'మురుగు' : 'Drain';
                                  break;
                                case 5:
                                  text = isTelugu ? 'విద్యుత్' : 'Power';
                                  break;
                                case 6:
                                  text = isTelugu ? 'శుభ్రత' : 'Sanit';
                                  break;
                                case 7:
                                  text = isTelugu ? 'వ్యవసాయం' : 'Agri';
                                  break;
                                case 8:
                                  text = isTelugu ? 'ఇతర' : 'Other';
                                  break;
                              }
                              return SideTitleWidget(
                                meta: meta,
                                space: 4,
                                child: Text(text, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                              );
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: true, reservedSize: 22),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: const FlGridData(show: true, drawVerticalLine: false),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(categories.length, (index) {
                        final cat = categories[index];
                        final tCount = totalByCat[cat] ?? 0;
                        final rCount = resolvedByCat[cat] ?? 0;

                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: tCount.toDouble(),
                              color: const Color(0xFF0F172A),
                              width: 8,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            BarChartRodData(
                              toY: rCount.toDouble(),
                              color: Colors.green.shade500,
                              width: 8,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ),
            )
          else
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  isTelugu ? 'ఎలాంటి గణాంక సమాచారం అందుబాటులో లేదు.' : 'No statistical data available.',
                  style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                ),
              ),
            ),

          const SizedBox(height: 20),

          // Detail cards summary
          Text(
            isTelugu ? 'సంఖ్యా సారాంశం' : 'Numerical Summary',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 10),
          _buildSummaryRow(Trans.t('pothole', isTelugu), totalByCat['Pothole & Road Repair'] ?? 0,
              resolvedByCat['Pothole & Road Repair'] ?? 0, isTelugu),
          _buildSummaryRow(Trans.t('waste', isTelugu), totalByCat['Waste Management'] ?? 0,
              resolvedByCat['Waste Management'] ?? 0, isTelugu),
          _buildSummaryRow(Trans.t('streetlight', isTelugu), totalByCat['Streetlight Issues'] ?? 0,
              resolvedByCat['Streetlight Issues'] ?? 0, isTelugu),
          _buildSummaryRow(Trans.t('water', isTelugu), totalByCat['Water Leakage'] ?? 0,
              resolvedByCat['Water Leakage'] ?? 0, isTelugu),
          _buildSummaryRow(Trans.t('drainage', isTelugu), totalByCat['Drainage & Sewerage'] ?? 0,
              resolvedByCat['Drainage & Sewerage'] ?? 0, isTelugu),
          _buildSummaryRow(Trans.t('electricity', isTelugu), totalByCat['Electricity & Power Issues'] ?? 0,
              resolvedByCat['Electricity & Power Issues'] ?? 0, isTelugu),
          _buildSummaryRow(Trans.t('sanitation', isTelugu), totalByCat['Public Sanitation'] ?? 0,
              resolvedByCat['Public Sanitation'] ?? 0, isTelugu),
          _buildSummaryRow(Trans.t('agriculture', isTelugu), totalByCat['Agriculture & Irrigation'] ?? 0,
              resolvedByCat['Agriculture & Irrigation'] ?? 0, isTelugu),
          _buildSummaryRow(Trans.t('others', isTelugu), totalByCat['Others'] ?? 0,
              resolvedByCat['Others'] ?? 0, isTelugu),


          const SizedBox(height: 80),
        ],
      ),
    );
  }

  double _getMaxValue(Iterable<int> values) {
    if (values.isEmpty) return 5.0;
    int maxVal = 0;
    for (var v in values) {
      if (v > maxVal) maxVal = v;
    }
    return maxVal < 4 ? 5.0 : maxVal.toDouble();
  }

  Widget _buildSummaryRow(String label, int total, int resolved, bool isTelugu) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
              Row(
                children: [
                  Text(
                    '${isTelugu ? 'మొత్తం' : 'Total'}: $total',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${isTelugu ? 'పరిష్కరించబడినవి' : 'Resolved'}: $resolved',
                    style: TextStyle(fontSize: 12, color: Colors.green.shade700, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
