import 'package:flutter/material.dart';

/// Localization support for Kisaan Mitra.
/// 3 languages: English (en), Hindi (hi), Marathi (mr).

class AppLocalizations {
  final String languageCode;

  AppLocalizations(this.languageCode);

  String get localeName {
    if (languageCode == 'hi') return 'Hindi';
    if (languageCode == 'mr') return 'Marathi';
    return 'English';
  }

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
      'sign_out': 'Sign Out',
      'sign_out_confirm_title': 'Sign Out',
      'sign_out_confirm_message': 'Are you sure you want to sign out?',
      'nav_schemes': 'Government\nSchemes',
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
      'other_crop_option': 'Other',
      'choose_another_crop': 'Choose another crop',
      'select_crop_title': 'Select Crop',
      'select_crop_subtitle': "Choose a crop that isn't in your recommendations.",
      'no_other_crops': 'No other crops are available.',

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
      'pest_hero_title': 'Identify what\'s\naffecting your crop',
      'pest_hero_subtitle': 'Take a clear photo of the\naffected plant or leaf and\nwe\'ll detect the problem.',
      'take_photo': 'Take Photo',
      'use_camera': 'Use camera',
      'or_divider': 'or',
      'upload_from_gallery': 'Upload from Gallery',
      'tips_title': 'Tips for best results',
      'tips_text': 'Use daylight • Focus on the affected area •\nAvoid blurry images',
      'camera_perm_title': 'Camera Permission Required',
      'camera_perm_body': 'Camera permission is required to capture photos of affected crops. Please allow camera access.',
      'camera_perm_denied_body': 'Camera permission is permanently denied. Please open App Settings to enable camera access.',
      'open_settings': 'Open Settings',
      'cancel_btn': 'Cancel',
      'nav_my_crop': 'My Crop',
      'nav_scan': 'Scan',
      'nav_advisory': 'Advisory',
      'nav_more': 'More',
      'ai_analyzing_photo': 'AI is analyzing\nyour photo',
      'takes_few_seconds': 'This usually takes a few seconds.',
      'step_image_quality': 'Image quality check',
      'step_detecting_patterns': 'Detecting patterns',
      'step_identifying_issues': 'Identifying issues',
      'step_preparing_questions': 'Preparing questions',
      'step_generating_insights': 'Generating insights',
      'data_safe_private': 'Your data is safe and private',
      'question_progress_format': 'Question {current} of {total}',
      'yes': 'Yes',
      'no': 'No',
      'not_sure': 'Not sure?',
      'skip_question': 'Skip this question',
      'this_helps_understand': 'This helps us understand\nthe problem better.',
      'please_select_answer': 'Please select an answer or skip this question.',
      'next_btn': 'Next',
      'previous_btn': 'Back',
      'questions_error': 'Could not load questions. Please try again.',

      // Pest Detection Page 4 - Diagnosis Report
      'diagnosis_report_title': 'Diagnosis Report',
      'what_we_found': 'What we found',
      'confidence_score': 'Confidence Score',
      'what_to_do_now': 'What to do now',
      'view_treatment_guide': 'View Treatment Guide',
      'affected_part_label': 'Affected part',
      'observed_damage_label': 'Observed damage',
      'spread_label': 'Spread',
      'affected_area_label': 'Affected area',
      'crop_stage_label': 'Your crop stage',
      'moderate_concern': 'Moderate Concern',

      // Pest Detection Page 5 - Treatment Guide
      'treatment_guide_title': 'Treatment Guide',
      'what_to_do_for_field': 'What to do (For Field)',
      'recommended_products': 'Recommended Products',
      'additional_tips': 'Additional Tips',
      'save_and_done': 'Save & Done',

      // PDF & Report History
      'pest_diagnosis_report_header': 'PEST DIAGNOSIS REPORT',
      'smart_farming_slogan': 'Smart Farming. Better Tomorrow.',
      'crop_health_analysis': 'Crop Health Analysis',
      'report_id_label': 'Report ID',
      'date_time_label': 'Date & Time',
      'affected_severity_title': 'AFFECTED SEVERITY',
      'plants_affected': 'Plants Affected',
      'severity_level': 'Severity Level',
      'crop_stage': 'Crop Stage',
      'about_this_report_title': 'ABOUT THIS REPORT',
      'about_this_report_body': 'This report is generated by Kisaan Mitra AI. The analysis is based on the photo you provided and AI evaluation. For best results, follow the recommendations and consult local agricultural expert if needed.',
      'important_note_title': 'IMPORTANT NOTE',
      'important_note_body': 'This advice is for general guidance only. Field conditions may vary. Please use your best judgement and local expert advice.',
      'trusted_analysis_title': 'Trusted Analysis',
      'trusted_analysis_sub': 'AI-powered crop health insights',
      'better_decisions_title': 'Better Decisions',
      'better_decisions_sub': 'Timely actions for healthier crops',
      'sustainable_farming_title': 'Sustainable Farming',
      'sustainable_farming_sub': 'Smarter solutions for a better tomorrow',
      'were_here_title': "We're Here for You",
      'were_here_sub': 'Stay informed. Grow better.',
      'thank_you_footer': 'Thank you for choosing Kisaan Mitra 💚',
      'report_history_title': 'Report History',
      'no_reports_found': 'No past diagnosis reports found',
      'download_report': 'Download Report',
      'share_report': 'Share Report',
      'preparing_report': 'Preparing your report...',
      'report_saved_success': 'Report saved to downloads successfully!',
      'low_concern': 'Low Concern',
      'high_concern': 'High Concern',
      'no_product_recommendation': 'No specific product recommendation available',

      // Farmer Wallet
      'wallet': 'Farmer Wallet',
      'farmCosts': 'Your Farm Costs',
      'seeds': 'Seeds',
      'fertilizer': 'Fertilizer',
      'labour': 'Labour',
      'machinery': 'Machinery',
      'irrigation': 'Irrigation',
      'pestControl': 'Pest Control',
      'other': 'Other',
      'submit': 'Submit / Save Changes',
      'saveSuccess': 'Expenses updated successfully.',
      'expectedProfit': 'Expected',
      'minimumExpected': 'Minimum Expected',
      'maximumExpected': 'Maximum Expected',
      'lowMarket': 'Low Market',
      'moderateMarket': 'Moderate Market',
      'highMarket': 'High Market',
      'totalCost': 'Total Cost',
      'addExpense': 'Add Expense',
      'oilseedMarketData': 'Oilseed Market Data',
      'yourCrop': 'Your Crop',
      'marketPrice': 'Market Price',
      'govtMsp': 'Govt MSP',
      'difference': 'Difference',
      'financialOutlook': 'Your Financial Outlook',
      'safePlanningRange': 'Safe Planning Range',
      'customCategoryName': 'Custom Category Name',
      'category': 'Category',
      'amount': 'Amount (₹)',
      'saveExpense': 'Save Expense',
      'estimatedLoss': 'Estimated Loss',
      'expectedProfitTitle': 'Expected Profit',
      'financialOverviewSubtitle': 'Financial overview for your farm',
      'planningModeSubtitle': 'Oilseed Market Data & Regional Intelligence',
      'confidenceNote': 'Based on predicted yield • 90% confidence range',
      'disclaimerNote': 'Estimated financial outlook — actual returns may vary.',
      'planExpensesAdvice': '💡 Plan your expenses around the lower estimate to reduce financial risk.',

      // Government Schemes
      'govt_schemes_title': 'Government Schemes',
      'govt_schemes_subtitle': 'Explore schemes that support farmers and strengthen agriculture.',
      'filter_all_schemes': 'All Schemes',
      'filter_central_govt': 'Central Government',
      'filter_state_govt': 'State Government',
      'central_govt_schemes': 'Central Government Schemes',
      'state_govt_schemes': 'State Government Schemes',
      'learn_more': 'Learn More',
      'status_active': 'Active',
      'view_all_schemes': 'View All Schemes',
      'cant_find_looking_for': "Can't find what you're looking for?",
      'cant_find_subtitle': 'Check all schemes or use filters to find the right scheme for you.',
      'about_these_schemes': 'About These Schemes',
      'about_schemes_desc': 'These schemes are provided through official government sources.',
      'loading_schemes': 'Loading schemes...',
      'unable_to_load_schemes': 'Unable to load schemes right now.',
      'official_link_unavailable': 'Official link unavailable',

      // Image Validation
      'photo_cannot_be_analyzed': 'This photo can’t be analyzed',
      'photo_not_a_crop': 'This photo is not a crop image',
      'photo_not_a_crop_desc': 'Please upload a clear photo of the affected crop, leaf, plant part, or visible pest.',
      'please_upload_crop_photo': 'Please upload a crop photo',
      'upload_crop_photo_desc': 'For pest detection, take or upload a clear photo of a crop, leaf, stem, fruit, flower, or affected plant part.',
      'photo_not_clear': 'Photo is not clear enough',
      'photo_not_clear_desc': 'Please take a closer, clearer photo of the affected crop or plant part.',
      'try_another_photo': 'Try Another Photo',
      'take_another_photo': 'Take Another Photo',
      'valid_examples_title': 'Tips for best results:',
      'tip_leaf_or_plant': '✓ Leaf, stem, fruit, or plant',
      'tip_visible_damage': '✓ Visible crop damage or symptoms',
      'tip_pest_on_crop': '✓ Visible pest or insect on crop',
      'unable_to_check_photo': 'Unable to check this photo right now. Please try again.',
      'validating_photo': 'Checking photo relevance...',
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
      'sign_out': 'साइन आउट',
      'sign_out_confirm_title': 'साइन आउट',
      'sign_out_confirm_message': 'क्या आप वाकई साइन आउट करना चाहते हैं?',
      'nav_schemes': 'सरकारी\nयोजनाएं',
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
      'other_crop_option': 'अन्य',
      'choose_another_crop': 'दूसरी फसल चुनें',
      'select_crop_title': 'फसल चुनें',
      'select_crop_subtitle': 'ऐसी फसल चुनें जो आपकी सिफारिशों में नहीं है।',
      'no_other_crops': 'कोई अन्य फसल उपलब्ध नहीं है।',

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
      'pest_hero_title': 'पहचानें कि आपकी फसल\nको क्या प्रभावित कर रहा है',
      'pest_hero_subtitle': 'प्रभावित पौधे या पत्ती की स्पष्ट फोटो लें\nऔर हम समस्या का पता लगाएंगे।',
      'take_photo': 'फोटो लें',
      'use_camera': 'कैमरा उपयोग करें',
      'or_divider': 'या',
      'upload_from_gallery': 'गैलरी से अपलोड करें',
      'tips_title': 'उत्तम परिणामों के लिए सुझाव',
      'tips_text': 'दिन के उजाले का उपयोग करें • प्रभावित क्षेत्र पर ध्यान केंद्रित करें •\nधुंधली छवियों से बचें',
      'camera_perm_title': 'कैमरा अनुमति आवश्यक',
      'camera_perm_body': 'फसल की फोटो लेने के लिए कैमरा अनुमति आवश्यक है। कृपया अनुमति दें।',
      'camera_perm_denied_body': 'कैमरा अनुमति स्थायी रूप से अस्वीकृत है। कृपया ऐप सेटिंग्स में इसे सक्षम करें।',
      'open_settings': 'सेटिंग्स खोलें',
      'cancel_btn': 'रद्द करें',
      'nav_my_crop': 'मेरी फसल',
      'nav_scan': 'स्कैन',
      'nav_advisory': 'सलाह',
      'nav_more': 'अधिक',
      'ai_analyzing_photo': 'AI आपकी फोटो का\nविश्लेषण कर रहा है',
      'takes_few_seconds': 'इसमें आमतौर पर कुछ सेकंड लगते हैं।',
      'step_image_quality': 'छवि गुणवत्ता जांच',
      'step_detecting_patterns': 'पैटर्न का पता लगाना',
      'step_identifying_issues': 'समस्याओं की पहचान',
      'step_preparing_questions': 'प्रश्न तैयार करना',
      'step_generating_insights': 'अंतर्दृष्टि उत्पन्न करना',
      'data_safe_private': 'आपका डेटा सुरक्षित और निजी है',
      'question_progress_format': 'प्रश्न {current} / {total}',
      'yes': 'हां',
      'no': 'नहीं',
      'not_sure': 'पक्का नहीं पता?',
      'skip_question': 'इस प्रश्न को छोड़ें',
      'this_helps_understand': 'यह हमें समस्या को\nबेहतर ढंग से समझने में मदद करता है।',
      'please_select_answer': 'कृपया उत्तर चुनें या इस प्रश्न को छोड़ें।',
      'next_btn': 'आगे',
      'previous_btn': 'मागे',
      'questions_error': 'प्रश्न लोड नहीं हो सके। कृपया पुनः प्रयास करें।',

      // Pest Detection Page 4 - Diagnosis Report
      'diagnosis_report_title': 'निदान रिपोर्ट',
      'what_we_found': 'हमें क्या मिला',
      'confidence_score': 'विश्वसनीयता स्कोर',
      'what_to_do_now': 'अब क्या करें',
      'view_treatment_guide': 'उपचार निर्देश देखें',
      'affected_part_label': 'प्रभावित भाग',
      'observed_damage_label': 'देखी गई क्षति',
      'spread_label': 'प्रसार',
      'affected_area_label': 'प्रभावित क्षेत्र',
      'crop_stage_label': 'आपकी फसल का चरण',
      'moderate_concern': 'मध्यम चिंता',

      // Pest Detection Page 5 - Treatment Guide
      'treatment_guide_title': 'उपचार मार्गदर्शक',
      'what_to_do_for_field': 'क्या करें (खेत के लिए)',
      'recommended_products': 'अनुशंसित उत्पाद',
      'additional_tips': 'अतिरिक्त सुझाव',
      'save_and_done': 'सहेजें और पूरा करें',

      // PDF & Report History
      'pest_diagnosis_report_header': 'कीट निदान रिपोर्ट',
      'smart_farming_slogan': 'स्मार्ट कृषि। बेहतर कल।',
      'crop_health_analysis': 'फसल स्वास्थ्य विश्लेषण',
      'report_id_label': 'रिपोर्ट आईडी',
      'date_time_label': 'दिनांक एवं समय',
      'affected_severity_title': 'प्रभावित गंभीरता',
      'plants_affected': 'प्रभावित पौधे',
      'severity_level': 'गंभीरता स्तर',
      'crop_stage': 'फसल अवस्था',
      'about_this_report_title': 'इस रिपोर्ट के बारे में',
      'about_this_report_body': 'यह रिपोर्ट किसान मित्र AI द्वारा तैयार की गई है। विश्लेषण आपके द्वारा प्रदान की गई फोटो और AI मूल्यांकन पर आधारित है। सर्वोत्तम परिणामों के लिए, सिफारिशों का पालन करें और यदि आवश्यक हो तो स्थानीय कृषि विशेषज्ञ से परामर्श लें।',
      'important_note_title': 'महत्वपूर्ण नोट',
      'important_note_body': 'यह सलाह केवल सामान्य कृषि मार्गदर्शन के लिए है। खेत की स्थितियां भिन्न हो सकती हैं। कृपया अपने सर्वोत्तम निर्णय और स्थानीय विशेषज्ञ सलाह का उपयोग करें।',
      'trusted_analysis_title': 'विश्वसनीय विश्लेषण',
      'trusted_analysis_sub': 'AI-संचालित फसल स्वास्थ्य जानकारी',
      'better_decisions_title': 'बेहतर निर्णय',
      'better_decisions_sub': 'स्वस्थ फसलों के लिए समय पर कदम',
      'sustainable_farming_title': 'सतत कृषि',
      'sustainable_farming_sub': 'बेहतर कल के लिए स्मार्ट समाधान',
      'were_here_title': 'हम आपके साथ हैं',
      'were_here_sub': 'सूचित रहें। बेहतर फसल उगाएं।',
      'thank_you_footer': 'किसान मित्र चुनने के लिए धन्यवाद 💚',
      'report_history_title': 'रिपोर्ट इतिहास',
      'no_reports_found': 'कोई पिछला निदान रिपोर्ट नहीं मिला',
      'download_report': 'रिपोर्ट डाउनलोड करें',
      'share_report': 'रिपोर्ट शेयर करें',
      'preparing_report': 'आपकी रिपोर्ट तैयार की जा रही है...',
      'report_saved_success': 'रिपोर्ट सफलतापूर्वक डाउनलोड में सहेजी गई!',
      'low_concern': 'कम चिंता',
      'high_concern': 'उच्च चिंता',
      'no_product_recommendation': 'कोई विशिष्ट उत्पाद सिफारिश उपलब्ध नहीं है',

      // Farmer Wallet
      'wallet': 'किसान वॉलेट',
      'farmCosts': 'आपके खेत के खर्चे',
      'seeds': 'बीज',
      'fertilizer': 'उर्वरक / खाद',
      'labour': 'मजदूरी',
      'machinery': 'मशीनरी',
      'irrigation': 'सिंचाई',
      'pestControl': 'कीट नियंत्रण',
      'other': 'अन्य',
      'submit': 'सबमिट / बदलाव सहेजें',
      'saveSuccess': 'खर्चे सफलतापूर्वक अद्यतन किए गए।',
      'expectedProfit': 'अनुमानित',
      'minimumExpected': 'न्यूनतम अनुमानित',
      'maximumExpected': 'अधिकतम अनुमानित',
      'lowMarket': 'कम बाजार',
      'moderateMarket': 'मध्यम बाजार',
      'highMarket': 'उच्च बाजार',
      'totalCost': 'कुल लागत',
      'addExpense': 'खर्च जोड़ें',
      'oilseedMarketData': 'तिलहन बाजार डेटा',
      'yourCrop': 'आपकी फसल',
      'marketPrice': 'बाजार भाव',
      'govtMsp': 'सरकारी एमएसपी',
      'difference': 'अंतर',
      'financialOutlook': 'आपका वित्तीय दृष्टिकोण',
      'safePlanningRange': 'सुरक्षित नियोजन सीमा',
      'customCategoryName': 'कस्टम श्रेणी का नाम',
      'category': 'श्रेणी',
      'amount': 'राशि (₹)',
      'saveExpense': 'खर्च सहेजें',
      'estimatedLoss': 'अनुमानित नुकसान',
      'expectedProfitTitle': 'अनुमानित लाभ',
      'financialOverviewSubtitle': 'आपके खेत के लिए वित्तीय अवलोकन',
      'planningModeSubtitle': 'तिलहन बाजार डेटा और क्षेत्रीय खुफिया जानकारी',
      'confidenceNote': 'अनुमानित उपज के आधार पर • 90% विश्वास सीमा',
      'disclaimerNote': 'अनुमानित वित्तीय दृष्टिकोण — वास्तविक लाभ भिन्न हो सकता है।',
      'planExpensesAdvice': '💡 वित्तीय जोखिम कम करने के लिए निचले अनुमान के आधार पर खर्चों की योजना बनाएं।',

      // Government Schemes
      'govt_schemes_title': 'सरकारी योजनाएं',
      'govt_schemes_subtitle': 'किसानों का समर्थन करने और कृषि को मजबूत करने वाली योजनाओं की खोज करें।',
      'filter_all_schemes': 'सभी योजनाएं',
      'filter_central_govt': 'केंद्र सरकार',
      'filter_state_govt': 'राज्य सरकार',
      'central_govt_schemes': 'केंद्र सरकार की योजनाएं',
      'state_govt_schemes': 'राज्य सरकार की योजनाएं',
      'learn_more': 'अधिक जानें',
      'status_active': 'सक्रिय',
      'view_all_schemes': 'सभी योजनाएं देखें',
      'cant_find_looking_for': 'क्या आप जो खोज रहे हैं वह नहीं मिला?',
      'cant_find_subtitle': 'अपने लिए सही योजना खोजने के लिए सभी योजनाएं देखें या फ़िल्टर का उपयोग करें।',
      'about_these_schemes': 'इन योजनाओं के बारे में',
      'about_schemes_desc': 'ये योजनाएं आधिकारिक सरकारी स्रोतों के माध्यम से प्रदान की जाती हैं।',
      'loading_schemes': 'योजनाएं लोड हो रही हैं...',
      'unable_to_load_schemes': 'अभी योजनाएं लोड करने में असमर्थ।',
      'official_link_unavailable': 'आधिकारिक लिंक उपलब्ध नहीं है',

      // Image Validation
      'photo_cannot_be_analyzed': 'यह फ़ोटो विश्लेषण के लिए उपयुक्त नहीं है',
      'photo_not_a_crop': 'यह फ़ोटो फसल की नहीं है',
      'photo_not_a_crop_desc': 'कृपया प्रभावित फसल, पत्ती, पौधे का हिस्सा या दिखाई देने वाले कीड़े की स्पष्ट फ़ोटो अपलोड करें।',
      'please_upload_crop_photo': 'कृपया फसल की फ़ोटो अपलोड करें',
      'upload_crop_photo_desc': 'कीट पहचान के लिए फसल, पत्ती, तना, फल, फूल या प्रभावित पौधे के हिस्से की स्पष्ट फ़ोटो लें या अपलोड करें।',
      'photo_not_clear': 'फ़ोटो पर्याप्त स्पष्ट नहीं है',
      'photo_not_clear_desc': 'कृपया प्रभावित फसल या पौधे के हिस्से की पास से और स्पष्ट फ़ोटो लें।',
      'try_another_photo': 'दूसरी फ़ोटो चुनें',
      'take_another_photo': 'दूसरी फ़ोटो लें',
      'valid_examples_title': 'सर्वोत्तम परिणाम के लिए सुझाव:',
      'tip_leaf_or_plant': '✓ पत्ती, तना, फल या पौधा',
      'tip_visible_damage': '✓ फसल की क्षति या लक्षण',
      'tip_pest_on_crop': '✓ फसल पर दिखाई देने वाला कीट',
      'unable_to_check_photo': 'अभी इस फ़ोटो की जांच नहीं की जा सकी। कृपया पुनः प्रयास करें।',
      'validating_photo': 'फ़ोटो की जांच हो रही है...',
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
      'sign_out': 'साइन आउट',
      'sign_out_confirm_title': 'साइन आउट',
      'sign_out_confirm_message': 'तुम्हाला नक्की साइन आउट करायचे आहे का?',
      'nav_schemes': 'शासकीय\nयोजना',
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
      'other_crop_option': 'इतर',
      'choose_another_crop': 'दुसरे पीक निवडा',
      'select_crop_title': 'पीक निवडा',
      'select_crop_subtitle': 'तुमच्या शिफारशींमध्ये नसलेले पीक निवडा.',
      'no_other_crops': 'इतर कोणतेही पिके उपलब्ध नाहीत।',

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
      'pest_hero_title': 'तुमच्या पिकाला काय\nबाधित करत आहे ते ओळखा',
      'pest_hero_subtitle': 'बाधित वनस्पती किंवा पाणाचा स्पष्ट फोटो घ्या\nआणि आम्ही समस्येचा शोध घेऊ.',
      'take_photo': 'फोटो घ्या',
      'use_camera': 'कॅमेरा वापरा',
      'or_divider': 'किंवा',
      'upload_from_gallery': 'गॅलरीमधून अपलोड करा',
      'tips_title': 'उत्तम परिणामांसाठी टिप्स',
      'tips_text': 'दिवसाच्या प्रकाशाचा वापर करा • बाधित भागावर लक्ष केंद्रित करा •\nअस्पष्ट फोटो टाळा',
      'camera_perm_title': 'कॅमेरा परवानगी आवश्यक',
      'camera_perm_body': 'पिकाचा फोटो घेण्यासाठी कॅमेरा परवानगी आवश्यक आहे. कृपया परवानगी द्या.',
      'camera_perm_denied_body': 'कॅमेरा परवानगी कायमची नाकारली गेली आहे. कृपया ॲप सेटिंग्जमध्ये सक्षम करा.',
      'open_settings': 'सेटिंग्ज उघडा',
      'cancel_btn': 'रद्द करा',
      'nav_my_crop': 'माझे पीक',
      'nav_scan': 'स्कॅन',
      'nav_advisory': 'सल्ला',
      'nav_more': 'अधिक',
      'ai_analyzing_photo': 'AI तुमच्या फोटोचे\nविश्लेषण करत आहे',
      'takes_few_seconds': 'याला सहसा काही सेकंद लागतात.',
      'step_image_quality': 'फोटो गुणवत्तेची तपासणी',
      'step_detecting_patterns': 'पॅटर्न शोधणे',
      'step_identifying_issues': 'समस्या ओळखणे',
      'step_preparing_questions': 'प्रश्न तयार करणे',
      'step_generating_insights': 'माहिती तयार करणे',
      'data_safe_private': 'तुमचा डेटा सुरक्षित आणि खाजगी आहे',
      'question_progress_format': 'प्रश्न {current} / {total}',
      'yes': 'होय',
      'no': 'नाही',
      'not_sure': 'खात्री नाही?',
      'skip_question': 'हा प्रश्न वगळा',
      'this_helps_understand': 'यामुळे आम्हाला समस्या\nअधिक चांगल्या प्रकारे समजण्यास मदत होते.',
      'please_select_answer': 'कृपया उत्तर निवडा किंवा हा प्रश्न वगळा.',
      'next_btn': 'पुढे',
      'previous_btn': 'मागे',
      'questions_error': 'प्रश्न लोड करता आले नाहीत. कृपया पुन्हा प्रयत्न करा.',

      // Pest Detection Page 4 - Diagnosis Report
      'diagnosis_report_title': 'निदान अहवाल',
      'what_we_found': 'आम्हाला काय आढळले',
      'confidence_score': 'विश्वासार्हता गुण',
      'what_to_do_now': 'आता काय करावे',
      'view_treatment_guide': 'उपचार मार्गदर्शक पहा',
      'affected_part_label': 'बाधित भाग',
      'observed_damage_label': 'आढळलेले नुकसान',
      'spread_label': 'प्रसार',
      'affected_area_label': 'बाधित क्षेत्र',
      'crop_stage_label': 'तुमच्या पिकाचा टप्पा',
      'moderate_concern': 'मध्यम चिंता',

      // Pest Detection Page 5 - Treatment Guide
      'treatment_guide_title': 'उपचार मार्गदर्शक',
      'what_to_do_for_field': 'काय करावे (शेतासाठी)',
      'recommended_products': 'शिफारस केलेली उत्पादने',
      'additional_tips': 'अतिरिक्त टिप्स',
      'save_and_done': 'सेव्ह करा आणि पूर्ण झाले',

      // PDF & Report History
      'pest_diagnosis_report_header': 'कीड निदान अहवाल',
      'smart_farming_slogan': 'स्मार्ट शेती. समृद्ध भविष्य.',
      'crop_health_analysis': 'पिक आरोग्य विश्लेषण',
      'report_id_label': 'अहवाल आयडी',
      'date_time_label': 'दिनांक आणि वेळ',
      'affected_severity_title': 'प्रभावित तीव्रता',
      'plants_affected': 'प्रभावित झाडे',
      'severity_level': 'तीव्रता स्तर',
      'crop_stage': 'पिकाचा टप्पा',
      'about_this_report_title': 'या अहवालाबद्दल',
      'about_this_report_body': 'हा अहवाल किसान मित्र AI द्वारे तयार केला गेला आहे. विश्लेषण आपण दिलेल्या फोटो आणि AI मूल्यांकनावर आधारित आहे. सर्वोत्तम निकालांसाठी, शिफारसींचे अनुसरण करा आणि आवश्यक असल्यास स्थानिक कृषी तज्ञांचा सल्ला घ्या.',
      'important_note_title': 'महत्त्वाची नोंद',
      'important_note_body': 'हा सल्ला केवळ सामान्य कृषी मार्गदर्शनासाठी आहे. शेतातील परिस्थिती भिन्न असू शकते. कृपया तुमचा सर्वोत्तम निर्णय आणि स्थानिक तज्ञांचा सल्ला वापरा.',
      'trusted_analysis_title': 'विश्वसनीय विश्लेषण',
      'trusted_analysis_sub': 'AI-आधारित पिक आरोग्य माहिती',
      'better_decisions_title': 'उत्तम निर्णय',
      'better_decisions_sub': 'निरोगी पिकांसाठी वेळेवर उपाय',
      'sustainable_farming_title': 'शाश्वत शेती',
      'sustainable_farming_sub': 'उज्ज्वल भविष्यासाठी स्मार्ट उपाय',
      'were_here_title': 'आम्ही तुमच्यासोबत आहोत',
      'were_here_sub': 'माहितगार रहा. उत्तम पिकवा.',
      'thank_you_footer': 'किसान मित्र निवडल्याबद्दल धन्यवाद 💚',
      'report_history_title': 'अहवाल इतिहास',
      'no_reports_found': 'कोणताही पूर्वीचा अहवाल आढळला नाही',
      'download_report': 'अहवाल डाउनलोड करा',
      'share_report': 'अहवाल शेअर करा',
      'preparing_report': 'आपला अहवाल तयार केला जात आहे...',
      'report_saved_success': 'अहवाल यशस्वीरित्या डाउनलोडमध्ये जतन केला!',
      'low_concern': 'कमी चिंता',
      'high_concern': 'उच्च चिंता',
      'no_product_recommendation': 'कोणतीही विशेष उत्पादन शिफारस उपलब्ध नाही',

      // Farmer Wallet
      'wallet': 'शेतकरी वॉलेट',
      'farmCosts': 'तुमच्या शेताचे खर्च',
      'seeds': 'बियाणे',
      'fertilizer': 'खते',
      'labour': 'मजुरी',
      'machinery': 'यंत्रसामग्री',
      'irrigation': 'सिंचन',
      'pestControl': 'कीड नियंत्रण',
      'other': 'इतर',
      'submit': 'सबमिट / बदल जतन करा',
      'saveSuccess': 'खर्च यशस्वीरित्या अद्यतनित केले.',
      'expectedProfit': 'अपेक्षित',
      'minimumExpected': 'किमान अपेक्षित',
      'maximumExpected': 'कमाल अपेक्षित',
      'lowMarket': 'कमी बाजार',
      'moderateMarket': 'मध्यम बाजार',
      'highMarket': 'उच्च बाजार',
      'totalCost': 'एकूण खर्च',
      'addExpense': 'खर्च जोडा',
      'oilseedMarketData': 'गळित धान्य बाजार माहिती',
      'yourCrop': 'तुमचे पीक',
      'marketPrice': 'बाजार भाव',
      'govtMsp': 'शासकीय एमएसपी',
      'difference': 'फरक',
      'financialOutlook': 'तुमचा आर्थिक दृष्टिकोन',
      'safePlanningRange': 'सुरक्षित नियोजन श्रेणी',
      'customCategoryName': 'सानुकूल श्रेणी नाव',
      'category': 'वर्ग',
      'amount': 'रक्कम (₹)',
      'saveExpense': 'खर्च जतन करा',
      'estimatedLoss': 'अंदाजे तोटा',
      'expectedProfitTitle': 'अपेक्षित नफा',
      'financialOverviewSubtitle': 'तुमच्या शेताचे आर्थिक विहंगावलोकन',
      'planningModeSubtitle': 'गळित धान्य बाजार डेटा आणि प्रादेशिक माहिती',
      'confidenceNote': 'अंदाजित उत्पादनावर आधारित • 90% विश्वास श्रेणी',
      'disclaimerNote': 'अंदाजित आर्थिक दृष्टिकोन — प्रत्यक्ष परतावा बदलू शकतो.',
      'planExpensesAdvice': '💡 आर्थिक धोका कमी करण्यासाठी कमी अंदाजाभोवती खर्चाचे नियोजन करा.',

      // Government Schemes
      'govt_schemes_title': 'शासकीय योजना',
      'govt_schemes_subtitle': 'शेतकऱ्यांना पाठिंबा देणाऱ्या आणि शेतीला बळकट करणाऱ्या योजना पहा.',
      'filter_all_schemes': 'सर्व योजना',
      'filter_central_govt': 'केंद्र शासन',
      'filter_state_govt': 'राज्य शासन',
      'central_govt_schemes': 'केंद्र शासन योजना',
      'state_govt_schemes': 'राज्य शासन योजना',
      'learn_more': 'अधिक माहिती',
      'status_active': 'सक्रिय',
      'view_all_schemes': 'सर्व योजना पहा',
      'cant_find_looking_for': 'तुम्हाला हवे ते सापडले नाही का?',
      'cant_find_subtitle': 'तुमच्यासाठी योग्य योजना शोधण्यासाठी सर्व योजना पहा किंवा फिल्टर वापरा.',
      'about_these_schemes': 'या योजनांबद्दल',
      'about_schemes_desc': 'या योजना अधिकृत शासकीय स्रोतांद्वारे प्रदान केल्या जातात.',
      'loading_schemes': 'योजना लोड होत आहेत...',
      'unable_to_load_schemes': 'सध्या योजना लोड करणे शक्य नाही.',
      'official_link_unavailable': 'अधिकृत लिंक उपलब्ध नाही',

      // Image Validation
      'photo_cannot_be_analyzed': 'हा फोटो विश्लेषणासाठी योग्य नाही',
      'photo_not_a_crop': 'हा फोटो पिकाचा नाही',
      'photo_not_a_crop_desc': 'कृपया बाधित पीक, पान, वनस्पतीचा भाग किंवा दिसणाऱ्या कीटकाचा स्पष्ट फोटो अपलोड करा.',
      'please_upload_crop_photo': 'कृपया पिकाचा फोटो अपलोड करा',
      'upload_crop_photo_desc': 'कीड ओळखीसाठी पीक, पान, खोड, फळ, फूल किंवा बाधित भागाचा स्पष्ट फोटो घ्या किंवा अपलोड करा.',
      'photo_not_clear': 'फोटो पुरेसा स्पष्ट नाही',
      'photo_not_clear_desc': 'कृपया बाधित पिकाचा किंवा वनस्पतीच्या भागाचा जवळून आणि स्पष्ट फोटो घ्या.',
      'try_another_photo': 'दूसरा फोटो निवडा',
      'take_another_photo': 'दूसरा फोटो घ्या',
      'valid_examples_title': 'उत्तम निकालासाठी टिप्स:',
      'tip_leaf_or_plant': '✓ पान, खोड, फळ किंवा रोप',
      'tip_visible_damage': '✓ पिकाचे नुकसान किंवा लक्षणे',
      'tip_pest_on_crop': '✓ पिकावर दिसणारा कीटक',
      'unable_to_check_photo': 'सध्या हा फोटो तपासता आला नाही. कृपया पुन्हा प्रयत्न करा.',
      'validating_photo': 'फोटो तपासत आहे...',
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
  String get signOut => get('sign_out');
  String get signOutConfirmTitle => get('sign_out_confirm_title');
  String get signOutConfirmMessage => get('sign_out_confirm_message');
  String get navSchemes => get('nav_schemes');
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
  String get otherCropOption => get('other_crop_option');
  String get chooseAnotherCrop => get('choose_another_crop');
  String get selectCropTitle => get('select_crop_title');
  String get selectCropSubtitle => get('select_crop_subtitle');
  String get noOtherCrops => get('no_other_crops');
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
  String get orDivider => get('or_divider');
  String get uploadFromGallery => get('upload_from_gallery');
  String get tipsTitle => get('tips_title');
  String get tipsText => get('tips_text');
  String get cameraPermTitle => get('camera_perm_title');
  String get cameraPermBody => get('camera_perm_body');
  String get cameraPermDeniedBody => get('camera_perm_denied_body');
  String get openSettings => get('open_settings');
  String get cancelBtn => get('cancel_btn');
  String get navMyCrop => get('nav_my_crop');
  String get navScan => get('nav_scan');
  String get navAdvisory => get('nav_advisory');
  String get navMore => get('nav_more');
  String get aiAnalyzingPhoto => get('ai_analyzing_photo');
  String get takesFewSeconds => get('takes_few_seconds');
  String get stepImageQuality => get('step_image_quality');
  String get stepDetectingPatterns => get('step_detecting_patterns');
  String get stepIdentifyingIssues => get('step_identifying_issues');
  String get stepPreparingQuestions => get('step_preparing_questions');
  String get stepGeneratingInsights => get('step_generating_insights');
  String get dataSafePrivate => get('data_safe_private');
  String get yesLabel => get('yes');
  String get noLabel => get('no');
  String get notSure => get('not_sure');
  String get skipQuestion => get('skip_question');
  String get thisHelpsUnderstand => get('this_helps_understand');
  String get pleaseSelectAnswer => get('please_select_answer');
  String get nextBtn => get('next_btn');
  String get previousBtn => get('previous_btn');
  String get questionsError => get('questions_error');
  String get diagnosisReportTitle => get('diagnosis_report_title');
  String get whatWeFound => get('what_we_found');
  String get confidenceScore => get('confidence_score');
  String get whatToDoNow => get('what_to_do_now');
  String get viewTreatmentGuide => get('view_treatment_guide');
  String get affectedPartLabel => get('affected_part_label');
  String get observedDamageLabel => get('observed_damage_label');
  String get spreadLabel => get('spread_label');
  String get affectedAreaLabel => get('affected_area_label');
  String get cropStageLabel => get('crop_stage_label');
  String get moderateConcern => get('moderate_concern');
  String get treatmentGuideTitle => get('treatment_guide_title');
  String get whatToDoForField => get('what_to_do_for_field');
  String get recommendedProducts => get('recommended_products');
  String get additionalTips => get('additional_tips');
  String get saveAndDone => get('save_and_done');
  String get pestDiagnosisReportHeader => get('pest_diagnosis_report_header');
  String get smartFarmingSlogan => get('smart_farming_slogan');
  String get cropHealthAnalysis => get('crop_health_analysis');
  String get reportIdLabel => get('report_id_label');
  String get dateTimeLabel => get('date_time_label');
  String get affectedSeverityTitle => get('affected_severity_title');
  String get plantsAffected => get('plants_affected');
  String get severityLevel => get('severity_level');
  String get reportCropStage => get('crop_stage');
  String get aboutThisReportTitle => get('about_this_report_title');
  String get aboutThisReportBody => get('about_this_report_body');
  String get importantNoteTitle => get('important_note_title');
  String get importantNoteBody => get('important_note_body');
  String get trustedAnalysisTitle => get('trusted_analysis_title');
  String get trustedAnalysisSub => get('trusted_analysis_sub');
  String get betterDecisionsTitle => get('better_decisions_title');
  String get betterDecisionsSub => get('better_decisions_sub');
  String get sustainableFarmingTitle => get('sustainable_farming_title');
  String get sustainableFarmingSub => get('sustainable_farming_sub');
  String get wereHereTitle => get('were_here_title');
  String get wereHereSub => get('were_here_sub');
  String get thankYouFooter => get('thank_you_footer');
  String get reportHistoryTitle => get('report_history_title');
  String get noReportsFound => get('no_reports_found');
  String get downloadReport => get('download_report');
  String get shareReport => get('share_report');
  String get preparingReport => get('preparing_report');
  String get reportSavedSuccess => get('report_saved_success');
  String get lowConcern => get('low_concern');
  String get highConcern => get('high_concern');
  String get noProductRecommendation => get('no_product_recommendation');
  String questionProgress(int current, int total) {
    return get('question_progress_format')
        .replaceAll('{current}', current.toString())
        .replaceAll('{total}', total.toString());
  }

  // Farmer Wallet getters
  String get wallet => get('wallet');
  String get farmCosts => get('farmCosts');
  String get seeds => get('seeds');
  String get fertilizer => get('fertilizer');
  String get labour => get('labour');
  String get machinery => get('machinery');
  String get irrigation => get('irrigation');
  String get pestControl => get('pestControl');
  String get other => get('other');
  String get submit => get('submit');
  String get saveSuccess => get('saveSuccess');
  String get expectedProfit => get('expectedProfit');
  String get minimumExpected => get('minimumExpected');
  String get maximumExpected => get('maximumExpected');
  String get lowMarket => get('lowMarket');
  String get moderateMarket => get('moderateMarket');
  String get highMarket => get('highMarket');
  String get totalCost => get('totalCost');
  String get addExpense => get('addExpense');
  String get oilseedMarketData => get('oilseedMarketData');
  String get yourCrop => get('yourCrop');
  String get marketPrice => get('marketPrice');
  String get govtMsp => get('govtMsp');
  String get difference => get('difference');
  String get financialOutlook => get('financialOutlook');
  String get safePlanningRange => get('safePlanningRange');
  String get customCategoryName => get('customCategoryName');
  String get category => get('category');
  String get amount => get('amount');
  String get saveExpense => get('saveExpense');
  String get estimatedLoss => get('estimatedLoss');
  String get expectedProfitTitle => get('expectedProfitTitle');
  String get financialOverviewSubtitle => get('financialOverviewSubtitle');
  String get planningModeSubtitle => get('planningModeSubtitle');
  String get confidenceNote => get('confidenceNote');
  String get disclaimerNote => get('disclaimerNote');
  String get planExpensesAdvice => get('planExpensesAdvice');

  // Government Schemes getters
  String get govtSchemesTitle => get('govt_schemes_title');
  String get govtSchemesSubtitle => get('govt_schemes_subtitle');
  String get filterAllSchemes => get('filter_all_schemes');
  String get filterCentralGovt => get('filter_central_govt');
  String get filterStateGovt => get('filter_state_govt');
  String get centralGovtSchemes => get('central_govt_schemes');
  String get stateGovtSchemes => get('state_govt_schemes');
  String get learnMore => get('learn_more');
  String get statusActive => get('status_active');
  String get viewAllSchemes => get('view_all_schemes');
  String get cantFindLookingFor => get('cant_find_looking_for');
  String get cantFindSubtitle => get('cant_find_subtitle');
  String get aboutTheseSchemes => get('about_these_schemes');
  String get aboutSchemesDesc => get('about_schemes_desc');
  String get loadingSchemes => get('loading_schemes');
  String get unableToLoadSchemes => get('unable_to_load_schemes');
  String get officialLinkUnavailable => get('official_link_unavailable');

  // Image Validation getters
  String get photoCannotBeAnalyzed => get('photo_cannot_be_analyzed');
  String get photoNotACrop => get('photo_not_a_crop');
  String get photoNotACropDesc => get('photo_not_a_crop_desc');
  String get pleaseUploadCropPhoto => get('please_upload_crop_photo');
  String get uploadCropPhotoDesc => get('upload_crop_photo_desc');
  String get photoNotClear => get('photo_not_clear');
  String get photoNotClearDesc => get('photo_not_clear_desc');
  String get tryAnotherPhoto => get('try_another_photo');
  String get takeAnotherPhoto => get('take_another_photo');
  String get validExamplesTitle => get('valid_examples_title');
  String get tipLeafOrPlant => get('tip_leaf_or_plant');
  String get tipVisibleDamage => get('tip_visible_damage');
  String get tipPestOnCrop => get('tip_pest_on_crop');
  String get unableToCheckPhoto => get('unable_to_check_photo');
  String get validatingPhoto => get('validating_photo');
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
