import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/app_state.dart';
import '../../services/translation_service.dart';
import '../../main.dart';

class LoginScreen extends StatefulWidget {
  final bool isLoginMode;
  const LoginScreen({super.key, this.isLoginMode = true});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController(); // For registration
  final _otpController = TextEditingController();

  bool _isLoginMode = true;
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _showOtp = false;
  String? _errorMessage;
  String? _otpErrorMessage;

  bool _isEmployed = false;
  String? _selectedEducation;

  @override
  void initState() {
    super.initState();
    _isLoginMode = widget.isLoginMode;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final appState = Provider.of<AppState>(context, listen: false);
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    bool success = false;
    if (_isLoginMode) {
      final error = await appState.login(
        _phoneController.text.trim(),
        _passwordController.text.trim(),
      );
      if (error == null && mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainGatekeeper()),
          (route) => false,
        );
        return;
      }
      if (error != null && mounted) {
        setState(() {
          _errorMessage = error;
        });
      }
    } else {
      success = await appState.register(
        _nameController.text.trim(),
        _phoneController.text.trim(),
        _passwordController.text.trim(),
        _isEmployed,
        _selectedEducation ?? '',
      );
      if (success && mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainGatekeeper()),
          (route) => false,
        );
        return;
      }
      if (!success && mounted) {
        setState(() {
          _errorMessage = appState.isTelugu 
              ? 'ఈ మొబైల్ సంఖ్యతో ఇప్పటికే ఖాతా ఉంది.' 
              : 'A user with this phone number already exists.';
          _showOtp = false; // Go back to correct credentials
        });
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        _otpController.clear();
      });
    }
  }



  void _onActionPressed() {
    if (_formKey.currentState!.validate()) {
      _submit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isTelugu = appState.isTelugu;


    final isChecking = appState.connectionStatus == ConnectionStatus.checking;
    final isConnected = appState.connectionStatus == ConnectionStatus.connected;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => appState.setLanguage(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: !isTelugu ? Theme.of(context).primaryColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'English',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: !isTelugu ? Colors.white : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => appState.setLanguage(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isTelugu ? Theme.of(context).primaryColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'తెలుగు',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isTelugu ? Colors.white : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,

              children: [
                const Spacer(flex: 1),
                // App Logo/Seal Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 80,
                          height: 80,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        Trans.t('title', isTelugu),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isTelugu
                            ? 'డిజిటల్ గ్రీవెన్స్ & రిడ్రెస్సల్ పోర్టల్'
                            : 'Digital Complaint & Redressal Portal',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 1),

                // Tracking button shown in registration mode
                if (!_isLoginMode) ...[
                  OutlinedButton.icon(
                    onPressed: () => _showTrackComplaintDialog(context, isTelugu),
                    icon: const Icon(Icons.search),
                    label: Text(
                      isTelugu ? 'నమోదు లేకుండా ఫిర్యాదును ట్రాక్ చేయండి' : 'Track Complaint Without Register',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      side: BorderSide(color: Theme.of(context).primaryColor),
                      foregroundColor: Theme.of(context).primaryColor,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Form card
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  shadowColor: Colors.black.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: _showOtp ? _buildOtpForm() : _buildCredentialsForm(),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                // DB connection status
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isChecking
                          ? Colors.grey.shade100
                          : isConnected
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isChecking
                            ? Colors.grey.shade300
                            : isConnected
                                ? const Color(0xFF86EFAC)
                                : const Color(0xFFFDE047),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isChecking)
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.grey,
                            ),
                          )
                        else
                          Icon(
                            isConnected ? Icons.cloud_done : Icons.cloud_off,
                            size: 16,
                            color: isConnected
                                ? const Color(0xFF15803D)
                                : const Color(0xFFB45309),
                          ),
                        const SizedBox(width: 8),
                        Text(
                          isChecking
                              ? (isTelugu ? 'కనెక్ట్ అవుతోంది...' : 'Connecting to Database…')
                              : isConnected
                                  ? '${Trans.t('db_connected', isTelugu)} — Live Sync'
                                  : '${Trans.t('offline_mode', isTelugu)} — Local Queue',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isChecking
                                ? Colors.grey.shade700
                                : isConnected
                                    ? const Color(0xFF15803D)
                                    : const Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  },
),
),
);
}

  Widget _buildCredentialsForm() {
    final appState = Provider.of<AppState>(context, listen: false);
    final isTelugu = appState.isTelugu;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _isLoginMode
                ? (isTelugu ? 'ఖాతాకు లాగిన్ చేయండి' : 'Login to Account')
                : (isTelugu ? 'పౌరుడి నమోదు' : 'Register Citizen'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (!_isLoginMode) ...[
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: Trans.t('name', isTelugu),
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              validator: (val) => val == null || val.isEmpty 
                  ? (isTelugu ? 'పేరును నమోదు చేయండి' : 'Enter name') 
                  : null,
            ),
            const SizedBox(height: 16),
          ],
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: Trans.t('phone_number', isTelugu),
              prefixIcon: const Icon(Icons.phone_outlined),
              hintText: 'e.g. 9876543210',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            validator: (val) {
              if (val == null || val.isEmpty) {
                return isTelugu ? 'మొబైల్ సంఖ్యను నమోదు చేయండి' : 'Enter phone';
              }
              if (val.length < 10) {
                return isTelugu ? '10 అంకెల సంఖ్యను నమోదు చేయండి' : 'Enter 10 digit number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: Trans.t('password', isTelugu),
              prefixIcon: const Icon(Icons.lock_outline),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            validator: (val) => val == null || val.isEmpty 
                ? (isTelugu ? 'పాస్‌వర్డ్‌ను నమోదు చేయండి' : 'Enter password') 
                : null,
          ),
          if (!_isLoginMode) ...[
            const SizedBox(height: 16),
            Text(
              isTelugu ? 'మీరు?' : 'Are You ?',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isEmployed = true;
                        _selectedEducation = null;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isEmployed == true ? Theme.of(context).primaryColor : Colors.grey.shade200,
                      foregroundColor: _isEmployed == true ? Colors.white : Colors.black,
                      elevation: 0,
                    ),
                    child: Text(isTelugu ? 'ఉద్యోగి' : 'Employed'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isEmployed = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isEmployed == false ? Theme.of(context).primaryColor : Colors.grey.shade200,
                      foregroundColor: _isEmployed == false ? Colors.white : Colors.black,
                      elevation: 0,
                    ),
                    child: Text(isTelugu ? 'నిరుద్యోగి' : 'Unemployed'),
                  ),
                ),
              ],
            ),
            if (_isEmployed == false) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: isTelugu ? 'విద్యార్హత' : 'Education Qualification',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                initialValue: _selectedEducation,
                items: [
                  '10th',
                  'Intermediate',
                  'ITI',
                  'Diploma',
                  'Degree (BA/BCom/BSc/BBA/BCA)',
                  'BTech/BE',
                  'MBBS',
                  'Post Graduation (MA/MCom/MSc/MBA/MCA/MTech)',
                  'PhD',
                  'Professional (CA/CS/CMA)',
                  'Other'
                ]
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedEducation = val;
                  });
                },
                validator: (val) => val == null ? (isTelugu ? 'దయచేసి విద్యార్హతను ఎంచుకోండి' : 'Please select education') : null,
              ),
            ],
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red.shade600, fontSize: 13, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _onActionPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 2,
            ),
            child: Text(
              _isLoginMode 
                  ? Trans.t('sign_in', isTelugu) 
                  : Trans.t('sign_up', isTelugu),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              setState(() {
                _isLoginMode = !_isLoginMode;
                _errorMessage = null;
              });
            },
            child: Text(
              _isLoginMode 
                  ? Trans.t('no_account', isTelugu) 
                  : Trans.t('has_account', isTelugu),
              style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpForm() {
    final appState = Provider.of<AppState>(context, listen: false);
    final isTelugu = appState.isTelugu;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
              onPressed: () {
                setState(() {
                  _showOtp = false;
                  _otpErrorMessage = null;
                });
              },
            ),
            Expanded(
              child: Text(
                Trans.t('otp_verification', isTelugu),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          Trans.t('otp_msg', isTelugu),
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 16),
          decoration: InputDecoration(
            counterText: '',
            hintText: '000000',
            hintStyle: TextStyle(color: Colors.grey.shade300, letterSpacing: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
            ),
          ),
        ),
        if (_otpErrorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            _otpErrorMessage!,
            style: TextStyle(color: Colors.red.shade600, fontSize: 13, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _onActionPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  Trans.t('verify', isTelugu),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _isLoading
              ? null
              : () {
                  setState(() {
                    _otpController.text = '123456';
                    _otpErrorMessage = null;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isTelugu ? 'OTP కోడ్ ఆటో-ఫిల్ చేయబడింది: 123456' : 'Simulated OTP Auto-filled: 123456',
                      ),
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                  );
                },
          child: Text(
            Trans.t('resend_otp', isTelugu),
            style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
          ),
        ),
      ],
    );
  }

  void _showTrackComplaintDialog(BuildContext context, bool isTelugu) {
    final TextEditingController idController = TextEditingController();
    bool isSearching = false;
    String? trackError;
    Map<String, dynamic>? complaintData;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    isTelugu ? 'ఫిర్యాదు స్థితి' : 'Track Complaint Status',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  if (complaintData == null) ...[
                    TextFormField(
                      controller: idController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: isTelugu ? 'ఫిర్యాదు ID నమోదు చేయండి' : 'Enter Complaint ID',
                        hintText: 'e.g. 1781690416750',
                        prefixIcon: const Icon(Icons.tag),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    if (trackError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        trackError!,
                        style: TextStyle(color: Colors.red.shade600, fontSize: 13, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: isSearching ? null : () async {
                        final id = idController.text.trim();
                        if (id.isEmpty) return;
                        
                        setModalState(() {
                          isSearching = true;
                          trackError = null;
                        });
                        
                        try {
                          final response = await Supabase.instance.client
                              .from('complaints')
                              .select('*, users!complaints_assignedOfficerId_fkey(name, officerRole, role)')
                              .eq('id', id)
                              .maybeSingle();
                              
                          if (response == null) {
                            setModalState(() {
                              trackError = isTelugu ? 'ఫిర్యాదు కనుగొనబడలేదు. దయచేసి IDని తనిఖీ చేయండి.' : 'Complaint not found. Please check the ID.';
                              isSearching = false;
                            });
                          } else {
                            setModalState(() {
                              complaintData = response;
                              isSearching = false;
                            });
                          }
                        } catch (e) {
                          // Try alternative foreign key syntax if the exact constraint name fails
                          try {
                            final response2 = await Supabase.instance.client
                                .from('complaints')
                                .select('*')
                                .eq('id', id)
                                .maybeSingle();
                            if (response2 != null && response2['assignedOfficerId'] != null) {
                              final userResp = await Supabase.instance.client
                                  .from('users')
                                  .select('name, officerRole, role')
                                  .eq('id', response2['assignedOfficerId'])
                                  .maybeSingle();
                              if (userResp != null) {
                                response2['users'] = userResp;
                              }
                            }
                            if (response2 == null) {
                              setModalState(() {
                                trackError = isTelugu ? 'ఫిర్యాదు కనుగొనబడలేదు. దయచేసి IDని తనిఖీ చేయండి.' : 'Complaint not found. Please check the ID.';
                                isSearching = false;
                              });
                            } else {
                              setModalState(() {
                                complaintData = response2;
                                isSearching = false;
                              });
                            }
                          } catch (innerE) {
                            setModalState(() {
                              trackError = isTelugu ? 'లోపం సంభవించింది: ${innerE.toString()}' : 'An error occurred: ${innerE.toString()}';
                              isSearching = false;
                            });
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: isSearching 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(isTelugu ? 'శోధించండి' : 'Search', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ] else ...[
                    // Show complaint details
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow('ID', complaintData!['id'].toString()),
                          _buildDetailRow(isTelugu ? 'విభాగం' : 'Category', complaintData!['category'].toString()),
                          
                          Builder(builder: (context) {
                            final status = complaintData!['status'].toString();
                            String statusDisplay = status;
                            if (isTelugu) {
                              if (status == 'submitted') {
                                statusDisplay = 'నిరీక్షణలో';
                              } else if (status == 'inProgress') {
                                statusDisplay = 'పరిష్కారంలో ఉంది';
                              } else if (status == 'resolved') {
                                statusDisplay = 'పరిష్కారమైంది';
                              }
                            }
                            return _buildDetailRow(isTelugu ? 'స్థితి' : 'Status', statusDisplay);
                          }),
                          
                          Builder(
                            builder: (context) {
                              String officerDisplay = isTelugu ? 'నియమించబడలేదు' : 'Not yet assigned';
                              if (complaintData!['users'] != null) {
                                final userObj = complaintData!['users'] as Map<String, dynamic>;
                                final roleLabel = userObj['officerRole'] ?? userObj['role'] ?? 'Officer';
                                officerDisplay = '${userObj['name']} ($roleLabel)';
                              } else if (complaintData!['assignedOfficerId'] != null) {
                                officerDisplay = isTelugu ? 'నియమించబడ్డారు' : 'Assigned';
                              }
                              return _buildDetailRow(isTelugu ? 'అధికారి' : 'Officer', officerDisplay);
                            }
                          ),
                          _buildDetailRow(
                            isTelugu ? 'తేదీ' : 'Date', 
                            DateTime.parse(complaintData!['createdAt']).toLocal().toString().split('.')[0]
                          ),
                          if (complaintData!['resolvedAt'] != null)
                            _buildDetailRow(
                              isTelugu ? 'పరిష్కార తేదీ' : 'Resolved', 
                              DateTime.parse(complaintData!['resolvedAt']).toLocal().toString().split('.')[0]
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(isTelugu ? 'మూసివేయు' : 'Close'),
                    )
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            );
          }
        );
      }
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
