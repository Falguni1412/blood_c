import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal();

  Locale _currentLocale = const Locale('en');
  Locale get currentLocale => _currentLocale;

  static const String _languageKey = 'selected_language';

  // Supported languages map: Name -> Code
  final Map<String, String> languages = {
    'English': 'en',
    'Telugu': 'te',
    'Hindi': 'hi',
    'Kannada': 'kn',
    'Marathi': 'mr',
    'Malayalam': 'ml',
  };

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString(_languageKey) ?? 'en';
    _currentLocale = Locale(langCode);
    notifyListeners();
  }

  Future<void> changeLanguage(String languageName) async {
    final langCode = languages[languageName] ?? 'en';
    _currentLocale = Locale(langCode);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, langCode);

    notifyListeners();
  }

  // Simple translation helper
  String translate(String key) {
    final translations =
        _allTranslations[_currentLocale.languageCode] ??
        _allTranslations['en']!;
    return translations[key] ?? key;
  }

  // Basic translations for the app
  final Map<String, Map<String, String>> _allTranslations = {
    'en': {
      'app_title': 'BloodCare',
      'home': 'Home',
      'donate': 'Donate',
      'chat': 'Chat',
      'profile': 'Profile',
      'emergency_requests': 'Emergency Requests',
      'see_all': 'See All',
      'blood_group': 'Blood Group',
      'activity': 'Activity',
      'upcoming_camps': 'Upcoming Camps',
      'edit_profile': 'Edit Profile',
      'logout': 'Logout',
      'available': 'Available',
      'create_post': 'Create Post',
      'blood_given': 'Blood Given',
      'refer_friend': 'Refer Friend',
      'select_language': 'Select Your Language',
      'confirm_selection': 'CONFIRM SELECTION',
    },
    'te': {
      'app_title': 'బ్లడ్ కేర్',
      'home': 'హోమ్',
      'donate': 'దానం చేయండి',
      'chat': 'చాట్',
      'profile': 'ప్రొఫైల్',
      'emergency_requests': 'అత్యవసర అభ్యర్థనలు',
      'see_all': 'అన్నీ చూడండి',
      'blood_group': 'రక్త వర్గం',
      'activity': 'కార్యకలాపాలు',
      'upcoming_camps': 'రాబోయే శిబిరాలు',
      'edit_profile': 'ప్రొఫైల్ సవరించండి',
      'logout': 'లాగ్అవుట్',
      'available': 'అందుబాటులో ఉంది',
      'create_post': 'పోస్ట్ సృష్టించండి',
      'blood_given': 'రక్తం ఇచ్చారు',
      'refer_friend': 'స్నేహితుడిని సూచించండి',
      'select_language': 'మీ భాషను ఎంచుకోండి',
      'confirm_selection': 'ఎంపికను నిర్ధారించండి',
    },
    'hi': {
      'app_title': 'ब्लडकेयर',
      'home': 'होम',
      'donate': 'दान करें',
      'chat': 'चैट',
      'profile': 'प्रोफ़ाइल',
      'emergency_requests': 'आपातकालीन अनुरोध',
      'see_all': 'सभी देखें',
      'blood_group': 'रक्त समूह',
      'activity': 'गतिविधि',
      'upcoming_camps': 'आगामी शिविर',
      'edit_profile': 'प्रोफ़ाइल संपादित करें',
      'logout': 'लॉगआउट',
      'available': 'उपलब्ध',
      'create_post': 'पोस्ट बनाएं',
      'blood_given': 'रक्त दिया गया',
      'refer_friend': 'मित्र को रेफर करें',
      'select_language': 'अपनी भाषा चुनें',
      'confirm_selection': 'चयन की पुष्टि करें',
    },
    'kn': {
      'app_title': 'ಬ್ಲಡ್ ಕೇರ್',
      'home': 'ಹೋಮ್',
      'donate': 'ದಾನ ಮಾಡಿ',
      'chat': 'ಚಾಟ್',
      'profile': 'ಪ್ರೊಫೈಲ್',
      'emergency_requests': 'ತುರ್ತು ವಿನಂತಿಗಳು',
      'see_all': 'ಎಲ್ಲವನ್ನೂ ನೋಡಿ',
      'blood_group': 'ರಕ್ತದ ಗುಂಪು',
      'activity': 'ಚಟುವಟಿಕೆ',
      'upcoming_camps': 'ಮುಂಬರುವ ಶಿಬಿರಗಳು',
      'edit_profile': 'ಪ್ರೊಫೈಲ್ ತಿದ್ದಿ',
      'logout': 'ಲಾಗ್ ಔಟ್',
      'available': 'ಲಭ್ಯವಿದೆ',
      'create_post': 'ಪೋಸ್ಟ್ ರಚಿಸಿ',
      'blood_given': 'ರಕ್ತ ನೀಡಲಾಗಿದೆ',
      'refer_friend': 'ಸ್ನೇಹಿತರನ್ನು ಉಲ್ಲೇಖಿಸಿ',
      'select_language': 'ನಿಮ್ಮ ಭಾಷೆಯನ್ನು ಆರಿಸಿ',
      'confirm_selection': 'ಆಯ್ಕೆಯನ್ನು ಖಚಿತಪಡಿಸಿ',
    },
    'mr': {
      'app_title': 'ब्लडकेअर',
      'home': 'होम',
      'donate': 'दान करा',
      'chat': 'चॅट',
      'profile': 'प्रोफाइल',
      'emergency_requests': 'तातडीच्या विनंत्या',
      'see_all': 'सर्व पहा',
      'blood_group': 'रक्त गट',
      'activity': 'activity',
      'upcoming_camps': 'आगामी शिबिरे',
      'edit_profile': 'प्रोफाइल संपादित करा',
      'logout': 'लॉगआउट',
      'available': 'उपलब्ध',
      'create_post': 'पोस्ट तयार करा',
      'blood_given': 'रक्त दिले',
      'refer_friend': 'मित्राला रेफर करा',
      'select_language': 'तुमची भाषा निवडा',
      'confirm_selection': 'निवडीची पुष्टी करा',
    },
    'ml': {
      'app_title': 'ബ്ലഡ് കെയർ',
      'home': 'ഹോം',
      'donate': 'ദാനം ചെയ്യുക',
      'chat': 'ചാറ്റ്',
      'profile': 'പ്രൊഫൈൽ',
      'emergency_requests': 'അടിയന്തിര അഭ്യർത്ഥനകൾ',
      'see_all': 'എല്ലാം കാണുക',
      'blood_group': 'രക്ത ഗ്രൂപ്പ്',
      'activity': 'പ്രവർത്തനം',
      'upcoming_camps': 'വരാനിരിക്കുന്ന ക്യാമ്പുകൾ',
      'edit_profile': 'പ്രൊഫൈൽ എഡിറ്റ് ചെയ്യുക',
      'logout': 'ലോഗ്ഔട്ട്',
      'available': 'ലഭ്യമാണ്',
      'create_post': 'പോസ്റ്റ് സൃഷ്ടിക്കുക',
      'blood_given': 'രക്തം നൽകി',
      'refer_friend': 'സുഹൃത്തിനെ റെഫർ ചെയ്യുക',
      'select_language': 'നിങ്ങളുടെ ഭാഷ തിരഞ്ഞെടുക്കുക',
      'confirm_selection': 'തിരഞ്ഞെടുപ്പ് സ്ഥിരീകരിക്കുക',
    },
  };
}
