import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AllNewsPage extends StatelessWidget {
  const AllNewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final news = [
      {
        'title': 'The Power of Giving: Why Your Blood Matters',
        'desc':
            'One donation can save up to three lives. Join our community today.',
        'color': const Color(0xFFFDE8E8),
        'date': 'Oct 24, 2024',
      },
      {
        'title': 'New Safety Protocols for COVID-24',
        'desc':
            'Ensuring donor safety is our top priority. Read the latest guidelines.',
        'color': const Color(0xFFE8F4FD),
        'date': 'Oct 20, 2024',
      },
      {
        'title': 'Mega Donation Drive in Navi Mumbai',
        'desc': 'Join us this Sunday at Central Mall for a cause.',
        'color': const Color(0xFFF1FDE8),
        'date': 'Oct 15, 2024',
      },
      {
        'title': 'Blood Donation myths debunked',
        'desc': 'Separating fact from fiction about blood donation.',
        'color': const Color(0xFFFFF7E0),
        'date': 'Oct 10, 2024',
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
          'Latest Updates',
          style: GoogleFonts.poppins(
            color: const Color(0xFF2D2D2D),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: news.length,
        itemBuilder: (context, index) {
          final item = news[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: item['color'] as Color, // Use the color from the item
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['date'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item['title'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D2D2D),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item['desc'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                    height: 1.5,
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
