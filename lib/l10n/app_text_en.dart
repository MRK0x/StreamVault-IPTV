// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_text.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppTextEn extends AppText {
  AppTextEn([String locale = 'en']) : super(locale);

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonClose => 'Close';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get commonNone => '—';

  @override
  String get navHome => 'Home';

  @override
  String get navLive => 'Live TV';

  @override
  String get navMovies => 'Movies';

  @override
  String get navSeries => 'Series';

  @override
  String get navAccount => 'Account';

  @override
  String get kindLive => 'Live';

  @override
  String get kindMovie => 'Movie';

  @override
  String get kindSeries => 'Series';

  @override
  String get settingsSubscription => 'Subscription';

  @override
  String get settingsContent => 'Content';

  @override
  String get settingsGeneral => 'General';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsTelegramChannel => 'Our Telegram channel';

  @override
  String get settingsTelegramAdmin => 'Contact the admin';

  @override
  String get settingsLogout => 'Log out';

  @override
  String get settingsLinkFailed => 'Couldn\'t open the link';

  @override
  String get settingsFetchFailedTapRetry => 'Couldn\'t load — tap to retry';

  @override
  String settingsConnectedTo(String url) {
    return 'Connected to $url';
  }

  @override
  String get settingsDemoMode =>
      'Demo mode (sample data) • backend not connected';

  @override
  String planExpiredOn(String date) {
    return 'Expired on $date';
  }

  @override
  String planRemaining(String days, String date) {
    return '$days left • expires $date';
  }

  @override
  String planDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get subscriptionActive => 'Subscription active';

  @override
  String get subscriptionExpired => 'Subscription expired';

  @override
  String get syncAll => 'Sync everything';

  @override
  String get syncing => 'Syncing…';

  @override
  String get syncingSubtitle => 'Reloading channels, movies and series';

  @override
  String syncLastAt(String when) {
    return 'Last sync: $when';
  }

  @override
  String get syncDone => 'Catalog fully synced ✅';

  @override
  String syncFailed(String error) {
    return 'Sync failed: $error';
  }

  @override
  String get syncNever => 'Never';

  @override
  String get agoNow => 'Just now';

  @override
  String agoMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String agoHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String agoDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get devicesTitle => 'Linked devices';

  @override
  String get devicesThisDevice => 'This device';

  @override
  String get devicesEvict => 'Remove';

  @override
  String get devicesEvictTitle => 'Remove device';

  @override
  String devicesEvictBody(String name) {
    return '“$name” will be signed out immediately and its slot freed for another device.';
  }

  @override
  String devicesEvicted(String name) {
    return '“$name” was removed and its slot freed';
  }

  @override
  String get devicesEvictFailed => 'Couldn\'t remove the device';

  @override
  String get devicesNotFound => 'Device not found';

  @override
  String get devicesFetchFailed => 'Couldn\'t load devices';

  @override
  String get devicesOverLimit =>
      'Over your plan\'s limit — remove the extra devices';

  @override
  String devicesOverLimitLong(int count, int max) {
    return 'You have $count devices but your plan allows only $max — remove the extras';
  }

  @override
  String devicesCountOfMax(int count, int max) {
    return '$count of $max devices';
  }

  @override
  String devicesRegistered(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count devices registered',
      one: '1 device registered',
    );
    return '$_temp0';
  }

  @override
  String devicesLastSeen(String when) {
    return 'Last active: $when';
  }

  @override
  String get deviceFallbackName => 'Device';

  @override
  String get userFallback => 'User';

  @override
  String get authTagline => 'Live TV • Movies • Series';

  @override
  String get authUsername => 'Username';

  @override
  String get authPassword => 'Password';

  @override
  String get authLogin => 'Sign In';

  @override
  String get authDemoHint => 'Demo mode: enter any credentials to continue';

  @override
  String get authDeviceLimitTitle =>
      'Your linked devices — sign one out to continue';

  @override
  String get authEvict => 'Sign out';

  @override
  String get activateTitle => 'Activate your account';

  @override
  String get activateSubtitle =>
      'Enter your activation code to start your subscription';

  @override
  String get activateCodeHint => 'Activation code';

  @override
  String get activateSubmit => 'Activate';

  @override
  String get activateLater => 'I\'ll add a code later';

  @override
  String get activateSuccess => 'Activated — your subscription is live ✅';

  @override
  String get activateErrInvalid => 'Invalid or already-used code';

  @override
  String get activateErrThrottled => 'Too many attempts — try again shortly';

  @override
  String get activateErrGeneric => 'Couldn\'t activate — try again';

  @override
  String get activateEmpty => 'Enter the code';

  @override
  String get activateFromSettings => 'Activate with a code';

  @override
  String get subscriptionNone => 'No subscription — activate with a code';

  @override
  String get authCreateAccount => 'Create account';

  @override
  String get authNoAccount => 'Don\'t have an account?';

  @override
  String get authRegisterTitle => 'New account';

  @override
  String get authRegisterSubtitle => 'Create your account and start watching';

  @override
  String get authEmail => 'Email';

  @override
  String get authConfirmPassword => 'Confirm password';

  @override
  String get authRegisterSubmit => 'Create account';

  @override
  String get authHaveAccount => 'Already have an account?';

  @override
  String get authLoginInstead => 'Sign in';

  @override
  String get authValEmailRequired => 'Enter your email';

  @override
  String get authValEmailInvalid => 'Invalid email address';

  @override
  String get authValUsernameRequired => 'Enter a username';

  @override
  String get authValUsernameShort => 'Username is too short';

  @override
  String get authValPasswordRequired => 'Enter a password';

  @override
  String get authValPasswordShort => 'Password must be at least 8 characters';

  @override
  String get authValPasswordMismatch => 'Passwords don\'t match';

  @override
  String get authErrUsernameTaken => 'Username is taken — pick another';

  @override
  String get authErrEmailTaken => 'This email is already registered';

  @override
  String get authErrPasswordCommon =>
      'Password is too common — pick a stronger one';

  @override
  String get authErrPasswordNumeric => 'Password is all numbers — add letters';

  @override
  String get authErrPasswordSimilar =>
      'Password is too similar to your name or email';

  @override
  String get authErrUsernameGeneric => 'Username not accepted';

  @override
  String get authErrEmailGeneric => 'Email not accepted';

  @override
  String get authErrPasswordGeneric => 'Password not accepted';

  @override
  String get authErrorThrottled => 'Too many attempts — try again shortly';

  @override
  String get authErrorRegisterFailed =>
      'Couldn\'t create the account — try again';

  @override
  String get authErrorEmptyCredentials => 'Enter your username and password';

  @override
  String get authErrorBadCredentials => 'Incorrect username or password';

  @override
  String get authErrorNetwork => 'Couldn\'t reach the server';

  @override
  String get authErrorDeviceLimit =>
      'You\'ve reached your device limit — sign one out to continue';

  @override
  String get authErrorGeneric => 'Couldn\'t sign in';

  @override
  String get homeLiveChannels => 'Live Channels';

  @override
  String get homeTrendingMovies => 'Trending Movies';

  @override
  String get homeSelectedSeries => 'Featured Series';

  @override
  String get homePlay => 'Play';

  @override
  String get homeDetails => 'Details';

  @override
  String get searchScopeLive => 'Channels';

  @override
  String searchHint(String scope) {
    return 'Search in $scope';
  }

  @override
  String searchNoResults(String query, String scope) {
    return 'No results for «$query» in $scope';
  }

  @override
  String searchResults(int count, String scope) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '1 result',
    );
    return '$_temp0 in $scope';
  }

  @override
  String get browseSeeMore => 'See More';

  @override
  String get browseSeeAll => 'See All';

  @override
  String get browseLoadFailed =>
      'Couldn\'t load content — check your connection';

  @override
  String get browseNoContent => 'No content';

  @override
  String get browseOther => 'Other';

  @override
  String get browseAllChannels => 'All Channels';

  @override
  String get browseSearchCategories => 'Search categories…';

  @override
  String get browseSearchChannels => 'Search channels…';

  @override
  String detailSeason(int number) {
    return 'Season $number';
  }

  @override
  String get detailLoadingEpisodes => 'Loading episodes…';

  @override
  String get detailWatchNow => 'Watch now';

  @override
  String get detailPlayFirstEpisode => 'Play first episode';

  @override
  String get detailPlay => 'Play';

  @override
  String get detailFavorites => 'Favorites';

  @override
  String get detailWatchParty => 'Watch party';

  @override
  String get detailNowShowing => 'Now showing';

  @override
  String get detailStory => 'Story';

  @override
  String get detailEpisodesError => 'Couldn\'t load episodes';

  @override
  String get detailNoEpisodes => 'No episodes available';

  @override
  String detailEpisodesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Episodes ($count)',
    );
    return '$_temp0';
  }

  @override
  String detailEpisodeMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String get badgeLive => 'Live';

  @override
  String get playerLive => 'Live';

  @override
  String get playerDemoMode =>
      'Demo mode: public sample — real streaming is enabled by passing HMAC_SECRET';

  @override
  String get playerLiveStream => 'Live';

  @override
  String get playerErrorTitle =>
      'The server isn\'t responding for this content';

  @override
  String get playerErrorAuthTitle => 'Couldn\'t verify your session';

  @override
  String get playerErrorAuthBody =>
      'The gateway rejected the request (expired session or invalid signature).\nSign out and sign back in.';

  @override
  String get playerErrorDemoBody =>
      'Check your internet connection (demo sample).';

  @override
  String get playerErrorRealBody =>
      '3 attempts failed (the gateway is returning a temporary 502).\nTry again shortly or pick different content.';

  @override
  String get playerBack => 'Back';

  @override
  String get voiceRoomTitle => 'Voice Room';

  @override
  String get voicePickAvatar => 'Choose your avatar';

  @override
  String get voiceEnterCodeHint => 'Enter room code';

  @override
  String get voiceJoin => 'Join';

  @override
  String get voiceOr => 'or';

  @override
  String get voiceNewRoomNameHint => 'New room name';

  @override
  String get voiceCreateRoom => 'Create Room';

  @override
  String get voiceWatchingNow => 'Watching now';

  @override
  String get voiceLive => 'Live';

  @override
  String get voiceContentUnavailable => 'This content isn\'t available to you';

  @override
  String get voiceUnfollow => 'Unfollow';

  @override
  String get voiceFollow => 'Follow';

  @override
  String get voiceAdmin => 'Admin';

  @override
  String get voiceMuteMic => 'Mute mic';

  @override
  String get voiceUnmuteMic => 'Unmute mic';

  @override
  String get voiceEndRoom => 'End room';

  @override
  String get voiceLeave => 'Leave';

  @override
  String get voiceCode => 'Code';

  @override
  String get voiceCodeCopied => 'Room code copied';

  @override
  String get voiceUnknownInitial => '?';

  @override
  String voiceYouSuffix(String name) {
    return '$name (you)';
  }

  @override
  String get voiceKickConfirmTitle => 'Remove permanently';

  @override
  String voiceKickConfirmBody(String name) {
    return '«$name» will be removed permanently and won\'t be able to rejoin this room.';
  }

  @override
  String get voiceKick => 'Remove';

  @override
  String get voiceErrInvalidResponse => 'Invalid response from the server';

  @override
  String get voiceErrNetwork => 'Connection to the server failed';

  @override
  String get voiceErrKicked => 'You\'ve been removed from this room';

  @override
  String get voiceErrNotFound => 'Room not found';

  @override
  String get voiceErrUnreachable => 'Couldn\'t reach the room';

  @override
  String get voiceErrJoinFailed => 'Couldn\'t join the room';

  @override
  String get voiceErrMicDenied => 'Microphone permission denied';
}
