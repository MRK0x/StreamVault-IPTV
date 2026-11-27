// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_text.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppTextAr extends AppText {
  AppTextAr([String locale = 'ar']) : super(locale);

  @override
  String get commonCancel => 'إلغاء';

  @override
  String get commonRetry => 'إعادة المحاولة';

  @override
  String get commonClose => 'إغلاق';

  @override
  String get commonLoading => 'جارٍ التحميل…';

  @override
  String get commonNone => '—';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navLive => 'البث المباشر';

  @override
  String get navMovies => 'الأفلام';

  @override
  String get navSeries => 'المسلسلات';

  @override
  String get navAccount => 'حسابي';

  @override
  String get kindLive => 'مباشر';

  @override
  String get kindMovie => 'فيلم';

  @override
  String get kindSeries => 'مسلسل';

  @override
  String get settingsSubscription => 'الاشتراك';

  @override
  String get settingsContent => 'المحتوى';

  @override
  String get settingsGeneral => 'عام';

  @override
  String get settingsAbout => 'عن التطبيق';

  @override
  String get settingsLanguage => 'اللغة';

  @override
  String get settingsVersion => 'الإصدار';

  @override
  String get settingsTelegramChannel => 'قناتنا على تلغرام';

  @override
  String get settingsTelegramAdmin => 'تواصل مع الأدمن';

  @override
  String get settingsLogout => 'تسجيل الخروج';

  @override
  String get settingsLinkFailed => 'تعذّر فتح الرابط';

  @override
  String get settingsFetchFailedTapRetry =>
      'تعذّر الجلب — اضغط لإعادة المحاولة';

  @override
  String settingsConnectedTo(String url) {
    return 'متصل بـ $url';
  }

  @override
  String get settingsDemoMode =>
      'وضع العرض (بيانات تجريبية) • الباك-إند غير مربوط';

  @override
  String planExpiredOn(String date) {
    return 'انتهى في $date';
  }

  @override
  String planRemaining(String days, String date) {
    return 'يتبقّى $days • ينتهي $date';
  }

  @override
  String planDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count يوماً',
      few: '$count أيام',
      two: 'يومان',
      one: 'يوم واحد',
    );
    return '$_temp0';
  }

  @override
  String get subscriptionActive => 'اشتراك فعّال';

  @override
  String get subscriptionExpired => 'اشتراك منتهٍ';

  @override
  String get syncAll => 'مزامنة الكل';

  @override
  String get syncing => 'جارٍ المزامنة…';

  @override
  String get syncingSubtitle => 'يُعاد تحميل القنوات والأفلام والمسلسلات';

  @override
  String syncLastAt(String when) {
    return 'آخر مزامنة: $when';
  }

  @override
  String get syncDone => 'تمت مزامنة الكتالوج بالكامل ✅';

  @override
  String syncFailed(String error) {
    return 'تعذّرت المزامنة: $error';
  }

  @override
  String get syncNever => 'لم تتم بعد';

  @override
  String get agoNow => 'الآن';

  @override
  String agoMinutes(int count) {
    return 'قبل $count دقيقة';
  }

  @override
  String agoHours(int count) {
    return 'قبل $count ساعة';
  }

  @override
  String agoDays(int count) {
    return 'قبل $count يوم';
  }

  @override
  String get devicesTitle => 'الأجهزة المرتبطة';

  @override
  String get devicesThisDevice => 'هذا جهازك';

  @override
  String get devicesEvict => 'إخراج';

  @override
  String get devicesEvictTitle => 'إخراج الجهاز';

  @override
  String devicesEvictBody(String name) {
    return 'سيُخرج «$name» ويُسجَّل خروجه فوراً، ويتحرّر مقعده لجهاز آخر.';
  }

  @override
  String devicesEvicted(String name) {
    return 'أُخرج «$name» وتحرّر مقعده';
  }

  @override
  String get devicesEvictFailed => 'تعذّر إخراج الجهاز';

  @override
  String get devicesNotFound => 'الجهاز غير موجود';

  @override
  String get devicesFetchFailed => 'تعذّر جلب الأجهزة';

  @override
  String get devicesOverLimit => 'تجاوزت حدّ خطتك — أخرج الأجهزة الزائدة';

  @override
  String devicesOverLimitLong(int count, int max) {
    return 'لديك $count أجهزة وخطتك تسمح بـ$max فقط — أخرج الزائد';
  }

  @override
  String devicesCountOfMax(int count, int max) {
    return '$count من $max جهاز';
  }

  @override
  String devicesRegistered(int count) {
    return '$count جهاز مسجّل';
  }

  @override
  String devicesLastSeen(String when) {
    return 'آخر نشاط: $when';
  }

  @override
  String get deviceFallbackName => 'جهاز';

  @override
  String get userFallback => 'مستخدم';

  @override
  String get authTagline => 'بثّ مباشر • أفلام • مسلسلات';

  @override
  String get authUsername => 'اسم المستخدم';

  @override
  String get authPassword => 'كلمة المرور';

  @override
  String get authLogin => 'تسجيل الدخول';

  @override
  String get authDemoHint => 'وضع العرض: أدخل أي بيانات للمتابعة';

  @override
  String get authDeviceLimitTitle => 'أجهزتك المرتبطة — أخرج واحداً للمتابعة';

  @override
  String get authEvict => 'أخرج';

  @override
  String get activateTitle => 'فعّل حسابك';

  @override
  String get activateSubtitle => 'أدخل كود التفعيل لتشغيل اشتراكك';

  @override
  String get activateCodeHint => 'كود التفعيل';

  @override
  String get activateSubmit => 'تفعيل';

  @override
  String get activateLater => 'لديّ كود لاحقاً';

  @override
  String get activateSuccess => 'تم التفعيل — اشتراكك فعّال الآن ✅';

  @override
  String get activateErrInvalid => 'الكود غير صحيح أو مستخدَم من قبل';

  @override
  String get activateErrThrottled => 'محاولات كثيرة — حاول بعد قليل';

  @override
  String get activateErrGeneric => 'تعذّر التفعيل — حاول مجدداً';

  @override
  String get activateEmpty => 'أدخل الكود';

  @override
  String get activateFromSettings => 'تفعيل بكود';

  @override
  String get subscriptionNone => 'بلا اشتراك — فعّل بكود';

  @override
  String get authCreateAccount => 'إنشاء حساب';

  @override
  String get authNoAccount => 'ليس لديك حساب؟';

  @override
  String get authRegisterTitle => 'حساب جديد';

  @override
  String get authRegisterSubtitle => 'أنشئ حسابك وابدأ المشاهدة';

  @override
  String get authEmail => 'البريد الإلكتروني';

  @override
  String get authConfirmPassword => 'تأكيد كلمة المرور';

  @override
  String get authRegisterSubmit => 'إنشاء الحساب';

  @override
  String get authHaveAccount => 'لديك حساب بالفعل؟';

  @override
  String get authLoginInstead => 'سجّل الدخول';

  @override
  String get authValEmailRequired => 'أدخل بريدك الإلكتروني';

  @override
  String get authValEmailInvalid => 'بريد إلكتروني غير صالح';

  @override
  String get authValUsernameRequired => 'أدخل اسم المستخدم';

  @override
  String get authValUsernameShort => 'اسم المستخدم قصير جداً';

  @override
  String get authValPasswordRequired => 'أدخل كلمة المرور';

  @override
  String get authValPasswordShort => 'كلمة المرور 8 أحرف على الأقل';

  @override
  String get authValPasswordMismatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get authErrUsernameTaken => 'اسم المستخدم محجوز — اختر غيره';

  @override
  String get authErrEmailTaken => 'هذا البريد مسجّل مسبقاً';

  @override
  String get authErrPasswordCommon => 'كلمة المرور شائعة جداً — اختر أقوى منها';

  @override
  String get authErrPasswordNumeric => 'كلمة المرور أرقام فقط — أضف أحرفاً';

  @override
  String get authErrPasswordSimilar => 'كلمة المرور تشبه اسمك أو بريدك';

  @override
  String get authErrUsernameGeneric => 'اسم مستخدم غير مقبول';

  @override
  String get authErrEmailGeneric => 'بريد إلكتروني غير مقبول';

  @override
  String get authErrPasswordGeneric => 'كلمة مرور غير مقبولة';

  @override
  String get authErrorThrottled => 'محاولات كثيرة — حاول بعد قليل';

  @override
  String get authErrorRegisterFailed => 'تعذّر إنشاء الحساب — حاول مجدداً';

  @override
  String get authErrorEmptyCredentials => 'أدخل اسم المستخدم وكلمة المرور';

  @override
  String get authErrorBadCredentials => 'اسم المستخدم أو كلمة المرور غير صحيحة';

  @override
  String get authErrorNetwork => 'تعذّر الاتصال بالخادم';

  @override
  String get authErrorDeviceLimit =>
      'بلغت الحدّ الأقصى للأجهزة — أخرج جهازاً للمتابعة';

  @override
  String get authErrorGeneric => 'تعذّر تسجيل الدخول';

  @override
  String get homeLiveChannels => 'قنوات مباشرة';

  @override
  String get homeTrendingMovies => 'أفلام رائجة';

  @override
  String get homeSelectedSeries => 'مسلسلات مختارة';

  @override
  String get homePlay => 'تشغيل';

  @override
  String get homeDetails => 'التفاصيل';

  @override
  String get searchScopeLive => 'القنوات';

  @override
  String searchHint(String scope) {
    return 'ابحث في $scope';
  }

  @override
  String searchNoResults(String query, String scope) {
    return 'لا نتائج لـ «$query» في $scope';
  }

  @override
  String searchResults(int count, String scope) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count نتيجة',
      many: '$count نتيجة',
      few: '$count نتائج',
      two: 'نتيجتان',
      one: 'نتيجة واحدة',
    );
    return '$_temp0 في $scope';
  }

  @override
  String get browseSeeMore => 'عرض المزيد';

  @override
  String get browseSeeAll => 'عرض الكل';

  @override
  String get browseLoadFailed => 'تعذّر تحميل المحتوى — تحقّق من اتصالك';

  @override
  String get browseNoContent => 'لا يوجد محتوى';

  @override
  String get browseOther => 'أخرى';

  @override
  String get browseAllChannels => 'كل القنوات';

  @override
  String get browseSearchCategories => 'ابحث في الفئات…';

  @override
  String get browseSearchChannels => 'ابحث في القنوات…';

  @override
  String detailSeason(int number) {
    return 'الموسم $number';
  }

  @override
  String get detailLoadingEpisodes => 'جارٍ تحميل الحلقات…';

  @override
  String get detailWatchNow => 'شاهد الآن';

  @override
  String get detailPlayFirstEpisode => 'تشغيل الحلقة الأولى';

  @override
  String get detailPlay => 'تشغيل';

  @override
  String get detailFavorites => 'المفضّلة';

  @override
  String get detailWatchParty => 'مشاهدة جماعية';

  @override
  String get detailNowShowing => 'يُعرض الآن';

  @override
  String get detailStory => 'القصّة';

  @override
  String get detailEpisodesError => 'تعذّر جلب الحلقات';

  @override
  String get detailNoEpisodes => 'لا توجد حلقات متاحة';

  @override
  String detailEpisodesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'الحلقات ($count)',
    );
    return '$_temp0';
  }

  @override
  String detailEpisodeMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count دقيقة',
    );
    return '$_temp0';
  }

  @override
  String get badgeLive => 'مباشر';

  @override
  String get playerLive => 'مباشر';

  @override
  String get playerDemoMode =>
      'وضع العرض: عيّنة عامة — البث الحقيقي يُفعَّل بتمرير HMAC_SECRET';

  @override
  String get playerLiveStream => 'بثّ مباشر';

  @override
  String get playerErrorTitle => 'الخادم لا يستجيب لهذا المحتوى';

  @override
  String get playerErrorAuthTitle => 'تعذّر التحقّق من جلستك';

  @override
  String get playerErrorAuthBody =>
      'رفضت البوابة الطلب (جلسة منتهية أو توقيع غير مقبول).\nسجّل الخروج ثم الدخول من جديد.';

  @override
  String get playerErrorDemoBody => 'تحقّق من الاتصال بالإنترنت (عيّنة العرض).';

  @override
  String get playerErrorRealBody =>
      'فشلت 3 محاولات (البوابة تردّ 502 مؤقّتاً).\nجرّب مرّة أخرى بعد قليل أو اختر محتوى آخر.';

  @override
  String get playerBack => 'رجوع';

  @override
  String get voiceRoomTitle => 'غرفة صوتية';

  @override
  String get voicePickAvatar => 'اختر صورتك';

  @override
  String get voiceEnterCodeHint => 'ادخل بكود الغرفة';

  @override
  String get voiceJoin => 'دخول';

  @override
  String get voiceOr => 'أو';

  @override
  String get voiceNewRoomNameHint => 'اسم الغرفة الجديدة';

  @override
  String get voiceCreateRoom => 'إنشاء غرفة';

  @override
  String get voiceWatchingNow => 'يشاهدون الآن';

  @override
  String get voiceLive => 'مباشر';

  @override
  String get voiceContentUnavailable => 'هذا المحتوى غير متاح لديك';

  @override
  String get voiceUnfollow => 'إيقاف المتابعة';

  @override
  String get voiceFollow => 'تابِعه';

  @override
  String get voiceAdmin => 'أدمن';

  @override
  String get voiceMuteMic => 'كتم المايك';

  @override
  String get voiceUnmuteMic => 'فتح المايك';

  @override
  String get voiceEndRoom => 'إنهاء الغرفة';

  @override
  String get voiceLeave => 'خروج';

  @override
  String get voiceCode => 'الكود';

  @override
  String get voiceCodeCopied => 'نُسخ كود الغرفة';

  @override
  String get voiceUnknownInitial => '؟';

  @override
  String voiceYouSuffix(String name) {
    return '$name (أنت)';
  }

  @override
  String get voiceKickConfirmTitle => 'طرد نهائي';

  @override
  String voiceKickConfirmBody(String name) {
    return 'سيُطرد «$name» نهائياً ولن يستطيع العودة لهذه الغرفة.';
  }

  @override
  String get voiceKick => 'طرد';

  @override
  String get voiceErrInvalidResponse => 'استجابة غير صالحة من الخادم';

  @override
  String get voiceErrNetwork => 'فشل الاتصال بالخادم';

  @override
  String get voiceErrKicked => 'أنت مطرود من هذه الغرفة';

  @override
  String get voiceErrNotFound => 'الغرفة غير موجودة';

  @override
  String get voiceErrUnreachable => 'تعذّر الوصول للغرفة';

  @override
  String get voiceErrJoinFailed => 'تعذّر الدخول للغرفة';

  @override
  String get voiceErrMicDenied => 'إذن المايكروفون مرفوض';
}
