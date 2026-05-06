import 'package:flutter/material.dart';
import 'package:blood_c/models/request_model.dart';
import 'package:blood_c/services/request_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:blood_c/pages/chat_page.dart';

class AllRequestsPage extends StatefulWidget {
  const AllRequestsPage({super.key});

  @override
  State<AllRequestsPage> createState() => _AllRequestsPageState();
}

class _AllRequestsPageState extends State<AllRequestsPage> {
  final RequestService _requestService = RequestService();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _lastDonationController = TextEditingController();

  int _donationFormStep = 0;
  bool _hasOperation = false;
  bool _hasInjection = false;
  bool _hadCovid = false;
  bool _isHivPositive = false;

  @override
  void dispose() {
    _ageController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    _phoneController.dispose();
    _lastDonationController.dispose();
    super.dispose();
  }

  void _clearControllers() {
    _ageController.clear();
    _addressController.clear();
    _pincodeController.clear();
    _phoneController.clear();
    _lastDonationController.clear();
    _hasOperation = false;
    _hasInjection = false;
    _hadCovid = false;
    _isHivPositive = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFFAB0202),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'All Requests',
          style: GoogleFonts.poppins(
            color: const Color(0xFF2D2D2D),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<RequestModel>>(
        stream: _requestService.getLiveRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFAB0202)),
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final requests = snapshot.data ?? [];
          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_turned_in_outlined,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No active requests found',
                    style: GoogleFonts.poppins(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return _buildRequestCard(request);
            },
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(RequestModel request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFAB0202).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  request.bloodGroup,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFAB0202),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.hospitalName,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: const Color(0xFF2D2D2D),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Patient: ${request.fullName}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (request.isUrgent)
                const Icon(
                  Icons.emergency_rounded,
                  color: Colors.red,
                  size: 24,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 16,
                color: Colors.grey,
              ),
              const SizedBox(width: 6),
              Text(
                _formatDate(request.timestamp),
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
              ),
              const Spacer(),
              _buildChatButton(request),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _showDonationDialog(context, request),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFAB0202),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                child: Text(
                  'Accept',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatButton(RequestModel request) {
    return GestureDetector(
      onTap: () => _openChat(request.senderId, request.fullName),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFAB0202).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.chat_bubble_outline_rounded,
          size: 20,
          color: Color(0xFFAB0202),
        ),
      ),
    );
  }

  void _openChat(String otherUserId, String otherUserName) {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    List<String> ids = [currentUser.uid, otherUserId];
    ids.sort();
    String chatId = ids.join('_');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ChatPage(
              chatId: chatId,
              recipientName: otherUserName,
              currentUserId: currentUser.uid,
            ),
      ),
    );
  }

  void _showDonationDialog(BuildContext context, RequestModel request) {
    _donationFormStep = 0;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder:
          (context) => StatefulBuilder(
            builder: (context, setModalState) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 24,
                  right: 24,
                  top: 24,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _donationFormStep == 0
                                ? 'Donor Details'
                                : _donationFormStep == 1
                                ? 'Health Verification'
                                : 'Confirm Donation',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Step ${_donationFormStep + 1}/3',
                            style: GoogleFonts.poppins(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _donationFormStep == 0
                            ? 'Confirm your personal and location details.'
                            : _donationFormStep == 1
                            ? 'Safety check to ensure a safe donation.'
                            : 'Review the request and confirm your help.',
                        style: GoogleFonts.poppins(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 25),
                      if (_donationFormStep == 0) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _buildSimpleInput(
                                'Age',
                                'Your age',
                                Icons.person,
                                _ageController,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: _buildSimpleInput(
                                'Phone',
                                'Contact Number',
                                Icons.phone,
                                _phoneController,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        _buildSimpleInput(
                          'Last Donation',
                          'e.g. 4 months ago',
                          Icons.calendar_today,
                          _lastDonationController,
                        ),
                        const SizedBox(height: 15),
                        _buildSimpleInput(
                          'Address',
                          'Detailed Address',
                          Icons.home,
                          _addressController,
                        ),
                        const SizedBox(height: 15),
                        _buildSimpleInput(
                          'Pincode',
                          'Area Code',
                          Icons.map,
                          _pincodeController,
                        ),
                      ] else if (_donationFormStep == 1) ...[
                        _buildSwitchTile(
                          'Recent Operation',
                          'Within last 6 months',
                          _hasOperation,
                          (v) => setModalState(() => _hasOperation = v),
                        ),
                        _buildSwitchTile(
                          'Recent Injections',
                          'Vaccines or medications',
                          _hasInjection,
                          (v) => setModalState(() => _hasInjection = v),
                        ),
                        _buildSwitchTile(
                          'Had COVID-19',
                          'Within last 3 months',
                          _hadCovid,
                          (v) => setModalState(() => _hadCovid = v),
                        ),
                        _buildSwitchTile(
                          'HIV Positive',
                          'Important for verification',
                          _isHivPositive,
                          (v) => setModalState(() => _isHivPositive = v),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0F0),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFFFEAEA)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Requesting Blood Group: ${request.bloodGroup}',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFAB0202),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color: Color(0xFFAB0202),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      request.hospitalName,
                                      style: GoogleFonts.poppins(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Contact info will be shared once you confirm.',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                      const SizedBox(height: 30),
                      Row(
                        children: [
                          if (_donationFormStep > 0)
                            Expanded(
                              child: OutlinedButton(
                                onPressed:
                                    () => setModalState(
                                      () => _donationFormStep--,
                                    ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: Color(0xFFAB0202),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                ),
                                child: Text(
                                  'BACK',
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFFAB0202),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          if (_donationFormStep > 0) const SizedBox(width: 15),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (_donationFormStep < 2) {
                                  if (_donationFormStep == 0) {
                                    if (_ageController.text.isEmpty ||
                                        _phoneController.text.isEmpty ||
                                        _addressController.text.isEmpty) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Please fill all fields',
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                  }
                                  setModalState(() => _donationFormStep++);
                                } else {
                                  if (_isHivPositive) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Safety check failed: Cannot donate if HIV Positive',
                                        ),
                                      ),
                                    );
                                    Navigator.pop(context);
                                    return;
                                  }
                                  await _confirmDonation(context, request);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFAB0202),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                              ),
                              child: Text(
                                _donationFormStep == 2 ? 'CONFIRM' : 'NEXT',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }

  Future<void> _confirmDonation(
    BuildContext context,
    RequestModel request,
  ) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'lastDonationDetails': {
                'age': int.parse(_ageController.text),
                'address': _addressController.text,
                'pincode': _pincodeController.text,
                'timestamp': DateTime.now(),
              },
            });

        await _requestService.acceptRequest(request.id, user.uid);

        if (context.mounted) {
          Navigator.pop(context);
          _clearControllers();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Donation Confirmed!')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _buildSimpleInput(
    String label,
    String hint,
    IconData icon,
    TextEditingController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
              border: InputBorder.none,
              icon: Icon(icon, size: 18, color: const Color(0xFFAB0202)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFFAB0202),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} • ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
