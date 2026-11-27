import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_text_ar.dart';
import 'app_text_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppText
/// returned by `AppText.of(context)`.
///
/// Applications need to include `AppText.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_text.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppText.localizationsDelegates,
///   supportedLocales: AppText.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppText.supportedLocales
/// property.
abstract class AppText {
  AppText(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppText of(BuildContext context) {
    return Localizations.of<AppText>(context, AppText)!;
  }

  static const LocalizationsDelegate<AppText> delegate = _AppTextDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @commonCancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get commonCancel;

  /// No description provided for @commonRetry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get commonRetry;

  /// No description provided for @commonClose.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get commonClose;

  /// No description provided for @commonLoading.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التحميل…'**
  String get commonLoading;

  /// No description provided for @commonNone.
  ///
  /// In ar, this message translates to:
  /// **'—'**
  String get commonNone;

  /// No description provided for @navHome.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get navHome;

  /// No description provided for @navLive.
  ///
  /// In ar, this message translates to:
  /// **'البث المباشر'**
  String get navLive;

  /// No description provided for @navMovies.
  ///
  /// In ar, this message translates to:
  /// **'الأفلام'**
  String get navMovies;

  /// No description provided for @navSeries.
  ///
  /// In ar, this message translates to:
  /// **'المسلسلات'**
  String get navSeries;

  /// No description provided for @navAccount.
  ///
  /// In ar, this message translates to:
  /// **'حسابي'**
  String get navAccount;

  /// No description provided for @kindLive.
  ///
  /// In ar, this message translates to:
  /// **'مباشر'**
  String get kindLive;

  /// No description provided for @kindMovie.
  ///
  /// In ar, this message translates to:
  /// **'فيلم'**
  String get kindMovie;

  /// No description provided for @kindSeries.
  ///
  /// In ar, this message translates to:
  /// **'مسلسل'**
  String get kindSeries;

  /// No description provided for @settingsSubscription.
  ///
  /// In ar, this message translates to:
  /// **'الاشتراك'**
  String get settingsSubscription;

  /// No description provided for @settingsContent.
  ///
  /// In ar, this message translates to:
  /// **'المحتوى'**
  String get settingsContent;

  /// No description provided for @settingsGeneral.
  ///
  /// In ar, this message translates to:
  /// **'عام'**
  String get settingsGeneral;

  /// No description provided for @settingsAbout.
  ///
  /// In ar, this message translates to:
  /// **'عن التطبيق'**
  String get settingsAbout;

  /// No description provided for @settingsLanguage.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get settingsLanguage;

  /// No description provided for @settingsVersion.
  ///
  /// In ar, this message translates to:
  /// **'الإصدار'**
  String get settingsVersion;

  /// No description provided for @settingsTelegramChannel.
  ///
  /// In ar, this message translates to:
  /// **'قناتنا على تلغرام'**
  String get settingsTelegramChannel;

  /// No description provided for @settingsTelegramAdmin.
  ///
  /// In ar, this message translates to:
  /// **'تواصل مع الأدمن'**
  String get settingsTelegramAdmin;

  /// No description provided for @settingsLogout.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get settingsLogout;

  /// No description provided for @settingsLinkFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر فتح الرابط'**
  String get settingsLinkFailed;

  /// No description provided for @settingsFetchFailedTapRetry.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الجلب — اضغط لإعادة المحاولة'**
  String get settingsFetchFailedTapRetry;

  /// No description provided for @settingsConnectedTo.
  ///
  /// In ar, this message translates to:
  /// **'متصل بـ {url}'**
  String settingsConnectedTo(String url);

  /// No description provided for @settingsDemoMode.
  ///
  /// In ar, this message translates to:
  /// **'وضع العرض (بيانات تجريبية) • الباك-إند غير مربوط'**
  String get settingsDemoMode;

  /// No description provided for @planExpiredOn.
  ///
  /// In ar, this message translates to:
  /// **'انتهى في {date}'**
  String planExpiredOn(String date);

  /// No description provided for @planRemaining.
  ///
  /// In ar, this message translates to:
  /// **'يتبقّى {days} • ينتهي {date}'**
  String planRemaining(String days, String date);

  /// No description provided for @planDays.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{يوم واحد} =2{يومان} few{{count} أيام} other{{count} يوماً}}'**
  String planDays(int count);

  /// No description provided for @subscriptionActive.
  ///
  /// In ar, this message translates to:
  /// **'اشتراك فعّال'**
  String get subscriptionActive;

  /// No description provided for @subscriptionExpired.
  ///
  /// In ar, this message translates to:
  /// **'اشتراك منتهٍ'**
  String get subscriptionExpired;

  /// No description provided for @syncAll.
  ///
  /// In ar, this message translates to:
  /// **'مزامنة الكل'**
  String get syncAll;

  /// No description provided for @syncing.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ المزامنة…'**
  String get syncing;

  /// No description provided for @syncingSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'يُعاد تحميل القنوات والأفلام والمسلسلات'**
  String get syncingSubtitle;

  /// No description provided for @syncLastAt.
  ///
  /// In ar, this message translates to:
  /// **'آخر مزامنة: {when}'**
  String syncLastAt(String when);

  /// No description provided for @syncDone.
  ///
  /// In ar, this message translates to:
  /// **'تمت مزامنة الكتالوج بالكامل ✅'**
  String get syncDone;

  /// No description provided for @syncFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّرت المزامنة: {error}'**
  String syncFailed(String error);

  /// No description provided for @syncNever.
  ///
  /// In ar, this message translates to:
  /// **'لم تتم بعد'**
  String get syncNever;

  /// No description provided for @agoNow.
  ///
  /// In ar, this message translates to:
  /// **'الآن'**
  String get agoNow;

  /// No description provided for @agoMinutes.
  ///
  /// In ar, this message translates to:
  /// **'قبل {count} دقيقة'**
  String agoMinutes(int count);

  /// No description provided for @agoHours.
  ///
  /// In ar, this message translates to:
  /// **'قبل {count} ساعة'**
  String agoHours(int count);

  /// No description provided for @agoDays.
  ///
  /// In ar, this message translates to:
  /// **'قبل {count} يوم'**
  String agoDays(int count);

  /// No description provided for @devicesTitle.
  ///
  /// In ar, this message translates to:
  /// **'الأجهزة المرتبطة'**
  String get devicesTitle;

  /// No description provided for @devicesThisDevice.
  ///
  /// In ar, this message translates to:
  /// **'هذا جهازك'**
  String get devicesThisDevice;

  /// No description provided for @devicesEvict.
  ///
  /// In ar, this message translates to:
  /// **'إخراج'**
  String get devicesEvict;

  /// No description provided for @devicesEvictTitle.
  ///
  /// In ar, this message translates to:
  /// **'إخراج الجهاز'**
  String get devicesEvictTitle;

  /// No description provided for @devicesEvictBody.
  ///
  /// In ar, this message translates to:
  /// **'سيُخرج «{name}» ويُسجَّل خروجه فوراً، ويتحرّر مقعده لجهاز آخر.'**
  String devicesEvictBody(String name);

  /// No description provided for @devicesEvicted.
  ///
  /// In ar, this message translates to:
  /// **'أُخرج «{name}» وتحرّر مقعده'**
  String devicesEvicted(String name);

  /// No description provided for @devicesEvictFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر إخراج الجهاز'**
  String get devicesEvictFailed;

  /// No description provided for @devicesNotFound.
  ///
  /// In ar, this message translates to:
  /// **'الجهاز غير موجود'**
  String get devicesNotFound;

  /// No description provided for @devicesFetchFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر جلب الأجهزة'**
  String get devicesFetchFailed;

  /// No description provided for @devicesOverLimit.
  ///
  /// In ar, this message translates to:
  /// **'تجاوزت حدّ خطتك — أخرج الأجهزة الزائدة'**
  String get devicesOverLimit;

  /// No description provided for @devicesOverLimitLong.
  ///
  /// In ar, this message translates to:
  /// **'لديك {count} أجهزة وخطتك تسمح بـ{max} فقط — أخرج الزائد'**
  String devicesOverLimitLong(int count, int max);

  /// No description provided for @devicesCountOfMax.
  ///
  /// In ar, this message translates to:
  /// **'{count} من {max} جهاز'**
  String devicesCountOfMax(int count, int max);

  /// No description provided for @devicesRegistered.
  ///
  /// In ar, this message translates to:
  /// **'{count} جهاز مسجّل'**
  String devicesRegistered(int count);

  /// No description provided for @devicesLastSeen.
  ///
  /// In ar, this message translates to:
  /// **'آخر نشاط: {when}'**
  String devicesLastSeen(String when);

  /// No description provided for @deviceFallbackName.
  ///
  /// In ar, this message translates to:
  /// **'جهاز'**
  String get deviceFallbackName;

  /// No description provided for @userFallback.
  ///
  /// In ar, this message translates to:
  /// **'مستخدم'**
  String get userFallback;

  /// No description provided for @authTagline.
  ///
  /// In ar, this message translates to:
  /// **'بثّ مباشر • أفلام • مسلسلات'**
  String get authTagline;

  /// No description provided for @authUsername.
  ///
  /// In ar, this message translates to:
  /// **'اسم المستخدم'**
  String get authUsername;

  /// No description provided for @authPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get authPassword;

  /// No description provided for @authLogin.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get authLogin;

  /// No description provided for @authDemoHint.
  ///
  /// In ar, this message translates to:
  /// **'وضع العرض: أدخل أي بيانات للمتابعة'**
  String get authDemoHint;

  /// No description provided for @authDeviceLimitTitle.
  ///
  /// In ar, this message translates to:
  /// **'أجهزتك المرتبطة — أخرج واحداً للمتابعة'**
  String get authDeviceLimitTitle;

  /// No description provided for @authEvict.
  ///
  /// In ar, this message translates to:
  /// **'أخرج'**
  String get authEvict;

  /// No description provided for @activateTitle.
  ///
  /// In ar, this message translates to:
  /// **'فعّل حسابك'**
  String get activateTitle;

  /// No description provided for @activateSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أدخل كود التفعيل لتشغيل اشتراكك'**
  String get activateSubtitle;

  /// No description provided for @activateCodeHint.
  ///
  /// In ar, this message translates to:
  /// **'كود التفعيل'**
  String get activateCodeHint;

  /// No description provided for @activateSubmit.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل'**
  String get activateSubmit;

  /// No description provided for @activateLater.
  ///
  /// In ar, this message translates to:
  /// **'لديّ كود لاحقاً'**
  String get activateLater;

  /// No description provided for @activateSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم التفعيل — اشتراكك فعّال الآن ✅'**
  String get activateSuccess;

  /// No description provided for @activateErrInvalid.
  ///
  /// In ar, this message translates to:
  /// **'الكود غير صحيح أو مستخدَم من قبل'**
  String get activateErrInvalid;

  /// No description provided for @activateErrThrottled.
  ///
  /// In ar, this message translates to:
  /// **'محاولات كثيرة — حاول بعد قليل'**
  String get activateErrThrottled;

  /// No description provided for @activateErrGeneric.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر التفعيل — حاول مجدداً'**
  String get activateErrGeneric;

  /// No description provided for @activateEmpty.
  ///
  /// In ar, this message translates to:
  /// **'أدخل الكود'**
  String get activateEmpty;

  /// No description provided for @activateFromSettings.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل بكود'**
  String get activateFromSettings;

  /// No description provided for @subscriptionNone.
  ///
  /// In ar, this message translates to:
  /// **'بلا اشتراك — فعّل بكود'**
  String get subscriptionNone;

  /// No description provided for @authCreateAccount.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب'**
  String get authCreateAccount;

  /// No description provided for @authNoAccount.
  ///
  /// In ar, this message translates to:
  /// **'ليس لديك حساب؟'**
  String get authNoAccount;

  /// No description provided for @authRegisterTitle.
  ///
  /// In ar, this message translates to:
  /// **'حساب جديد'**
  String get authRegisterTitle;

  /// No description provided for @authRegisterSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ حسابك وابدأ المشاهدة'**
  String get authRegisterSubtitle;

  /// No description provided for @authEmail.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get authEmail;

  /// No description provided for @authConfirmPassword.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد كلمة المرور'**
  String get authConfirmPassword;

  /// No description provided for @authRegisterSubmit.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء الحساب'**
  String get authRegisterSubmit;

  /// No description provided for @authHaveAccount.
  ///
  /// In ar, this message translates to:
  /// **'لديك حساب بالفعل؟'**
  String get authHaveAccount;

  /// No description provided for @authLoginInstead.
  ///
  /// In ar, this message translates to:
  /// **'سجّل الدخول'**
  String get authLoginInstead;

  /// No description provided for @authValEmailRequired.
  ///
  /// In ar, this message translates to:
  /// **'أدخل بريدك الإلكتروني'**
  String get authValEmailRequired;

  /// No description provided for @authValEmailInvalid.
  ///
  /// In ar, this message translates to:
  /// **'بريد إلكتروني غير صالح'**
  String get authValEmailInvalid;

  /// No description provided for @authValUsernameRequired.
  ///
  /// In ar, this message translates to:
  /// **'أدخل اسم المستخدم'**
  String get authValUsernameRequired;

  /// No description provided for @authValUsernameShort.
  ///
  /// In ar, this message translates to:
  /// **'اسم المستخدم قصير جداً'**
  String get authValUsernameShort;

  /// No description provided for @authValPasswordRequired.
  ///
  /// In ar, this message translates to:
  /// **'أدخل كلمة المرور'**
  String get authValPasswordRequired;

  /// No description provided for @authValPasswordShort.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور 8 أحرف على الأقل'**
  String get authValPasswordShort;

  /// No description provided for @authValPasswordMismatch.
  ///
  /// In ar, this message translates to:
  /// **'كلمتا المرور غير متطابقتين'**
  String get authValPasswordMismatch;

  /// No description provided for @authErrUsernameTaken.
  ///
  /// In ar, this message translates to:
  /// **'اسم المستخدم محجوز — اختر غيره'**
  String get authErrUsernameTaken;

  /// No description provided for @authErrEmailTaken.
  ///
  /// In ar, this message translates to:
  /// **'هذا البريد مسجّل مسبقاً'**
  String get authErrEmailTaken;

  /// No description provided for @authErrPasswordCommon.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور شائعة جداً — اختر أقوى منها'**
  String get authErrPasswordCommon;

  /// No description provided for @authErrPasswordNumeric.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور أرقام فقط — أضف أحرفاً'**
  String get authErrPasswordNumeric;

  /// No description provided for @authErrPasswordSimilar.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور تشبه اسمك أو بريدك'**
  String get authErrPasswordSimilar;

  /// No description provided for @authErrUsernameGeneric.
  ///
  /// In ar, this message translates to:
  /// **'اسم مستخدم غير مقبول'**
  String get authErrUsernameGeneric;

  /// No description provided for @authErrEmailGeneric.
  ///
  /// In ar, this message translates to:
  /// **'بريد إلكتروني غير مقبول'**
  String get authErrEmailGeneric;

  /// No description provided for @authErrPasswordGeneric.
  ///
  /// In ar, this message translates to:
  /// **'كلمة مرور غير مقبولة'**
  String get authErrPasswordGeneric;

  /// No description provided for @authErrorThrottled.
  ///
  /// In ar, this message translates to:
  /// **'محاولات كثيرة — حاول بعد قليل'**
  String get authErrorThrottled;

  /// No description provided for @authErrorRegisterFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر إنشاء الحساب — حاول مجدداً'**
  String get authErrorRegisterFailed;

  /// No description provided for @authErrorEmptyCredentials.
  ///
  /// In ar, this message translates to:
  /// **'أدخل اسم المستخدم وكلمة المرور'**
  String get authErrorEmptyCredentials;

  /// No description provided for @authErrorBadCredentials.
  ///
  /// In ar, this message translates to:
  /// **'اسم المستخدم أو كلمة المرور غير صحيحة'**
  String get authErrorBadCredentials;

  /// No description provided for @authErrorNetwork.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الاتصال بالخادم'**
  String get authErrorNetwork;

  /// No description provided for @authErrorDeviceLimit.
  ///
  /// In ar, this message translates to:
  /// **'بلغت الحدّ الأقصى للأجهزة — أخرج جهازاً للمتابعة'**
  String get authErrorDeviceLimit;

  /// No description provided for @authErrorGeneric.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تسجيل الدخول'**
  String get authErrorGeneric;

  /// No description provided for @homeLiveChannels.
  ///
  /// In ar, this message translates to:
  /// **'قنوات مباشرة'**
  String get homeLiveChannels;

  /// No description provided for @homeTrendingMovies.
  ///
  /// In ar, this message translates to:
  /// **'أفلام رائجة'**
  String get homeTrendingMovies;

  /// No description provided for @homeSelectedSeries.
  ///
  /// In ar, this message translates to:
  /// **'مسلسلات مختارة'**
  String get homeSelectedSeries;

  /// No description provided for @homePlay.
  ///
  /// In ar, this message translates to:
  /// **'تشغيل'**
  String get homePlay;

  /// No description provided for @homeDetails.
  ///
  /// In ar, this message translates to:
  /// **'التفاصيل'**
  String get homeDetails;

  /// No description provided for @searchScopeLive.
  ///
  /// In ar, this message translates to:
  /// **'القنوات'**
  String get searchScopeLive;

  /// No description provided for @searchHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث في {scope}'**
  String searchHint(String scope);

  /// No description provided for @searchNoResults.
  ///
  /// In ar, this message translates to:
  /// **'لا نتائج لـ «{query}» في {scope}'**
  String searchNoResults(String query, String scope);

  /// No description provided for @searchResults.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{نتيجة واحدة} =2{نتيجتان} few{{count} نتائج} many{{count} نتيجة} other{{count} نتيجة}} في {scope}'**
  String searchResults(int count, String scope);

  /// No description provided for @browseSeeMore.
  ///
  /// In ar, this message translates to:
  /// **'عرض المزيد'**
  String get browseSeeMore;

  /// No description provided for @browseSeeAll.
  ///
  /// In ar, this message translates to:
  /// **'عرض الكل'**
  String get browseSeeAll;

  /// No description provided for @browseLoadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل المحتوى — تحقّق من اتصالك'**
  String get browseLoadFailed;

  /// No description provided for @browseNoContent.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد محتوى'**
  String get browseNoContent;

  /// No description provided for @browseOther.
  ///
  /// In ar, this message translates to:
  /// **'أخرى'**
  String get browseOther;

  /// No description provided for @browseAllChannels.
  ///
  /// In ar, this message translates to:
  /// **'كل القنوات'**
  String get browseAllChannels;

  /// No description provided for @browseSearchCategories.
  ///
  /// In ar, this message translates to:
  /// **'ابحث في الفئات…'**
  String get browseSearchCategories;

  /// No description provided for @browseSearchChannels.
  ///
  /// In ar, this message translates to:
  /// **'ابحث في القنوات…'**
  String get browseSearchChannels;

  /// No description provided for @detailSeason.
  ///
  /// In ar, this message translates to:
  /// **'الموسم {number}'**
  String detailSeason(int number);

  /// No description provided for @detailLoadingEpisodes.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تحميل الحلقات…'**
  String get detailLoadingEpisodes;

  /// No description provided for @detailWatchNow.
  ///
  /// In ar, this message translates to:
  /// **'شاهد الآن'**
  String get detailWatchNow;

  /// No description provided for @detailPlayFirstEpisode.
  ///
  /// In ar, this message translates to:
  /// **'تشغيل الحلقة الأولى'**
  String get detailPlayFirstEpisode;

  /// No description provided for @detailPlay.
  ///
  /// In ar, this message translates to:
  /// **'تشغيل'**
  String get detailPlay;

  /// No description provided for @detailFavorites.
  ///
  /// In ar, this message translates to:
  /// **'المفضّلة'**
  String get detailFavorites;

  /// No description provided for @detailWatchParty.
  ///
  /// In ar, this message translates to:
  /// **'مشاهدة جماعية'**
  String get detailWatchParty;

  /// No description provided for @detailNowShowing.
  ///
  /// In ar, this message translates to:
  /// **'يُعرض الآن'**
  String get detailNowShowing;

  /// No description provided for @detailStory.
  ///
  /// In ar, this message translates to:
  /// **'القصّة'**
  String get detailStory;

  /// No description provided for @detailEpisodesError.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر جلب الحلقات'**
  String get detailEpisodesError;

  /// No description provided for @detailNoEpisodes.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد حلقات متاحة'**
  String get detailNoEpisodes;

  /// No description provided for @detailEpisodesCount.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, other{الحلقات ({count})}}'**
  String detailEpisodesCount(int count);

  /// No description provided for @detailEpisodeMinutes.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, other{{count} دقيقة}}'**
  String detailEpisodeMinutes(int count);

  /// No description provided for @badgeLive.
  ///
  /// In ar, this message translates to:
  /// **'مباشر'**
  String get badgeLive;

  /// No description provided for @playerLive.
  ///
  /// In ar, this message translates to:
  /// **'مباشر'**
  String get playerLive;

  /// No description provided for @playerDemoMode.
  ///
  /// In ar, this message translates to:
  /// **'وضع العرض: عيّنة عامة — البث الحقيقي يُفعَّل بتمرير HMAC_SECRET'**
  String get playerDemoMode;

  /// No description provided for @playerLiveStream.
  ///
  /// In ar, this message translates to:
  /// **'بثّ مباشر'**
  String get playerLiveStream;

  /// No description provided for @playerErrorTitle.
  ///
  /// In ar, this message translates to:
  /// **'الخادم لا يستجيب لهذا المحتوى'**
  String get playerErrorTitle;

  /// No description provided for @playerErrorAuthTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر التحقّق من جلستك'**
  String get playerErrorAuthTitle;

  /// No description provided for @playerErrorAuthBody.
  ///
  /// In ar, this message translates to:
  /// **'رفضت البوابة الطلب (جلسة منتهية أو توقيع غير مقبول).\nسجّل الخروج ثم الدخول من جديد.'**
  String get playerErrorAuthBody;

  /// No description provided for @playerErrorDemoBody.
  ///
  /// In ar, this message translates to:
  /// **'تحقّق من الاتصال بالإنترنت (عيّنة العرض).'**
  String get playerErrorDemoBody;

  /// No description provided for @playerErrorRealBody.
  ///
  /// In ar, this message translates to:
  /// **'فشلت 3 محاولات (البوابة تردّ 502 مؤقّتاً).\nجرّب مرّة أخرى بعد قليل أو اختر محتوى آخر.'**
  String get playerErrorRealBody;

  /// No description provided for @playerBack.
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get playerBack;

  /// No description provided for @voiceRoomTitle.
  ///
  /// In ar, this message translates to:
  /// **'غرفة صوتية'**
  String get voiceRoomTitle;

  /// No description provided for @voicePickAvatar.
  ///
  /// In ar, this message translates to:
  /// **'اختر صورتك'**
  String get voicePickAvatar;

  /// No description provided for @voiceEnterCodeHint.
  ///
  /// In ar, this message translates to:
  /// **'ادخل بكود الغرفة'**
  String get voiceEnterCodeHint;

  /// No description provided for @voiceJoin.
  ///
  /// In ar, this message translates to:
  /// **'دخول'**
  String get voiceJoin;

  /// No description provided for @voiceOr.
  ///
  /// In ar, this message translates to:
  /// **'أو'**
  String get voiceOr;

  /// No description provided for @voiceNewRoomNameHint.
  ///
  /// In ar, this message translates to:
  /// **'اسم الغرفة الجديدة'**
  String get voiceNewRoomNameHint;

  /// No description provided for @voiceCreateRoom.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء غرفة'**
  String get voiceCreateRoom;

  /// No description provided for @voiceWatchingNow.
  ///
  /// In ar, this message translates to:
  /// **'يشاهدون الآن'**
  String get voiceWatchingNow;

  /// No description provided for @voiceLive.
  ///
  /// In ar, this message translates to:
  /// **'مباشر'**
  String get voiceLive;

  /// No description provided for @voiceContentUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'هذا المحتوى غير متاح لديك'**
  String get voiceContentUnavailable;

  /// No description provided for @voiceUnfollow.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف المتابعة'**
  String get voiceUnfollow;

  /// No description provided for @voiceFollow.
  ///
  /// In ar, this message translates to:
  /// **'تابِعه'**
  String get voiceFollow;

  /// No description provided for @voiceAdmin.
  ///
  /// In ar, this message translates to:
  /// **'أدمن'**
  String get voiceAdmin;

  /// No description provided for @voiceMuteMic.
  ///
  /// In ar, this message translates to:
  /// **'كتم المايك'**
  String get voiceMuteMic;

  /// No description provided for @voiceUnmuteMic.
  ///
  /// In ar, this message translates to:
  /// **'فتح المايك'**
  String get voiceUnmuteMic;

  /// No description provided for @voiceEndRoom.
  ///
  /// In ar, this message translates to:
  /// **'إنهاء الغرفة'**
  String get voiceEndRoom;

  /// No description provided for @voiceLeave.
  ///
  /// In ar, this message translates to:
  /// **'خروج'**
  String get voiceLeave;

  /// No description provided for @voiceCode.
  ///
  /// In ar, this message translates to:
  /// **'الكود'**
  String get voiceCode;

  /// No description provided for @voiceCodeCopied.
  ///
  /// In ar, this message translates to:
  /// **'نُسخ كود الغرفة'**
  String get voiceCodeCopied;

  /// No description provided for @voiceUnknownInitial.
  ///
  /// In ar, this message translates to:
  /// **'؟'**
  String get voiceUnknownInitial;

  /// No description provided for @voiceYouSuffix.
  ///
  /// In ar, this message translates to:
  /// **'{name} (أنت)'**
  String voiceYouSuffix(String name);

  /// No description provided for @voiceKickConfirmTitle.
  ///
  /// In ar, this message translates to:
  /// **'طرد نهائي'**
  String get voiceKickConfirmTitle;

  /// No description provided for @voiceKickConfirmBody.
  ///
  /// In ar, this message translates to:
  /// **'سيُطرد «{name}» نهائياً ولن يستطيع العودة لهذه الغرفة.'**
  String voiceKickConfirmBody(String name);

  /// No description provided for @voiceKick.
  ///
  /// In ar, this message translates to:
  /// **'طرد'**
  String get voiceKick;

  /// No description provided for @voiceErrInvalidResponse.
  ///
  /// In ar, this message translates to:
  /// **'استجابة غير صالحة من الخادم'**
  String get voiceErrInvalidResponse;

  /// No description provided for @voiceErrNetwork.
  ///
  /// In ar, this message translates to:
  /// **'فشل الاتصال بالخادم'**
  String get voiceErrNetwork;

  /// No description provided for @voiceErrKicked.
  ///
  /// In ar, this message translates to:
  /// **'أنت مطرود من هذه الغرفة'**
  String get voiceErrKicked;

  /// No description provided for @voiceErrNotFound.
  ///
  /// In ar, this message translates to:
  /// **'الغرفة غير موجودة'**
  String get voiceErrNotFound;

  /// No description provided for @voiceErrUnreachable.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الوصول للغرفة'**
  String get voiceErrUnreachable;

  /// No description provided for @voiceErrJoinFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الدخول للغرفة'**
  String get voiceErrJoinFailed;

  /// No description provided for @voiceErrMicDenied.
  ///
  /// In ar, this message translates to:
  /// **'إذن المايكروفون مرفوض'**
  String get voiceErrMicDenied;
}

class _AppTextDelegate extends LocalizationsDelegate<AppText> {
  const _AppTextDelegate();

  @override
  Future<AppText> load(Locale locale) {
    return SynchronousFuture<AppText>(lookupAppText(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppTextDelegate old) => false;
}

AppText lookupAppText(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppTextAr();
    case 'en':
      return AppTextEn();
  }

  throw FlutterError(
    'AppText.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
