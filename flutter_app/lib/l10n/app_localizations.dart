import 'package:flutter/material.dart';

/// Localization support for Kisaan Mitra.
/// 3 languages: English (en), Hindi (hi), Marathi (mr).

class AppLocalizations {
  final String languageCode;

  AppLocalizations(this.languageCode);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(Localizations.localeOf(context).languageCode);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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

      // Profile Screen
      'profile_title': 'Profile',
      'farmer_details': 'Farmer Details',
      'farm_information': 'Farm Information',
      'language_card': 'Language',
      'name_label': 'Name',
      'farmer_role': 'Farmer',
      'not_available': 'Not available',

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
      'welcome': 'Welcome back,',

      // Dashboard Header & Badges
      'active_crop': 'ACTIVE CROP',
      'no_crop_sown': 'NO CROP SOWN',
      'hi_farmer': 'Hi,',

      // Weather Card
      'feels_like': 'Feels like',
      'wind': 'Wind',
      'rain': 'Rain',

      // Crop Stage Card
      'crop_stage': 'Crop Stage',
      'on_track': 'On track',
      'stage_sowing': 'Sowing',
      'stage_veg': 'Veg.',
      'stage_flowering': 'Flowering',
      'stage_maturity': 'Maturity',

      // Water Status Card
      'water_status': 'Water Status',
      'no_irrigation_needed': 'No irrigation needed',
      'needs_irrigation': 'Needs irrigation',

      // Crop Health Card
      'crop_health': 'Crop Health',

      // Yield Prediction Card
      'ml_yield_prediction': 'ML YIELD PREDICTION',
      'expected_yield': 'Expected Yield',
      'tons_per_hectare': 'Tons / Hectare',
      'confidence_range': 'Confidence Range',

      // Recommendations & Planning
      'top_recommendations': 'Top Recommendations',
      'crop_cycle_complete': 'CROP CYCLE COMPLETE',
      'no_crop_sown_yet': 'NO CROP SOWN YET',
      'plan_next_season': 'Choose a crop to plan your next season.',
      'planning_description': "We'll compare crops using your farm's soil, weather, water requirement and local market demand.",
      'top_crop_recommendations': 'Top Crop Recommendations',
      'net_return': 'Net return',
      'water_req': 'Water Req.',
      'recommended_sowing': 'Recommended Sowing',
      'suitable': 'Suitable',
      'personalized_recs_info': 'These recommendations are personalized for your farm.',
      'ranking_factors': 'Ranking considers: Market Demand • Water Requirement • Sowing Period',

      // Sowing Date Modal & Recommendation Modal
      'plan_crop': 'Plan',
      'select_sowing_date': 'Select Sowing Date',
      'confirm_start_growing': 'Confirm & Start Growing',
      'switched_crop_success': 'Switched active crop to',
      'got_it': 'Got it',
      'why_recommendation': 'Why this recommendation?',
      'unable_connect_backend': 'Unable to connect to backend',
      'check_network_backend': 'Please check your network or backend server and try again.',

      // Pest Detection Page 1
      'pest_detection_title': 'Pest Detection',
      'pest_hero_title': 'Something wrong\nwith your crop?',
      'pest_hero_subtitle': 'Take a photo of the affected plant and we\'ll help identify the possible pest or problem.',
      'take_photo': 'Take Photo',
      'use_camera': 'Use camera',
      'choose_photo': 'Choose Photo',
      'from_gallery': 'From gallery',
      'quick_easy_private': 'Quick • Easy • Private',
      'not_sure_what_to_scan': 'Not sure what to scan?',
      'look_for_signs': 'Look for signs like these',
      'symptom_holes': 'Holes /\neaten leaves',
      'symptom_insects': 'Insects',
      'symptom_spots': 'Spots /\ndiscoloration',
      'symptom_curling': 'Curling /\ndistortion',
      'symptom_webbing': 'Webbing',
      'symptom_sudden_damage': 'Sudden\ndamage',
      'nav_my_crop': 'My Crop',
      'nav_scan': 'Scan',
      'nav_advisory': 'Advisory',
      'nav_more': 'More',
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

      // Profile Screen
      'profile_title': 'प्रोफाइल',
      'farmer_details': 'किसान विवरण',
      'farm_information': 'खेत की जानकारी',
      'language_card': 'भाषा',
      'name_label': 'नाम',
      'farmer_role': 'किसान',
      'not_available': 'उपलब्ध नहीं',

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
      'welcome': 'स्वागत है,',

      // Dashboard Header & Badges
      'active_crop': 'सक्रिय फसल',
      'no_crop_sown': 'फसल बोई नहीं गई',
      'hi_farmer': 'नमस्ते,',

      // Weather Card
      'feels_like': 'महसूस होता है',
      'wind': 'हवा',
      'rain': 'बारिश',

      // Crop Stage Card
      'crop_stage': 'फसल का चरण',
      'on_track': 'सही स्थिति में',
      'stage_sowing': 'बुवाई',
      'stage_veg': 'बढ़वार',
      'stage_flowering': 'फूल आना',
      'stage_maturity': 'पकाई',

      // Water Status Card
      'water_status': 'जल स्थिति',
      'no_irrigation_needed': 'सिंचाई की आवश्यकता नहीं',
      'needs_irrigation': 'सिंचाई की आवश्यकता',

      // Crop Health Card
      'crop_health': 'फसल का स्वास्थ्य',

      // Yield Prediction Card
      'ml_yield_prediction': 'ML उपज अनुमान',
      'expected_yield': 'अपेक्षित उपज',
      'tons_per_hectare': 'टन / हेक्टेयर',
      'confidence_range': 'विश्वास सीमा',

      // Recommendations & Planning
      'top_recommendations': 'प्रमुख सिफारिशें',
      'crop_cycle_complete': 'फसल चक्र पूर्ण',
      'no_crop_sown_yet': 'अभी कोई फसल नहीं बोई गई',
      'plan_next_season': 'अगले सीजन की योजना बनाने के लिए फसल चुनें।',
      'planning_description': 'हम आपके खेत की मिट्टी, मौसम, पानी की आवश्यकता और बाजार मांग के आधार पर फसलों की तुलना करेंगे।',
      'top_crop_recommendations': 'शीर्ष फसल सिफारिशें',
      'net_return': 'शुद्ध लाभ',
      'water_req': 'पानी आवश्यकता',
      'recommended_sowing': 'अनुशंसित बुवाई',
      'suitable': 'उपयुक्त',
      'personalized_recs_info': 'ये सिफारिशें आपके खेत के लिए व्यक्तिगत हैं।',
      'ranking_factors': 'रैंकिंग का आधार: बाजार मांग • पानी की आवश्यकता • बुवाई का समय',

      // Sowing Date Modal & Recommendation Modal
      'plan_crop': 'योजना बनाएं',
      'select_sowing_date': 'बुवाई की तारीख चुनें',
      'confirm_start_growing': 'पुष्टि करें और खेती शुरू करें',
      'switched_crop_success': 'सक्रिय फसल बदलकर हुई',
      'got_it': 'समझ गया',
      'why_recommendation': 'यह सिफारिश क्यों?',
      'unable_connect_backend': 'बैकएंड से कनेक्ट करने में असमर्थ',
      'check_network_backend': 'कृपया अपना नेटवर्क या बैकएंड सर्वर जांचें और पुनः प्रयास करें।',

      // Pest Detection Page 1
      'pest_detection_title': 'कीट पहचान',
      'pest_hero_title': 'आपकी फसल में\nकुछ समस्या है?',
      'pest_hero_subtitle': 'प्रभावित पौधे की फोटो लें और हम संभावित कीट या समस्या की पहचान करने में मदद करेंगे।',
      'take_photo': 'फोटो लें',
      'use_camera': 'कैमरा उपयोग करें',
      'choose_photo': 'फोटो चुनें',
      'from_gallery': 'गैलरी से',
      'quick_easy_private': 'त्वरित • आसान • निजी',
      'not_sure_what_to_scan': 'क्या स्कैन करें समझ नहीं आ रहा?',
      'look_for_signs': 'इस तरह के लक्षण देखें',
      'symptom_holes': 'छेद /\nखाई हुई पत्तियाँ',
      'symptom_insects': 'कीड़े',
      'symptom_spots': 'धब्बे /\nरंग बदलना',
      'symptom_curling': 'मुड़ना /\nविकृति',
      'symptom_webbing': 'जाला (वेबिंग)',
      'symptom_sudden_damage': 'अचानक\nनुकसान',
      'nav_my_crop': 'मेरी फसल',
      'nav_scan': 'स्कैन',
      'nav_advisory': 'सलाह',
      'nav_more': 'अधिक',
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

      // Profile Screen
      'profile_title': 'प्रोफाइल',
      'farmer_details': 'शेतकरी तपशील',
      'farm_information': 'शेताची माहिती',
      'language_card': 'भाषा',
      'name_label': 'नाव',
      'farmer_role': 'शेतकरी',
      'not_available': 'उपलब्ध नाही',

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
      'welcome': 'स्वागत आहे,',

      // Dashboard Header & Badges
      'active_crop': 'सक्रिय पीक',
      'no_crop_sown': 'पीक पेरलेले नाही',
      'hi_farmer': 'नमस्कार,',

      // Weather Card
      'feels_like': 'जाणवते',
      'wind': 'वारा',
      'rain': 'पाऊस',

      // Crop Stage Card
      'crop_stage': 'पिकाचा टप्पा',
      'on_track': 'योग्य मार्गावर',
      'stage_sowing': 'पेरणी',
      'stage_veg': 'वाढ',
      'stage_flowering': 'फुलोरा',
      'stage_maturity': 'पक्वता',

      // Water Status Card
      'water_status': 'पाणी स्थिती',
      'no_irrigation_needed': 'सिंचनाची गरज नाही',
      'needs_irrigation': 'सिंचनाची गरज',

      // Crop Health Card
      'crop_health': 'पिकाचे आरोग्य',

      // Yield Prediction Card
      'ml_yield_prediction': 'ML उत्पादन अंदाज',
      'expected_yield': 'अपेक्षित उत्पादन',
      'tons_per_hectare': 'टन / हेक्टर',
      'confidence_range': 'विश्वास श्रेणी',

      // Recommendations & Planning
      'top_recommendations': 'प्रमुख शिफारसी',
      'crop_cycle_complete': 'पीक चक्र पूर्ण',
      'no_crop_sown_yet': 'अजून कोणतेही पीक पेरलेले नाही',
      'plan_next_season': 'पुढील हंगामाचे नियोजन करण्यासाठी पीक निवडा.',
      'planning_description': 'आम्ही तुमच्या शेताची माती, हवामान, पाण्याची गरज आणि बाजार मागणीनुसार पिकांची तुलना करू.',
      'top_crop_recommendations': 'प्रमुख पीक शिफारसी',
      'net_return': 'निव्वळ नफा',
      'water_req': 'पाण्याची गरज',
      'recommended_sowing': 'योग्य पेरणी वेळ',
      'suitable': 'योग्य',
      'personalized_recs_info': 'या शिफारसी तुमच्या शेतासाठी वैयक्तिकृत आहेत.',
      'ranking_factors': 'रँकिंगचे निकष: बाजार मागणी • पाण्याची गरज • पेरणीचा काळ',

      // Sowing Date Modal & Recommendation Modal
      'plan_crop': 'नियोजन करा',
      'select_sowing_date': 'पेरणी तारीख निवडा',
      'confirm_start_growing': 'खात्री करा आणि शेती सुरू करा',
      'switched_crop_success': 'सक्रिय पीक बदलून झाले',
      'got_it': 'समजले',
      'why_recommendation': 'ही शिफारस का?',
      'unable_connect_backend': 'बॅकएंडशी कनेक्ट करण्यात अक्षम',
      'check_network_backend': 'कृपया तुमचे नेटवर्क किंवा बॅकएंड सर्व्हर तपासा आणि पुन्हा प्रयत्न करा.',

      // Pest Detection Page 1
      'pest_detection_title': 'कीड ओळख',
      'pest_hero_title': 'तुमच्या पिकात\nकाही समस्या आहे का?',
      'pest_hero_subtitle': 'बाधित रोपाचा फोटो घ्या आणि आम्ही संभाव्य कीड किंवा समस्येची ओळख पटवण्यास मदत करू.',
      'take_photo': 'फोटो घ्या',
      'use_camera': 'कॅमेरा वापरा',
      'choose_photo': 'फोटो निवडा',
      'from_gallery': 'गॅलरीमधून',
      'quick_easy_private': 'जलद • सोपे • खाजगी',
      'not_sure_what_to_scan': 'काय स्कॅन करावे हे समजत नाही?',
      'look_for_signs': 'यासारखी लक्षणे शोधा',
      'symptom_holes': 'छिद्रे /\nखाल्लेली पाने',
      'symptom_insects': 'कीटक',
      'symptom_spots': 'डाग /\nरंग बदलणे',
      'symptom_curling': 'वळणे /\nविकृती',
      'symptom_webbing': 'जाळे (वेबिंग)',
      'symptom_sudden_damage': 'अचानक\nनुकसान',
      'nav_my_crop': 'माझे पीक',
      'nav_scan': 'स्कॅन',
      'nav_advisory': 'सल्ला',
      'nav_more': 'अधिक',
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
  String get profileTitle => get('profile_title');
  String get farmerDetails => get('farmer_details');
  String get farmInformation => get('farm_information');
  String get languageCard => get('language_card');
  String get nameLabel => get('name_label');
  String get farmerRole => get('farmer_role');
  String get notAvailable => get('not_available');

  // Dashboard getters
  String get activeCrop => get('active_crop');
  String get noCropSown => get('no_crop_sown');
  String get hiFarmer => get('hi_farmer');
  String get feelsLike => get('feels_like');
  String get wind => get('wind');
  String get rain => get('rain');
  String get cropStage => get('crop_stage');
  String get onTrack => get('on_track');
  String get stageSowing => get('stage_sowing');
  String get stageVeg => get('stage_veg');
  String get stageFlowering => get('stage_flowering');
  String get stageMaturity => get('stage_maturity');
  String get waterStatus => get('water_status');
  String get noIrrigationNeeded => get('no_irrigation_needed');
  String get needsIrrigation => get('needs_irrigation');
  String get cropHealth => get('crop_health');
  String get mlYieldPrediction => get('ml_yield_prediction');
  String get expectedYield => get('expected_yield');
  String get tonsPerHectare => get('tons_per_hectare');
  String get confidenceRange => get('confidence_range');
  String get topRecommendations => get('top_recommendations');
  String get cropCycleComplete => get('crop_cycle_complete');
  String get noCropSownYet => get('no_crop_sown_yet');
  String get planNextSeason => get('plan_next_season');
  String get planningDescription => get('planning_description');
  String get topCropRecommendations => get('top_crop_recommendations');
  String get netReturn => get('net_return');
  String get waterReq => get('water_req');
  String get recommendedSowing => get('recommended_sowing');
  String get suitable => get('suitable');
  String get personalizedRecsInfo => get('personalized_recs_info');
  String get rankingFactors => get('ranking_factors');
  String get planCrop => get('plan_crop');
  String get selectSowingDate => get('select_sowing_date');
  String get confirmStartGrowing => get('confirm_start_growing');
  String get switchedCropSuccess => get('switched_crop_success');
  String get gotIt => get('got_it');
  String get whyRecommendation => get('why_recommendation');
  String get unableConnectBackend => get('unable_connect_backend');
  String get checkNetworkBackend => get('check_network_backend');

  // Pest Detection getters
  String get pestDetectionTitle => get('pest_detection_title');
  String get pestHeroTitle => get('pest_hero_title');
  String get pestHeroSubtitle => get('pest_hero_subtitle');
  String get takePhoto => get('take_photo');
  String get useCamera => get('use_camera');
  String get choosePhoto => get('choose_photo');
  String get fromGallery => get('from_gallery');
  String get quickEasyPrivate => get('quick_easy_private');
  String get notSureWhatToScan => get('not_sure_what_to_scan');
  String get lookForSigns => get('look_for_signs');
  String get symptomHoles => get('symptom_holes');
  String get symptomInsects => get('symptom_insects');
  String get symptomSpots => get('symptom_spots');
  String get symptomCurling => get('symptom_curling');
  String get symptomWebbing => get('symptom_webbing');
  String get symptomSuddenDamage => get('symptom_sudden_damage');
  String get navMyCrop => get('nav_my_crop');
  String get navScan => get('nav_scan');
  String get navAdvisory => get('nav_advisory');
  String get navMore => get('nav_more');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'hi', 'mr'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale.languageCode);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
