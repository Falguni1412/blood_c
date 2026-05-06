import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:blood_c/services/language_service.dart';

class LanguageSelectionPage extends StatefulWidget {
  const LanguageSelectionPage({super.key});

  @override
  State<LanguageSelectionPage> createState() => _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends State<LanguageSelectionPage> {
  late String _selectedLanguage;

  @override
  void initState() {
    super.initState();
    final currentCode = LanguageService().currentLocale.languageCode;
    _selectedLanguage =
        LanguageService().languages.entries
            .firstWhere(
              (e) => e.value == currentCode,
              orElse: () => LanguageService().languages.entries.first,
            )
            .key;
  }

  final List<Map<String, String>> _languages = [
    {
      'name': 'English',
      'native': 'English',
      'initial': 'A',
      'subtitle': 'International',
    },
    {
      'name': 'Telugu',
      'native': 'తెలుగు',
      'initial': 'ఆ',
      'subtitle': 'Regional',
    },
    {
      'name': 'Hindi',
      'native': 'हिन्दी',
      'initial': 'अ',
      'subtitle': 'National',
    },
    {
      'name': 'Kannada',
      'native': 'ಕನ್ನಡ',
      'initial': 'ಕ',
      'subtitle': 'Regional',
    },
    {
      'name': 'Marathi',
      'native': 'मराठी',
      'initial': 'म',
      'subtitle': 'Regional',
    },
    {
      'name': 'Malayalam',
      'native': 'മലയാളം',
      'initial': 'മ',
      'subtitle': 'Regional',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFAB0202),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Preferred Language',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 25),
            decoration: const BoxDecoration(
              color: Color(0xFFAB0202),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  LanguageService().translate('select_language'),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Choose the language you are most comfortable with for a better experience.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(25),
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 1.1,
              ),
              itemCount: _languages.length,
              itemBuilder: (context, index) {
                final lang = _languages[index];
                final isSelected = _selectedLanguage == lang['name'];

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedLanguage = lang['name']!;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? const Color(0xFFAB0202) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color:
                              isSelected
                                  ? const Color(
                                    0xFFAB0202,
                                  ).withValues(alpha: 0.3)
                                  : Colors.black.withValues(alpha: 0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? Colors.white.withValues(alpha: 0.2)
                                    : const Color(
                                      0xFFAB0202,
                                    ).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              lang['initial']!,
                              style: GoogleFonts.poppins(
                                color:
                                    isSelected
                                        ? Colors.white
                                        : const Color(0xFFAB0202),
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          lang['native']!,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color:
                                isSelected
                                    ? Colors.white
                                    : const Color(0xFF2D2D2D),
                          ),
                        ),
                        Text(
                          lang['name']!,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color:
                                isSelected
                                    ? Colors.white.withValues(alpha: 0.7)
                                    : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(25, 10, 25, 40),
            child: SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () async {
                  await LanguageService().changeLanguage(_selectedLanguage);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Language updated to $_selectedLanguage'),
                        backgroundColor: const Color(0xFFAB0202),
                      ),
                    );
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFAB0202),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 8,
                  shadowColor: const Color(0xFFAB0202).withValues(alpha: 0.4),
                ),
                child: Text(
                  LanguageService().translate('confirm_selection'),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
