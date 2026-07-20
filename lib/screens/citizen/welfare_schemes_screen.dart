import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../themes/theme_provider.dart';
import '../../themes/party_theme_config.dart';
import '../../l10n/app_localizations.dart';

class WelfareSchemesScreen extends StatefulWidget {
  const WelfareSchemesScreen({super.key});

  @override
  State<WelfareSchemesScreen> createState() => _WelfareSchemesScreenState();
}

class _WelfareSchemesScreenState extends State<WelfareSchemesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _selectedFilter = "All";

  List<String> _getFilters(AppLocalizations loc) {
    return ["All", loc.catAgriculture, loc.catEducation, loc.catSocialWelfare, loc.catEconomy, loc.catHealth];
  }

  List<Map<String, dynamic>> _getCategories(AppLocalizations loc) {
    return [
      {"id": "Farmers Welfare", "name": loc.farmersWelfare, "icon": Icons.agriculture, "filter": loc.catAgriculture, "color": Colors.green},
      {"id": "Students & Education", "name": loc.studentsEducation, "icon": Icons.school, "filter": loc.catEducation, "color": Colors.blue},
      {"id": "Women Empowerment", "name": loc.womenEmpowerment, "icon": Icons.woman, "filter": loc.catSocialWelfare, "color": Colors.pink},
      {"id": "Senior Citizens", "name": loc.seniorCitizens, "icon": Icons.elderly, "filter": loc.catSocialWelfare, "color": Colors.brown},
      {"id": "Youth & Employment", "name": loc.youthEmployment, "icon": Icons.work, "filter": loc.catEconomy, "color": Colors.orange},
      {"id": "Housing Schemes", "name": loc.housingSchemes, "icon": Icons.home, "filter": loc.catSocialWelfare, "color": Colors.deepPurple},
      {"id": "Healthcare & Cashless", "name": loc.healthcareCashless, "icon": Icons.local_hospital, "filter": loc.catHealth, "color": Colors.red},
      {"id": "Business & MSME", "name": loc.businessMsme, "icon": Icons.business, "filter": loc.catEconomy, "color": Colors.indigo},
      {"id": "Workers & Labour", "name": loc.workersLabour, "icon": Icons.engineering, "filter": loc.catEconomy, "color": Colors.blueGrey},
      {"id": "Subsidies & Energy", "name": loc.subsidiesEnergy, "icon": Icons.bolt, "filter": loc.catAgriculture, "color": Colors.amber},
      {"id": "Fishermen Welfare", "name": loc.fishermenWelfare, "icon": Icons.sailing, "filter": loc.catAgriculture, "color": Colors.lightBlue},
    ];
  }

  void _navigateToSchemeList(String categoryId, String categoryName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SchemeDetailsScreen(categoryId: categoryId, categoryName: categoryName),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeParty = Provider.of<ThemeProvider>(context).activeParty;
    final loc = AppLocalizations.of(context)!;
    
    final categories = _getCategories(loc);

    final filteredCategories = categories.where((c) {
      final matchesSearch = c["name"].toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFilter = _selectedFilter == "All" || c["filter"] == _selectedFilter;
      return matchesSearch && matchesFilter;
    }).toList();

    return Scaffold(
      backgroundColor: activeParty.backgroundColor,
      appBar: AppBar(
        title: const Text('Welfare & Schemes Directory', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 1,
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(activeParty, loc),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 160,
                childAspectRatio: 0.85,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: filteredCategories.length,
              itemBuilder: (context, index) {
                final cat = filteredCategories[index];
                return _buildCategoryCard(cat);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(PartyThemeConfig activeParty, AppLocalizations loc) {
    final filters = _getFilters(loc);
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: '${loc.track} ${loc.welfareSchemes}...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: activeParty.primaryColor),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filters.map((f) {
                final isSelected = _selectedFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f),
                    selected: isSelected,
                    onSelected: (val) => setState(() => _selectedFilter = f),
                    selectedColor: activeParty.primaryColor.withValues(alpha: 0.1),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? activeParty.primaryColor : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: isSelected ? activeParty.primaryColor : Colors.grey.shade300),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> cat) {
    final String name = cat["name"];
    final IconData icon = cat["icon"];
    final Color color = cat["color"];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToSchemeList(cat["id"], name),
        borderRadius: BorderRadius.circular(24),
        splashColor: color.withValues(alpha: 0.1),
        highlightColor: color.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SchemeDetailsScreen extends StatelessWidget {
  final String categoryId;
  final String categoryName;

  const SchemeDetailsScreen({super.key, required this.categoryId, required this.categoryName});

  String _mapCategoryToInternal(String cat) {
    cat = cat.toLowerCase();
    if (cat.contains("farmer")) return "farmers";
    if (cat.contains("student") || cat.contains("education")) return "students";
    if (cat.contains("women")) return "women";
    if (cat.contains("senior")) return "seniors";
    if (cat.contains("youth")) return "youth";
    if (cat.contains("housing")) return "housing";
    if (cat.contains("health")) return "health";
    if (cat.contains("business")) return "business";
    if (cat.contains("worker")) return "workers";
    if (cat.contains("subsid")) return "subsidies";
    if (cat.contains("fisher")) return "fishermen";
    return "other";
  }

  @override
  Widget build(BuildContext context) {
    final activeParty = Provider.of<ThemeProvider>(context).activeParty;
    
    final internalCat = _mapCategoryToInternal(categoryId);
    
    // We treat "Education" from Super Six as "students" in the internal check for parity
    final filteredSchemes = _welfareSchemesData.where((s) {
      final sCat = (s["category"] as String).toLowerCase();
      if (internalCat == "students" && sCat.contains("education")) return true;
      if (internalCat == "women" && sCat.contains("women")) return true;
      return sCat == internalCat;
    }).toList();

    return Scaffold(
      backgroundColor: activeParty.backgroundColor,
      appBar: AppBar(
        title: Text(categoryName, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 1,
      ),
      body: filteredSchemes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 80, color: activeParty.primaryColor.withValues(alpha: 0.5)),
                  const SizedBox(height: 24),
                  Text('No schemes available currently.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: activeParty.primaryColor)),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 450,
                mainAxisExtent: 380, // Fixed height for standard card rendering
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: filteredSchemes.length,
              itemBuilder: (context, index) {
                final scheme = filteredSchemes[index];
                return _buildSchemeCard(scheme, activeParty);
              },
            ),
    );
  }

  Widget _buildSchemeCard(Map<String, dynamic> scheme, PartyThemeConfig activeParty) {
    final name = scheme['name'] ?? '';
    final desc = scheme['desc'] ?? 'State supported welfare program.';
    final benefit = scheme['benefits'] ?? scheme['benefit'] ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'AP STATE GOVERNMENT',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'ACTIVE',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87, height: 1.2),
                ),
                const SizedBox(height: 8),
                Text(
                  desc,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildDetailRow(Icons.group, 'Eligibility:', 'Eligible citizens per official guidelines'),
                  const SizedBox(height: 10),
                  _buildDetailRow(Icons.description, 'Required Documents:', 'Aadhaar Card, Ration Card, Bank Passbook'),
                  const SizedBox(height: 10),
                  _buildDetailRow(Icons.card_giftcard, 'Benefits:', benefit, valueColor: Colors.green.shade700),
                  const SizedBox(height: 10),
                    _buildDetailRow(Icons.edit_document, 'Application Process:', 'Gram/Ward Secretariat / Online Portal'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 12, color: valueColor ?? Colors.black87),
          ),
        ),
      ],
    );
  }
}

const List<Map<String, dynamic>> _welfareSchemesData = [
    {
      "id": "SS-01",
      "name": "Talliki Vandanam",
      "desc": "Financial assistance of ₹15,000 per year to every mother who sends her children to school.",
      "category": "Education",
      "benefit": "₹15,000 / year per child",
    },
    {
      "id": "SS-02",
      "name": "Aadabidda Nidhi",
      "desc": "Monthly financial assistance of ₹1,500 to women aged 18 to 59 years.",
      "category": "Women",
      "benefit": "₹1,500 / month",
    },
    {
      "id": "SS-03",
      "name": "Deepam 2.0 (Free Gas Cylinders)",
      "desc": "Three free LPG cylinders per year to every eligible household.",
      "category": "Women",
      "benefit": "3 Free Gas Cylinders per Year",
    },
    {
      "id": "SS-04",
      "name": "Free RTC Bus Travel",
      "desc": "Free bus travel for all women in APSRTC ordinary and express buses.",
      "category": "Women",
      "benefit": "Free RTC Bus Rides across AP",
    },
    {
      "id": "SS-05",
      "name": "Nirudyoga Bruthi (Youth Fund)",
      "desc": "Monthly financial aid of ₹3,000 and skilling allowances for unemployed youth.",
      "category": "Youth",
      "benefit": "₹3,000 / month + Skill Training",
    },
    {
      "id": "SS-06",
      "name": "Annadata",
      "desc": "Financial assistance of ₹20,000 per year to support farmers (including PM-KISAN funds).",
      "category": "Farmers",
      "benefit": "₹20,000 / year investment support",
    },
    {
      "id": "SCH-F-01",
      "category": "farmers",
      "name": "Annadata Sukhibhava",
      "desc": "Welfare program providing ₹20,000 annual investment support for agricultural inputs and machinery in AP (combined with PM-KISAN funds).",
      "benefits": "₹20,000 per year direct benefit transfer"
    },
    {
      "id": "SCH-F-02",
      "category": "farmers",
      "name": "Free Power for Agriculture",
      "desc": "AP State Government initiative supplying 9 hours of free, uninterrupted daytime power to all agricultural pump sets.",
      "benefits": "100% electricity subsidy for farming motors"
    },
    {
      "id": "SCH-F-03",
      "category": "farmers",
      "name": "Drip & Sprinkler Micro Irrigation Subsidy",
      "desc": "Subsidy ranging from 55% to 90% for implementing micro-irrigation systems to conserve water and improve yield.",
      "benefits": "55% to 90% cost subsidy for drip/sprinklers"
    },
    {
      "id": "SCH-F-04",
      "category": "farmers",
      "name": "Farm Mechanization & Seed Subsidy",
      "desc": "Subsidized distribution of certified seeds, tractors, rotavators, and other essential implements to farmers.",
      "benefits": "50% subsidy on seeds & machinery purchases"
    },
    {
      "id": "SCH-F-05",
      "category": "farmers",
      "name": "Rythu Bandhu",
      "desc": "Telangana's flagship investment support scheme offering financial assistance per acre per season to landholding farmers.",
      "benefits": "₹10,000 per acre/year investment support"
    },
    {
      "id": "SCH-F-06",
      "category": "farmers",
      "name": "PM Kisan Samman Nidhi",
      "desc": "Central scheme providing income support of ₹6,000 per year in three equal installments of ₹2,000 directly to landholding families.",
      "benefits": "₹6,000 per year direct benefit transfer"
    },
    {
      "id": "SCH-F-07",
      "category": "farmers",
      "name": "PM Fasal Bima Yojana",
      "desc": "National agricultural insurance program providing cover against yield loss due to natural calamities, pests, or disease.",
      "benefits": "Low premium crop insurance protection"
    },
    {
      "id": "SCH-F-08",
      "category": "farmers",
      "name": "Kisan Credit Card (KCC)",
      "desc": "Provides institutional credit to farmers for their cultivation needs, purchase of machinery, and emergency expenses at highly subsidized interest rates.",
      "benefits": "Agricultural loans up to ₹3 Lakhs at 4% interest rate"
    },
    {
      "id": "SCH-S-01",
      "category": "students",
      "name": "Thalliki Vandanam",
      "desc": "TDP Super Six scheme providing ₹15,000 per year to mothers of school-going kids from Classes 1 to 12 in AP.",
      "benefits": "₹15,000 per year credited to mother's bank account"
    },
    {
      "id": "SCH-S-02",
      "category": "students",
      "name": "Jagananna Vidya Deevena (Fee Reimbursement)",
      "desc": "100% tuition fee reimbursement program for ITI, Polytechnic, Degree, Engineering, and Medical college students.",
      "benefits": "Full college tuition fee reimbursement"
    },
    {
      "id": "SCH-S-03",
      "category": "students",
      "name": "Jagananna Vasathi Deevena (Hostel Aid)",
      "desc": "Financial assistance for boarding and lodging expenses of higher education students.",
      "benefits": "Up to ₹20,000 per year hostel & mess assistance"
    },
    {
      "id": "SCH-S-04",
      "category": "students",
      "name": "Telangana Overseas Study Scheme",
      "desc": "Financial assistance to SC, ST, BC, and Minority students pursuing higher education (Post Graduation/Ph.D.) in top universities abroad.",
      "benefits": "Up to ₹20 Lakhs scholarship grant per student"
    },
    {
      "id": "SCH-S-05",
      "category": "students",
      "name": "National Scholarship Portal (NSP)",
      "desc": "Centralized scholarship system for merit-cum-means based financial aid to students from minority, SC, and ST communities.",
      "benefits": "Up to ₹50,000 per year scholarship assistance"
    },
    {
      "id": "SCH-S-06",
      "category": "students",
      "name": "PM YASASVI",
      "desc": "Central scholarship scheme for OBC, EBC, and DNT students studying in top school classes (9th to 12th) or college courses.",
      "benefits": "Up to ₹1,25,000 per year educational grant"
    },
    {
      "id": "SCH-W-01",
      "category": "women",
      "name": "Aadabidda Nidhi",
      "desc": "TDP Super Six scheme providing monthly financial assistance of ₹1,500 to women aged 18 to 59 years.",
      "benefits": "₹1,500 per month financial assistance"
    },
    {
      "id": "SCH-W-02",
      "category": "women",
      "name": "DWCRA / SHG Loan & Interest Subsidy",
      "desc": "Subsidized interest scheme for Self-Help Groups (SHGs) to run small businesses and gain financial independence.",
      "benefits": "Zero-interest loans up to ₹5 Lakhs for SHGs"
    },
    {
      "id": "SCH-W-03",
      "category": "women",
      "name": "Deepam Scheme (3 Free LPG Cylinders)",
      "desc": "AP State welfare initiative providing three domestic LPG cooking gas cylinders free of cost annually to BPL families.",
      "benefits": "3 Free Gas Cylinders per year"
    },
    {
      "id": "SCH-W-04",
      "category": "women",
      "name": "Aadabidda Free RTC Bus Travel",
      "desc": "Enables women, girls, and transgender persons to travel free of cost on ordinary and express APSRTC buses.",
      "benefits": "100% free RTC bus travel inside state limits"
    },
    {
      "id": "SCH-W-05",
      "category": "women",
      "name": "Kalyana Lakshmi / Shaadi Mubarak",
      "desc": "Telangana scheme offering one-time financial assistance to girls of SC, ST, BC, and Minorities at the time of marriage.",
      "benefits": "₹1,00,116 one-time marriage grant"
    },
    {
      "id": "SCH-W-06",
      "category": "women",
      "name": "PM Matru Vandana Yojana (PMMVY)",
      "desc": "Maternity benefit scheme providing direct cash assistance to pregnant women and lactating mothers for the first child.",
      "benefits": "₹5,000 cash incentive in bank accounts"
    },
    {
      "id": "SCH-W-07",
      "category": "women",
      "name": "Lakhpati Didi",
      "desc": "National initiative to empower women in Self Help Groups (SHGs) to earn a sustainable income of at least ₹1 Lakh per year.",
      "benefits": "Skill training, financial literacy, and startup micro-loans"
    },
    {
      "id": "SCH-W-08",
      "category": "women",
      "name": "Beti Bachao Beti Padhao",
      "desc": "Campaign aimed at generating awareness and improving the efficiency of welfare services intended for girls.",
      "benefits": "Educational support, insurance policies, and security initiatives"
    },
    {
      "id": "SCH-O-01",
      "category": "seniors",
      "name": "NTR Bharosa Pension",
      "desc": "Monthly welfare pension of ₹4,000 distributed to senior citizens, widows, weavers, and toddy tappers in AP.",
      "benefits": "₹4,000 per month cash pension at doorsteps"
    },
    {
      "id": "SCH-O-02",
      "category": "seniors",
      "name": "Aasara Pensions (Senior Citizens)",
      "desc": "Welfare pension scheme supporting senior citizens, widows, weavers, and AIDS patients across Telangana.",
      "benefits": "₹2,016 per month cash pension support"
    },
    {
      "id": "SCH-Y-01",
      "category": "youth",
      "name": "Nirudyoga Bruthi (Youth Fund)",
      "desc": "Financial assistance program offering monthly cash relief to registered unemployed youths in AP while they acquire skills.",
      "benefits": "₹3,000 per month unemployment allowance"
    },
    {
      "id": "SCH-Y-02",
      "category": "youth",
      "name": "APSSDC Skill Training Programs",
      "desc": "AP State Skill Development Corporation's placement-linked training courses in IT, logistics, healthcare, and retail sectors.",
      "benefits": "Free certification, job placement drives, and kits"
    },
    {
      "id": "SCH-H-01",
      "category": "housing",
      "name": "NTR Housing (House Site Pattas)",
      "desc": "AP State housing program distributing free residential plots (house site pattas) to homeless poor families.",
      "benefits": "Free residential plot patta document in name of female head"
    },
    {
      "id": "SCH-H-02",
      "category": "housing",
      "name": "AP Rural Housing Development",
      "desc": "Financial assistance and subsidized raw material kits for constructing permanent pucca homes in rural assembly sectors.",
      "benefits": "₹1.8 Lakhs construction subsidy + subsidized cement/iron"
    },
    {
      "id": "SCH-H-03",
      "category": "housing",
      "name": "PM Awas Yojana (PMAY)",
      "desc": "Central scheme providing credit linked subsidy (CLSS) on home loans for purchase or construction of houses for EWS/LIG families.",
      "benefits": "Up to ₹2.67 Lakhs home loan interest subsidy"
    },
    {
      "id": "SCH-Fi-01",
      "category": "fishermen",
      "name": "YSR Matsyakara Bharosa",
      "desc": "Financial assistance to marine fishermen families during the annual marine fishing ban period (April 15 to June 14) and diesel subsidies.",
      "benefits": "₹10,000 ban compensation + ₹9/litre diesel subsidy"
    },
    {
      "id": "SCH-He-01",
      "category": "health",
      "name": "Ayushman Bharat PM-JAY",
      "desc": "National health protection scheme providing coverage up to ₹5 Lakhs per family per year for secondary and tertiary care hospitalization.",
      "benefits": "₹500,000 per family/year cashless medical cover"
    },
    {
      "id": "SCH-He-02",
      "category": "health",
      "name": "Pradhan Mantri Bhartiya Janaushadhi Pariyojana",
      "desc": "A campaign launched by the Department of Pharmaceuticals to provide quality generic medicines at affordable prices through PMBJP Kendras.",
      "benefits": "50% to 90% cheaper generic medicines"
    },
    {
      "id": "SCH-B-01",
      "category": "business",
      "name": "PMEGP (Employment Generation Programme)",
      "desc": "Credit-linked subsidy program for setting up new micro-enterprises in manufacturing and services sector.",
      "benefits": "Up to 35% project cost subsidy + low-interest bank loans"
    },
    {
      "id": "SCH-B-02",
      "category": "business",
      "name": "PM Mudra Yojana (Shishu, Kishor, Tarun)",
      "desc": "Provides collateral-free loans up to ₹10 Lakhs to micro and small non-farm, non-corporate enterprises.",
      "benefits": "Up to ₹10 Lakhs collateral-free business loans"
    },
    {
      "id": "SCH-B-03",
      "category": "business",
      "name": "Stand-Up India Scheme",
      "desc": "Promotes entrepreneurship among women and SC/ST communities by providing bank loans for starting greenfield enterprises.",
      "benefits": "Bank loans between ₹10 Lakhs and ₹1 Crore"
    },
    {
      "id": "SCH-B-04",
      "category": "business",
      "name": "Startup India Scheme",
      "desc": "Simplifies startup registrations, provides income tax exemptions for 3 years, and sets up seed funding networks.",
      "benefits": "Tax exemptions, patent application rebates, and funding"
    },
    {
      "id": "SCH-K-01",
      "category": "workers",
      "name": "E-Shram Card Registration",
      "desc": "Registry of unorganized workers (laborers, gig workers, street vendors) to coordinate social security welfare benefits and insurance.",
      "benefits": "₹2 Lakhs accidental death insurance + direct welfare link"
    },
    {
      "id": "SCH-K-02",
      "category": "workers",
      "name": "PM Shram Yogi Maandhan (PM-SYM)",
      "desc": "Voluntary and contributory pension scheme for unorganized workers with monthly income up to ₹15,000.",
      "benefits": "Assured minimum pension of ₹3,000/month after age 60"
    },
    {
      "id": "SCH-V-01",
      "category": "subsidies",
      "name": "PM Surya Ghar (Rooftop Solar Subsidy)",
      "desc": "Subsidizes the installation of grid-connected rooftop solar plants for domestic consumers to receive up to 300 units free power.",
      "benefits": "Up to ₹78,000 direct subsidy on solar panels"
    },
    {
      "id": "SCH-V-02",
      "category": "subsidies",
      "name": "PM-KUSUM Solar Pump Subsidy",
      "desc": "Subsidy program for farmers to install solar agricultural water pump sets, replacing diesel and grid-electricity motors.",
      "benefits": "Up to 90% combined Central & State subsidy on solar pumps"
    },
    {
      "id": "SCH-V-03",
      "category": "subsidies",
      "name": "Dairy Unit Establishment Subsidy",
      "desc": "AP State Animal Husbandry department subsidy for purchasing milk cows/buffaloes to support rural milk cooperative yields.",
      "benefits": "50% to 75% subsidy on procurement of 2-milch animal units"
    },
    {
      "id": "SCH-V-04",
      "category": "subsidies",
      "name": "Fish Pond Construction Subsidy",
      "desc": "Subsidies under PM Matsya Sampada Yojana for excavation of new freshwater fish ponds and purchase of fingerlings/feed.",
      "benefits": "40% (General) to 60% (Women/SC/ST) cost subsidy on aquaculture setup"
    }
];
