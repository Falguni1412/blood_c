import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:blood_c/services/auth_service.dart';
import 'package:blood_c/widgets/custom_text_field.dart';
import 'donor_home_page.dart';
import 'receiver_home_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  File? _image;
  final ImagePicker _picker = ImagePicker();

  // Step 1: Basic Info
  final _formKeyStep1 = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();

  // Step 2: OTP Verification
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  int _resendSeconds = 30;
  Timer? _resendTimer;

  // Step 3: Role
  String? _selectedRole; // 'Donor', 'Receiver'

  // Step 4: Details
  final _formKeyStep3 = GlobalKey<FormState>();
  final _govIdController = TextEditingController();
  String? _bloodGroup;
  // Donor Fields
  final _weightController = TextEditingController();
  final _lastDonationController = TextEditingController();
  // Receiver Fields
  final _hospitalController = TextEditingController();
  String? _urgencyLevel;

  final AuthService _authService = AuthService();

  final List<String> _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'O+',
    'O-',
    'AB+',
    'AB-',
  ];
  final List<String> _urgencyLevels = ['Routine', 'Urgent', 'Critical'];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    _govIdController.dispose();
    _weightController.dispose();
    _lastDonationController.dispose();
    _hospitalController.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    _resendTimer?.cancel();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_formKeyStep1.currentState!.validate()) {
        if (_passController.text != _confirmPassController.text) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Passwords do not match')),
          );
          return;
        }
        _goToPage(1);
        _startResendTimer();
      }
    } else if (_currentStep == 1) {
      _verifyOTP();
    } else if (_currentStep == 2) {
      if (_selectedRole == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please select a role')));
        return;
      }
      _goToPage(3);
    }
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    _resendSeconds = 30;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds > 0) {
        setState(() => _resendSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  void _verifyOTP() {
    String otp = _otpControllers.map((e) => e.text).join();
    if (otp == '123456') {
      _goToPage(2);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid OTP. Use 123456')));
    }
  }

  void _goToPage(int page) {
    setState(() => _currentStep = page);
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _submitCombined() async {
    if (!_formKeyStep3.currentState!.validate()) return;
    if (_bloodGroup == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select Blood Group')));
      return;
    }

    setState(() => _isLoading = true);

    Map<String, dynamic> details = {
      'govId': _govIdController.text.trim(),
      'bloodGroup': _bloodGroup,
    };

    if (_selectedRole == 'Donor') {
      details['weight'] = _weightController.text.trim();
      details['lastDonation'] = _lastDonationController.text.trim();
    } else {
      details['hospital'] = _hospitalController.text.trim();
      details['urgency'] = _urgencyLevel ?? 'Routine';
    }

    try {
      await _authService.registerWithPhone(
        phone: _phoneController.text.trim(),
        password: _passController.text.trim(),
        fullName: _nameController.text.trim(),
        role: _selectedRole!,
        photo: _image,
        additionalDetails: details,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration / Login Successful!')),
        );

        // Navigate based on role
        if (_selectedRole == 'Donor') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (c) => const DonorHomePage()),
            (route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (c) => const ReceiverHomePage()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = const Color(0xFFAB0202);
    final Color secondary = const Color(0xFF4A0E0E); // Darker tone for gradient

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              // 1. Gradient Header
              Container(
                height: MediaQuery.of(context).size.height * 0.4,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primary, secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: const Align(
                  alignment: Alignment(-1, -0.3),
                  child: Text(
                    'Create Your Account',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // 2. White Card with Steps
              Positioned(
                top: MediaQuery.of(context).size.height * 0.25,
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF9F9F9),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // Progress Indicator (Optional but helpful)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Row(
                          children: List.generate(
                            4,
                            (index) => Expanded(
                              child: Container(
                                height: 4,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      index <= _currentStep
                                          ? primary
                                          : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: PageView(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _buildStep1BasicInfo(),
                            _buildStepOTPVerification(),
                            _buildStep2RoleSelection(),
                            _buildStep3Details(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Back Button (Optional floating or positioned)
              if (_currentStep == 0)
                Positioned(
                  top: 40,
                  left: 10,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep1BasicInfo() {
    final Color primary = const Color(0xFFAB0202);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Form(
        key: _formKeyStep1,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            shape: BoxShape.circle,
                            border: Border.all(color: primary, width: 2),
                            image:
                                _image != null
                                    ? DecorationImage(
                                      image: FileImage(_image!),
                                      fit: BoxFit.cover,
                                    )
                                    : null,
                          ),
                          child:
                              _image == null
                                  ? Icon(Icons.person, size: 50, color: primary)
                                  : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add Profile Photo',
                    style: TextStyle(
                      color: primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            CustomTextField(
              labelText: 'Full Name',
              controller: _nameController,
              isUnderline: false,
              prefixIcon: Icons.person_outline,
              labelColor: Colors.black,
              hintText: 'John Smith',
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 3),
            CustomTextField(
              labelText: 'Phone No',
              controller: _phoneController,
              isUnderline: false,
              prefixIcon: Icons.phone_android,
              labelColor: Colors.black,
              hintText: '1234567890',
              validator: (v) => v!.length < 10 ? 'Invalid input' : null,
            ),
            const SizedBox(height: 3),
            CustomTextField(
              labelText: 'Password',
              controller: _passController,
              obscureText: _obscurePassword,
              isUnderline: false,
              prefixIcon: Icons.lock_outline,
              labelColor: Colors.black,
              hintText: '••••••••',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              validator: (v) => v!.length < 6 ? 'Min 6 chars' : null,
            ),
            const SizedBox(height: 3),
            CustomTextField(
              labelText: 'Confirm Password',
              controller: _confirmPassController,
              obscureText: _obscureConfirmPassword,
              isUnderline: false,
              prefixIcon: Icons.lock_outline,
              labelColor: Colors.black,
              hintText: '••••••••',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 25),
            _primaryButton('Get OTP', _nextStep),
            const SizedBox(height: 15),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Back to Login', style: TextStyle(color: primary)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepOTPVerification() {
    final Color primary = const Color(0xFFAB0202);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Column(
        children: [
          const SizedBox(height: 10),
          const Icon(
            Icons.mark_email_unread_outlined,
            size: 80,
            color: Color.fromARGB(255, 184, 41, 31),
          ),
          const SizedBox(height: 20),
          Text(
            'Enter OTP',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: primary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'We have sent OTP on your number',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              6,
              (index) => SizedBox(
                width: 40,
                height: 50,
                child: TextField(
                  controller: _otpControllers[index],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  decoration: InputDecoration(
                    counterText: "",
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primary),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    fillColor: Colors.red.withValues(alpha: 0.05),
                    filled: true,
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty && index < 5) {
                      FocusScope.of(context).nextFocus();
                    } else if (value.isEmpty && index > 0) {
                      FocusScope.of(context).previousFocus();
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          Text(
            'OTP Auto resend in $_resendSeconds sec',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 30),
          _primaryButton('VERIFY', _nextStep),
          const SizedBox(height: 15),
          TextButton(
            onPressed: () => _goToPage(0),
            child: const Text('Back', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2RoleSelection() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Select Your Role',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),
          _roleCard('Donor', Icons.favorite, Colors.red),
          const SizedBox(height: 20),
          _roleCard('Receiver', Icons.local_hospital, Colors.blue),
          const SizedBox(height: 40),
          _primaryButton('Next', _nextStep),
          const SizedBox(height: 10),
          TextButton(onPressed: () => _goToPage(1), child: const Text('Back')),
        ],
      ),
    );
  }

  Widget _roleCard(String role, IconData icon, Color color) {
    bool isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(width: 20),
            Text(
              role,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const Spacer(),
            if (isSelected) Icon(Icons.check_circle, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3Details() {
    final Color primary = const Color(0xFFAB0202);
    bool isDonor = _selectedRole == 'Donor';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Form(
        key: _formKeyStep3,
        child: Column(
          children: [
            Text(
              'Enter ${isDonor ? 'Donor' : 'Receiver'} Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primary,
              ),
            ),
            const SizedBox(height: 20),

            // Common Fields
            CustomTextField(
              labelText: 'Government ID / Aadhar',
              controller: _govIdController,
              isUnderline: true,
              labelColor: Colors.black,
              hintText: 'Enter your ID',
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            _buildDropdown(
              'Blood Group',
              _bloodGroups,
              _bloodGroup,
              (v) => setState(() => _bloodGroup = v),
            ),
            const SizedBox(height: 15),

            if (isDonor) ...[
              CustomTextField(
                labelText: 'Weight (kg)',
                controller: _weightController,
                isUnderline: true,
                labelColor: Colors.black,
                hintText: 'e.g. 65',
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              CustomTextField(
                labelText: 'Last Date of Donation (Optional)',
                controller: _lastDonationController,
                isUnderline: true,
                labelColor: Colors.black,
                hintText: 'DD/MM/YYYY',
              ),
            ] else ...[
              CustomTextField(
                labelText: 'Hospital Name',
                controller: _hospitalController,
                isUnderline: true,
                labelColor: Colors.black,
                hintText: 'Enter hospital name',
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              _buildDropdown(
                'Urgency Level',
                _urgencyLevels,
                _urgencyLevel,
                (v) => setState(() => _urgencyLevel = v),
              ),
            ],

            const SizedBox(height: 40),
            _isLoading
                ? CircularProgressIndicator(color: primary)
                : _primaryButton('Register & Login', _submitCombined),

            const SizedBox(height: 10),
            TextButton(
              onPressed: () => _goToPage(2),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _primaryButton(String text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 45,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFAB0202),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String hint,
    List<String> items,
    String? value,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint),
          isExpanded: true,
          onChanged: onChanged,
          items:
              items
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
        ),
      ),
    );
  }
}
