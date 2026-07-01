import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';
import '../../models/ward.dart';
import '../../models/user.dart';
import '../../utils/category_mapping.dart';
import '../../utils/mandal_mapping.dart';

class AdminManagementTab extends StatefulWidget {
  const AdminManagementTab({super.key});

  @override
  State<AdminManagementTab> createState() => _AdminManagementTabState();
}

class _AdminManagementTabState extends State<AdminManagementTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  final _wardController = TextEditingController();
  final _panchayatController = TextEditingController();
  final _villageController = TextEditingController();

  String? _errorMessage;
  bool _showAllOfficers = false;

  int _selectedRoleType = 0; // 0: Ward Admin, 1: Category Officer, 2: Mandal Officer
  String _selectedOfficerRole = CategoryMapping.officerCategories.keys.first;
  String _selectedMandalRole = CategoryMapping.mandalOfficerCategories.keys.first;

  String? _selectedWardId;
  String? _selectedWardName;
  String? _selectedMandal;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _wardController.dispose();
    _panchayatController.dispose();
    _villageController.dispose();
    super.dispose();
  }

  Future<void> _submit(bool isTelugu) async {
    if (!_formKey.currentState!.validate()) return;

    final appState = Provider.of<AppState>(context, listen: false);
    setState(() {
      _errorMessage = null;
    });

    final String wardId;
    final String wardName;
    if (_selectedRoleType == 1 || _selectedRoleType == 0) {
      final wardInput = _wardController.text.trim();
      final panchayatInput = _panchayatController.text.trim();
      
      if (_selectedRoleType == 0) {
        // Ward Admin has a specific ward
        String prefix = _villageController.text.trim().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
        if (prefix.isEmpty) {
          prefix = _panchayatController.text.trim().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
        }
        wardId = _selectedWardId ?? (wardInput.isNotEmpty ? '${prefix}_ward_$wardInput' : 'ward_unknown');
        wardName = _selectedWardName ?? (wardInput.isNotEmpty ? 'Ward $wardInput - ${_villageController.text.trim()}' : 'Unknown Ward');
      } else {
        // Category Officer covers a whole Panchayat
        wardId = panchayatInput;
        wardName = panchayatInput;
      }
    } else {
      wardId = 'mandal_level';
      wardName = 'Mandal Level';
    }

    try {
      final bool success;
      if (_selectedRoleType == 1) {
        success = await appState.createCategoryOfficer(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          password: _passwordController.text.trim(),
          wardId: wardId,
          wardName: wardName,
          mandalName: _selectedMandal,
          villageName: _villageController.text.trim().isNotEmpty ? _villageController.text.trim() : null,
          officerRole: _selectedOfficerRole,
        );
      } else if (_selectedRoleType == 2) {
        success = await appState.createMandalOfficer(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          password: _passwordController.text.trim(),
          mandalName: _selectedMandal,
          villageName: _villageController.text.trim().isNotEmpty ? _villageController.text.trim() : null,
          officerRole: _selectedMandalRole,
        );
      } else {
        success = await appState.createWardAdmin(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          password: _passwordController.text.trim(),
          wardId: wardId,
          wardName: wardName,
          mandalName: _selectedMandal,
          villageName: _villageController.text.trim().isNotEmpty ? _villageController.text.trim() : null,
          postId: _panchayatController.text.trim(),
        );
      }

      if (!mounted) return;
      if (success) {
        _nameController.clear();
        _phoneController.clear();
        _passwordController.clear();
        _wardController.clear();
        _panchayatController.clear();
        _villageController.clear();
        _selectedWardId = null;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isTelugu
                  ? 'వార్డు అధికారి ఖాతా విజయవంతంగా సృష్టించబడింది!'
                  : 'Ward Officer account created successfully!',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).primaryColor,
          ),
        );
      } else {
        setState(() {
          _errorMessage = isTelugu
              ? 'ఈ మొబైల్ సంఖ్యతో ఇప్పటికే ఒక ఖాతా ఉంది.'
              : 'An account with this phone number already exists.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isTelugu = appState.isTelugu;
    final wards = appState.wards;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isTelugu ? 'వార్డు అధికారుల నిర్వహణ' : 'Manage Ward Officers',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          Text(
            isTelugu
                ? 'కొత్త వార్డు అధికారులను చేర్చండి మరియు వారి వార్డులను కేటాయించండి.'
                : 'Provision new ward administrators and assign them to specific municipal jurisdictions.',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          // Register Form Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      isTelugu ? 'అధికారి ప్రొఫైల్ సృష్టించు' : 'Create Officer Profile',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedRoleType = 0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedRoleType == 0 ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _selectedRoleType == 0 ? Theme.of(context).primaryColor : Colors.grey.shade300,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(isTelugu ? 'వార్డు అడ్మిన్' : 'Ward Admin', style: TextStyle(fontSize: 12, fontWeight: _selectedRoleType == 0 ? FontWeight.bold : FontWeight.normal, color: _selectedRoleType == 0 ? Theme.of(context).primaryColor : Colors.grey.shade700)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _selectedRoleType = 1;
                              _selectedWardId = null; // Clear ward selection
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedRoleType == 1 ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _selectedRoleType == 1 ? Theme.of(context).primaryColor : Colors.grey.shade300,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(isTelugu ? 'క్యాటగిరీ ఆఫీసర్' : 'Category Officer', style: TextStyle(fontSize: 12, fontWeight: _selectedRoleType == 1 ? FontWeight.bold : FontWeight.normal, color: _selectedRoleType == 1 ? Theme.of(context).primaryColor : Colors.grey.shade700)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _selectedRoleType = 2;
                              _selectedWardId = null; // Clear ward selection
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedRoleType == 2 ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _selectedRoleType == 2 ? Theme.of(context).primaryColor : Colors.grey.shade300,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(isTelugu ? 'మండల అధికారి' : 'Mandal Officer', style: TextStyle(fontSize: 12, fontWeight: _selectedRoleType == 2 ? FontWeight.bold : FontWeight.normal, color: _selectedRoleType == 2 ? Theme.of(context).primaryColor : Colors.grey.shade700)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_selectedRoleType == 1) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedOfficerRole,
                        decoration: InputDecoration(
                          labelText: isTelugu ? 'ఆఫీసర్ పాత్ర' : 'Officer Role',
                          prefixIcon: const Icon(Icons.badge_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: CategoryMapping.officerCategories.keys.map((role) {
                          return DropdownMenuItem<String>(
                            value: role,
                            child: Text(role),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedOfficerRole = val!;
                          });
                        },
                      ),
                    ],
                    if (_selectedRoleType == 2) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedMandalRole,
                        decoration: InputDecoration(
                          labelText: isTelugu ? 'మండల ఆఫీసర్ పాత్ర' : 'Mandal Officer Role',
                          prefixIcon: const Icon(Icons.star_border),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: CategoryMapping.mandalOfficerCategories.keys.map((role) {
                          return DropdownMenuItem<String>(
                            value: role,
                            child: Text(role),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedMandalRole = val!;
                          });
                        },
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: isTelugu ? 'అధికారి పూర్తి పేరు' : 'Officer Full Name',
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      validator: (val) => val == null || val.isEmpty
                          ? (isTelugu ? 'పేరును నమోదు చేయండి' : 'Enter name')
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: isTelugu ? 'మొబైల్ సంఖ్య' : 'Contact Mobile Number',
                        prefixIcon: const Icon(Icons.phone_outlined),
                      ),
                      validator: (val) => val == null || val.length < 10
                          ? (isTelugu ? 'సరైన సంఖ్యను నమోదు చేయండి' : 'Enter valid number')
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: isTelugu ? 'పోర్టల్ పాస్‌వర్డ్' : 'Portal Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                      ),
                      validator: (val) => val == null || val.isEmpty
                          ? (isTelugu ? 'పాస్‌వర్డ్‌ను నమోదు చేయండి' : 'Enter password')
                          : null,
                    ),
                    const SizedBox(height: 12),

                    // Mandal Selection (Applicable for all Officer roles)
                    DropdownButtonFormField<String>(
                      initialValue: _selectedMandal,
                      decoration: InputDecoration(
                        labelText: isTelugu ? 'మండలం ఎంచుకోండి' : 'Select Mandal',
                        prefixIcon: const Icon(Icons.account_balance_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: MandalMapping.mandals.map((m) {
                        return DropdownMenuItem<String>(
                          value: m,
                          child: Text(m),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedMandal = val;
                          _panchayatController.clear(); // Reset panchayat if mandal changes
                        });
                      },
                      validator: (val) => val == null || val.isEmpty
                          ? (isTelugu ? 'మండలాన్ని ఎంచుకోండి' : 'Select Mandal')
                          : null,
                    ),
                    const SizedBox(height: 12),

                    // Panchayat Picker for BOTH Ward Admin and Category Officer
                    if (_selectedRoleType == 0 || _selectedRoleType == 1)
                      TextFormField(
                        controller: _panchayatController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: isTelugu ? 'కేటాయించిన పంచాయతీ' : 'Assigned Panchayat Jurisdiction',
                          prefixIcon: const Icon(Icons.location_city_outlined),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: () {
                              if (_selectedMandal == null) return;
                              final filteredPanchayats = MandalMapping.getPanchayatsForMandal(_selectedMandal!, appState.uniquePanchayats);
                              _showSearchablePanchayatPicker(context, filteredPanchayats, isTelugu);
                            },
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onTap: () {
                          if (_selectedMandal == null) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isTelugu ? 'ముందుగా మండలాన్ని ఎంచుకోండి' : 'Please select a Mandal first')));
                            return;
                          }
                          final filteredPanchayats = MandalMapping.getPanchayatsForMandal(_selectedMandal!, appState.uniquePanchayats);
                          _showSearchablePanchayatPicker(context, filteredPanchayats, isTelugu);
                        },
                        validator: (val) => val == null || val.isEmpty
                            ? (isTelugu ? 'పంచాయతీని ఎంచుకోండి' : 'Select Panchayat')
                            : null,
                        onChanged: (_) {
                          _villageController.clear();
                        },
                      ),
                    if (_selectedRoleType == 0 || _selectedRoleType == 1)
                      const SizedBox(height: 12),

                    // Village Picker for BOTH Ward Admin and Category Officer
                    if (_selectedRoleType == 0 || _selectedRoleType == 1)
                      TextFormField(
                        controller: _villageController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: isTelugu ? 'కేటాయించిన గ్రామం' : 'Assigned Village',
                          prefixIcon: const Icon(Icons.home_work_outlined),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: () {
                              if (_panchayatController.text.isEmpty) return;
                              final filteredVillages = MandalMapping.getVillagesForPanchayat(_panchayatController.text);
                              _showSearchableVillagePicker(context, filteredVillages, isTelugu);
                            },
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onTap: () {
                          if (_panchayatController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isTelugu ? 'ముందుగా పంచాయతీని ఎంచుకోండి' : 'Please select a Panchayat first')));
                            return;
                          }
                          final filteredVillages = MandalMapping.getVillagesForPanchayat(_panchayatController.text);
                          _showSearchableVillagePicker(context, filteredVillages, isTelugu);
                        },
                        // Not strictly mandatory for Category Officer since they can manage the whole Panchayat, but useful for Ward Admin
                        validator: (val) {
                          if (_selectedRoleType == 0 && (val == null || val.isEmpty)) {
                            return isTelugu ? 'గ్రామాన్ని ఎంచుకోండి' : 'Select Village';
                          }
                          return null;
                        },
                      ),
                    if (_selectedRoleType == 0 || _selectedRoleType == 1)
                      const SizedBox(height: 12),
                    
                    // Ward Number Input ONLY for Ward Admin
                    if (_selectedRoleType == 0)
                      TextFormField(
                        controller: _wardController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: isTelugu ? 'కేటాయించిన వార్డు (ఉదా. 50)' : 'Assigned Jurisdiction (Ward Number)',
                          prefixIcon: const Icon(Icons.map_outlined),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: () => _showSearchableWardPicker(context, wards, isTelugu),
                            tooltip: isTelugu ? 'వార్డును ఎంచుకోండి' : 'Select Ward',
                          ),
                          hintText: 'e.g., 50',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        validator: (val) => val == null || val.isEmpty
                            ? (isTelugu ? 'వార్డు నంబర్‌ను నమోదు చేయండి' : 'Enter ward number')
                            : null,
                        onChanged: (_) {
                          _selectedWardId = null;
                          _selectedWardName = null;
                        },
                      ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade600, fontSize: 12, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _submit(isTelugu),
                      child: Text(isTelugu ? 'అధికారిని సృష్టించు' : 'CREATE OFFICER'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Officer Listings
          Text(
            isTelugu ? 'క్రియాశీల అధికారులు & వార్డులు' : 'Active Officers & Wards',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 10),

          Builder(builder: (context) {
            final officers = appState.users.where((u) => u.role == UserRole.wardAdmin || u.role == UserRole.categoryOfficer || u.role == UserRole.mandalOfficer).toList();
            // sort so newest is first
            officers.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
            
            final displayCount = _showAllOfficers
                ? officers.length
                : (officers.length > 3 ? 3 : officers.length);
                
            return Column(
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayCount,
                  itemBuilder: (context, index) {
                    final o = officers[index];
                    final isCategory = o.role == UserRole.categoryOfficer;
                    final isMandal = o.role == UserRole.mandalOfficer;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.teal.shade50, shape: BoxShape.circle),
                              child: Icon(isMandal ? Icons.star : (isCategory ? Icons.category : Icons.admin_panel_settings), color: Theme.of(context).primaryColor),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    o.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  Text(
                                    isTelugu 
                                      ? (isMandal ? 'మండల అధికారి: ${o.officerRole}' : isCategory ? 'కేటగిరీ: ${o.officerRole} (${o.wardName})' : 'బాధ్యత వార్డు: ${o.wardName}') 
                                      : (isMandal ? 'Mandal Officer: ${o.officerRole}' : isCategory ? 'Role: ${o.officerRole} (${o.wardName})' : 'Responsible for: ${o.wardName}'),
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isCategory || isMandal)
                                  IconButton(
                                    icon: Icon(Icons.edit_outlined, size: 20, color: Theme.of(context).primaryColor),
                                    tooltip: 'Edit Role',
                                    onPressed: () => _showEditRoleDialog(context, o, isTelugu, appState),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                                  tooltip: 'Delete',
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text('Confirm Delete'),
                                        content: Text('Delete ${o.name}?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                        ],
                                      ),
                                    );
                                    if (confirm == true && context.mounted) {
                                      await appState.deleteUser(o.id);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                if (officers.length > 3)
                  TextButton(
                    onPressed: () => setState(() => _showAllOfficers = !_showAllOfficers),
                    child: Text(
                      _showAllOfficers
                          ? (isTelugu ? 'తక్కువ చూపించు' : 'Show Less')
                          : (isTelugu ? 'మరిన్ని చూపించు (${officers.length - 3} more)' : 'Show More (${officers.length - 3} more)'),
                      style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                    ),
                  ),
              ],
            );
          }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _showEditRoleDialog(BuildContext context, User officer, bool isTelugu, AppState appState) {
    final isCategory = officer.role == UserRole.categoryOfficer;
    final allRoles = isCategory
        ? CategoryMapping.officerCategories.keys.toList()
        : CategoryMapping.mandalOfficerCategories.keys.toList();
    
    String selectedRole = officer.officerRole ?? allRoles.first;
    if (!allRoles.contains(selectedRole)) selectedRole = allRoles.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheet) {
          return Padding(
            padding: EdgeInsets.only(
              top: 20, left: 20, right: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isTelugu ? '${officer.name} పాత్రను సవరించు' : 'Edit Role: ${officer.name}',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  isTelugu ? 'ప్రస్తుత పాత్ర: ${officer.officerRole ?? "-"}' : 'Current role: ${officer.officerRole ?? "-"}',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  decoration: InputDecoration(
                    labelText: isTelugu ? 'కొత్త పాత్ర' : 'New Role',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: allRoles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (val) => setSheet(() => selectedRole = val!),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await appState.updateOfficerRole(officer.id, selectedRole);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(isTelugu ? 'పాత్ర విజయవంతంగా నవీకరించబడింది!' : 'Role updated successfully!'),
                        backgroundColor: Theme.of(context).primaryColor,
                      ));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(isTelugu ? 'నవీకరించు' : 'Update Role'),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  void _showSearchableWardPicker(BuildContext context, List<Ward> wards, bool isTelugu) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _SearchableWardPicker(
          wards: wards,
          isTelugu: isTelugu,
          onSelected: (ward) {
            setState(() {
              _selectedWardId = ward.id;
              _selectedWardName = ward.name;
              _wardController.text = ward.name;
            });
          },
        );
      },
    );
  }
  void _showSearchablePanchayatPicker(BuildContext context, List<String> panchayats, bool isTelugu) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _SearchablePanchayatPicker(
          panchayats: panchayats,
          isTelugu: isTelugu,
          onSelected: (panchayat) {
            setState(() {
              _panchayatController.text = panchayat;
              _villageController.clear();
            });
          },
        );
      },
    );
  }

  void _showSearchableVillagePicker(BuildContext context, List<String> villages, bool isTelugu) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _SearchableVillagePicker(
          villages: villages,
          isTelugu: isTelugu,
          onSelected: (village) {
            setState(() {
              _villageController.text = village;
            });
          },
        );
      },
    );
  }
}

class _SearchableWardPicker extends StatefulWidget {
  final List<Ward> wards;
  final bool isTelugu;
  final ValueChanged<Ward> onSelected;

  const _SearchableWardPicker({
    required this.wards,
    required this.isTelugu,
    required this.onSelected,
  });

  @override
  State<_SearchableWardPicker> createState() => _SearchableWardPickerState();
}

class _SearchableWardPickerState extends State<_SearchableWardPicker> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.wards.where((w) {
      final nameLower = w.name.toLowerCase();
      final queryLower = _searchQuery.trim().toLowerCase();
      if (queryLower.isEmpty) return true;
      // Match by name, or by ward number alone (e.g. "150" matches "Ward 150")
      if (nameLower.contains(queryLower)) return true;
      // Extract ward number from name like "Ward 150 - ..."
      final numMatch = RegExp(r'ward\s*(\d+)', caseSensitive: false).firstMatch(w.name);
      if (numMatch != null && numMatch.group(1)!.startsWith(queryLower)) return true;
      return false;
    }).toList();

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.isTelugu ? 'వార్డును ఎంచుకోండి' : 'Select Ward Jurisdiction',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              hintText: widget.isTelugu ? 'వార్డును శోధించండి...' : 'Search wards...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      widget.isTelugu ? 'ఫలితాలు లేవు' : 'No wards found',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final w = filtered[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        leading: Icon(Icons.map_outlined, color: Theme.of(context).primaryColor),
                        title: Text(
                          w.name,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        onTap: () {
                          widget.onSelected(w);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SearchablePanchayatPicker extends StatefulWidget {
  final List<String> panchayats;
  final bool isTelugu;
  final ValueChanged<String> onSelected;

  const _SearchablePanchayatPicker({
    required this.panchayats,
    required this.isTelugu,
    required this.onSelected,
  });

  @override
  State<_SearchablePanchayatPicker> createState() => _SearchablePanchayatPickerState();
}

class _SearchablePanchayatPickerState extends State<_SearchablePanchayatPicker> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.panchayats.where((p) {
      return p.toLowerCase().contains(_searchQuery.trim().toLowerCase());
    }).toList();

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.isTelugu ? 'పంచాయతీని ఎంచుకోండి' : 'Select Panchayat',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              hintText: widget.isTelugu ? 'పంచాయతీని శోధించండి...' : 'Search panchayats...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      widget.isTelugu ? 'ఫలితాలు లేవు' : 'No panchayats found',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final p = filtered[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        leading: Icon(Icons.location_city_outlined, color: Theme.of(context).primaryColor),
                        title: Text(
                          p,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        onTap: () {
                          widget.onSelected(p);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SearchableVillagePicker extends StatefulWidget {
  final List<String> villages;
  final bool isTelugu;
  final ValueChanged<String> onSelected;

  const _SearchableVillagePicker({
    required this.villages,
    required this.isTelugu,
    required this.onSelected,
  });

  @override
  State<_SearchableVillagePicker> createState() => _SearchableVillagePickerState();
}

class _SearchableVillagePickerState extends State<_SearchableVillagePicker> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.villages.where((v) {
      return v.toLowerCase().contains(_searchQuery.trim().toLowerCase());
    }).toList();

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.isTelugu ? 'గ్రామాన్ని ఎంచుకోండి' : 'Select Village',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              hintText: widget.isTelugu ? 'గ్రామాన్ని శోధించండి...' : 'Search villages...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      widget.isTelugu ? 'ఫలితాలు లేవు' : 'No villages found',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final v = filtered[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        leading: Icon(Icons.home_work_outlined, color: Theme.of(context).primaryColor),
                        title: Text(
                          v,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        onTap: () {
                          widget.onSelected(v);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
