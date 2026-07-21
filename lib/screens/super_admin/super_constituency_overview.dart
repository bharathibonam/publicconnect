import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_demo_app/l10n/app_localizations.dart';
import '../../themes/theme_provider.dart';

class SuperConstituencyOverview extends StatelessWidget {
  const SuperConstituencyOverview({super.key});

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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(l10n.constituencyOverview, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(themeConfig.getLocalizedConstituencyName(context) + ' Constituency', style: const TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 16),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(16)),
              child: const Center(child: Icon(Icons.map, size: 40, color: Colors.grey)),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _statBox(l10n.mandal, '12')),
                const SizedBox(width: 12),
                Expanded(child: _statBox(l10n.wardsAndPollingStations.split(' ')[0], '235')),
                const SizedBox(width: 12),
                Expanded(child: _statBox(l10n.villages, '268')),
                const SizedBox(width: 12),
                Expanded(child: _statBox(l10n.pollingBooths, '1,542')),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _infoBox('Population', '12.45L')),
                const SizedBox(width: 12),
                Expanded(child: _infoBox('Households', '3.21L')),
                const SizedBox(width: 12),
                Expanded(child: _infoBox('Voters', '1.72L')),
                const SizedBox(width: 12),
                Expanded(child: _infoBox('Polling %', '84.62%')),
              ],
            ),
            const SizedBox(height: 32),
            Text(l10n.constituencyHierarchy, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text('MP Parliament', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(width: 16),
                      const Icon(Icons.arrow_right_alt, color: Colors.grey, size: 16),
                      const SizedBox(width: 16),
                      Text('Andhra East', style: TextStyle(color: themeConfig.primaryColor, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('MLA Constituency', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(width: 16),
                      const Icon(Icons.arrow_right_alt, color: Colors.grey, size: 16),
                      const SizedBox(width: 16),
                      Text(themeConfig.getLocalizedConstituencyName(context), style: TextStyle(color: themeConfig.primaryColor, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _smallStat('Mandal', '12'),
                      _smallStat('Ward', '235'),
                      _smallStat('Village', '268'),
                      _smallStat('Booth', '1,542'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: (){},
              style: ElevatedButton.styleFrom(
                backgroundColor: themeConfig.primaryColor,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(l10n.viewDetailedMap, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _statBox(String label, String val) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _infoBox(String label, String val) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }

  Widget _smallStat(String label, String val) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
