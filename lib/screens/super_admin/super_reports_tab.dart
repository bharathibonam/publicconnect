import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_demo_app/l10n/app_localizations.dart';
import '../../themes/theme_provider.dart';
import '../../services/app_state.dart';

class SuperReportsTab extends StatelessWidget {
  const SuperReportsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final themeConfig = Provider.of<ThemeProvider>(context).activeParty;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
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
        title: Text(l10n.reports, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list, color: Colors.black87), onPressed: (){}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_month, size: 20, color: Colors.black54),
                const SizedBox(width: 8),
                const Text('This Month (Jul 2026)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                const Spacer(),
                Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
              ],
            ),
            const SizedBox(height: 24),
            Text(l10n.complaintAnalytics, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    SizedBox(
                      height: 120,
                      width: 120,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              sectionsSpace: 0,
                              centerSpaceRadius: 40,
                              sections: [
                                PieChartSectionData(color: Colors.green, value: 83.6, radius: 10, showTitle: false),
                                PieChartSectionData(color: Colors.red, value: 12.4, radius: 10, showTitle: false),
                                PieChartSectionData(color: Colors.orange, value: 4.0, radius: 10, showTitle: false),
                              ],
                            ),
                          ),
                          const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('1,254', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              Text('Total', style: TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          )
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _legendItem(Colors.green, l10n.resolved, '1,048 (83.6%)'),
                          const SizedBox(height: 12),
                          _legendItem(Colors.red, l10n.pending, '156 (12.4%)'),
                          const SizedBox(height: 12),
                          _legendItem(Colors.orange, l10n.inReview, '50 (4.0%)'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.categoryWiseComplaints, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                Text(l10n.viewAll, style: const TextStyle(fontSize: 12, color: Colors.blue)),
              ],
            ),
            const SizedBox(height: 16),
            _barItem('Water Supply', 0.8, '521 (41%)', Colors.blue),
            const SizedBox(height: 12),
            _barItem('Roads & Infra', 0.6, '312 (25%)', Colors.indigo),
            const SizedBox(height: 12),
            _barItem('Electricity', 0.5, '210 (17%)', Colors.purple),
            const SizedBox(height: 12),
            _barItem('Sanitation', 0.4, '145 (11%)', Colors.red),
            const SizedBox(height: 12),
            _barItem('Others', 0.15, '66 (6%)', Colors.orange),

            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.topMandalsByComplaints, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                Text(l10n.viewAll, style: const TextStyle(fontSize: 12, color: Colors.blue)),
              ],
            ),
            const SizedBox(height: 12),
            _mandalRow('1', 'Rajanagaram', '230'),
            const Divider(),
            _mandalRow('2', 'Amalapuram', '186'),
            const Divider(),
            _mandalRow('3', 'Mandapeta', '142'),
            const Divider(),
            _mandalRow('4', 'Gannavaram', '118'),
            const Divider(),
            _mandalRow('5', 'Kothapeta', '97'),

            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.thisMonthTrend, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const Text('Mar-Apr', style: TextStyle(fontSize: 12, color: Colors.blue)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(1, 20), FlSpot(2, 40), FlSpot(3, 30),
                        FlSpot(4, 50), FlSpot(5, 40), FlSpot(6, 68),
                      ],
                      isCurved: false,
                      color: themeConfig.primaryColor,
                      barWidth: 2,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
        Text(value, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _barItem(String label, double percent, String value, Color color) {
    return Row(
      children: [
        SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
        const SizedBox(width: 8),
        Expanded(
          child: Stack(
            children: [
              Container(height: 6, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(3))),
              FractionallySizedBox(
                widthFactor: percent,
                child: Container(height: 6, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(width: 60, child: Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
      ],
    );
  }

  Widget _mandalRow(String index, String name, String count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(index, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(width: 16),
          Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600))),
          Text(count, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
