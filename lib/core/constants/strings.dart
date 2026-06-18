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
  static String get explore => _ar ? 'استكشف' : 'Explore';
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

  static String get avatarDemoTitle =>
      _ar ? 'عرض الصورة الرمزية ثلاثية الأبعاد' : '3D Avatar Demo';
  static String get avatarDemoSub => _ar
      ? 'استكشف حركات الإشارة بشكل تفاعلي'
      : 'Explore sign animations interactively';

  // ── Settings ──────────────────────────────────────────────────────────────
  static String get settings => _ar ? 'الإعدادات' : 'Settings';
  static String get backend => _ar ? 'الخادم' : 'Backend';
  static String get baseUrl => _ar ? 'رابط الخادم' : 'Base URL';
  static String get testConnection => _ar ? 'اختبار الاتصال' : 'Test Connection';
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
  static String get recordHint =>
      _ar ? 'سجّل صوتك أدناه ثم اضغط ترجمة' : 'Record your voice below and tap Translate';
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
  static String get textIdleHint =>
      _ar ? 'اكتب نصاً أدناه ثم اضغط ترجمة' : 'Type text below and tap Translate';

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
  static String get generatedSpeech => _ar ? 'الكلام المُنشأ' : 'Generated Speech';
  static String translatedLabel(String text) =>
      _ar ? 'الترجمة: $text' : 'Translated: $text';
  static String get stopSpeech => _ar ? 'إيقاف الكلام' : 'Stop Speech';
  static String get playGeneratedSpeech =>
      _ar ? 'تشغيل الكلام' : 'Play Generated Speech';
  static String get videoRecordedOk =>
      _ar ? 'تم تسجيل الفيديو بنجاح!' : 'Video recorded successfully!';
  static String get videoLoadedOk =>
      _ar ? 'تم تحميل الفيديو بنجاح!' : 'Video loaded successfully!';
  static String get noCameraAvailable =>
      _ar ? 'لا توجد كاميرا على هذا الجهاز' : 'No camera available on this device';
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
}
