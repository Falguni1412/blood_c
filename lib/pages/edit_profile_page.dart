import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:blood_c/services/auth_service.dart';
import 'package:blood_c/widgets/custom_text_field.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const EditProfilePage({super.key, required this.userData});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _weightController;
  late TextEditingController _govIdController;
  late TextEditingController _addressController;
  late TextEditingController _pincodeController;
  late TextEditingController _medicalConditionsController;
  String? _bloodGroup;
  File? _image;
  bool _isLoading = false;

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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData['fullName']);
    final details = widget.userData['details'] as Map<String, dynamic>? ?? {};
    _weightController = TextEditingController(
      text: details['weight']?.toString(),
    );
    _govIdController = TextEditingController(
      text: details['govId']?.toString(),
    );
    _addressController = TextEditingController(
      text: details['address']?.toString(),
    );
    _pincodeController = TextEditingController(
      text: details['pincode']?.toString(),
    );
    _medicalConditionsController = TextEditingController(
      text: details['medicalConditions']?.toString(),
    );
    _bloodGroup = details['bloodGroup'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _govIdController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    _medicalConditionsController.dispose();
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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final details = Map<String, dynamic>.from(
        widget.userData['details'] ?? {},
      );
      details['weight'] = _weightController.text.trim();
      details['govId'] = _govIdController.text.trim();
      details['address'] = _addressController.text.trim();
      details['pincode'] = _pincodeController.text.trim();
      details['medicalConditions'] = _medicalConditionsController.text.trim();
      details['bloodGroup'] = _bloodGroup;

      await _authService.updateProfile(
        uid: widget.userData['uid'],
        fullName: _nameController.text.trim(),
        photo: _image,
        details: details,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context, true);
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Photo
              Center(
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: primary, width: 3),
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[200],
                        backgroundImage:
                            _image != null
                                ? FileImage(_image!)
                                : (widget.userData['photoUrl'] != null &&
                                    widget.userData['photoUrl'].isNotEmpty)
                                ? NetworkImage(widget.userData['photoUrl'])
                                : const AssetImage(
                                      'assets/images/user_placeholder.jpg',
                                    )
                                    as ImageProvider,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              CustomTextField(
                labelText: 'Full Name',
                controller: _nameController,
                prefixIcon: Icons.person_outline,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 15),

              CustomTextField(
                labelText: 'Government ID',
                controller: _govIdController,
                prefixIcon: Icons.badge_outlined,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      labelText: 'Weight (kg)',
                      controller: _weightController,
                      prefixIcon: Icons.monitor_weight_outlined,
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildDropdown(
                      'Blood Group',
                      _bloodGroups,
                      _bloodGroup,
                      (v) => setState(() => _bloodGroup = v),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              CustomTextField(
                labelText: 'Address (Optional)',
                controller: _addressController,
                prefixIcon: Icons.home_outlined,
              ),
              const SizedBox(height: 15),

              CustomTextField(
                labelText: 'Pincode (Optional)',
                controller: _pincodeController,
                prefixIcon: Icons.pin_drop_outlined,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 15),

              CustomTextField(
                labelText: 'Medical Conditions (Optional)',
                controller: _medicalConditionsController,
                prefixIcon: Icons.medical_services_outlined,
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                  ),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                            'Save Changes',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ),
            ],
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: const TextStyle(fontSize: 12)),
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
