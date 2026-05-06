import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyContactsPage extends StatelessWidget {
  const EmergencyContactsPage({super.key});

  final Map<String, List<Map<String, String>>> categorizedContacts = const {
    'Universal Emergency': [
      {
        'name': 'All-in-One Emergency',
        'number': '112',
        'desc': 'Police, Ambulance, Fire (National)',
        'icon': 'emergency',
      },
      {
        'name': 'Police Control Room',
        'number': '100',
        'desc': 'Direct Police Emergency',
        'icon': 'policy',
      },
      {
        'name': 'Ambulance',
        'number': '108',
        'desc': 'Free Gov Ambulance Service',
        'icon': 'medical_services',
      },
      {
        'name': 'Fire Brigade',
        'number': '101',
        'desc': 'Fire Emergencies',
        'icon': 'local_fire_department',
      },
    ],
    'Women & Girl Safety': [
      {
        'name': 'Women Helpline (Mah)',
        'number': '181',
        'desc': '24x7 Support for distress',
        'icon': 'woman',
      },
      {
        'name': 'Women Police helpline',
        'number': '1091',
        'desc': 'Direct Police Assistance',
        'icon': 'shield',
      },
      {
        'name': 'NCW WhatsApp',
        'number': '7827170170',
        'desc': 'Women Commission Helpline',
        'icon': 'chat',
      },
    ],
    'Medical & Blood Support': [
      {
        'name': 'Blood Bank Helpline',
        'number': '104',
        'desc': 'State Blood Bank Information',
        'icon': 'bloodtype',
      },
      {
        'name': 'Red Cross Helpline',
        'number': '1800-11-2333',
        'desc': 'National Red Cross Support',
        'icon': 'health_and_safety',
      },
      {
        'name': 'Gov Ambulance (Alt)',
        'number': '102',
        'desc': 'Maternity & Medical SOS',
        'icon': 'ambulance',
      },
    ],
    'Mental & Child Safety': [
      {
        'name': 'Tele-MANAS',
        'number': '14416',
        'desc': '24x7 Mental Health Support',
        'icon': 'psychology',
      },
      {
        'name': 'Child Helpline',
        'number': '1098',
        'desc': 'For children in risk',
        'icon': 'child_care',
      },
      {
        'name': 'Suicide Prevention',
        'number': '91-22-27546669',
        'desc': 'Support for distress',
        'icon': 'favorite',
      },
    ],
  };

  Future<void> _makeCall(String number) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: number.replaceAll('-', '').replaceAll(' ', ''),
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        title: Text(
          'Emergency Care',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFFAB0202),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          for (var entry in categorizedContacts.entries) ...[
            _buildCategorySection(entry.key),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildContactCard(entry.value[index]),
                  childCount: entry.value.length,
                ),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFAB0202), Color(0xFF880101)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(25, 10, 25, 40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: Colors.white,
              size: 45,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Safety & Support Hub',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'One tap away from life-saving assistance.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(String title) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(25, 30, 25, 15),
      sliver: SliverToBoxAdapter(
        child: Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: const Color(0xFFAB0202),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(Map<String, String> contact) {
    IconData iconData;
    switch (contact['icon']) {
      case 'emergency':
        iconData = Icons.emergency_rounded;
        break;
      case 'policy':
        iconData = Icons.policy_rounded;
        break;
      case 'medical_services':
        iconData = Icons.medical_services_rounded;
        break;
      case 'local_fire_department':
        iconData = Icons.local_fire_department_rounded;
        break;
      case 'woman':
        iconData = Icons.woman_rounded;
        break;
      case 'shield':
        iconData = Icons.shield_rounded;
        break;
      case 'chat':
        iconData = Icons.chat_rounded;
        break;
      case 'bloodtype':
        iconData = Icons.bloodtype_rounded;
        break;
      case 'health_and_safety':
        iconData = Icons.health_and_safety_rounded;
        break;
      case 'ambulance':
        iconData = Icons.airport_shuttle_rounded;
        break;
      case 'psychology':
        iconData = Icons.psychology_rounded;
        break;
      case 'child_care':
        iconData = Icons.child_care_rounded;
        break;
      case 'favorite':
        iconData = Icons.favorite_rounded;
        break;
      default:
        iconData = Icons.phone_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => _makeCall(contact['number']!),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFFAB0202).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    iconData,
                    color: const Color(0xFFAB0202),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact['name']!,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: const Color(0xFF2D2D2D),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        contact['desc']!,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        contact['number']!,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFAB0202),
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.call,
                    color: Color(0xFF4CAF50),
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
