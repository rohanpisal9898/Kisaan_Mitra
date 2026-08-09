library;

/// Localization support for Kisaan Mitra.
/// 3 languages: English (en), Hindi (hi), Marathi (mr).

class AppLocalizations {
  final String languageCode;

  AppLocalizations(this.languageCode);

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Splash
      'app_name': 'Kisaan Mitra',
      'splash_title': 'Farm Smarter.\nHarvest Better.',
      'splash_subtitle': 'AI-powered tools for smarter farming',
      'get_started': 'Get Started',

      // Language Selection
      'choose_language': 'Choose Language',
      'choose_language_subtitle': 'Pick your preferred language',
      'continue_btn': 'Continue',
      'lang_english': 'English',
      'lang_hindi': 'Hindi',
      'lang_marathi': 'Marathi',

      // Farmer Profile & Account (Step 1)
      'step_1_of_2': 'Step 1 of 2',
      'your_farmer_profile': 'Account Details',
      'profile_subtitle': 'Tell us a bit about yourself so we can personalise your dashboard.',
      'account_details': 'Account Details',
      'account_subtitle': 'Manage your farm account credentials and profile.',
      'farmer_name': 'Farmer Name',
      'farmer_name_hint': 'e.g., Ramesh Patel',
      'village': 'Village',
      'village_hint': 'e.g., Sonepur',
      'district': 'District',
      'district_hint': 'e.g., Nashik',
      'state': 'State',
      'state_hint': 'e.g., Maharashtra',
      'select_state': 'Select State',
      'select_district': 'Select District',
      'next_add_farm': 'Next: Add Farm',
      'password': 'Password',
      'password_hint': 'Enter password',
      'sign_in': 'Sign In',
      'create_account': 'Create Account',
      'already_have_account': 'Already have an account? Sign In',
      'dont_have_account': "Don't have an account? Create One",

      // Add Farm (Step 2)
      'step_2_of_2': 'Step 2 of 2',
      'add_your_farm': 'Add Your Farm',
      'farm_subtitle': "We'll use this to predict yield & fetch weather data.",
      'auto_detect_location': 'Auto Detect Location',
      'auto_detect_subtitle': 'Use GPS to fetch soil & weather data',
      'crop_type': 'Crop Type',
      'farm_area': 'Farm Area',
      'acres': 'Acres',
      'hectares': 'Hectares',
      'sowing_date': 'Sowing Date',
      'farm_location_label': 'Farm Location (Village / Landmark)',
      'farm_location_hint': 'e.g., Near Green Field, Nashik',
      'analyze_my_farm': 'Analyze My Farm',

      // AI Analysis
      'ai_analyzing': 'AI is Analyzing\nYour Farm',
      'ai_subtitle': 'Combining weather, soil & satellite data to predict your yield with 90% confidence.',
      'fetching_weather': 'Fetching Weather Data',
      'analyzing_satellite': 'Analyzing Satellite Imagery',
      'reading_soil': 'Reading Soil Information',
      'predicting_yield': 'Predicting Expected Yield',

      // Common
      'loading': 'Loading...',
      'error': 'Error',
      'retry': 'Retry',
      'back': 'Back',
      'phone_number': 'Phone Number',
      'phone_hint': 'e.g., 9876543210',
      'nav_home': 'Home',
      'nav_pest': 'Pest',
      'nav_wallet': 'Wallet',
      'nav_profile': 'Profile',
    },

    'hi': {
      // Splash
      'app_name': 'किसान मित्र',
      'splash_title': 'स्मार्ट खेती।\nबेहतर फसल।',
      'splash_subtitle': 'स्मार्ट खेती के लिए AI-संचालित उपकरण',
      'get_started': 'शुरू करें',

      // Language Selection
      'choose_language': 'भाषा चुनें',
      'choose_language_subtitle': 'अपनी पसंदीदा भाषा चुनें',
      'continue_btn': 'जारी रखें',
      'lang_english': 'English',
      'lang_hindi': 'हिन्दी',
      'lang_marathi': 'मराठी',

      // Farmer Profile & Account (Step 1)
      'step_1_of_2': 'चरण 1 / 2',
      'your_farmer_profile': 'खाता विवरण',
      'profile_subtitle': 'अपने बारे में थोड़ा बताएं ताकि हम आपका डैशबोर्ड अनुकूलित कर सकें।',
      'account_details': 'खाता विवरण',
      'account_subtitle': 'अपने फार्म खाते की जानकारी और प्रोफाइल प्रबंधित करें।',
      'farmer_name': 'किसान का नाम',
      'farmer_name_hint': 'उदा., रमेश पटेल',
      'village': 'गांव',
      'village_hint': 'उदा., सोनेपुर',
      'district': 'जिला',
      'district_hint': 'उदा., नाशिक',
      'state': 'राज्य',
      'state_hint': 'उदा., महाराष्ट्र',
      'select_state': 'राज्य चुनें',
      'select_district': 'जिला चुनें',
      'next_add_farm': 'अगला: खेत जोड़ें',
      'password': 'पासवर्ड',
      'password_hint': 'पासवर्ड दर्ज करें',
      'sign_in': 'साइन इन करें',
      'create_account': 'खाता बनाएं',
      'already_have_account': 'क्या आपके पास पहले से खाता है? साइन इन करें',
      'dont_have_account': 'खाता नहीं है? नया बनाएं',

      // Add Farm (Step 2)
      'step_2_of_2': 'चरण 2 / 2',
      'add_your_farm': 'अपना खेत जोड़ें',
      'farm_subtitle': 'इसका उपयोग उपज की भविष्यवाणी और मौसम डेटा प्राप्त करने के लिए किया जाएगा।',
      'auto_detect_location': 'स्थान स्वतः पता लगाएं',
      'auto_detect_subtitle': 'मिट्टी और मौसम डेटा प्राप्त करने के लिए GPS का उपयोग करें',
      'crop_type': 'फसल का प्रकार',
      'farm_area': 'खेत का क्षेत्र',
      'acres': 'एकड़',
      'hectares': 'हेक्टेयर',
      'sowing_date': 'बुवाई की तारीख',
      'farm_location_label': 'खेत का स्थान (गांव / पहचान चिन्ह)',
      'farm_location_hint': 'उदा., ग्रीन फील्ड के पास, नाशिक',
      'analyze_my_farm': 'मेरे खेत का विश्लेषण करें',

      // AI Analysis
      'ai_analyzing': 'AI आपके खेत\nका विश्लेषण कर रहा है',
      'ai_subtitle': 'मौसम, मिट्टी और उपग्रह डेटा को मिलाकर 90% विश्वास के साथ आपकी उपज की भविष्यवाणी।',
      'fetching_weather': 'मौसम डेटा प्राप्त हो रहा है',
      'analyzing_satellite': 'उपग्रह इमेजरी विश्लेषण',
      'reading_soil': 'मिट्टी की जानकारी पढ़ रहा है',
      'predicting_yield': 'अपेक्षित उपज का अनुमान',

      // Common
      'loading': 'लोड हो रहा है...',
      'error': 'त्रुटि',
      'retry': 'पुनः प्रयास करें',
      'back': 'वापस',
      'phone_number': 'फोन नंबर',
      'phone_hint': 'उदा., 9876543210',
      'nav_home': 'होम',
      'nav_pest': 'कीट',
      'nav_wallet': 'वॉलेट',
      'nav_profile': 'प्रोफाइल',
    },

    'mr': {
      // Splash
      'app_name': 'किसान मित्र',
      'splash_title': 'हुशार शेती।\nचांगली कापणी।',
      'splash_subtitle': 'स्मार्ट शेतीसाठी AI-चालित साधने',
      'get_started': 'सुरू करा',

      // Language Selection
      'choose_language': 'भाषा निवडा',
      'choose_language_subtitle': 'तुमची आवडती भाषा निवडा',
      'continue_btn': 'पुढे चला',
      'lang_english': 'English',
      'lang_hindi': 'हिन्दी',
      'lang_marathi': 'मराठी',

      // Farmer Profile & Account (Step 1)
      'step_1_of_2': 'पायरी 1 / 2',
      'your_farmer_profile': 'खाते तपशील',
      'profile_subtitle': 'तुमचे डॅशबोर्ड वैयक्तिकृत करण्यासाठी स्वतःबद्दल थोडे सांगा.',
      'account_details': 'खाते तपशील',
      'account_subtitle': 'तुमच्या फार्म खात्याची माहिती आणि प्रोफाइल व्यवस्थापित करा.',
      'farmer_name': 'शेतकऱ्याचे नाव',
      'farmer_name_hint': 'उदा., रमेश पाटील',
      'village': 'गाव',
      'village_hint': 'उदा., सोनेपुर',
      'district': 'जिल्हा',
      'district_hint': 'उदा., नाशिक',
      'state': 'राज्य',
      'state_hint': 'उदा., महाराष्ट्र',
      'select_state': 'राज्य निवडा',
      'select_district': 'जिल्हा निवडा',
      'next_add_farm': 'पुढे: शेत जोडा',
      'password': 'पासवर्ड',
      'password_hint': 'पासवर्ड टाका',
      'sign_in': 'साइन इन करा',
      'create_account': 'खाते तयार करा',
      'already_have_account': 'आधीपासून खाते आहे? साइन इन करा',
      'dont_have_account': 'खाते नाही? नवीन तयार करा',

      // Add Farm (Step 2)
      'step_2_of_2': 'पायरी 2 / 2',
      'add_your_farm': 'तुमचे शेत जोडा',
      'farm_subtitle': 'उत्पादन अंदाज आणि हवामान डेटा मिळवण्यासाठी हे वापरले जाईल.',
      'auto_detect_location': 'स्थान आपोआप शोधा',
      'auto_detect_subtitle': 'माती आणि हवामान डेटा मिळवण्यासाठी GPS वापरा',
      'crop_type': 'पिकाचा प्रकार',
      'farm_area': 'शेताचे क्षेत्र',
      'acres': 'एकर',
      'hectares': 'हेक्टर',
      'sowing_date': 'पेरणी तारीख',
      'farm_location_label': 'शेताचे ठिकाण (गाव / खूण)',
      'farm_location_hint': 'उदा., ग्रीन फील्ड जवळ, नाशिक',
      'analyze_my_farm': 'माझ्या शेताचे विश्लेषण करा',

      // AI Analysis
      'ai_analyzing': 'AI तुमच्या शेताचे\nविश्लेषण करत आहे',
      'ai_subtitle': 'हवामान, माती आणि उपग्रह डेटा एकत्र करून 90% विश्वासाने तुमच्या उत्पादनाचा अंदाज.',
      'fetching_weather': 'हवामान डेटा मिळवत आहे',
      'analyzing_satellite': 'उपग्रह प्रतिमा विश्लेषण',
      'reading_soil': 'माती माहिती वाचत आहे',
      'predicting_yield': 'अपेक्षित उत्पादन अंदाज',

      // Common
      'loading': 'लोड होत आहे...',
      'error': 'त्रुटी',
      'retry': 'पुन्हा प्रयत्न करा',
      'back': 'मागे',
      'phone_number': 'फोन नंबर',
      'phone_hint': 'उदा., 9876543210',
      'nav_home': 'होम',
      'nav_pest': 'कीड',
      'nav_wallet': 'वॉलेट',
      'nav_profile': 'प्रोफाइल',
    },
  };

  String get(String key) {
    return _localizedValues[languageCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }

  // Convenience getters
  String get appName => get('app_name');
  String get splashTitle => get('splash_title');
  String get splashSubtitle => get('splash_subtitle');
  String get getStarted => get('get_started');
  String get chooseLanguage => get('choose_language');
  String get chooseLanguageSubtitle => get('choose_language_subtitle');
  String get continueBtn => get('continue_btn');
  String get step1of2 => get('step_1_of_2');
  String get yourFarmerProfile => get('your_farmer_profile');
  String get profileSubtitle => get('profile_subtitle');
  String get farmerName => get('farmer_name');
  String get farmerNameHint => get('farmer_name_hint');
  String get village => get('village');
  String get villageHint => get('village_hint');
  String get district => get('district');
  String get districtHint => get('district_hint');
  String get state => get('state');
  String get stateHint => get('state_hint');
  String get selectState => get('select_state');
  String get selectDistrict => get('select_district');
  String get nextAddFarm => get('next_add_farm');
  String get step2of2 => get('step_2_of_2');
  String get addYourFarm => get('add_your_farm');
  String get farmSubtitle => get('farm_subtitle');
  String get autoDetectLocation => get('auto_detect_location');
  String get autoDetectSubtitle => get('auto_detect_subtitle');
  String get cropType => get('crop_type');
  String get farmArea => get('farm_area');
  String get acresLabel => get('acres');
  String get hectaresLabel => get('hectares');
  String get sowingDate => get('sowing_date');
  String get farmLocationLabel => get('farm_location_label');
  String get farmLocationHint => get('farm_location_hint');
  String get analyzeMyFarm => get('analyze_my_farm');
  String get aiAnalyzing => get('ai_analyzing');
  String get aiSubtitle => get('ai_subtitle');
  String get fetchingWeather => get('fetching_weather');
  String get analyzingSatellite => get('analyzing_satellite');
  String get readingSoil => get('reading_soil');
  String get predictingYield => get('predicting_yield');
  String get loading => get('loading');
  String get error => get('error');
  String get retry => get('retry');
  String get back => get('back');
  String get phoneNumber => get('phone_number');
  String get phoneHint => get('phone_hint');
  String get navHome => get('nav_home');
  String get navPest => get('nav_pest');
  String get navWallet => get('nav_wallet');
  String get navProfile => get('nav_profile');
  String get accountDetails => get('account_details');
  String get accountSubtitle => get('account_subtitle');
  String get password => get('password');
  String get passwordHint => get('password_hint');
  String get signIn => get('sign_in');
  String get createAccount => get('create_account');
  String get alreadyHaveAccount => get('already_have_account');
  String get dontHaveAccount => get('dont_have_account');
}
