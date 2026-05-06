import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:blood_c/pages/chat_page.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchDonorsPage extends StatefulWidget {
  final String currentUserId;
  const SearchDonorsPage({super.key, required this.currentUserId});

  @override
  State<SearchDonorsPage> createState() => _SearchDonorsPageState();
}

class _SearchDonorsPageState extends State<SearchDonorsPage> {
  String _searchQuery = '';
  String _selectedBloodGroup = 'All';
  final List<String> _bloodGroups = [
    'All',
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Find Donors',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFAB0202),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [_buildFilters(), Expanded(child: _buildResults())],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search by name or pincode...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFFAB0202)),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  _bloodGroups.map((bg) {
                    bool isSelected = _selectedBloodGroup == bg;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedBloodGroup = bg),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? const Color(0xFFAB0202)
                                  : Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          bg,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
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

  Widget _buildResults() {
    Query query = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'Donor');

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var donors =
            snapshot.data!.docs.where((doc) {
              var data = doc.data() as Map<String, dynamic>;
              var details = data['details'] ?? {};
              String name = (data['fullName'] ?? '').toString().toLowerCase();
              String pincode = (details['pincode'] ?? '').toString();
              String bloodGroup = details['bloodGroup'] ?? '';

              bool matchesSearch =
                  name.contains(_searchQuery.toLowerCase()) ||
                  pincode.contains(_searchQuery);
              bool matchesGroup =
                  _selectedBloodGroup == 'All' ||
                  bloodGroup == _selectedBloodGroup;

              return matchesSearch && matchesGroup;
            }).toList();

        if (donors.isEmpty) {
          return Center(
            child: Text(
              'No donors found matching criteria.',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: donors.length,
          itemBuilder: (context, index) {
            var data = donors[index].data() as Map<String, dynamic>;
            var details = data['details'] ?? {};

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(
                      0xFFAB0202,
                    ).withValues(alpha: 0.1),
                    child: Text(
                      details['bloodGroup'] ?? '?',
                      style: const TextStyle(
                        color: Color(0xFFAB0202),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['fullName'] ?? 'Unknown',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Pincode: ${details['pincode'] ?? 'N/A'}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.chat_bubble_outline,
                      color: Color(0xFFAB0202),
                    ),
                    onPressed:
                        () => _openChat(
                          donors[index].id,
                          data['fullName'] ?? 'Donor',
                        ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openChat(String donorId, String donorName) {
    List<String> ids = [widget.currentUserId, donorId];
    ids.sort();
    String chatId = ids.join('_');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (c) => ChatPage(
              chatId: chatId,
              recipientName: donorName,
              currentUserId: widget.currentUserId,
            ),
      ),
    );
  }
}
