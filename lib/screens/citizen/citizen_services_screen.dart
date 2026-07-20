import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../themes/theme_provider.dart';
import '../../themes/party_theme_config.dart';
import '../../l10n/app_localizations.dart';

class CitizenServicesScreen extends StatefulWidget {
  const CitizenServicesScreen({super.key});

  @override
  State<CitizenServicesScreen> createState() => _CitizenServicesScreenState();
}

class _CitizenServicesScreenState extends State<CitizenServicesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _selectedFilter = "All";

  List<String> _getFilters(AppLocalizations loc) {
    return ["All", loc.catEducation, loc.catHealth, loc.catGovernment, loc.catTransport, loc.catPublicSafety, loc.catFinancial, loc.catUtilities];
  }

  List<Map<String, dynamic>> _getAllServices(AppLocalizations loc) {
    return [
      {"id": "Schools", "name": loc.schools, "icon": Icons.school, "category": loc.catEducation, "color": Colors.blue},
      {"id": "Junior Colleges", "name": loc.juniorColleges, "icon": Icons.school_outlined, "category": loc.catEducation, "color": Colors.indigo},
      {"id": "Degree Colleges", "name": loc.degreeColleges, "icon": Icons.account_balance, "category": loc.catEducation, "color": Colors.purple},
      {"id": "Polytechnic Colleges", "name": loc.polytechnicColleges, "icon": Icons.settings, "category": loc.catEducation, "color": Colors.deepPurple},
      {"id": "ITI Colleges", "name": loc.itiColleges, "icon": Icons.build, "category": loc.catEducation, "color": Colors.orange},
      {"id": "Anganwadi Centres", "name": loc.anganwadi, "icon": Icons.child_care, "category": loc.catEducation, "color": Colors.pink},
      {"id": "Libraries", "name": loc.libraries, "icon": Icons.local_library, "category": loc.catEducation, "color": Colors.brown},
      {"id": "Government Hospitals", "name": loc.govHospitals, "icon": Icons.local_hospital, "category": loc.catHealth, "color": Colors.red},
      {"id": "Private Hospitals", "name": loc.pvtHospitals, "icon": Icons.healing, "category": loc.catHealth, "color": Colors.redAccent},
      {"id": "Primary Health Centres (PHCs)", "name": loc.phc, "icon": Icons.medical_services, "category": loc.catHealth, "color": Colors.teal},
      {"id": "Community Health Centres", "name": loc.chc, "icon": Icons.health_and_safety, "category": loc.catHealth, "color": Colors.green},
      {"id": "Veterinary Hospitals", "name": loc.vetHospitals, "icon": Icons.pets, "category": loc.catHealth, "color": Colors.lightGreen},
      {"id": "Government Offices", "name": loc.govOffices, "icon": Icons.location_city, "category": loc.catGovernment, "color": Colors.blueGrey},
      {"id": "Municipal Office", "name": loc.municipalOffice, "icon": Icons.apartment, "category": loc.catGovernment, "color": Colors.cyan},
      {"id": "MeeSeva Centres", "name": loc.meesevaCentres, "icon": Icons.computer, "category": loc.catGovernment, "color": Colors.lightBlue},
      {"id": "Post Offices", "name": loc.postOffices, "icon": Icons.local_post_office, "category": loc.catGovernment, "color": Colors.deepOrange},
      {"id": "Bus Stations", "name": loc.busStations, "icon": Icons.directions_bus, "category": loc.catTransport, "color": Colors.amber},
      {"id": "Railway Information", "name": loc.railwayInfo, "icon": Icons.train, "category": loc.catTransport, "color": Colors.grey},
      {"id": "Police Stations", "name": loc.policeStations, "icon": Icons.local_police, "category": loc.catPublicSafety, "color": Colors.indigo},
      {"id": "Fire Stations", "name": loc.fireStations, "icon": Icons.fire_truck, "category": loc.catPublicSafety, "color": Colors.red},
      {"id": "Banks & Financial Hubs", "name": loc.banks, "icon": Icons.account_balance_wallet, "category": loc.catFinancial, "color": Colors.green},
      {"id": "Ration Shops (PDS)", "name": loc.rationShops, "icon": Icons.shopping_basket, "category": loc.catUtilities, "color": Colors.orange},
      {"id": "Public Parks", "name": loc.publicParks, "icon": Icons.park, "category": loc.catUtilities, "color": Colors.green},
      {"id": "Other Public Services", "name": loc.otherPublicServices, "icon": Icons.public, "category": loc.catUtilities, "color": Colors.blue},
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToService(String serviceId, String serviceName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceDetailsScreen(serviceId: serviceId, serviceName: serviceName),
      ),
    );
  }

  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final activeParty = themeProvider.activeParty;
    final loc = AppLocalizations.of(context)!;

    final allServices = _getAllServices(loc);

    final filteredServices = allServices.where((s) {
      final matchesSearch = s["name"].toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFilter = _selectedFilter == "All" || s["category"] == _selectedFilter;
      return matchesSearch && matchesFilter;
    }).toList();

    return Scaffold(
      backgroundColor: activeParty.backgroundColor,
      appBar: AppBar(
        title: Text(loc.services, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
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
              itemCount: filteredServices.length,
              itemBuilder: (context, index) {
                final service = filteredServices[index];
                return ServiceCard(
                  name: service["name"],
                  icon: service["icon"],
                  color: service["color"],
                  onTap: () => _navigateToService(service["id"], service["name"]),
                );
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
              hintText: '${loc.track} ${loc.services}...',
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
}

class ServiceCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const ServiceCard({
    super.key,
    required this.name,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
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

class ServiceDetailsScreen extends StatelessWidget {
  final String serviceId;
  final String serviceName;

  const ServiceDetailsScreen({super.key, required this.serviceId, required this.serviceName});

  @override
  Widget build(BuildContext context) {
    final activeParty = Provider.of<ThemeProvider>(context).activeParty;
    final loc = AppLocalizations.of(context)!;

    final items = _serviceData[serviceId] ?? [];

    return Scaffold(
      backgroundColor: activeParty.backgroundColor,
      appBar: AppBar(
        title: Text(serviceName, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 1,
      ),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.construction, size: 80, color: activeParty.primaryColor.withValues(alpha: 0.5)),
                  const SizedBox(height: 24),
                  Text('Data not yet available', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: activeParty.primaryColor)),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 450,
                mainAxisExtent: 320, // Fixed height for Address/GPS cards
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
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
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              items[index],
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: activeParty.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'GOVERNMENT',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: activeParty.primaryColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Public facility serving the local community with modern amenities and dedicated staff.',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow(Icons.location_on, 'Address:', 'Main Road, Rajamahendravaram', color: Colors.pink.shade300),
                            const SizedBox(height: 10),
                            _buildInfoRow(Icons.phone, 'Contact:', '1800-123-4567', color: Colors.pink.shade300),
                            const SizedBox(height: 10),
                            _buildInfoRow(Icons.how_to_vote, 'Polling Station:', 'PS-145', color: Colors.grey),
                            const SizedBox(height: 10),
                            _buildInfoRow(Icons.access_time, 'Working Hours:', '9:00 AM - 4:30 PM', color: Colors.grey),
                            const SizedBox(height: 10),
                            _buildInfoRow(Icons.language, 'GPS Coordinates:', '17.0005° N, 81.8040° E', color: Colors.blue),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                ),
              );
            },
          ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {required Color color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 12, color: label == 'GPS Coordinates:' ? Colors.blue : Colors.black87),
          ),
        ),
      ],
    );
  }
}

const Map<String, List<String>> _serviceData = {
  "Schools": [
    "Government Boys High School, Rajamahendravaram",
    "Government Girls High School, Rajamahendravaram",
    "Zilla Parishad High School, Korukonda",
    "ZP High School, Kadiyam",
    "ZP High School, Rajanagaram",
    "Municipal High School, Rajamahendravaram"
  ],
  "Junior Colleges": [
    "Government Junior College, Rajamahendravaram",
    "Government Junior College, Kadiyam",
    "Government Junior College, Rajanagaram",
    "SKVT Junior College",
    "Aditya Junior College",
    "Sri Chaitanya Junior College",
    "Narayana Junior College"
  ],
  "Degree Colleges": [
    "Government Degree College for Men",
    "Government Degree College for Women",
    "Adikavi Nannaya University Colleges",
    "Government Arts College",
    "VSM College",
    "GIET Degree College"
  ],
  "Polytechnic Colleges": [
    "Government Polytechnic College",
    "Aditya Polytechnic",
    "GIET Polytechnic"
  ],
  "ITI Colleges": [
    "Government ITI Rajamahendravaram",
    "Private ITI Kadiyam",
    "Sri Sai ITI"
  ],
  "Government Hospitals": [
    "Government General Hospital Rajamahendravaram",
    "District Hospital Rajamahendravaram",
    "Urban Community Health Centre",
    "Area Hospital Kadiyam"
  ],
  "Private Hospitals": [
    "Apollo Hospital",
    "KIMS Hospital",
    "Bollineni Hospital",
    "Sri Hospitals",
    "Siddhartha Hospital",
    "Life Emergency Hospital"
  ],
  "Primary Health Centres (PHCs)": [
    "PHC Kadiyam",
    "PHC Korukonda",
    "PHC Rajanagaram",
    "PHC Seethanagaram",
    "PHC Dowleswaram"
  ],
  "Community Health Centres": [
    "CHC Kadiyam",
    "CHC Korukonda",
    "CHC Rajanagaram"
  ],
  "Veterinary Hospitals": [
    "Veterinary Hospital Rajamahendravaram",
    "Veterinary Hospital Kadiyam",
    "Veterinary Hospital Rajanagaram"
  ],
  "Anganwadi Centres": [
    "Ward Anganwadi Centres",
    "Kadiyam Anganwadi Centres",
    "Korukonda Anganwadi Centres",
    "Rajanagaram Anganwadi Centres"
  ],
  "Banks & Financial Hubs": [
    "State Bank of India",
    "Andhra Bank",
    "Union Bank",
    "Canara Bank",
    "Indian Bank",
    "Indian Overseas Bank",
    "HDFC Bank",
    "ICICI Bank",
    "Axis Bank",
    "Punjab National Bank"
  ],
  "Post Offices": [
    "Rajamahendravaram Head Post Office",
    "Kadiyam Post Office",
    "Korukonda Post Office",
    "Dowleswaram Post Office",
    "Rajanagaram Post Office"
  ],
  "Police Stations": [
    "One Town Police Station",
    "Two Town Police Station",
    "Three Town Police Station",
    "Kadiyam Police Station",
    "Korukonda Police Station",
    "Rajanagaram Police Station",
    "Dowleswaram Police Station"
  ],
  "Fire Stations": [
    "Rajamahendravaram Fire Station",
    "Kadiyam Fire Station"
  ],
  "Government Offices": [
    "Collector Office",
    "RDO Office",
    "MRO Office",
    "Municipal Corporation Office",
    "District Panchayat Office",
    "Agriculture Office",
    "Revenue Office",
    "Civil Supplies Office",
    "Electricity Office",
    "Irrigation Office"
  ],
  "Municipal Office": [
    "Rajamahendravaram Municipal Corporation",
    "Kadiyam Nagar Panchayat"
  ],
  "MeeSeva Centres": [
    "MeeSeva Rajamahendravaram",
    "MeeSeva Kadiyam",
    "MeeSeva Korukonda",
    "MeeSeva Rajanagaram",
    "Multiple Authorized MeeSeva Centers"
  ],
  "Ration Shops (PDS)": [
    "Fair Price Shop Ward 1",
    "Fair Price Shop Ward 5",
    "Fair Price Shop Ward 12",
    "Fair Price Shop Kadiyam",
    "Fair Price Shop Korukonda",
    "Fair Price Shop Rajanagaram"
  ],
  "Libraries": [
    "District Central Library",
    "Municipal Library",
    "Government College Library",
    "Adikavi Nannaya University Library"
  ],
  "Public Parks": [
    "Pushkar Ghat Park",
    "Godavari River Front Park",
    "Municipal Children's Park",
    "Kadiyam Eco Park"
  ],
  "Bus Stations": [
    "APSRTC Rajamahendravaram Bus Complex",
    "Kadiyam Bus Station",
    "Korukonda Bus Stop",
    "Rajanagaram Bus Stand"
  ],
  "Railway Information": [
    "Rajamahendravaram Railway Station",
    "Godavari Railway Station",
    "Kadiyam Railway Station"
  ],
  "Other Public Services": [
    "Aadhaar Enrollment Centres",
    "Electricity Bill Counters",
    "Water Supply Office",
    "Passport Seva Kendra",
    "Employment Exchange",
    "CSC Centres",
    "e-Seva Centres",
    "Public Toilets",
    "Drinking Water Points"
  ],
};
