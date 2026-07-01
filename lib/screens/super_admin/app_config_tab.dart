import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/app_config.dart';
import '../../services/app_state.dart';
import '../../services/supabase_service.dart';
import '../../themes/theme_provider.dart';

class AppConfigTab extends StatefulWidget {
  const AppConfigTab({super.key});

  @override
  State<AppConfigTab> createState() => _AppConfigTabState();
}

class _AppConfigTabState extends State<AppConfigTab> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _roleController = TextEditingController();
  final _constituencyController = TextEditingController();
  
  String? _partyLogoUrl;
  String? _politicianImageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  void _loadCurrentConfig() {
    final appState = Provider.of<AppState>(context, listen: false);
    final config = appState.appConfig;
    if (config != null) {
      _nameController.text = config.politicianName;
      _roleController.text = config.politicianRole;
      _constituencyController.text = config.constituencyName;
      _partyLogoUrl = config.partyLogoUrl;
      _politicianImageUrl = config.politicianImageUrl;
    } else {
      _nameController.clear();
      _roleController.clear();
      _constituencyController.clear();
      _partyLogoUrl = null;
      _politicianImageUrl = null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _constituencyController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isPartyLogo) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (isPartyLogo) {
          _partyLogoUrl = pickedFile.path;
        } else {
          _politicianImageUrl = pickedFile.path;
        }
      });
    }
  }

  Future<void> _saveConfig() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      final appState = Provider.of<AppState>(context, listen: false);
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      String? finalPartyLogoUrl = _partyLogoUrl;
      String? finalPoliticianUrl = _politicianImageUrl;

      try {
        if (_partyLogoUrl != null && !_partyLogoUrl!.startsWith('http')) {
          final file = File(_partyLogoUrl!);
          if (file.existsSync()) {
            final url = await SupabaseService.uploadAppAssetImage(file, '${themeProvider.activeParty.id}_party_logo');
            if (url != null) {
              finalPartyLogoUrl = url;
            } else {
              finalPartyLogoUrl = appState.appConfig?.partyLogoUrl;
            }
          }
        }

        if (_politicianImageUrl != null && !_politicianImageUrl!.startsWith('http')) {
          final file = File(_politicianImageUrl!);
          if (file.existsSync()) {
            final url = await SupabaseService.uploadAppAssetImage(file, '${themeProvider.activeParty.id}_politician_image');
            if (url != null) {
              finalPoliticianUrl = url;
            } else {
              finalPoliticianUrl = appState.appConfig?.politicianImageUrl;
            }
          }
        }

        final newConfig = AppConfig(
          id: themeProvider.activeParty.id,
          politicianName: _nameController.text.trim(),
          politicianRole: _roleController.text.trim(),
          constituencyName: _constituencyController.text.trim(),
          partyLogoUrl: finalPartyLogoUrl,
          politicianImageUrl: finalPoliticianUrl,
        );

        await appState.updateAppConfig(newConfig);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(appState.isTelugu ? 'విజయవంతంగా సేవ్ చేయబడింది!' : 'Configuration saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving config: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTelugu = Provider.of<AppState>(context).isTelugu;

    return Scaffold(
      appBar: AppBar(
        title: Text(isTelugu ? 'యాప్ రూపకల్పన' : 'App Branding'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Party Toggle
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    final isTdp = themeProvider.activeParty.id == 'tdp';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade300, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () async {
                              if (isTdp) return;
                              // Instantly update theme
                              themeProvider.setActiveParty('tdp');
                              
                              // Fetch config without full-screen loading
                              final appState = Provider.of<AppState>(context, listen: false);
                              await appState.reloadAppConfigForParty('tdp');
                              if (mounted) {
                                _loadCurrentConfig();
                                setState(() {}); // Trigger rebuild just for text fields if needed
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                              decoration: BoxDecoration(
                                color: isTdp ? Theme.of(context).primaryColor : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'TDP',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isTdp ? Colors.white : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              if (!isTdp) return;
                              // Instantly update theme
                              themeProvider.setActiveParty('jsp');
                              
                              // Fetch config without full-screen loading
                              final appState = Provider.of<AppState>(context, listen: false);
                              await appState.reloadAppConfigForParty('jsp');
                              if (mounted) {
                                _loadCurrentConfig();
                                setState(() {}); // Trigger rebuild just for text fields if needed
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                              decoration: BoxDecoration(
                                color: !isTdp ? Theme.of(context).primaryColor : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'JSP',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: !isTdp ? Colors.white : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                
                Text(
                  isTelugu ? 'వెల్‌కమ్ స్క్రీన్ వివరాలు' : 'Welcome Screen Details',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: isTelugu ? 'రాజకీయ నాయకుడి పేరు' : 'Politician Name',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _roleController,
                  decoration: InputDecoration(
                    labelText: isTelugu ? 'హోదా / పార్టీ' : 'Role / Party (e.g. TDP MLA)',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _constituencyController,
                  decoration: InputDecoration(
                    labelText: isTelugu ? 'నియోజకవర్గం' : 'Constituency',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 24),

                Text(
                  isTelugu ? 'చిత్రాలు అప్‌లోడ్' : 'Upload Images',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Text('Party Logo/Background'),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _pickImage(true),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: _partyLogoUrl != null 
                                ? (_partyLogoUrl!.startsWith('http') || kIsWeb
                                    ? NetworkImage(_partyLogoUrl!) 
                                    : FileImage(File(_partyLogoUrl!))) as ImageProvider
                                : null,
                              child: _partyLogoUrl == null ? const Icon(Icons.add_a_photo, size: 30) : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          const Text('Politician Photo'),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _pickImage(false),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: _politicianImageUrl != null 
                                ? (_politicianImageUrl!.startsWith('http') || kIsWeb
                                    ? NetworkImage(_politicianImageUrl!) 
                                    : FileImage(File(_politicianImageUrl!))) as ImageProvider
                                : null,
                              child: _politicianImageUrl == null ? const Icon(Icons.add_a_photo, size: 30) : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
                    onPressed: _saveConfig,
                    child: Text(isTelugu ? 'సేవ్ చేయండి' : 'Save Configuration'),
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }
}
