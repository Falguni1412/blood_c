import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AllCampsPage extends StatelessWidget {
  const AllCampsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Static data from home page, extended
    final List<Map<String, String>> camps = [
      {
        'name': 'Goregaon Camp',
        'date': '25 Jan',
        'time': '10:00 AM',
        'venue': 'Rotary Club Hall, Goregaon West',
      },
      {
        'name': 'City Square Drive',
        'date': '02 Feb',
        'time': '09:00 AM',
        'venue': 'City Square Mall, Atrium',
      },
      {
        'name': 'Navi Mumbai Mega Drive',
        'date': '15 Mar',
        'time': '08:00 AM',
        'venue': 'CIDCO Exhibition Centre',
      },
      {
        'name': 'Corporate Care Event',
        'date': '22 Mar',
        'time': '11:00 AM',
        'venue': 'Tech Park, Andheri East',
      },
      {
        'name': 'Community Welfare Camp',
        'date': '01 Apr',
        'time': '09:30 AM',
        'venue': 'Community Center, Bandra',
      },
    ];

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
          'Detailed Camps',
          style: GoogleFonts.poppins(
            color: const Color(0xFF2D2D2D),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: camps.length,
        itemBuilder: (context, index) {
          final camp = camps[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFAB0202).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        camp['date']!.split(' ')[0],
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFAB0202),
                        ),
                      ),
                      Text(
                        camp['date']!.split(' ')[1],
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFAB0202),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        camp['name']!,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2D2D2D),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        camp['venue']!,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 16,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            camp['time']!,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
