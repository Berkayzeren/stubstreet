import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Stub Street'**
  String get appTitle;

  /// No description provided for @appSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sell your ticket, buy your dream'**
  String get appSubtitle;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @identityNumber.
  ///
  /// In en, this message translates to:
  /// **'Identity Number'**
  String get identityNumber;

  /// No description provided for @birthDate.
  ///
  /// In en, this message translates to:
  /// **'Birth Date'**
  String get birthDate;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @verificationCode.
  ///
  /// In en, this message translates to:
  /// **'Verification Code'**
  String get verificationCode;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send Code'**
  String get sendCode;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resendCode;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Register'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get alreadyHaveAccount;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// Welcome message on the home screen
  ///
  /// In en, this message translates to:
  /// **'Welcome, {email}!'**
  String welcomeMessage(String email);

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get invalidEmail;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @passwordsDontMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords don\'t match'**
  String get passwordsDontMatch;

  /// No description provided for @firstNameRequired.
  ///
  /// In en, this message translates to:
  /// **'First name is required'**
  String get firstNameRequired;

  /// No description provided for @lastNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Last name is required'**
  String get lastNameRequired;

  /// No description provided for @phoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get phoneRequired;

  /// No description provided for @invalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get invalidPhone;

  /// No description provided for @identityRequired.
  ///
  /// In en, this message translates to:
  /// **'Identity number is required'**
  String get identityRequired;

  /// No description provided for @invalidIdentity.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid identity number'**
  String get invalidIdentity;

  /// No description provided for @birthDateRequired.
  ///
  /// In en, this message translates to:
  /// **'Birth date is required'**
  String get birthDateRequired;

  /// No description provided for @mustBeAdult.
  ///
  /// In en, this message translates to:
  /// **'You must be at least 18 years old'**
  String get mustBeAdult;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get loginFailed;

  /// No description provided for @registrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed'**
  String get registrationFailed;

  /// No description provided for @verificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification failed'**
  String get verificationFailed;

  /// No description provided for @phoneVerification.
  ///
  /// In en, this message translates to:
  /// **'Phone Verification'**
  String get phoneVerification;

  /// No description provided for @phoneVerificationDesc.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to your phone'**
  String get phoneVerificationDesc;

  /// No description provided for @featureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'This feature is coming soon'**
  String get featureComingSoon;

  /// No description provided for @termsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms and Conditions'**
  String get termsAndConditions;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @kvkk.
  ///
  /// In en, this message translates to:
  /// **'Data Protection Policy'**
  String get kvkk;

  /// No description provided for @iAgreeToThe.
  ///
  /// In en, this message translates to:
  /// **'I agree to the:'**
  String get iAgreeToThe;

  /// No description provided for @and.
  ///
  /// In en, this message translates to:
  /// **'and'**
  String get and;

  /// No description provided for @mustAcceptTerms.
  ///
  /// In en, this message translates to:
  /// **'You must accept the terms and conditions'**
  String get mustAcceptTerms;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @addTicket.
  ///
  /// In en, this message translates to:
  /// **'Add Ticket'**
  String get addTicket;

  /// No description provided for @myTickets.
  ///
  /// In en, this message translates to:
  /// **'My Tickets'**
  String get myTickets;

  /// No description provided for @myOrders.
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get myOrders;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @emailNotifications.
  ///
  /// In en, this message translates to:
  /// **'Email Notifications'**
  String get emailNotifications;

  /// No description provided for @messageNotifications.
  ///
  /// In en, this message translates to:
  /// **'Message Notifications'**
  String get messageNotifications;

  /// No description provided for @ticketNotifications.
  ///
  /// In en, this message translates to:
  /// **'Ticket Notifications'**
  String get ticketNotifications;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @securitySettings.
  ///
  /// In en, this message translates to:
  /// **'Security Settings'**
  String get securitySettings;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About App'**
  String get aboutApp;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @selectTheme.
  ///
  /// In en, this message translates to:
  /// **'Select Theme'**
  String get selectTheme;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @shareYourSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Share your suggestions with us'**
  String get shareYourSuggestions;

  /// No description provided for @sendEmail.
  ///
  /// In en, this message translates to:
  /// **'Send Email'**
  String get sendEmail;

  /// No description provided for @feedbackEmailSubject.
  ///
  /// In en, this message translates to:
  /// **'StubStreet Feedback'**
  String get feedbackEmailSubject;

  /// No description provided for @privacyDataUsage.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Data Usage'**
  String get privacyDataUsage;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @loginRequired.
  ///
  /// In en, this message translates to:
  /// **'Login required'**
  String get loginRequired;

  /// No description provided for @loginToUseFeature.
  ///
  /// In en, this message translates to:
  /// **'You must log in to use this feature.'**
  String get loginToUseFeature;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchTickets.
  ///
  /// In en, this message translates to:
  /// **'Search tickets...'**
  String get searchTickets;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResults;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @conversations.
  ///
  /// In en, this message translates to:
  /// **'Conversations'**
  String get conversations;

  /// No description provided for @archived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get archived;

  /// No description provided for @searchConversations.
  ///
  /// In en, this message translates to:
  /// **'Search Conversations'**
  String get searchConversations;

  /// No description provided for @noConversations.
  ///
  /// In en, this message translates to:
  /// **'No Conversations'**
  String get noConversations;

  /// No description provided for @noSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No Search Results'**
  String get noSearchResults;

  /// No description provided for @tryDifferentSearch.
  ///
  /// In en, this message translates to:
  /// **'Try a different search'**
  String get tryDifferentSearch;

  /// No description provided for @startNewConversation.
  ///
  /// In en, this message translates to:
  /// **'Start New Conversation'**
  String get startNewConversation;

  /// No description provided for @startConversation.
  ///
  /// In en, this message translates to:
  /// **'Start Conversation'**
  String get startConversation;

  /// No description provided for @errorLoadingConversations.
  ///
  /// In en, this message translates to:
  /// **'Error loading conversations'**
  String get errorLoadingConversations;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @muteNotifications.
  ///
  /// In en, this message translates to:
  /// **'Mute Notifications'**
  String get muteNotifications;

  /// No description provided for @archiveConversation.
  ///
  /// In en, this message translates to:
  /// **'Archive Conversation'**
  String get archiveConversation;

  /// No description provided for @blockUser.
  ///
  /// In en, this message translates to:
  /// **'Block User'**
  String get blockUser;

  /// No description provided for @deleteConversation.
  ///
  /// In en, this message translates to:
  /// **'Delete Conversation'**
  String get deleteConversation;

  /// No description provided for @deleteConversationConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this conversation?'**
  String get deleteConversationConfirmation;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light Theme'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark Theme'**
  String get darkTheme;

  /// No description provided for @systemTheme.
  ///
  /// In en, this message translates to:
  /// **'System Theme'**
  String get systemTheme;

  /// No description provided for @guest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guest;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @emailOrUsername.
  ///
  /// In en, this message translates to:
  /// **'Email or Username'**
  String get emailOrUsername;

  /// No description provided for @emailOrUsernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Email or username is required'**
  String get emailOrUsernameRequired;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @usernameHint.
  ///
  /// In en, this message translates to:
  /// **'example_username'**
  String get usernameHint;

  /// No description provided for @usernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Username is required'**
  String get usernameRequired;

  /// No description provided for @usernameMinLength.
  ///
  /// In en, this message translates to:
  /// **'Username must be at least 3 characters'**
  String get usernameMinLength;

  /// No description provided for @usernameMaxLength.
  ///
  /// In en, this message translates to:
  /// **'Username must be at most 20 characters'**
  String get usernameMaxLength;

  /// No description provided for @usernameAllowedChars.
  ///
  /// In en, this message translates to:
  /// **'Only letters, numbers, and _ are allowed'**
  String get usernameAllowedChars;

  /// No description provided for @usernameNoLeadingTrailingSpace.
  ///
  /// In en, this message translates to:
  /// **'Cannot start or end with a space'**
  String get usernameNoLeadingTrailingSpace;

  /// No description provided for @usernameAlreadyTaken.
  ///
  /// In en, this message translates to:
  /// **'This username is already taken'**
  String get usernameAlreadyTaken;

  /// No description provided for @continueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue without signing up'**
  String get continueAsGuest;

  /// No description provided for @usernameEmailNotFound.
  ///
  /// In en, this message translates to:
  /// **'No email found for this username'**
  String get usernameEmailNotFound;

  /// No description provided for @usernameResolveFailed.
  ///
  /// In en, this message translates to:
  /// **'Username could not be resolved. Please enter your email address.'**
  String get usernameResolveFailed;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @tcknLabel.
  ///
  /// In en, this message translates to:
  /// **'T.R. Identity Number'**
  String get tcknLabel;

  /// No description provided for @tcknHint.
  ///
  /// In en, this message translates to:
  /// **'11-digit TCKN'**
  String get tcknHint;

  /// No description provided for @tcknRequired.
  ///
  /// In en, this message translates to:
  /// **'T.R. Identity Number is required'**
  String get tcknRequired;

  /// No description provided for @tckn11Digits.
  ///
  /// In en, this message translates to:
  /// **'Must be 11 digits'**
  String get tckn11Digits;

  /// No description provided for @tcknStartsWithZero.
  ///
  /// In en, this message translates to:
  /// **'Cannot start with 0'**
  String get tcknStartsWithZero;

  /// No description provided for @invalidTcknK1.
  ///
  /// In en, this message translates to:
  /// **'Invalid TCKN (k1)'**
  String get invalidTcknK1;

  /// No description provided for @invalidTcknK2.
  ///
  /// In en, this message translates to:
  /// **'Invalid TCKN (k2)'**
  String get invalidTcknK2;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @selectCountryCode.
  ///
  /// In en, this message translates to:
  /// **'Select Country Code'**
  String get selectCountryCode;

  /// No description provided for @localPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'Local number (e.g., 5XXXXXXXXX)'**
  String get localPhoneHint;

  /// No description provided for @phoneLenTurkey.
  ///
  /// In en, this message translates to:
  /// **'Must be 10 digits for Turkey (5XXXXXXXXX)'**
  String get phoneLenTurkey;

  /// No description provided for @phoneLenGeneric.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid local number length'**
  String get phoneLenGeneric;

  /// No description provided for @invalidPhoneFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone format'**
  String get invalidPhoneFormat;

  /// No description provided for @sendingSms.
  ///
  /// In en, this message translates to:
  /// **'Sending SMS...'**
  String get sendingSms;

  /// No description provided for @resendSmsIn.
  ///
  /// In en, this message translates to:
  /// **'Resend ({time})'**
  String resendSmsIn(Object time);

  /// No description provided for @resendSms.
  ///
  /// In en, this message translates to:
  /// **'Resend SMS'**
  String get resendSms;

  /// No description provided for @sendSmsCode.
  ///
  /// In en, this message translates to:
  /// **'Send SMS Code'**
  String get sendSmsCode;

  /// No description provided for @smsCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'SMS Verification Code'**
  String get smsCodeLabel;

  /// No description provided for @smsCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code'**
  String get smsCodeHint;

  /// No description provided for @smsCodeRequired.
  ///
  /// In en, this message translates to:
  /// **'SMS code is required'**
  String get smsCodeRequired;

  /// No description provided for @smsCodeSixDigits.
  ///
  /// In en, this message translates to:
  /// **'SMS code must be 6 digits'**
  String get smsCodeSixDigits;

  /// No description provided for @smsCodeSent.
  ///
  /// In en, this message translates to:
  /// **'SMS code sent. Please check your phone.'**
  String get smsCodeSent;

  /// No description provided for @smsInfoSentTo.
  ///
  /// In en, this message translates to:
  /// **'The SMS code was sent to {phone}. If you did not receive it, check your spam.'**
  String smsInfoSentTo(Object phone);

  /// No description provided for @smsSendError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while sending SMS: {error}'**
  String smsSendError(Object error);

  /// No description provided for @completeRegistration.
  ///
  /// In en, this message translates to:
  /// **'Complete Registration'**
  String get completeRegistration;

  /// No description provided for @pleaseAcceptAllAgreements.
  ///
  /// In en, this message translates to:
  /// **'Please accept all agreements to continue'**
  String get pleaseAcceptAllAgreements;

  /// No description provided for @missingRegistrationData.
  ///
  /// In en, this message translates to:
  /// **'Missing registration data. Please complete previous steps.'**
  String get missingRegistrationData;

  /// No description provided for @guestContinueError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred during guest login: {error}'**
  String guestContinueError(Object error);

  /// No description provided for @unexpectedAuthError.
  ///
  /// In en, this message translates to:
  /// **'Unexpected authentication error'**
  String get unexpectedAuthError;

  /// No description provided for @openText.
  ///
  /// In en, this message translates to:
  /// **'Open Text'**
  String get openText;

  /// No description provided for @openInSeparateWindow.
  ///
  /// In en, this message translates to:
  /// **'Open in a separate window'**
  String get openInSeparateWindow;

  /// No description provided for @acceptPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'I have read and accept the Privacy Policy'**
  String get acceptPrivacyPolicy;

  /// No description provided for @acceptKvkkNotice.
  ///
  /// In en, this message translates to:
  /// **'I have read and accept the KVKK Notice'**
  String get acceptKvkkNotice;

  /// No description provided for @acceptTerms.
  ///
  /// In en, this message translates to:
  /// **'I have read and accept the User Agreement'**
  String get acceptTerms;

  /// No description provided for @nameMinLength.
  ///
  /// In en, this message translates to:
  /// **'{field} must be at least {min} characters'**
  String nameMinLength(Object field, Object min);

  /// No description provided for @nameLettersOnly.
  ///
  /// In en, this message translates to:
  /// **'{field} must contain letters only'**
  String nameLettersOnly(Object field);

  /// No description provided for @fieldFirstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get fieldFirstName;

  /// No description provided for @fieldLastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get fieldLastName;

  /// No description provided for @forgotPasswordDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address or username; we\'ll send a reset link to your email.'**
  String get forgotPasswordDescription;

  /// No description provided for @sendResetEmail.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Email'**
  String get sendResetEmail;

  /// No description provided for @passwordResetEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent to {email}'**
  String passwordResetEmailSent(Object email);

  /// Snackbar error message shown when sending password reset fails
  ///
  /// In en, this message translates to:
  /// **'Failed to send password reset email: {error}'**
  String passwordResetEmailFailed(String error);

  /// No description provided for @reportUser.
  ///
  /// In en, this message translates to:
  /// **'Report User'**
  String get reportUser;

  /// No description provided for @reportUserReason.
  ///
  /// In en, this message translates to:
  /// **'Why are you reporting this user?'**
  String get reportUserReason;

  /// No description provided for @reportReasonSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam or harassment'**
  String get reportReasonSpam;

  /// No description provided for @reportReasonFakeProfile.
  ///
  /// In en, this message translates to:
  /// **'Fake profile'**
  String get reportReasonFakeProfile;

  /// No description provided for @reportReasonInappropriate.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate content'**
  String get reportReasonInappropriate;

  /// No description provided for @reportReasonFraud.
  ///
  /// In en, this message translates to:
  /// **'Fraud'**
  String get reportReasonFraud;

  /// No description provided for @reportReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get reportReasonOther;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @activeTicket.
  ///
  /// In en, this message translates to:
  /// **'Active Ticket'**
  String get activeTicket;

  /// No description provided for @totalSellers.
  ///
  /// In en, this message translates to:
  /// **'Total Sellers'**
  String get totalSellers;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @concerts.
  ///
  /// In en, this message translates to:
  /// **'Concerts'**
  String get concerts;

  /// No description provided for @concertsDescription.
  ///
  /// In en, this message translates to:
  /// **'Live music experience'**
  String get concertsDescription;

  /// No description provided for @sports.
  ///
  /// In en, this message translates to:
  /// **'Sports'**
  String get sports;

  /// No description provided for @sportsDescription.
  ///
  /// In en, this message translates to:
  /// **'Sports events'**
  String get sportsDescription;

  /// No description provided for @theater.
  ///
  /// In en, this message translates to:
  /// **'Theater'**
  String get theater;

  /// No description provided for @theaterDescription.
  ///
  /// In en, this message translates to:
  /// **'Performing arts'**
  String get theaterDescription;

  /// No description provided for @festivals.
  ///
  /// In en, this message translates to:
  /// **'Festivals'**
  String get festivals;

  /// No description provided for @festivalsDescription.
  ///
  /// In en, this message translates to:
  /// **'Music and art festivals'**
  String get festivalsDescription;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @todaysEventQuestion.
  ///
  /// In en, this message translates to:
  /// **'Which event will you join today?'**
  String get todaysEventQuestion;

  /// No description provided for @searchEventsPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search events, artists, venues...'**
  String get searchEventsPlaceholder;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least {min} characters'**
  String passwordMinLength(String min);

  /// No description provided for @passwordMaxLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at most {max} characters'**
  String passwordMaxLength(String max);

  /// No description provided for @passwordRequireUppercase.
  ///
  /// In en, this message translates to:
  /// **'At least one uppercase letter'**
  String get passwordRequireUppercase;

  /// No description provided for @passwordRequireLowercase.
  ///
  /// In en, this message translates to:
  /// **'At least one lowercase letter'**
  String get passwordRequireLowercase;

  /// No description provided for @passwordRequireNumber.
  ///
  /// In en, this message translates to:
  /// **'At least one number'**
  String get passwordRequireNumber;

  /// No description provided for @passwordRequireSpecial.
  ///
  /// In en, this message translates to:
  /// **'At least one special character'**
  String get passwordRequireSpecial;

  /// No description provided for @passwordTooCommon.
  ///
  /// In en, this message translates to:
  /// **'This password is too common'**
  String get passwordTooCommon;

  /// No description provided for @passwordNoSequential.
  ///
  /// In en, this message translates to:
  /// **'Cannot contain sequential characters'**
  String get passwordNoSequential;

  /// No description provided for @passwordNoRepeating.
  ///
  /// In en, this message translates to:
  /// **'Cannot contain repeating characters'**
  String get passwordNoRepeating;

  /// No description provided for @passwordVeryWeak.
  ///
  /// In en, this message translates to:
  /// **'Very Weak'**
  String get passwordVeryWeak;

  /// No description provided for @passwordWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get passwordWeak;

  /// No description provided for @passwordFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get passwordFair;

  /// No description provided for @passwordGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get passwordGood;

  /// No description provided for @passwordStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get passwordStrong;

  /// No description provided for @passwordStrength.
  ///
  /// In en, this message translates to:
  /// **'Password Strength'**
  String get passwordStrength;

  /// No description provided for @passwordRequirements.
  ///
  /// In en, this message translates to:
  /// **'Password Requirements'**
  String get passwordRequirements;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
