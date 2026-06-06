import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_sv.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'arb/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('nl'),
    Locale('pl'),
    Locale('pt'),
    Locale('ru'),
    Locale('sv'),
    Locale('tr'),
    Locale('zh'),
  ];

  /// Text shown in the AppDrawer
  ///
  /// In en, this message translates to:
  /// **'Your Music Loop Station'**
  String get appSubtitle;

  /// Title for user settings section
  ///
  /// In en, this message translates to:
  /// **'User Settings'**
  String get userSettings;

  /// Label for the language selector in the drawer
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Option in the language picker to follow the device language
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get systemDefault;

  /// No description provided for @cancelSubscription.
  ///
  /// In en, this message translates to:
  /// **'Cancel Subscription'**
  String get cancelSubscription;

  /// No description provided for @buyRepeatLabPro.
  ///
  /// In en, this message translates to:
  /// **'Buy RepeatLab Pro'**
  String get buyRepeatLabPro;

  /// No description provided for @improveTheApp.
  ///
  /// In en, this message translates to:
  /// **'Improve the App'**
  String get improveTheApp;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback/Bugs'**
  String get feedback;

  /// No description provided for @rateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate App'**
  String get rateApp;

  /// No description provided for @legals.
  ///
  /// In en, this message translates to:
  /// **'Legals'**
  String get legals;

  /// No description provided for @dataProtection.
  ///
  /// In en, this message translates to:
  /// **'Data Protection'**
  String get dataProtection;

  /// No description provided for @legalNotices.
  ///
  /// In en, this message translates to:
  /// **'Legal Notices'**
  String get legalNotices;

  /// No description provided for @licenses.
  ///
  /// In en, this message translates to:
  /// **'Licenses'**
  String get licenses;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @informationWeCollect.
  ///
  /// In en, this message translates to:
  /// **'Information We Collect'**
  String get informationWeCollect;

  /// No description provided for @informationWeCollectSummary.
  ///
  /// In en, this message translates to:
  /// **'Your privacy is important to us. This Privacy Policy outlines how we collect, use, and protect your information when you use our mobile application (the \'App\'), which is available on iOS and Android platforms. This policy is compliant with the General Data Protection Regulation (GDPR).\n\nEffective Date: 17. July 2025'**
  String get informationWeCollectSummary;

  /// No description provided for @informationWeCollectDescription.
  ///
  /// In en, this message translates to:
  /// **'• Personal Information: Information you provide to us, such as your email address when submitting feedback via Wiredash.\n• Payment Information: Data related to in-app purchases and subscriptions, processed by RevenueCat.\n• Crash Logs: Information about app errors and crashes, collected through Sentry.\n• Usage Statistics: Usage data to help us improve the app.\n• Heatmaps & Session Recording: Analytics data to help us improve your experience through Microsoft Clarity.'**
  String get informationWeCollectDescription;

  /// No description provided for @dataController.
  ///
  /// In en, this message translates to:
  /// **'Data Controller'**
  String get dataController;

  /// No description provided for @dataControllerDescription.
  ///
  /// In en, this message translates to:
  /// **'The data controller responsible for your information is:\n\nVerena Zaiser\nReichenbachstr. 17\n70372 Stuttgart\n\nEmail: support@repeatlab.de'**
  String get dataControllerDescription;

  /// No description provided for @legalBasisForProcessing.
  ///
  /// In en, this message translates to:
  /// **'Legal Basis for Processing'**
  String get legalBasisForProcessing;

  /// No description provided for @legalBasisForProcessingDescription.
  ///
  /// In en, this message translates to:
  /// **'We process your data based on the following legal bases:\n\n• Your consent for feedback submissions via Wiredash and app analytics.\n• Performance of a contract for processing payments and managing subscriptions through RevenueCat.\n• Our legitimate interest in ensuring the App operates effectively by using Sentry for crash reporting.'**
  String get legalBasisForProcessingDescription;

  /// No description provided for @howWeUseYourInformation.
  ///
  /// In en, this message translates to:
  /// **'How We Use Your Information'**
  String get howWeUseYourInformation;

  /// No description provided for @howWeUseYourInformationDescription.
  ///
  /// In en, this message translates to:
  /// **'We use the information we collect for the following purposes:\n\n• To process in-app purchases and manage subscriptions through RevenueCat.\n• To gather feedback and improve the App using Wiredash.\n• To monitor and fix issues using Sentry crash logging.\n• To improve user experience and enhance App features.\n• To improve the app through Microsoft Clarity.'**
  String get howWeUseYourInformationDescription;

  /// No description provided for @yourRights.
  ///
  /// In en, this message translates to:
  /// **'Your Rights'**
  String get yourRights;

  /// No description provided for @yourRightsDescription.
  ///
  /// In en, this message translates to:
  /// **'Under the GDPR, you have the following rights:\n\n• The right to access the personal information we hold about you.\n• The right to request corrections to your personal information.\n• The right to request deletion of your personal information (\'right to be forgotten\').\n• The right to data portability.\n• The right to object to processing based on our legitimate interests.\n• The right to withdraw consent at any time.\n• The right to lodge a complaint with a supervisory authority.'**
  String get yourRightsDescription;

  /// No description provided for @thirdPartyServices.
  ///
  /// In en, this message translates to:
  /// **'Third-Party Services'**
  String get thirdPartyServices;

  /// No description provided for @thirdPartyServicesDescription.
  ///
  /// In en, this message translates to:
  /// **'We use third-party services to enhance our App:\n\n• Wiredash: Used to collect user feedback.\n• RevenueCat: Used to process in-app purchases and subscriptions.\n• Sentry: Used for error monitoring and crash reporting.\n• Microsoft Clarity: Used for analytics and user experience improvement.'**
  String get thirdPartyServicesDescription;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @contactUsDescription.
  ///
  /// In en, this message translates to:
  /// **'If you have any questions or concerns about this Privacy Policy, or if you wish to exercise your rights under GDPR, please contact us at support@repeatlab.de\n\nThank you for using our App!'**
  String get contactUsDescription;

  /// No description provided for @crashLogs.
  ///
  /// In en, this message translates to:
  /// **'Crash Logs'**
  String get crashLogs;

  /// No description provided for @addSong.
  ///
  /// In en, this message translates to:
  /// **'Add Song'**
  String get addSong;

  /// No description provided for @noSongsFound.
  ///
  /// In en, this message translates to:
  /// **'No songs found'**
  String get noSongsFound;

  /// No description provided for @tapToAddSong.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add your first song'**
  String get tapToAddSong;

  /// No description provided for @legalNoticesDescription.
  ///
  /// In en, this message translates to:
  /// **'§5 TMG\n\nVerena Zaiser\nReichenbachstr. 17\n70372 Stuttgart\nE-Mail: support@repeatlab.de\n\nRechtsform: Freelancer'**
  String get legalNoticesDescription;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Welcome to RepeatLab'**
  String get onboardingTitle1;

  /// No description provided for @onboardingDescription1.
  ///
  /// In en, this message translates to:
  /// **'Master any song by practicing difficult sections with repeating them or slowing them down.'**
  String get onboardingDescription1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Create Precise Loops'**
  String get onboardingTitle2;

  /// No description provided for @onboardingDescription2.
  ///
  /// In en, this message translates to:
  /// **'Simply tap to mark the start and end of a section you want to practice. Adjust and fine-tune with our intuitive waveform display.'**
  String get onboardingDescription2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Privacy First'**
  String get onboardingTitle3;

  /// No description provided for @onboardingDescription3.
  ///
  /// In en, this message translates to:
  /// **'We value your privacy and handle your data with care. Please review our privacy policy and accept to continue.'**
  String get onboardingDescription3;

  /// No description provided for @onboardingIAccept.
  ///
  /// In en, this message translates to:
  /// **'I accept the '**
  String get onboardingIAccept;

  /// No description provided for @onboardingPrivacyPolicyLink.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get onboardingPrivacyPolicyLink;

  /// No description provided for @onboardingTermsOfServiceLink.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get onboardingTermsOfServiceLink;

  /// No description provided for @and.
  ///
  /// In en, this message translates to:
  /// **' and the '**
  String get and;

  /// No description provided for @onboardingIAcceptUsageStatistics.
  ///
  /// In en, this message translates to:
  /// **'I accept the usage of my data for analytics and crash reporting to improve the app.'**
  String get onboardingIAcceptUsageStatistics;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardingGetStarted;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @sendRating.
  ///
  /// In en, this message translates to:
  /// **'Send Rating'**
  String get sendRating;

  /// No description provided for @leaveReview.
  ///
  /// In en, this message translates to:
  /// **'Leave Review'**
  String get leaveReview;

  /// No description provided for @yourFeedbackHelpsMe.
  ///
  /// In en, this message translates to:
  /// **'Your Feedback helps me to add the features '**
  String get yourFeedbackHelpsMe;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **' you '**
  String get you;

  /// No description provided for @want.
  ///
  /// In en, this message translates to:
  /// **'want'**
  String get want;

  /// No description provided for @rateDialogDescription.
  ///
  /// In en, this message translates to:
  /// **'Hi! I\'m the creator of this app. Loving the app? A quick 5-star review would mean the world to me 😊! It motivates me to add more cool features for you.\nThank you! ❤️'**
  String get rateDialogDescription;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not Now'**
  String get notNow;

  /// No description provided for @editLoop.
  ///
  /// In en, this message translates to:
  /// **'Edit Loop'**
  String get editLoop;

  /// No description provided for @loopName.
  ///
  /// In en, this message translates to:
  /// **'Loop Name'**
  String get loopName;

  /// No description provided for @startTime.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get startTime;

  /// No description provided for @endTime.
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get endTime;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @invalidFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid format (mm:ss.sss)'**
  String get invalidFormat;

  /// No description provided for @startCannotBeAfterEnd.
  ///
  /// In en, this message translates to:
  /// **'Start cannot be after end'**
  String get startCannotBeAfterEnd;

  /// No description provided for @endCannotBeBeforeStart.
  ///
  /// In en, this message translates to:
  /// **'End cannot be before start'**
  String get endCannotBeBeforeStart;

  /// No description provided for @noActiveLoop.
  ///
  /// In en, this message translates to:
  /// **'No active loop.\nAdd a new loop or select an existing one.'**
  String get noActiveLoop;

  /// No description provided for @startMustBeBeforeEnd.
  ///
  /// In en, this message translates to:
  /// **'Start position must be before end position'**
  String get startMustBeBeforeEnd;

  /// No description provided for @setLoopStart.
  ///
  /// In en, this message translates to:
  /// **'Set Loop Start'**
  String get setLoopStart;

  /// No description provided for @setLoopEnd.
  ///
  /// In en, this message translates to:
  /// **'Set Loop End'**
  String get setLoopEnd;

  /// No description provided for @endMustBeAfterStart.
  ///
  /// In en, this message translates to:
  /// **'End position must be after start position'**
  String get endMustBeAfterStart;

  /// No description provided for @premiumHeadline.
  ///
  /// In en, this message translates to:
  /// **'Master Your Favorite Songs like a Pro with Tempo Control, Zoom & Unlimited Loops!'**
  String get premiumHeadline;

  /// No description provided for @premiumFeatureUnlimitedLoops.
  ///
  /// In en, this message translates to:
  /// **'Unlimited Loops'**
  String get premiumFeatureUnlimitedLoops;

  /// No description provided for @premiumFeatureChangeMusicSpeed.
  ///
  /// In en, this message translates to:
  /// **'Audio Speed Control (BPM/Multiplier)'**
  String get premiumFeatureChangeMusicSpeed;

  /// No description provided for @premiumFeatureZoomInOut.
  ///
  /// In en, this message translates to:
  /// **'Waveform Zoom-In/Out'**
  String get premiumFeatureZoomInOut;

  /// No description provided for @premiumFeatureSupportDeveloper.
  ///
  /// In en, this message translates to:
  /// **'Support the independent Developer'**
  String get premiumFeatureSupportDeveloper;

  /// No description provided for @freeFeatureUnlimitedSongs.
  ///
  /// In en, this message translates to:
  /// **'Unlimited Songs + One Loop per Song'**
  String get freeFeatureUnlimitedSongs;

  /// No description provided for @freeFeatureExportLoops.
  ///
  /// In en, this message translates to:
  /// **'Export Loops'**
  String get freeFeatureExportLoops;

  /// No description provided for @freeFeatureNoAds.
  ///
  /// In en, this message translates to:
  /// **'No Ads'**
  String get freeFeatureNoAds;

  /// No description provided for @freeFeatureOneLoopPerSong.
  ///
  /// In en, this message translates to:
  /// **'One Loop per Song'**
  String get freeFeatureOneLoopPerSong;

  /// No description provided for @purchase.
  ///
  /// In en, this message translates to:
  /// **'Purchase'**
  String get purchase;

  /// No description provided for @purchaseYearly.
  ///
  /// In en, this message translates to:
  /// **'Try for {trialString} days free'**
  String purchaseYearly(String trialString);

  /// No description provided for @purchaseLifetime.
  ///
  /// In en, this message translates to:
  /// **'Purchase'**
  String get purchaseLifetime;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @deny.
  ///
  /// In en, this message translates to:
  /// **'Deny'**
  String get deny;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get notAvailable;

  /// No description provided for @cancelAnytime.
  ///
  /// In en, this message translates to:
  /// **'You can cancel anytime before the trial ends in Google Play settings to avoid being charged.'**
  String get cancelAnytime;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @terms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get terms;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @yearlyDescription.
  ///
  /// In en, this message translates to:
  /// **'{trialString}-day free trial, then {priceString}/year. Subscription auto-renews unless canceled in Google Play settings before the trial ends.'**
  String yearlyDescription(String priceString, String trialString);

  /// No description provided for @subscribeWeekly.
  ///
  /// In en, this message translates to:
  /// **'Subscribe Weekly'**
  String get subscribeWeekly;

  /// No description provided for @subscribeYearly.
  ///
  /// In en, this message translates to:
  /// **'Subscribe Yearly'**
  String get subscribeYearly;

  /// No description provided for @weeklyDescriptionNoTrial.
  ///
  /// In en, this message translates to:
  /// **'{priceString}/week. Subscription auto-renews unless canceled in store settings.'**
  String weeklyDescriptionNoTrial(String priceString);

  /// No description provided for @yearlyDescriptionNoTrial.
  ///
  /// In en, this message translates to:
  /// **'{priceString}/year. Subscription auto-renews unless canceled in store settings.'**
  String yearlyDescriptionNoTrial(String priceString);

  /// No description provided for @lifetimeDescription.
  ///
  /// In en, this message translates to:
  /// **'One-time payment. No subscription required.'**
  String get lifetimeDescription;

  /// No description provided for @deleteSongLoops.
  ///
  /// In en, this message translates to:
  /// **'Delete Song & Loops'**
  String get deleteSongLoops;

  /// No description provided for @deleteSongLoopsDescription.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this song and all attached loops? This can\'t be undone.'**
  String get deleteSongLoopsDescription;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @startPositionMustBeBeforeEndPosition.
  ///
  /// In en, this message translates to:
  /// **'Start position must be before end position'**
  String get startPositionMustBeBeforeEndPosition;

  /// No description provided for @endPositionMustBeAfterStartPosition.
  ///
  /// In en, this message translates to:
  /// **'End position must be after start position'**
  String get endPositionMustBeAfterStartPosition;

  /// No description provided for @tutorialNavigateThroughSong.
  ///
  /// In en, this message translates to:
  /// **'Navigate through the song with dragging and dropping'**
  String get tutorialNavigateThroughSong;

  /// No description provided for @tutorialNavigateThroughSongDescription.
  ///
  /// In en, this message translates to:
  /// **'Use your fingers to drag and drop the whole song to the left or right and zoom in/out for better precision'**
  String get tutorialNavigateThroughSongDescription;

  /// No description provided for @tutorialPlayAndPauseSong.
  ///
  /// In en, this message translates to:
  /// **'Play, pause or change the speed of the song'**
  String get tutorialPlayAndPauseSong;

  /// No description provided for @tutorialPlayAndPauseSongDescription.
  ///
  /// In en, this message translates to:
  /// **'Use these buttons to control the song and loops'**
  String get tutorialPlayAndPauseSongDescription;

  /// No description provided for @tutorialJumpToLoop.
  ///
  /// In en, this message translates to:
  /// **'See and jump to loops'**
  String get tutorialJumpToLoop;

  /// No description provided for @tutorialJumpToLoopDescription.
  ///
  /// In en, this message translates to:
  /// **'Your loops will be displayed here. You can jump to them by tapping on them'**
  String get tutorialJumpToLoopDescription;

  /// No description provided for @tutorialSetLoopStart.
  ///
  /// In en, this message translates to:
  /// **'Set the start position of the loop'**
  String get tutorialSetLoopStart;

  /// No description provided for @tutorialSetLoopStartDescription.
  ///
  /// In en, this message translates to:
  /// **'You can always adjust the start position of the loop by moving the song marker and tapping on the start position'**
  String get tutorialSetLoopStartDescription;

  /// No description provided for @tutorialSetLoopEnd.
  ///
  /// In en, this message translates to:
  /// **'Set the end position of the loop'**
  String get tutorialSetLoopEnd;

  /// No description provided for @tutorialSetLoopEndDescription.
  ///
  /// In en, this message translates to:
  /// **'You can always adjust the end position of the loop by moving the song marker and tapping on the end position'**
  String get tutorialSetLoopEndDescription;

  /// No description provided for @tutorialActivateLoop.
  ///
  /// In en, this message translates to:
  /// **'Activate the loop mode for selected loop'**
  String get tutorialActivateLoop;

  /// No description provided for @tutorialActivateLoopDescription.
  ///
  /// In en, this message translates to:
  /// **'If you want to play the loop, you have to activate the loop mode. If it\'s disabled, the whole song will be played.'**
  String get tutorialActivateLoopDescription;

  /// No description provided for @tutorialAddLoop.
  ///
  /// In en, this message translates to:
  /// **'Add a new loop'**
  String get tutorialAddLoop;

  /// No description provided for @tutorialAddLoopDescription.
  ///
  /// In en, this message translates to:
  /// **'You can add a new loop by tapping on the + button'**
  String get tutorialAddLoopDescription;

  /// No description provided for @week.
  ///
  /// In en, this message translates to:
  /// **'week'**
  String get week;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'year'**
  String get year;

  /// No description provided for @purchaseWeekly.
  ///
  /// In en, this message translates to:
  /// **'Try for {trialString} days free'**
  String purchaseWeekly(String trialString);

  /// No description provided for @weeklySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try it out for a week'**
  String get weeklySubtitle;

  /// No description provided for @weeklyDescription.
  ///
  /// In en, this message translates to:
  /// **'{trialString}-day free trial, then {priceString}/week. Subscription auto-renews unless canceled in store settings before the trial ends.'**
  String weeklyDescription(String priceString, String trialString);

  /// No description provided for @purchasedAlready.
  ///
  /// In en, this message translates to:
  /// **'Purchased already'**
  String get purchasedAlready;

  /// No description provided for @purchaseSuccess.
  ///
  /// In en, this message translates to:
  /// **'Purchase successful. Thank you for supporting the developer ❤️!'**
  String get purchaseSuccess;

  /// No description provided for @voteForFeatures.
  ///
  /// In en, this message translates to:
  /// **'Vote for Features'**
  String get voteForFeatures;

  /// No description provided for @changelogTitle.
  ///
  /// In en, this message translates to:
  /// **'Changelog'**
  String get changelogTitle;

  /// Changelog entry title for the 1.8.0 song reorder feature
  ///
  /// In en, this message translates to:
  /// **'Reorder your songs'**
  String get changelog180Title;

  /// Changelog entry description for the 1.8.0 song reorder feature
  ///
  /// In en, this message translates to:
  /// **'Organize your song list the way you want — long-press any song and drag it to a new position. Your custom order is saved automatically.'**
  String get changelog180Description;

  /// No description provided for @changelog170Title.
  ///
  /// In en, this message translates to:
  /// **'Back up and move your library'**
  String get changelog170Title;

  /// No description provided for @changelog170Description.
  ///
  /// In en, this message translates to:
  /// **'Export your entire library — songs, loops, and audio — to a single file, then restore it on another device with Pro. Choose Merge to add new songs alongside your existing ones, or Replace to start fresh.'**
  String get changelog170Description;

  /// Changelog entry title for the 1.7.0 language switcher feature
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get changelog170LanguageTitle;

  /// Changelog entry description for the 1.7.0 language switcher feature
  ///
  /// In en, this message translates to:
  /// **'Switch the app language from the drawer — pick from 16 supported languages or follow your device\'s system default.'**
  String get changelog170LanguageDescription;

  /// No description provided for @changelog1601Title.
  ///
  /// In en, this message translates to:
  /// **'1/3 Auto-Play when selecting loops or navigating between them'**
  String get changelog1601Title;

  /// No description provided for @changelog1601Description.
  ///
  /// In en, this message translates to:
  /// **'In the song settings you can now enable or disable the automatic playback of loops and the entire song.'**
  String get changelog1601Description;

  /// No description provided for @changelog1602Title.
  ///
  /// In en, this message translates to:
  /// **'2/3 Improved loop control'**
  String get changelog1602Title;

  /// No description provided for @changelog1602Description.
  ///
  /// In en, this message translates to:
  /// **'You can now jump to the next or previous loop by tapping the previous or next button. Also in the notification and lock screen.'**
  String get changelog1602Description;

  /// No description provided for @changelog1603Title.
  ///
  /// In en, this message translates to:
  /// **'3/3 Layout adjustments'**
  String get changelog1603Title;

  /// No description provided for @changelog1603Description.
  ///
  /// In en, this message translates to:
  /// **'The layout of the app has been adjusted to improve the user experience.'**
  String get changelog1603Description;

  /// No description provided for @changelog150Title.
  ///
  /// In en, this message translates to:
  /// **'Enorme Improvement of Audio Quality at Speed Changes'**
  String get changelog150Title;

  /// No description provided for @changelog150Description.
  ///
  /// In en, this message translates to:
  /// **'The audio quality at speed changes has been significantly improved. This allows for a better playback of loops with different speeds.'**
  String get changelog150Description;

  /// No description provided for @changelog140Title.
  ///
  /// In en, this message translates to:
  /// **'1/2 Export Loops'**
  String get changelog140Title;

  /// No description provided for @changelog140Description.
  ///
  /// In en, this message translates to:
  /// **'You can now export loops with different formats and quality.'**
  String get changelog140Description;

  /// No description provided for @changelog1402Title.
  ///
  /// In en, this message translates to:
  /// **'2/2 Bug Fixes & Design Optimizations'**
  String get changelog1402Title;

  /// No description provided for @changelog1402Description.
  ///
  /// In en, this message translates to:
  /// **'Several Bugs were fixed and design optimized.'**
  String get changelog1402Description;

  /// No description provided for @changelog130Title.
  ///
  /// In en, this message translates to:
  /// **'Change tempo based on BPM'**
  String get changelog130Title;

  /// No description provided for @changelog130Description.
  ///
  /// In en, this message translates to:
  /// **'You can now change the tempo of the song based on the BPM. This allows for precise tempo adjustments. Additionally, the tempo can now be reset with a button.'**
  String get changelog130Description;

  /// No description provided for @changelog1201Title.
  ///
  /// In en, this message translates to:
  /// **'1/4 Added media data for audio files'**
  String get changelog1201Title;

  /// No description provided for @changelog1201Description.
  ///
  /// In en, this message translates to:
  /// **'The app now shows the media data for audio files. This includes the title and artist for now.'**
  String get changelog1201Description;

  /// No description provided for @changelog1202Title.
  ///
  /// In en, this message translates to:
  /// **'2/4 Convert m4a to mp3'**
  String get changelog1202Title;

  /// No description provided for @changelog1202Description.
  ///
  /// In en, this message translates to:
  /// **'The app now converts m4a files (which is currently not a supported format by the app) to mp3 files.'**
  String get changelog1202Description;

  /// No description provided for @changelog1203Title.
  ///
  /// In en, this message translates to:
  /// **'3/4 Delete single songs'**
  String get changelog1203Title;

  /// No description provided for @changelog1203Description.
  ///
  /// In en, this message translates to:
  /// **'You can now delete a song by sliding it to the left and tapping \'Delete Song\'. This will delete the song and all attached loops.'**
  String get changelog1203Description;

  /// No description provided for @changelog1204Title.
  ///
  /// In en, this message translates to:
  /// **'4/4 Changed audio format'**
  String get changelog1204Title;

  /// No description provided for @changelog1204Description.
  ///
  /// In en, this message translates to:
  /// **'The audio format was changed to a more standard format and loops can be edited more precisely now.'**
  String get changelog1204Description;

  /// No description provided for @changelog115Title.
  ///
  /// In en, this message translates to:
  /// **'Fixed several bugs'**
  String get changelog115Title;

  /// No description provided for @changelog115Description.
  ///
  /// In en, this message translates to:
  /// **'If no loop end was set, the loop would play until the end of the song and consider the song end as the loop end. Audio background service will now stop when the app is closed.'**
  String get changelog115Description;

  /// No description provided for @changelog110Title.
  ///
  /// In en, this message translates to:
  /// **'Audio now plays in background and standby'**
  String get changelog110Title;

  /// No description provided for @changelog110Description.
  ///
  /// In en, this message translates to:
  /// **'The audio files now play even when the app goes to the background or the phone goes into standby mode.'**
  String get changelog110Description;

  /// No description provided for @changelog1017Title.
  ///
  /// In en, this message translates to:
  /// **'Reorder Loops'**
  String get changelog1017Title;

  /// No description provided for @changelog1017Description.
  ///
  /// In en, this message translates to:
  /// **'You can now reorder your loops by dragging and dropping them. Just long press on a loop and drag it to the new position.'**
  String get changelog1017Description;

  /// No description provided for @changelog1013Title.
  ///
  /// In en, this message translates to:
  /// **'Feature Voting & Feature proposal now possible'**
  String get changelog1013Title;

  /// No description provided for @changelog1013Description.
  ///
  /// In en, this message translates to:
  /// **'You can now vote for new features or submit your own feature proposals in the app. Just open the menu and open the \'Vote for Features\' board. Happy to hear your wishes!'**
  String get changelog1013Description;

  /// No description provided for @whatsNew.
  ///
  /// In en, this message translates to:
  /// **'What\'s New'**
  String get whatsNew;

  /// No description provided for @songAddError.
  ///
  /// In en, this message translates to:
  /// **'Failed to add song. This could be due to a problem with the file format. Please try to convert the file to a supported format like mp3 or wav.'**
  String get songAddError;

  /// No description provided for @unsupportedAudioFormatError.
  ///
  /// In en, this message translates to:
  /// **'The audio format \".{format}\" is not supported. Supported formats: {supportedFormats}.'**
  String unsupportedAudioFormatError(String format, String supportedFormats);

  /// Snackbar error shown when the user picks a video file whose extension is not in the supported list. {format} is the file extension without the leading dot; {supportedFormats} is a comma-separated list of supported extensions.
  ///
  /// In en, this message translates to:
  /// **'The video format \".{format}\" is not supported. Supported formats: {supportedFormats}.'**
  String unsupportedVideoFormatError(String format, String supportedFormats);

  /// No description provided for @loopAdded.
  ///
  /// In en, this message translates to:
  /// **'Loop added and activated'**
  String get loopAdded;

  /// No description provided for @loopModeEnabled.
  ///
  /// In en, this message translates to:
  /// **'Loop mode enabled'**
  String get loopModeEnabled;

  /// No description provided for @loopModeDisabled.
  ///
  /// In en, this message translates to:
  /// **'Loop mode disabled'**
  String get loopModeDisabled;

  /// No description provided for @loopExportButton.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get loopExportButton;

  /// No description provided for @loopExportDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Export loop'**
  String get loopExportDialogTitle;

  /// No description provided for @loopExportDialogDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose a file format and quality for this loop.'**
  String get loopExportDialogDescription;

  /// No description provided for @loopExportFormatLabel.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get loopExportFormatLabel;

  /// No description provided for @loopExportFormatMp3.
  ///
  /// In en, this message translates to:
  /// **'MP3 (compressed)'**
  String get loopExportFormatMp3;

  /// No description provided for @loopExportFormatWav.
  ///
  /// In en, this message translates to:
  /// **'WAV (lossless)'**
  String get loopExportFormatWav;

  /// No description provided for @loopExportSampleRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Sample rate'**
  String get loopExportSampleRateLabel;

  /// No description provided for @loopExportBitrateLabel.
  ///
  /// In en, this message translates to:
  /// **'Bitrate'**
  String get loopExportBitrateLabel;

  /// No description provided for @loopExportConfirm.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get loopExportConfirm;

  /// No description provided for @loopExportPickLocation.
  ///
  /// In en, this message translates to:
  /// **'Choose where to save the exported loop'**
  String get loopExportPickLocation;

  /// No description provided for @loopExportFallbackName.
  ///
  /// In en, this message translates to:
  /// **'loop'**
  String get loopExportFallbackName;

  /// No description provided for @loopExportInProgress.
  ///
  /// In en, this message translates to:
  /// **'Exporting loop...'**
  String get loopExportInProgress;

  /// No description provided for @loopExportValidationError.
  ///
  /// In en, this message translates to:
  /// **'Check the loop start and end times before exporting.'**
  String get loopExportValidationError;

  /// No description provided for @loopExportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Loop exported successfully.'**
  String get loopExportSuccess;

  /// Shown after a loop export completes and includes the output file name.
  ///
  /// In en, this message translates to:
  /// **'Loop exported to {fileName}.'**
  String loopExportSuccessWithPath(String fileName);

  /// Shown when loop export fails and includes the error message.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t export loop: {errorMessage}'**
  String loopExportError(String errorMessage);

  /// No description provided for @loopExportGenericError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t export loop.'**
  String get loopExportGenericError;

  /// No description provided for @loopExportCanceled.
  ///
  /// In en, this message translates to:
  /// **'Loop export canceled.'**
  String get loopExportCanceled;

  /// No description provided for @pleaseSelectLoop.
  ///
  /// In en, this message translates to:
  /// **'Please select a loop'**
  String get pleaseSelectLoop;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @pro.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get pro;

  /// No description provided for @oneCoffee.
  ///
  /// In en, this message translates to:
  /// **'= One Coffee for the Developer (per Year)'**
  String get oneCoffee;

  /// No description provided for @onePairOfDrumSticks.
  ///
  /// In en, this message translates to:
  /// **'= One Pair of Drum Sticks for the Developer (one-time)'**
  String get onePairOfDrumSticks;

  /// No description provided for @localData.
  ///
  /// In en, this message translates to:
  /// **'Local Data'**
  String get localData;

  /// No description provided for @deleteAllLocalData.
  ///
  /// In en, this message translates to:
  /// **'Delete All Local Data'**
  String get deleteAllLocalData;

  /// No description provided for @deleteAllDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete All Data, Songs and Loops'**
  String get deleteAllDataTitle;

  /// No description provided for @deleteAllDataMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete all data? This will delete all your songs and loops. This action cannot be undone.'**
  String get deleteAllDataMessage;

  /// No description provided for @addLoop.
  ///
  /// In en, this message translates to:
  /// **'Add Loop'**
  String get addLoop;

  /// No description provided for @deleteSong.
  ///
  /// In en, this message translates to:
  /// **'Delete Song'**
  String get deleteSong;

  /// No description provided for @reportBugAndFeedback.
  ///
  /// In en, this message translates to:
  /// **'Report Bug & Feedback'**
  String get reportBugAndFeedback;

  /// Menu item to toggle full song repeat mode
  ///
  /// In en, this message translates to:
  /// **'Repeat Full Song'**
  String get repeatFullSong;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @end.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get end;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @deleteAllDataSuccess.
  ///
  /// In en, this message translates to:
  /// **'All data deleted successfully'**
  String get deleteAllDataSuccess;

  /// No description provided for @deleteAllDataError.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete all data'**
  String get deleteAllDataError;

  /// No description provided for @backupAndRestore.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get backupAndRestore;

  /// No description provided for @backupExport.
  ///
  /// In en, this message translates to:
  /// **'Export my library'**
  String get backupExport;

  /// No description provided for @backupExportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save all songs and loops to a single file you can transfer to another device.'**
  String get backupExportSubtitle;

  /// No description provided for @backupImport.
  ///
  /// In en, this message translates to:
  /// **'Import backup'**
  String get backupImport;

  /// No description provided for @backupImportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Restore songs and loops from a previously exported file.'**
  String get backupImportSubtitle;

  /// No description provided for @backupProOnly.
  ///
  /// In en, this message translates to:
  /// **'Pro feature'**
  String get backupProOnly;

  /// No description provided for @backupExporting.
  ///
  /// In en, this message translates to:
  /// **'Preparing backup…'**
  String get backupExporting;

  /// No description provided for @backupImporting.
  ///
  /// In en, this message translates to:
  /// **'Importing…'**
  String get backupImporting;

  /// No description provided for @backupExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {message}'**
  String backupExportFailed(String message);

  /// No description provided for @backupImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {message}'**
  String backupImportFailed(String message);

  /// No description provided for @backupImportConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Import backup'**
  String get backupImportConfirmTitle;

  /// No description provided for @backupImportConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This backup contains {songCount} songs (exported {exportedAt}).'**
  String backupImportConfirmMessage(int songCount, String exportedAt);

  /// No description provided for @backupImportModeMerge.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get backupImportModeMerge;

  /// No description provided for @backupImportModeMergeDescription.
  ///
  /// In en, this message translates to:
  /// **'Add new songs, keep existing ones.'**
  String get backupImportModeMergeDescription;

  /// No description provided for @backupImportModeReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get backupImportModeReplace;

  /// No description provided for @backupImportModeReplaceDescription.
  ///
  /// In en, this message translates to:
  /// **'Delete everything and import from scratch.'**
  String get backupImportModeReplaceDescription;

  /// No description provided for @backupImportReplaceConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Replace entire library?'**
  String get backupImportReplaceConfirmTitle;

  /// No description provided for @backupImportReplaceConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all current songs and loops before importing. This cannot be undone.'**
  String get backupImportReplaceConfirmMessage;

  /// No description provided for @backupImportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Imported {imported} songs. {skipped} skipped, {renamed} renamed.'**
  String backupImportSuccess(int imported, int skipped, int renamed);

  /// No description provided for @backupImportSchemaTooNew.
  ///
  /// In en, this message translates to:
  /// **'This backup was created by a newer version of RepeatLab. Please update the app to import it.'**
  String get backupImportSchemaTooNew;

  /// No description provided for @backupImportMalformed.
  ///
  /// In en, this message translates to:
  /// **'This file isn\'t a valid RepeatLab backup.'**
  String get backupImportMalformed;

  /// No description provided for @errorOpeningStore.
  ///
  /// In en, this message translates to:
  /// **'Failed to open app store listing. Please try to submit a review via Play or Apple Store directly. Thank you!'**
  String get errorOpeningStore;

  /// No description provided for @loopMode.
  ///
  /// In en, this message translates to:
  /// **'Loop Mode'**
  String get loopMode;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get hours;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get minutes;

  /// No description provided for @seconds.
  ///
  /// In en, this message translates to:
  /// **'Seconds'**
  String get seconds;

  /// No description provided for @milliseconds.
  ///
  /// In en, this message translates to:
  /// **'Milliseconds'**
  String get milliseconds;

  /// No description provided for @deleteSongConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{songTitle}\" and all attached loops?'**
  String deleteSongConfirmation(String songTitle);

  /// No description provided for @deleteSongConfirmationTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Song'**
  String get deleteSongConfirmationTitle;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// No description provided for @analyticsDescription.
  ///
  /// In en, this message translates to:
  /// **'We use Microsoft Clarity to collect usage data and improve the app. This data is not shared with third parties.'**
  String get analyticsDescription;

  /// No description provided for @enterSongBpm.
  ///
  /// In en, this message translates to:
  /// **'Song BPM'**
  String get enterSongBpm;

  /// No description provided for @enterSongBpmDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter the original BPM of the song to change the tempo. This is useful when practicing a song with a different tempo. The BPM will be assigned to the song and saved.'**
  String get enterSongBpmDescription;

  /// No description provided for @enterSongBpmHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 120'**
  String get enterSongBpmHint;

  /// No description provided for @tapBpm.
  ///
  /// In en, this message translates to:
  /// **'TAP'**
  String get tapBpm;

  /// No description provided for @tapTheButtonBelowInRhythmWithYourMusicToDetectTheBpm.
  ///
  /// In en, this message translates to:
  /// **'Tap the button below in rhythm with your music to detect the BPM.'**
  String get tapTheButtonBelowInRhythmWithYourMusicToDetectTheBpm;

  /// No description provided for @detectedBpm.
  ///
  /// In en, this message translates to:
  /// **'Detected BPM'**
  String get detectedBpm;

  /// No description provided for @tapAtLeast2TimesToDetectBpm.
  ///
  /// In en, this message translates to:
  /// **'Tap at least 2 times to detect BPM'**
  String get tapAtLeast2TimesToDetectBpm;

  /// No description provided for @tap.
  ///
  /// In en, this message translates to:
  /// **'TAP'**
  String get tap;

  /// No description provided for @taps.
  ///
  /// In en, this message translates to:
  /// **'Taps'**
  String get taps;

  /// No description provided for @useBpm.
  ///
  /// In en, this message translates to:
  /// **'Use BPM'**
  String get useBpm;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @speedControl.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get speedControl;

  /// No description provided for @hereYouCanSetTheOriginalBpmOfTheAudioFile.
  ///
  /// In en, this message translates to:
  /// **'Here you can set the original BPM of the audio file.'**
  String get hereYouCanSetTheOriginalBpmOfTheAudioFile;

  /// No description provided for @setBpm.
  ///
  /// In en, this message translates to:
  /// **'SET'**
  String get setBpm;

  /// No description provided for @originalBpm.
  ///
  /// In en, this message translates to:
  /// **'ORIGINAL BPM'**
  String get originalBpm;

  /// No description provided for @currentBpm.
  ///
  /// In en, this message translates to:
  /// **'CURRENT BPM'**
  String get currentBpm;

  /// No description provided for @loops.
  ///
  /// In en, this message translates to:
  /// **'Loops'**
  String get loops;

  /// No description provided for @songSettings.
  ///
  /// In en, this message translates to:
  /// **'Song Settings'**
  String get songSettings;

  /// No description provided for @playbackSettings.
  ///
  /// In en, this message translates to:
  /// **'Playback'**
  String get playbackSettings;

  /// No description provided for @autoPlayOnLoopSelect.
  ///
  /// In en, this message translates to:
  /// **'Auto-play Loops'**
  String get autoPlayOnLoopSelect;

  /// No description provided for @autoPlayOnLoopSelectDescription.
  ///
  /// In en, this message translates to:
  /// **'Automatically start playing when selecting a loop or navigating to next/previous loop'**
  String get autoPlayOnLoopSelectDescription;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @speedChangeFailed.
  ///
  /// In en, this message translates to:
  /// **'Speed change failed. Please try again.'**
  String get speedChangeFailed;

  /// Button or action to copy text to the device clipboard
  ///
  /// In en, this message translates to:
  /// **'Copy to Clipboard'**
  String get copyToClipboard;

  /// No description provided for @editSong.
  ///
  /// In en, this message translates to:
  /// **'Edit Song'**
  String get editSong;

  /// No description provided for @editSongTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get editSongTitle;

  /// No description provided for @editSongArtist.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get editSongArtist;

  /// No description provided for @editSongTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title cannot be empty'**
  String get editSongTitleRequired;

  /// Title of the "Add video" option in the add-media bottom sheet on the home page. Used as a button-style label.
  ///
  /// In en, this message translates to:
  /// **'Add video'**
  String get addVideo;

  /// Short pill/badge label shown next to features that are in beta. Should remain very short (3-6 chars) and uppercase where appropriate for the locale.
  ///
  /// In en, this message translates to:
  /// **'BETA'**
  String get betaLabel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'de',
    'en',
    'es',
    'fr',
    'hi',
    'it',
    'ja',
    'ko',
    'nl',
    'pl',
    'pt',
    'ru',
    'sv',
    'tr',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'nl':
      return AppLocalizationsNl();
    case 'pl':
      return AppLocalizationsPl();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'sv':
      return AppLocalizationsSv();
    case 'tr':
      return AppLocalizationsTr();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
