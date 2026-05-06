import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:blood_c/services/auth_service.dart';
import 'package:blood_c/services/request_service.dart';
import 'package:blood_c/models/request_model.dart';
import 'package:blood_c/pages/login_page.dart';
import 'package:blood_c/pages/refer_friend_page.dart';
import 'package:blood_c/pages/privacy_policy_page.dart';
import 'package:blood_c/pages/blood_bank_page.dart';
import 'package:blood_c/pages/chat_page.dart';
import 'package:blood_c/pages/language_selection_page.dart';
import 'package:blood_c/pages/emergency_contacts_page.dart';
import 'package:blood_c/pages/all_requests_page.dart';
import 'package:blood_c/pages/all_camps_page.dart';
import 'package:blood_c/pages/all_news_page.dart';
import 'package:blood_c/pages/stats_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:blood_c/pages/map_view_page.dart';
import 'package:blood_c/services/language_service.dart';
import 'dart:ui';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:blood_c/pages/edit_profile_page.dart';

class DonorHomePage extends StatefulWidget {
  const DonorHomePage({super.key});

  @override
  State<DonorHomePage> createState() => _DonorHomePageState();
}

class _DonorHomePageState extends State<DonorHomePage> {
  final AuthService _authService = AuthService();
  final RequestService _requestService = RequestService();
  int _selectedIndex = 0;
  String _selectedBloodGroup = 'All';
  late PageController _carouselController;
  int _currentCarouselIndex = 0;

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
  void initState() {
    super.initState();
    _carouselController = PageController();
  }

  @override
  void dispose() {
    _carouselController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    _phoneController.dispose();
    _lastDonationController.dispose();
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

            Map<String, dynamic> userData = {};
            if (snapshot.hasData && snapshot.data!.exists) {
              userData = snapshot.data!.data() as Map<String, dynamic>;
            }

            return SafeArea(child: _buildCurrentView(userData));
          },
        ),
        bottomNavigationBar: _buildBottomNavBar(context),
        extendBody: true,
      ),
    );
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
    switch (_selectedIndex) {
      case 0:
        return _buildHomeView(userData);
      case 1:
        return _buildDonationHistoryView();
      case 2:
        return _buildChatView();
      case 3:
        return _buildProfilePlaceholder(userData);
      default:
        return _buildHomeView(userData);
    }
  }

  Widget _buildHomeView(Map<String, dynamic> userData) {
    String fullName = userData['fullName'] ?? 'User';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(fullName, context),
          const SizedBox(height: 20),

          _buildSearchBar(),
          const SizedBox(height: 25),
          _buildLiveStatsCard(),
          const SizedBox(height: 30),
          _buildSectionTitle(
            LanguageService().translate('emergency_requests'),
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const AllRequestsPage()),
              );
            },
          ),
          const SizedBox(height: 15),
          _buildEmergencyRequests(),
          const SizedBox(height: 30),
          _buildSectionTitle('Nearby Blood Banks', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => const BloodBankPage()),
            );
          }),
          const SizedBox(height: 15),
          GestureDetector(onTap: _openMapPage, child: _buildMapPreview()),
          const SizedBox(height: 30),
          _buildSectionTitle('Highlights', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => const AllNewsPage()),
            );
          }),
          const SizedBox(height: 15),
          _buildHeroCarousel(),
          const SizedBox(height: 30),
          _buildSectionTitle('Blood Group', () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Showing requests for $_selectedBloodGroup'),
                duration: const Duration(seconds: 1),
              ),
            );
          }),
          const SizedBox(height: 15),
          _buildBloodGroupList(),
          const SizedBox(height: 30),
          _buildSectionTitle(LanguageService().translate('activity'), () {
            setState(() => _selectedIndex = 1); // Navigate to My Donations
          }),
          const SizedBox(height: 15),
          _buildActivityGrid(),
          const SizedBox(height: 30),
          _buildSectionTitle('Upcoming Camps', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => const AllCampsPage()),
            );
          }),
          const SizedBox(height: 15),
          _buildCampsSection(),
          const SizedBox(height: 30),
          _buildSectionTitle('Our Contribution', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => const StatsPage()),
            );
          }),
          const SizedBox(height: 15),
          _buildContributionSection(),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildDonationHistoryView() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Please login"));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 24, right: 24, top: 20),
          child: Text(
            'My Donations',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D2D2D),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<RequestModel>>(
            stream: _requestService.getDonationHistory(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }
              final donations = snapshot.data ?? [];
              if (donations.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 80,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 15),
                      Text(
                        'No donations found',
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
                itemCount: donations.length,
                itemBuilder: (context, index) {
                  return _buildHistoryCard(donations[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(RequestModel request) {
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
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 30,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Donated ${request.bloodGroup}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  request.hospitalName,
                  style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  'On ${_formatDate(request.timestamp)}',
                  style: GoogleFonts.poppins(
                    color: Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'SUCCESS',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _showCertificate(request),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFAB0202).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.workspace_premium,
                    color: Color(0xFFAB0202),
                    size: 20,
                  ),
                ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Blood Donor',
                style: GoogleFonts.poppins(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              _buildHeroBadge(details['rank'] ?? 0),
            ],
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
                  'Weight',
                  details['weight'] != null ? "${details['weight']} kg" : 'N/A',
                  Icons.monitor_weight_outlined,
                ),
                Container(width: 1, height: 40, color: Colors.white24),
                _buildInfoItem('Verified', 'YES', Icons.verified_user),
              ],
            ),
          ),

          const SizedBox(height: 40),
          _buildProfileItem(Icons.bloodtype_outlined, '1', () {}),
          _buildProfileItem(
            Icons.person_outline,
            LanguageService().translate('edit_profile'),
            () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) => EditProfilePage(userData: userData),
                ),
              );
              if (result == true) {
                setState(() {}); // Refresh data
              }
            },
          ),
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
          _buildProfileItem(
            Icons.language_rounded,
            LanguageService().translate('select_language'),
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) => const LanguageSelectionPage(),
                ),
              );
            },
          ),
          _buildProfileItem(Icons.security_rounded, 'Emergency Support', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => const EmergencyContactsPage()),
            );
          }),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 20),
          _buildProfileItem(
            Icons.logout_rounded,
            LanguageService().translate('logout'),
            () async {
              await _authService.signOut();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (c) => const LoginPage()),
                (r) => false,
              );
            },
            isLogout: true,
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBadge(int donationCount) {
    String rank = 'Blood Buddy';
    Color color = Colors.brown;
    IconData icon = Icons.star_border;

    if (donationCount >= 10) {
      rank = 'Guardian Angel';
      color = Colors.amber.shade700;
      icon = Icons.auto_awesome;
    } else if (donationCount >= 5) {
      rank = 'Blood Hero';
      color = const Color(0xFFFFD700);
      icon = Icons.military_tech;
    } else if (donationCount >= 3) {
      rank = 'Life Saver';
      color = Colors.grey.shade400;
      icon = Icons.favorite;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            rank,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
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

  Widget _buildHeader(String name, BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFAB0202), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFAB0202).withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
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
              'Ready to save lives?',
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
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () {
            // Notification action
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFAB0202),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFAB0202).withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFE5E5)),
      ),
      child: TextField(
        onSubmitted: (val) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Searching for "$val"...'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFFAB0202),
            ),
          );
        },
        style: GoogleFonts.poppins(color: Colors.black87),
        decoration: InputDecoration(
          hintText: 'Search Blood Group or Location...',
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
            '120',
            'Donors Online',
            Icons.online_prediction,
            Colors.green,
          ),
          Container(width: 1, height: 40, color: Colors.grey.shade200),
          _buildStatItem('45', 'Urgent Needs', Icons.emergency, Colors.red),
          Container(width: 1, height: 40, color: Colors.grey.shade200),
          _buildStatItem(
            '12',
            'Camps Today',
            Icons.festival_rounded,
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

  Widget _buildSectionTitle(String title, VoidCallback onSeeAll) {
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
        TextButton(
          onPressed: onSeeAll,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(50, 30),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
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

  Widget _buildBloodGroupList() {
    final bloodGroups = [
      'All',
      'A+',
      'A-',
      'B+',
      'B-',
      'AB+',
      'AB-',
      'O+',
      'O-',
    ];
    return SizedBox(
      height: 65,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: bloodGroups.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          bool isSelected = _selectedBloodGroup == bloodGroups[index];
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedBloodGroup = bloodGroups[index];
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFFAB0202) : Colors.white,
                border: Border.all(
                  color:
                      isSelected
                          ? const Color(0xFFAB0202)
                          : const Color(0xFFEEEEEE),
                  width: 2,
                ),
                boxShadow:
                    isSelected
                        ? [
                          BoxShadow(
                            color: const Color(
                              0xFFAB0202,
                            ).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                        : [],
              ),
              child: Center(
                child: Text(
                  bloodGroups[index],
                  style: GoogleFonts.poppins(
                    color: isSelected ? Colors.white : const Color(0xFFAB0202),
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActivityGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('blood_requests')
              .where('status', isEqualTo: 'pending')
              .snapshots(),
      builder: (context, requestsSnapshot) {
        final pendingCount =
            requestsSnapshot.hasData ? requestsSnapshot.data!.docs.length : 0;

        return StreamBuilder<List<RequestModel>>(
          stream: _requestService.getDonationHistory(
            FirebaseAuth.instance.currentUser?.uid ?? '',
          ),
          builder: (context, donationsSnapshot) {
            final donationCount =
                donationsSnapshot.hasData ? donationsSnapshot.data!.length : 0;

            final activities = [
              {
                'title': LanguageService().translate('available'),
                'subtitle': '$pendingCount Requests',
                'icon': Icons.bloodtype,
                'color': const Color(0xFFFFF5EF),
                'iconColor': const Color(0xFFFF8A65),
                'action':
                    (BuildContext context) => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) => const AllRequestsPage(),
                      ),
                    ),
              },
              {
                'title': LanguageService().translate('create_post'),
                'subtitle': 'Need Blood?',
                'icon': Icons.add_rounded,
                'color': const Color(0xFFF1F8FF),
                'iconColor': const Color(0xFF42A5F5),
                'action': (BuildContext context) => _showQuickSOSDialog(),
              },
              {
                'title': LanguageService().translate('blood_given'),
                'subtitle': '$donationCount Times',
                'icon': Icons.water_drop_rounded,
                'color': const Color(0xFFFFF0F0),
                'iconColor': const Color(0xFFAB0202),
                'action': (BuildContext context) {
                  setState(
                    () => _selectedIndex = 1,
                  ); // Navigate to My Donations
                },
              },
              {
                'title': LanguageService().translate('refer_friend'),
                'subtitle': 'Earn points',
                'icon': Icons.share_rounded,
                'color': const Color(0xFFE8F5E9),
                'iconColor': const Color(0xFF4CAF50),
                'action':
                    (BuildContext context) => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) => const ReferFriendPage(),
                      ),
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
                childAspectRatio: 1.45,
              ),
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final item = activities[index];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (item['iconColor'] as Color).withValues(
                          alpha: 0.1,
                        ),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        if (item.containsKey('action')) {
                          (item['action'] as Function(BuildContext))(context);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: item['color'] as Color,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                item['icon'] as IconData,
                                color: item['iconColor'] as Color,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    item['title'] as String,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF2D2D2D),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item['subtitle'] as String,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: const Color(0xFF9E9E9E),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
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
          },
        );
      },
    );
  }

  Widget _buildContributionSection() {
    final contributions = [
      {'count': '5K+', 'label': 'Blood Donor'},
      {'count': '50', 'label': 'Post Daily'},
      {'count': '50', 'label': 'Join Daily'},
      {'count': '120', 'label': 'Camps'},
    ];

    return SizedBox(
      height: 105,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: contributions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final item = contributions[index];
          return Container(
            width: 120,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(
                0xFFFFF6F1,
              ), // Specific Peach color from design
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFFFE0D0)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item['count']!,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFAB0202),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item['label']!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6D6D6D),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmergencyRequests() {
    return StreamBuilder<List<RequestModel>>(
      stream: _requestService.getLiveRequests(bloodGroup: _selectedBloodGroup),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        final requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Center(
              child: Text(
                'No urgent requests at the moment.',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
          );
        }

        return SizedBox(
          height: 155,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: requests.length,
            separatorBuilder: (context, index) => const SizedBox(width: 15),
            itemBuilder: (context, index) {
              final request = requests[index];
              return Container(
                width: MediaQuery.of(context).size.width - 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFAB0202),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFAB0202).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            request.bloodGroup,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.emergency_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Patient (${request.bloodGroup})',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      request.hospitalName,
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.white70,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            request.hospitalName,
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap:
                              () =>
                                  _openChat(request.senderId, request.fullName),
                          child: _buildSmallActionButton(
                            'Chat',
                            const Color(0xFFAB0202),
                            Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _showDonationDialog(context, request),
                          child: _buildSmallActionButton(
                            'Accept',
                            Colors.white,
                            const Color(0xFFAB0202),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showDonationDialog(BuildContext context, RequestModel request) {
    _donationFormStep = 0; // Reset step
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
                              const SizedBox(height: 10),
                              Text(
                                request.shareContactDetails
                                    ? 'Requester has opted to share contact details upon your acceptance.'
                                    : 'Requester prefers to keep contact details private. You can connect via the hospital.',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.grey.shade700,
                                  fontStyle: FontStyle.italic,
                                ),
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
                                    int? age = int.tryParse(
                                      _ageController.text,
                                    );
                                    if (age == null || age < 18 || age > 65) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Age must be between 18 and 65',
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
      // Save donor verification info to their profile (simulated)
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
                'hasOperation': _hasOperation,
                'hasInjection': _hasInjection,
                'hadCovid': _hadCovid,
                'isHivPositive': _isHivPositive,
                'timestamp': DateTime.now(),
              },
            });

        await _requestService.acceptRequest(request.id, user.uid);

        if (context.mounted) {
          Navigator.pop(context);
          _clearControllers();

          String message = 'Donation Confirmed!';
          if (request.shareContactDetails) {
            message +=
                '\nPatient: ${request.fullName}\nPhone: ${request.phone}';
          } else {
            message += '\nRequester prefers privacy. Contact via hospital.';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              duration: const Duration(seconds: 10),
              action: SnackBarAction(label: 'OK', onPressed: () {}),
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

  Widget _buildSmallActionButton(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: textColor,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
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
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.location_on,
                  size: 40,
                  color: Color(0xFFAB0202),
                ),
                const SizedBox(height: 10),
                Text(
                  'Locate Blood Banks',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D2D2D),
                  ),
                ),
                Text(
                  'Find nearest centers on map',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFAB0202),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFAB0202).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Open Map',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCarousel() {
    final news = [
      {
        'title': 'The Power of Giving: Why Your Blood Matters',
        'desc':
            'One donation can save up to three lives. Join our community today.',
        'color': const Color(0xFFFDE8E8),
      },
      {
        'title': 'New Safety Protocols for COVID-24',
        'desc':
            'Ensuring donor safety is our top priority. Read the latest guidelines.',
        'color': const Color(0xFFE8F4FD),
      },
      {
        'title': 'Mega Donation Drive in Navi Mumbai',
        'desc': 'Join us this Sunday at Central Mall for a cause.',
        'color': const Color(0xFFF1FDE8),
      },
    ];

    return Column(
      children: [
        SizedBox(
          height: 150,
          child: PageView.builder(
            controller: _carouselController,
            onPageChanged: (index) {
              setState(() {
                _currentCarouselIndex = index;
              });
            },
            itemCount: news.length,
            itemBuilder: (context, index) {
              final item = news[index];
              return AnimatedBuilder(
                animation: _carouselController,
                builder: (context, child) {
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
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item['title'] as String,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF2D2D2D),
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 18,
                                color: Color(0xFFAB0202),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
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
              );
            },
          ),
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            news.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 6,
              width: _currentCarouselIndex == index ? 20 : 6,
              decoration: BoxDecoration(
                color:
                    _currentCarouselIndex == index
                        ? const Color(0xFFAB0202)
                        : Colors.grey.shade300,
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
      {'name': 'Goregaon Camp', 'date': '25 Jan', 'time': '10:00 AM'},
      {'name': 'City Square Drive', 'date': '02 Feb', 'time': '09:00 AM'},
    ];
    return Column(
      children:
          camps.map((camp) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => const AllCampsPage()),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7F7),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFFFEAEA)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFAB0202).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          camp['date']!.split(' ')[0],
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFAB0202),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
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
                            '${camp['date']} • ${camp['time']}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: Color(0xFFAB0202),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }

  Future<void> _openMapPage() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (c) => const MapViewPage()),
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
          _buildNavItem(
            Icons.home_rounded,
            LanguageService().translate('home'),
            0,
          ),
          _buildNavItem(
            Icons.favorite_rounded,
            LanguageService().translate('donate'),
            1,
          ),
          _buildNavItem(
            Icons.chat_bubble_rounded,
            LanguageService().translate('chat'),
            2,
          ),
          _buildNavItem(
            Icons.person_rounded,
            LanguageService().translate('profile'),
            3,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    int index, {
    VoidCallback? onTap,
  }) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          onTap();
        } else {
          setState(() {
            _selectedIndex = index;
          });
        }
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

  void _showCertificate(RequestModel request) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, const Color(0xFFFFF0F0)],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.workspace_premium,
                    color: Color(0xFFAB0202),
                    size: 60,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'CERTIFICATE OF APPRECIATION',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.oswald(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFAB0202),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Divider(color: Color(0xFFAB0202), thickness: 2),
                  const SizedBox(height: 20),
                  Text(
                    'This is to certify that',
                    style: GoogleFonts.poppins(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    request.fullName.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'has heroically donated ${request.bloodGroup} blood',
                    style: GoogleFonts.poppins(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'at ${request.hospitalName}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          Text(
                            _formatDate(request.timestamp),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Text(
                            'Date',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                      const Icon(Icons.bloodtype, color: Colors.red, size: 40),
                      Column(
                        children: [
                          const Text(
                            'ADMIN',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Text(
                            'Signed',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.download),
                    label: const Text('SAVE TO GALLERY'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFAB0202),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
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
                  'Quick Request',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFAB0202),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Choose blood group for a quick emergency request.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 30),
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

      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      final userData = snapshot.data() as Map<String, dynamic>;
      final details = userData['details'] as Map<String, dynamic>? ?? {};

      RequestModel request = RequestModel(
        id: '',
        senderId: user.uid,
        fullName: userData['fullName'] ?? 'Emergency Patient',
        bloodGroup: bloodGroup,
        quantity: '1 Unit',
        hospitalName: details['hospitalName'] ?? 'Emergency Hospital',
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
            content: Text('Request Broadcast Sent Successfully!'),
            backgroundColor: Color(0xFFAB0202),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Pop loading
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sending request: $e')));
      }
    }
  }
}
