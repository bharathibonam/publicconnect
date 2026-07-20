import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';
import '../../themes/theme_provider.dart';

class JobsScreen extends StatelessWidget {
  const JobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final activeParty = themeProvider.activeParty;
    final isTelugu = Provider.of<AppState>(context).isTelugu;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(isTelugu ? 'ఉద్యోగాలు (Jobs)' : 'Jobs & Opportunities', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 1,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [activeParty.primaryColor, activeParty.secondaryColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.work, color: Colors.white, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                isTelugu ? 'స్థానిక యువతకు ఉపాధి అవకాశాలు' : 'Employment Opportunities for Local Youth',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isTelugu ? 'మీ నైపుణ్యాలకు సరిపోయే ఉద్యోగాలను కనుగొనండి మరియు సులభంగా దరఖాస్తు చేసుకోండి.' : 'Find jobs that match your skills and apply easily through our portal.',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Job Categories
                  Row(
                    children: [
                      Expanded(child: _buildCategoryCard(context, Icons.account_balance, 'Govt Jobs', Colors.blue)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildCategoryCard(context, Icons.business, 'Private Sector', Colors.orange)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildCategoryCard(context, Icons.computer, 'IT & Tech', Colors.purple)),
                    ],
                  ),
                  const SizedBox(height: 28),
                  
                  Text(
                    isTelugu ? 'ఇటీవల పోస్ట్ చేయబడినవి' : 'Recently Posted',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 16),
                  
                  // Mock Job 1
                  _buildJobCard(
                    context,
                    company: 'Tech Mahindra',
                    role: isTelugu ? 'సాఫ్ట్‌వేర్ డెవలపర్' : 'Software Developer',
                    location: 'Visakhapatnam, AP',
                    salary: '₹4L - ₹8L / yr',
                    type: 'Full Time',
                    isGovt: false,
                    color: activeParty.primaryColor,
                    isTelugu: isTelugu,
                  ),
                  
                  // Mock Job 2
                  _buildJobCard(
                    context,
                    company: 'AP State Government',
                    role: isTelugu ? 'వార్డ్ సచివాలయం సెక్రటరీ' : 'Ward Secretariat Secretary',
                    location: '${activeParty.getLocalizedConstituencyName(context)} Constituency',
                    salary: '₹15,000 / month',
                    type: 'Govt. Contract',
                    isGovt: true,
                    color: activeParty.primaryColor,
                    isTelugu: isTelugu,
                  ),
                  
                  // Mock Job 3
                  _buildJobCard(
                    context,
                    company: 'Kia Motors',
                    role: isTelugu ? 'మెకానికల్ ఇంజనీర్' : 'Mechanical Engineer',
                    location: 'Anantapur, AP',
                    salary: '₹3L - ₹5L / yr',
                    type: 'Full Time',
                    isGovt: false,
                    color: activeParty.primaryColor,
                    isTelugu: isTelugu,
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildJobCard(BuildContext context, {required String company, required String role, required String location, required String salary, required String type, required bool isGovt, required Color color, required bool isTelugu}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isGovt ? Colors.green.shade50 : color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(isGovt ? Icons.account_balance : Icons.business, color: isGovt ? Colors.green : color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(role, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                      const SizedBox(height: 4),
                      Text(company, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                if (isGovt)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(8)),
                    child: const Text('GOVT', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(location, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                const Spacer(),
                Icon(Icons.payments_outlined, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(salary, style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                  child: Text(type, style: TextStyle(color: Colors.grey.shade800, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isTelugu ? 'దరఖాస్తు సమర్పించబడింది!' : 'Application Submitted!')));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  ),
                  child: Text(isTelugu ? 'అప్లై చేయండి' : 'Apply Now'),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
