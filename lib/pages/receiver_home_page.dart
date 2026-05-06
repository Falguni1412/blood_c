import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:blood_c/services/auth_service.dart';
import 'package:blood_c/services/request_service.dart';
import 'package:blood_c/models/request_model.dart';
import 'package:blood_c/pages/login_page.dart';
import 'package:blood_c/pages/refer_friend_page.dart';
import 'package:blood_c/pages/privacy_policy_page.dart';
import 'package:blood_c/pages/chat_page.dart';
import 'package:blood_c/pages/language_selection_page.dart';
import 'package:blood_c/pages/search_donors_page.dart';
import 'package:blood_c/pages/emergency_contacts_page.dart';
import 'package:blood_c/pages/all_news_page.dart';
import 'package:blood_c/pages/all_camps_page.dart';
import 'package:blood_c/pages/edit_profile_page.dart';
import 'dart:ui';
import 'package:blood_c/pages/map_view_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class ReceiverHomePage extends StatefulWidget {
  const ReceiverHomePage({super.key});

  @override
  State<ReceiverHomePage> createState() => _ReceiverHomePageState();
}

class _ReceiverHomePageState extends State<ReceiverHomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseScale;
  late Animation<double> _pulseOpacity;
  final AuthService _authService = AuthService();
  final RequestService _requestService = RequestService();
  late PageController _carouselController;
  int _currentCarouselIndex = 0;
  int _selectedIndex = 0;

  final TextEditingController _bloodGroupController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _hospitalController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  int _requestFormStep = 0;
  bool _hasOperation = false;
  bool _hasInjection = false;
  bool _hadCovid = false;
  bool _isHivPositive = false;
  bool _isUrgent = false;
  bool _shareContactDetails = false;

  @override
  void initState() {
    super.initState();
    _carouselController = PageController();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _pulseScale = Tween<double>(
      begin: 1.0,
      end: 1.8,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));

    _pulseOpacity = Tween<double>(
      begin: 0.5,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));

    // Simulated urgent notification
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.emergency, color: Colors.white),
              SizedBox(width: 10),
              Text('URGENT: Donor found nearby!'),
            ],
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'VIEW',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _carouselController.dispose();
    _pulseController.dispose();
    _bloodGroupController.dispose();
    _quantityController.dispose();
    _hospitalController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<DocumentSnapshot> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not logged in");
    return FirebaseFirestore.instance.collection('users').doc(user.uid).get();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _showExitDialog(context);
        if (shouldExit && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 0,
          toolbarHeight: 0,
        ),
        body: FutureBuilder<DocumentSnapshot>(
          future: _fetchUserData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFAB0202)),
              );
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text("User data not found."));
            }

            var userData = snapshot.data!.data() as Map<String, dynamic>;
            // var details = userData['details'] ?? {};
            // String bloodGroup = details['bloodGroup'] ?? 'N/A';
            // String hospital = details['hospital'] ?? 'N/A';
            // String urgency = details['urgency'] ?? 'Routine';
            // String govId = details['govId'] ?? 'N/A';

            return SafeArea(child: _buildCurrentView(userData));
          },
        ),
        floatingActionButton: _selectedIndex == 0 ? _buildSOSButton() : null,
        bottomNavigationBar: _buildBottomNavBar(context),
        extendBody: true,
      ),
    );
  }

  Widget _buildSOSButton() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Pulse Ring
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(
                  0xFFAB0202,
                ).withValues(alpha: _pulseOpacity.value),
              ),
              transform: Matrix4.identity()..scale(_pulseScale.value),
            ),
            // The Button
            GestureDetector(
              onTap: _showQuickSOSDialog,
              child: Container(
                width: 65,
                height: 65,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFAB0202),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.emergency_share, color: Colors.white, size: 24),
                    Text(
                      'SOS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showQuickSOSDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 25),
                const Icon(Icons.emergency, color: Color(0xFFAB0202), size: 50),
                const SizedBox(height: 15),
                Text(
                  'Quick SOS Broadcast',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFAB0202),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'This will alert all donors near you about a Critical Emergency.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 30),
                // Simple Blood Group Selector
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children:
                      ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-']
                          .map(
                            (bg) => GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                                _triggerInstantSOS(bg);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFAB0202,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFAB0202),
                                  ),
                                ),
                                child: Text(
                                  bg,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFAB0202),
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
    );
  }

  Future<void> _triggerInstantSOS(String bloodGroup) async {
    // Show Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const Center(
            child: CircularProgressIndicator(color: Color(0xFFAB0202)),
          ),
    );

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Create a critical request with default hospital from profile if available
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      final userData = snapshot.data() as Map<String, dynamic>;
      final details = userData['details'] as Map<String, dynamic>;

      RequestModel request = RequestModel(
        id: '',
        senderId: user.uid,
        fullName: userData['fullName'] ?? 'Emergency Patient',
        bloodGroup: bloodGroup,
        quantity: '2 Units',
        hospitalName: details['hospital'] ?? 'Emergency Hospital',
        timestamp: DateTime.now(),
        age: userData['age'] ?? 0,
        address: details['address'] ?? 'N/A',
        pincode: details['pincode'] ?? 'N/A',
        phone: userData['mobileNumber'] ?? '',
        hasOperation: details['hasOperation'] ?? false,
        hasInjection: details['hasInjection'] ?? false,
        hadCovid: details['hadCovid'] ?? false,
        isHivPositive: details['isHivPositive'] ?? false,
        isUrgent: true,
        shareContactDetails: true,
        isCritical: true,
      );

      await _requestService.createRequest(request);

      if (mounted) {
        Navigator.pop(context); // Pop loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SOS Broadcast Sent Successfully!'),
            backgroundColor: Color(0xFFAB0202),
          ),
        );
        setState(() => _selectedIndex = 1); // Go to My Requests
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Pop loading
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sending SOS: $e')));
      }
    }
  }

  Future<bool> _showExitDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                content: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    'Are you sure you want to exit?',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      'NO',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFAB0202),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(
                      'YES',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFAB0202),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
        ) ??
        false;
  }

  Widget _buildCurrentView(Map<String, dynamic> userData) {
    String fullName = userData['fullName'] ?? 'User';
    switch (_selectedIndex) {
      case 0:
        return _buildHomeView(fullName);
      case 1:
        return _buildMyRequestsView();
      case 2:
        return _buildChatView();
      case 3:
        return _buildProfilePlaceholder(userData);
      default:
        return _buildHomeView(fullName);
    }
  }

  Widget _buildHomeView(String fullName) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(fullName, context),
          const SizedBox(height: 25),
          _buildSearchBar(context),
          const SizedBox(height: 25),
          _buildLiveStatsCard(),
          const SizedBox(height: 30),
          _buildRequestSection(context),
          const SizedBox(height: 30),
          _buildSectionTitle('Active Donors Map', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => const MapViewPage()),
            );
          }),
          const SizedBox(height: 15),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const MapViewPage()),
              );
            },
            child: _buildMapPreview(),
          ),
          const SizedBox(height: 30),
          _buildSectionTitle('Safety Guidelines', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => const AllNewsPage()),
            );
          }),
          const SizedBox(height: 15),
          _buildHeroCarousel(),
          const SizedBox(height: 30),
          _buildSectionTitle('Quick Actions'),
          const SizedBox(height: 15),
          _buildActionGrid(context),
          const SizedBox(height: 30),
          _buildSectionTitle('Ongoing Camps', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => const AllCampsPage()),
            );
          }),
          const SizedBox(height: 15),
          _buildCampsSection(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildMyRequestsView() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Please login"));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 24, right: 24, top: 20),
          child: Text(
            'My Requests',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D2D2D),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<RequestModel>>(
            stream: _requestService.getMyRequests(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }
              final requests = snapshot.data ?? [];
              if (requests.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.post_add_rounded,
                        size: 80,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 15),
                      Text(
                        'No requests yet',
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
                padding: const EdgeInsets.all(24),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  return _buildRequestCard(requests[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRequestCard(RequestModel request) {
    bool isAccepted = request.status == 'accepted';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFAB0202).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.bloodtype,
                  color: Color(0xFFAB0202),
                  size: 30,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Request for ${request.bloodGroup}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      request.hospitalName,
                      style: GoogleFonts.poppins(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color:
                      isAccepted
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  request.status.toUpperCase(),
                  style: GoogleFonts.poppins(
                    color: isAccepted ? Colors.green : Colors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Divider(),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Created on ${_formatDate(request.timestamp)}',
                style: GoogleFonts.poppins(color: Colors.grey, fontSize: 11),
              ),
              if (!isAccepted)
                TextButton.icon(
                  onPressed: () => _confirmDelete(request.id),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  void _confirmDelete(String requestId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Cancel Request?',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Are you sure you want to remove this request?',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('NO', style: GoogleFonts.poppins()),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _requestService.deleteRequest(requestId);
                },
                child: Text(
                  'YES, CANCEL',
                  style: GoogleFonts.poppins(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildChatView() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Please login"));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Messages',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D2D2D),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('chats')
                    .where('participants', arrayContains: user.uid)
                    .orderBy('lastTimestamp', descending: true)
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 15),
                      Text(
                        'No active conversations',
                        style: GoogleFonts.poppins(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var chat = snapshot.data!.docs[index];
                  var data = chat.data() as Map<String, dynamic>;
                  String otherUserId = (data['participants'] as List)
                      .firstWhere((id) => id != user.uid);

                  return FutureBuilder<DocumentSnapshot>(
                    future:
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(otherUserId)
                            .get(),
                    builder: (context, userSnapshot) {
                      String name = 'User';
                      if (userSnapshot.hasData) {
                        name =
                            (userSnapshot.data!.data()
                                as Map<String, dynamic>?)?['fullName'] ??
                            'User';
                      }

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(
                            0xFFAB0202,
                          ).withValues(alpha: 0.1),
                          child: Text(
                            name[0].toUpperCase(),
                            style: const TextStyle(color: Color(0xFFAB0202)),
                          ),
                        ),
                        title: Text(
                          name,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          data['lastMessage'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.chevron_right, size: 20),
                        onTap: () => _openChat(otherUserId, name),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _openChat(String otherUserId, String otherUserName) {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    List<String> ids = [user.uid, otherUserId];
    ids.sort();
    String chatId = ids.join('_');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (c) => ChatPage(
              chatId: chatId,
              recipientName: otherUserName,
              currentUserId: user.uid,
            ),
      ),
    );
  }

  Widget _buildProfilePlaceholder(Map<String, dynamic> userData) {
    String name = userData['fullName'] ?? 'User';
    String photoUrl = userData['photoUrl'] ?? '';
    Map<String, dynamic> details = userData['details'] ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Center(
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFAB0202),
                      width: 3,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage:
                        photoUrl.isNotEmpty
                            ? NetworkImage(photoUrl)
                            : const AssetImage(
                                  'assets/images/user_placeholder.jpg',
                                )
                                as ImageProvider,
                    backgroundColor: const Color(0xFFF1F1F1),
                  ),
                ),
                Positioned(
                  bottom: 5,
                  right: 5,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFAB0202),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D2D2D),
            ),
          ),
          Text(
            'Blood Receiver',
            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 30),

          // User Info Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFAB0202),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFAB0202).withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem(
                  'Blood',
                  details['bloodGroup'] ?? 'N/A',
                  Icons.bloodtype,
                ),
                Container(width: 1, height: 40, color: Colors.white24),
                _buildInfoItem(
                  'Urgency',
                  details['urgency'] ?? 'Routine',
                  Icons.emergency,
                ),
                Container(width: 1, height: 40, color: Colors.white24),
                _buildInfoItem('Verified', 'YES', Icons.verified_user),
              ],
            ),
          ),

          const SizedBox(height: 40),
          _buildProfileItem(
            Icons.local_hospital_outlined,
            details['hospital'] ?? 'No Hospital',
            () {},
          ),
          _buildProfileItem(Icons.person_outline, 'Edit Profile', () {
            userData['uid'] = FirebaseAuth.instance.currentUser?.uid;
            Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => EditProfilePage(userData: userData)),
            ).then((_) {
              if (mounted) setState(() {});
            });
          }),
          _buildProfileItem(Icons.history, 'My Activity', () {
            setState(() => _selectedIndex = 1);
          }),
          _buildProfileItem(Icons.settings_outlined, 'Settings', () {}),
          _buildProfileItem(Icons.policy_outlined, 'Privacy Policy', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => const PrivacyPolicyPage()),
            );
          }),
          _buildProfileItem(Icons.language_rounded, 'Choose Language', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => const LanguageSelectionPage()),
            );
          }),
          _buildProfileItem(Icons.security_rounded, 'Emergency Support', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => const EmergencyContactsPage()),
            );
          }),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 20),
          _buildProfileItem(Icons.logout_rounded, 'Logout', () async {
            await _authService.signOut();
            if (!mounted) return;
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (c) => const LoginPage()),
              (r) => false,
            );
          }, isLogout: true),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildProfileItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isLogout = false,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color:
              isLogout
                  ? Colors.red.withValues(alpha: 0.1)
                  : const Color(0xFFAB0202).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isLogout ? Colors.red : const Color(0xFFAB0202),
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isLogout ? Colors.red : const Color(0xFF2D2D2D),
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: () {
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (c) => SearchDonorsPage(currentUserId: user.uid),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0F0),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFFE5E5)),
        ),
        child: AbsorbPointer(
          child: TextField(
            style: GoogleFonts.poppins(color: Colors.black87),
            decoration: InputDecoration(
              hintText: 'Find Blood Groups or Donors...',
              hintStyle: GoogleFonts.poppins(color: const Color(0xFFBDBDBD)),
              prefixIcon: const Padding(
                padding: EdgeInsets.all(12.0),
                child: Icon(
                  Icons.search_rounded,
                  color: Color(0xFFAB0202),
                  size: 28,
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLiveStatsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFEEEE)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            '2.4k',
            'Total Donors',
            Icons.people_alt_rounded,
            Colors.blue,
          ),
          Container(width: 1, height: 40, color: Colors.grey.shade200),
          _buildStatItem(
            '350',
            'Requests Met',
            Icons.check_circle_rounded,
            Colors.green,
          ),
          Container(width: 1, height: 40, color: Colors.grey.shade200),
          _buildStatItem(
            '8',
            'Active Vans',
            Icons.local_shipping_rounded,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String val, String label, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              val,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D2D2D),
              ),
            ),
          ],
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(String name, BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFAB0202), width: 2),
          ),
          child: const CircleAvatar(
            radius: 22,
            backgroundImage: AssetImage('assets/images/user_placeholder.jpg'),
            backgroundColor: Color(0xFFF1F1F1),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, $name',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D2D2D),
              ),
            ),
            Text(
              'Looking for blood?',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF9E9E9E),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const Spacer(),
        GestureDetector(
          onTap: () async {
            await _authService.signOut();
            if (context.mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (c) => const LoginPage()),
                (r) => false,
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F0),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFEAEA)),
            ),
            child: const Icon(
              Icons.logout_rounded,
              color: Color(0xFFAB0202),
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequestSection(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFAB0202),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFAB0202).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.add_circle, color: Colors.white, size: 30),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Need Blood Urgently?',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Click to create a new request',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showRequestSheet(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFAB0202),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
              ),
              child: Text(
                'REQUEST BLOOD',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRequestSheet(BuildContext context) {
    _requestFormStep = 0; // Reset step
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
                            _requestFormStep == 0
                                ? 'Basic Information'
                                : _requestFormStep == 1
                                ? 'Health Verification'
                                : 'Privacy & Confirm',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Step ${_requestFormStep + 1}/3',
                            style: GoogleFonts.poppins(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _requestFormStep == 0
                            ? 'Tell us what you need and where.'
                            : _requestFormStep == 1
                            ? 'For safety, please answer honestly.'
                            : 'Review and set your privacy.',
                        style: GoogleFonts.poppins(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 25),
                      if (_requestFormStep == 0) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _buildSimpleInput(
                                'Blood Group',
                                'e.g. O+',
                                Icons.bloodtype,
                                _bloodGroupController,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: _buildSimpleInput(
                                'Quantity',
                                'e.g. 2 Units',
                                Icons.water_drop,
                                _quantityController,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        _buildSimpleInput(
                          'Hospital Name',
                          'Enter hospital location',
                          Icons.local_hospital,
                          _hospitalController,
                        ),
                        const SizedBox(height: 15),
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
                        Row(
                          children: [
                            Expanded(
                              child: _buildSimpleInput(
                                'Address',
                                'Detailed Address',
                                Icons.home,
                                _addressController,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: _buildSimpleInput(
                                'Pincode',
                                'Area Code',
                                Icons.map,
                                _pincodeController,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        _buildSwitchTile(
                          'Urgent Request',
                          'Priority matching',
                          _isUrgent,
                          (v) => setModalState(() => _isUrgent = v),
                        ),
                      ] else if (_requestFormStep == 1) ...[
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
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F8FF),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.privacy_tip,
                                color: Color(0xFF0056D2),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Text(
                                  'Your health details (HIV, COVID, etc.) are only used for verification and will never be shared publicly.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: const Color(0xFF0056D2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildSwitchTile(
                          'Share Contact Details',
                          'Reveal name/phone to donors on accept',
                          _shareContactDetails,
                          (v) => setModalState(() => _shareContactDetails = v),
                        ),
                      ],
                      const SizedBox(height: 30),
                      Row(
                        children: [
                          if (_requestFormStep > 0)
                            Expanded(
                              child: OutlinedButton(
                                onPressed:
                                    () =>
                                        setModalState(() => _requestFormStep--),
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
                          if (_requestFormStep > 0) const SizedBox(width: 15),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (_requestFormStep < 2) {
                                  if (_requestFormStep == 0) {
                                    if (_bloodGroupController.text.isEmpty ||
                                        _quantityController.text.isEmpty ||
                                        _ageController.text.isEmpty ||
                                        _phoneController.text.isEmpty) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Please fill basic fields',
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    int? age = int.tryParse(
                                      _ageController.text,
                                    );
                                    if (age == null || age < 18) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Must be 18+ to request',
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                  }
                                  setModalState(() => _requestFormStep++);
                                } else {
                                  if (_isHivPositive) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Safety check failed: HIV Positive',
                                        ),
                                      ),
                                    );
                                    Navigator.pop(context);
                                    return;
                                  }
                                  await _submitRequest(context);
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
                                _requestFormStep == 2 ? 'SUBMIT' : 'NEXT',
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

  Future<void> _submitRequest(BuildContext context) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        var userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
        String fullName = userDoc.data()?['fullName'] ?? 'Receiver';

        final newRequest = RequestModel(
          id: '',
          senderId: user.uid,
          fullName: fullName,
          bloodGroup: _bloodGroupController.text,
          quantity: _quantityController.text,
          hospitalName: _hospitalController.text,
          timestamp: DateTime.now(),
          age: int.parse(_ageController.text),
          address: _addressController.text,
          pincode: _pincodeController.text,
          phone: _phoneController.text,
          hasOperation: _hasOperation,
          hasInjection: _hasInjection,
          hadCovid: _hadCovid,
          isHivPositive: _isHivPositive,
          isUrgent: _isUrgent,
          shareContactDetails: _shareContactDetails,
        );

        await _requestService.createRequest(newRequest);

        if (context.mounted) {
          Navigator.pop(context);
          _clearControllers();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Request Published! Finding donors...'),
            ),
          );
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

  void _clearControllers() {
    _bloodGroupController.clear();
    _quantityController.clear();
    _hospitalController.clear();
    _ageController.clear();
    _addressController.clear();
    _pincodeController.clear();
    _phoneController.clear();
    _hasOperation = false;
    _hasInjection = false;
    _hadCovid = false;
    _isHivPositive = false;
    _isUrgent = false;
    _shareContactDetails = false;
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

  Widget _buildSectionTitle(String title, [VoidCallback? onSeeAll]) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D2D2D),
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: Text(
              'See All',
              style: GoogleFonts.poppins(
                color: const Color(0xFFAB0202),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMapPreview() {
    return Container(
      height: 180,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Stack(
        children: [
          FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(19.0760, 72.8777),
              initialZoom: 12.0,
              interactionOptions: InteractionOptions(
                flags: InteractiveFlag.none,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.blood.app',
              ),
            ],
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
              child: Container(color: Colors.transparent),
            ),
          ),
          const Center(
            child: Icon(Icons.location_on, size: 50, color: Color(0xFFAB0202)),
          ),
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                'Find Donors',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFAB0202),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    final actions = [
      {
        'title': 'Find Donors',
        'icon': Icons.search_rounded,
        'color': const Color(0xFFF1F8FF),
        'iconColor': const Color(0xFF42A5F5),
        'action': (BuildContext context) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => const MapViewPage()),
          );
        },
      },
      {
        'title': 'My Requests',
        'icon': Icons.list_alt_rounded,
        'color': const Color(0xFFFFF5EF),
        'iconColor': const Color(0xFFFF8965),
        'action': (BuildContext context) => setState(() => _selectedIndex = 1),
      },
      {
        'title': 'Refer Friend',
        'icon': Icons.share_rounded,
        'color': const Color(0xFFE8F5E9),
        'iconColor': const Color(0xFF4CAF50),
        'action':
            (BuildContext context) => Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => const ReferFriendPage()),
            ),
      },
      {
        'title': 'Safety Support',
        'icon': Icons.security_rounded,
        'color': const Color(0xFFFFF0F0),
        'iconColor': const Color(0xFFAB0202),
        'action':
            (BuildContext context) => Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => const EmergencyContactsPage()),
            ),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.55,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final item = actions[index];
        final iconColor = item['iconColor'] as Color;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: iconColor.withValues(alpha: 0.08),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () {
                if (item.containsKey('action')) {
                  (item['action'] as Function(BuildContext))(context);
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: (item['color'] as Color),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        item['icon'] as IconData,
                        color: iconColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item['title'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2D2D2D),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroCarousel() {
    final news = [
      {
        'title': 'Emergency Preparedness Guide',
        'desc': 'Essential steps to take during a medical emergency.',
        'color': const Color(0xFFF1F8FF),
      },
      {
        'title': 'How to Handle Donor Coordination',
        'desc': 'Learn how to efficiently manage donors for your hospital.',
        'color': const Color(0xFFFFF5EF),
      },
    ];

    // Assuming _carouselController and _currentCarouselIndex are defined in the State class
    // For example:
    // final PageController _carouselController = PageController();
    // int _currentCarouselIndex = 0;

    return Column(
      children: [
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: _carouselController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _currentCarouselIndex = index;
              });
            },
            itemCount: news.length,
            itemBuilder: (context, index) {
              final item = news[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (c) => const AllNewsPage()),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: item['color'] as Color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2D2D2D),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item['desc'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            news.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 4,
              width:
                  _currentCarouselIndex == index
                      ? 15
                      : 4, // Uncomment if _currentCarouselIndex is available
              decoration: BoxDecoration(
                color:
                    _currentCarouselIndex == index
                        ? const Color(0xFFAB0202)
                        : Colors
                            .grey
                            .shade300, // Uncomment if _currentCarouselIndex is available
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCampsSection() {
    final camps = [
      {'name': 'Regional Blood Center', 'location': 'Central Plaza'},
    ];
    return Column(
      children:
          camps.map((camp) {
            return Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFFFFF0F0),
                    child: Icon(Icons.location_on, color: Color(0xFFAB0202)),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          camp['name']!,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          camp['location']!,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Join',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFAB0202),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 24, right: 24, bottom: 30),
      height: 75,
      decoration: BoxDecoration(
        color: const Color(0xFFAB0202),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFAB0202).withValues(alpha: 0.5),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.home_rounded, 'Home', 0),
          _buildNavItem(Icons.list_alt_rounded, 'Requests', 1),
          _buildNavItem(Icons.chat_bubble_rounded, 'Chat', 2),
          _buildNavItem(Icons.person_rounded, 'Profile', 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 18 : 12,
          vertical: 10,
        ),
        decoration:
            isSelected
                ? BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                )
                : null,
        child: Row(
          children: [
            Icon(
              icon,
              color:
                  isSelected
                      ? const Color(0xFFAB0202)
                      : Colors.white.withValues(alpha: 0.8),
              size: 26,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: const Color(0xFFAB0202),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
