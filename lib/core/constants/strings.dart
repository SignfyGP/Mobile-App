import 'package:signfy/core/services/settings_service.dart';

class S {
  static bool get _ar => SettingsService.instance.appLanguage == 'ar';

  // ── Common ────────────────────────────────────────────────────────────────
  static String get translating => _ar ? 'جارٍ الترجمة…' : 'Translating…';
  static String get translateToSign =>
      _ar ? 'ترجمة إلى إشارة' : 'Translate to Sign';
  static String get signing => _ar ? 'جارٍ التوقيع' : 'Signing';
  static String get signingEllipsis => _ar ? 'جارٍ التوقيع…' : 'Signing…';
  static String translationFailed(Object error) =>
      _ar ? 'فشلت الترجمة: $error' : 'Translation failed: $error';

  // ── Home ──────────────────────────────────────────────────────────────────
  static String get translationModes =>
      _ar ? 'أوضاع الترجمة' : 'Translation Modes';
  static String get settingsTooltip => _ar ? 'الإعدادات' : 'Settings';

  static String get speechToSign => _ar ? 'كلام إلى إشارة' : 'Speech to Sign';
  static String get speechToSignSub => _ar
      ? 'تحدّث وشاهد الصورة الرمزية تترجم'
      : 'Speak or type — watch the avatar sign it back';

  static String get textToSign => _ar ? 'نص إلى إشارة' : 'Text to Sign';
  static String get textToSignSub => _ar
      ? 'اكتب أي نص وشاهد الصورة الرمزية تترجم'
      : 'Type any text — watch the avatar sign each word';

  static String get signToSpeech => _ar ? 'إشارة إلى كلام' : 'Sign to Speech';
  static String get signToSpeechSub => _ar
      ? 'أرِ يديك واحصل على كلام مسموع'
      : 'Show your hands — get spoken words back';

  // ── Settings ──────────────────────────────────────────────────────────────
  static String get settings => _ar ? 'الإعدادات' : 'Settings';
  static String get backend => _ar ? 'الخادم' : 'Backend';
  static String get baseUrl => _ar ? 'رابط الخادم' : 'Base URL';
  static String get testConnection =>
      _ar ? 'اختبار الاتصال' : 'Test Connection';
  static String get serverReachable =>
      _ar ? 'الخادم متاح' : 'Server is reachable';
  static String get serverUnreachable =>
      _ar ? 'تعذّر الوصول إلى الخادم' : 'Could not reach server';
  static String get language => _ar ? 'اللغة' : 'Language';
  static String get translationLanguage =>
      _ar ? 'لغة الترجمة' : 'Translation Language';
  static String get about => _ar ? 'حول' : 'About';
  static String get appLabel => _ar ? 'التطبيق' : 'App';
  static String get version => _ar ? 'الإصدار' : 'Version';
  static String get description => _ar ? 'الوصف' : 'Description';
  static String get resetToDefaults =>
      _ar ? 'إعادة الضبط' : 'Reset to Defaults';
  static String get save => _ar ? 'حفظ' : 'Save';
  static String get settingsSaved =>
      _ar ? 'تم حفظ الإعدادات' : 'Settings saved';
  static String get resetDone => _ar ? 'تمت إعادة الضبط' : 'Reset to defaults';
  static String get urlValidationError => _ar
      ? 'يجب أن يبدأ الرابط بـ http:// أو https://'
      : 'URL must start with http:// or https://';

  // ── Speech to Sign ────────────────────────────────────────────────────────
  static String get speechToSignTitle =>
      _ar ? 'كلام إلى إشارة' : 'Speech to Sign';
  static String get recordHint => _ar
      ? 'سجّل صوتك أدناه ثم اضغط ترجمة'
      : 'Record your voice below and tap Translate';
  static String get listening => _ar ? 'جارٍ الاستماع…' : 'Listening…';
  static String get stopPlayback => _ar ? 'إيقاف التشغيل' : 'Stop playback';
  static String get playRecordedAudio =>
      _ar ? 'تشغيل الصوت المسجل' : 'Play recorded audio';
  static String get micPermission =>
      _ar ? 'يلزم إذن الميكروفون.' : 'Microphone permission is required.';

  // ── Text to Sign ──────────────────────────────────────────────────────────
  static String get textToSignTitle => _ar ? 'نص إلى إشارة' : 'Text to Sign';
  static String get textHint => _ar
      ? 'اكتب نصاً للترجمة إلى لغة الإشارة…'
      : 'Type text to translate into sign language…';
  static String get textIdleHint => _ar
      ? 'اكتب نصاً أدناه ثم اضغط ترجمة'
      : 'Type text below and tap Translate';

  // ── Sign to Speech ────────────────────────────────────────────────────────
  static String get signToSpeechTitle =>
      _ar ? 'إشارة إلى كلام' : 'Sign to Speech';
  static String get inputVideo => _ar ? 'الفيديو المدخل' : 'Input Video';
  static String get noVideoSelected =>
      _ar ? 'لم يتم اختيار فيديو' : 'No video selected';
  static String get recordVideo => _ar ? 'تسجيل فيديو' : 'Record Video';
  static String get selectVideo => _ar ? 'اختيار فيديو' : 'Select Video';
  static String get playVideo => _ar ? 'تشغيل الفيديو' : 'Play Video';
  static String get pauseVideo => _ar ? 'إيقاف مؤقت' : 'Pause Video';
  static String get translateToSpeech =>
      _ar ? 'ترجمة إلى كلام' : 'Translate to Speech';
  static String get generatedSpeech =>
      _ar ? 'الكلام المُنشأ' : 'Generated Speech';
  static String translatedLabel(String text) =>
      _ar ? 'الترجمة: $text' : 'Translated: $text';
  static String get stopSpeech => _ar ? 'إيقاف الكلام' : 'Stop Speech';
  static String get playGeneratedSpeech =>
      _ar ? 'تشغيل الكلام' : 'Play Generated Speech';
  static String get videoRecordedOk =>
      _ar ? 'تم تسجيل الفيديو بنجاح!' : 'Video recorded successfully!';
  static String get videoLoadedOk =>
      _ar ? 'تم تحميل الفيديو بنجاح!' : 'Video loaded successfully!';
  static String get noCameraAvailable => _ar
      ? 'لا توجد كاميرا على هذا الجهاز'
      : 'No camera available on this device';
  static String get loadVideoFirst =>
      _ar ? 'يرجى تحميل فيديو أولاً' : 'Please load a video first';
  static String get videoTranslatedOk =>
      _ar ? 'تمت ترجمة الفيديو إلى كلام!' : 'Video translated to speech!';
  static String videoError(Object e) =>
      _ar ? 'خطأ في الفيديو: $e' : 'Error loading video: $e';
  static String recordError(Object e) =>
      _ar ? 'خطأ في التسجيل: $e' : 'Error recording video: $e';
  static String selectError(Object e) =>
      _ar ? 'خطأ في الاختيار: $e' : 'Error selecting video: $e';

  // ── Camera recorder ───────────────────────────────────────────────────────
  static String get recordVideoTitle => _ar ? 'تسجيل فيديو' : 'Record Video';
  static String get startRecording => _ar ? 'بدء التسجيل' : 'Start Recording';
  static String get stopRecording => _ar ? 'إيقاف التسجيل' : 'Stop Recording';
  static String get cancel => _ar ? 'إلغاء' : 'Cancel';

  // ── About & Help ──────────────────────────────────────────────────────────
  static String get aboutHelp => _ar ? 'حول والمساعدة' : 'About & Help';
  static String get aboutHelpTooltip => _ar ? 'حول والمساعدة' : 'About & Help';
  static String get aboutIntro => _ar
      ? 'سيجنيفاي تطبيق لترجمة لغة الإشارة العربية في الاتجاهين. حوّل الكلام أو النص إلى إشارات تؤديها صورة رمزية ثلاثية الأبعاد، أو ترجم إشارات الفيديو إلى كلام ونص.'
      : 'Signify is a bidirectional Arabic Sign Language translator. Turn speech or text into signs performed by a 3D avatar, or translate signed video back into speech and text.';
  static String get howToUse => _ar ? 'كيفية الاستخدام' : 'How to Use';

  static String get helpSpeechTitle =>
      _ar ? 'كلام إلى إشارة' : 'Speech to Sign';
  static String get helpSpeechBody => _ar
      ? 'اضغط زر الميكروفون لتسجيل صوتك، ثم اضغط ترجمة. ستؤدي الصورة الرمزية الإشارات المقابلة.'
      : 'Tap the microphone to record your voice, then tap Translate. The avatar will perform the matching signs.';

  static String get helpTextTitle => _ar ? 'نص إلى إشارة' : 'Text to Sign';
  static String get helpTextBody => _ar
      ? 'اكتب أي نص في الحقل ثم اضغط ترجمة لمشاهدة الصورة الرمزية توقّع كل كلمة.'
      : 'Type any text in the field and tap Translate to watch the avatar sign each word.';

  static String get helpSignTitle => _ar ? 'إشارة إلى كلام' : 'Sign to Speech';
  static String get helpSignBody => _ar
      ? 'سجّل فيديو أو اختر واحداً من جهازك، ثم اضغط ترجمة للحصول على الكلام المسموع والنص العربي.'
      : 'Record a video or pick one from your device, then tap Translate to get spoken audio and Arabic text.';

  static String get tipsTitle => _ar ? 'نصائح' : 'Tips';
  static String get tipBackend => _ar
      ? 'تأكد من ضبط رابط الخادم الصحيح في الإعدادات إن لم تنجح الترجمة.'
      : 'Make sure the correct backend URL is set in Settings if translation fails.';
  static String get tipLighting => _ar
      ? 'صوّر إشاراتك في إضاءة جيدة مع ظهور اليدين بوضوح للحصول على أفضل النتائج.'
      : 'Record your signs in good lighting with hands clearly visible for best results.';
  static String get tipPermissions => _ar
      ? 'امنح أذونات الميكروفون والكاميرا عند طلبها لتعمل الترجمة.'
      : 'Grant microphone and camera permissions when prompted so translation can work.';

  // ── Onboarding ────────────────────────────────────────────────────────────
  static String get skip => _ar ? 'تخطّي' : 'Skip';
  static String get next => _ar ? 'التالي' : 'Next';
  static String get getStarted => _ar ? 'ابدأ الآن' : 'Get Started';

  static String get onboardWelcomeTitle =>
      _ar ? 'مرحباً بك في سيجنيفاي' : 'Welcome to Signify';
  static String get onboardWelcomeBody => _ar
      ? 'مترجم لغة الإشارة العربية في الاتجاهين — يربط بين الكلام والنص ولغة الإشارة.'
      : 'A bidirectional Arabic Sign Language translator — bridging speech, text, and sign.';

  static String get onboardSpeechTextTitle =>
      _ar ? 'تحدّث أو اكتب' : 'Speak or Type';
  static String get onboardSpeechTextBody => _ar
      ? 'سجّل صوتك أو اكتب نصاً، وشاهد صورة رمزية ثلاثية الأبعاد تؤدي الإشارات.'
      : 'Record your voice or type text, and watch a 3D avatar perform the signs.';

  static String get onboardSignTitle =>
      _ar ? 'وقّع وترجم' : 'Sign and Translate';
  static String get onboardSignBody => _ar
      ? 'صوّر إشاراتك أو اختر فيديو، واحصل على كلام مسموع ونص عربي في المقابل.'
      : 'Record your signs or pick a video, and get spoken audio and Arabic text back.';

  static String get credits => _ar ? 'شكر وتقدير' : 'Credits';
  static String get gradProject => _ar ? 'مشروع تخرّج' : 'Graduation Project';
  static String get madeWith =>
      _ar ? 'صُمّم باستخدام فلاتر' : 'Built with Flutter';

  static String get teamTitle => _ar ? 'فريق العمل' : 'Team';
  static List<String> get teamMembers => _ar
      ? const ['مصطفى ربيع', 'علي بحر', 'محمد عمرو', 'محمد خالد']
      : const ['Mostafa Rabie', 'Ali Bahr', 'Mohamed Amr', 'Mohamed Khaled'];

  static String get supervisorTitle => _ar ? 'إشراف' : 'Supervisor';
  static String get supervisorName =>
      _ar ? 'أ.د. نيفين درويش' : 'Prof. Nevin Darwish';
}
