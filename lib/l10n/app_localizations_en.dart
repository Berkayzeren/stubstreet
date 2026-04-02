// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Stub Street';

  @override
  String get appSubtitle => 'Sell your ticket, buy your dream';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get firstName => 'First Name';

  @override
  String get lastName => 'Last Name';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get identityNumber => 'Identity Number';

  @override
  String get birthDate => 'Birth Date';

  @override
  String get gender => 'Gender';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get other => 'Other';

  @override
  String get verificationCode => 'Verification Code';

  @override
  String get sendCode => 'Send Code';

  @override
  String get resendCode => 'Resend Code';

  @override
  String get verify => 'Verify';

  @override
  String get dontHaveAccount => 'Don\'t have an account? Register';

  @override
  String get alreadyHaveAccount => 'Already have an account? Login';

  @override
  String get createAccount => 'Create Account';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get or => 'or';

  @override
  String welcomeMessage(String email) {
    return 'Welcome, $email!';
  }

  @override
  String get emailRequired => 'Email is required';

  @override
  String get invalidEmail => 'Please enter a valid email address';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get passwordsDontMatch => 'Passwords don\'t match';

  @override
  String get firstNameRequired => 'First name is required';

  @override
  String get lastNameRequired => 'Last name is required';

  @override
  String get phoneRequired => 'Phone number is required';

  @override
  String get invalidPhone => 'Please enter a valid phone number';

  @override
  String get identityRequired => 'Identity number is required';

  @override
  String get invalidIdentity => 'Please enter a valid identity number';

  @override
  String get birthDateRequired => 'Birth date is required';

  @override
  String get mustBeAdult => 'You must be at least 18 years old';

  @override
  String get loginFailed => 'Login failed';

  @override
  String get registrationFailed => 'Registration failed';

  @override
  String get verificationFailed => 'Verification failed';

  @override
  String get phoneVerification => 'Phone Verification';

  @override
  String get phoneVerificationDesc =>
      'Enter the 6-digit code sent to your phone';

  @override
  String get featureComingSoon => 'This feature is coming soon';

  @override
  String get termsAndConditions => 'Terms and Conditions';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get kvkk => 'Data Protection Policy';

  @override
  String get iAgreeToThe => 'I agree to the:';

  @override
  String get and => 'and';

  @override
  String get mustAcceptTerms => 'You must accept the terms and conditions';

  @override
  String get profile => 'Profile';

  @override
  String get home => 'Home';

  @override
  String get addTicket => 'Add Ticket';

  @override
  String get myTickets => 'My Tickets';

  @override
  String get myOrders => 'My Orders';

  @override
  String get messages => 'Messages';

  @override
  String get settings => 'Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get language => 'Language';

  @override
  String get notifications => 'Notifications';

  @override
  String get pushNotifications => 'Push Notifications';

  @override
  String get emailNotifications => 'Email Notifications';

  @override
  String get messageNotifications => 'Message Notifications';

  @override
  String get ticketNotifications => 'Ticket Notifications';

  @override
  String get privacy => 'Privacy';

  @override
  String get securitySettings => 'Security Settings';

  @override
  String get account => 'Account';

  @override
  String get helpSupport => 'Help & Support';

  @override
  String get aboutApp => 'About App';

  @override
  String get logout => 'Logout';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'OK';

  @override
  String get close => 'Close';

  @override
  String get back => 'Back';

  @override
  String get selectTheme => 'Select Theme';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get feedback => 'Feedback';

  @override
  String get shareYourSuggestions => 'Share your suggestions with us';

  @override
  String get sendEmail => 'Send Email';

  @override
  String get feedbackEmailSubject => 'StubStreet Feedback';

  @override
  String get privacyDataUsage => 'Privacy & Data Usage';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get loginRequired => 'Login required';

  @override
  String get loginToUseFeature => 'You must log in to use this feature.';

  @override
  String get search => 'Search';

  @override
  String get searchTickets => 'Search tickets...';

  @override
  String get noResults => 'No results found';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get warning => 'Warning';

  @override
  String get info => 'Info';

  @override
  String get conversations => 'Conversations';

  @override
  String get archived => 'Archived';

  @override
  String get searchConversations => 'Search Conversations';

  @override
  String get noConversations => 'No Conversations';

  @override
  String get noSearchResults => 'No Search Results';

  @override
  String get tryDifferentSearch => 'Try a different search';

  @override
  String get startNewConversation => 'Start New Conversation';

  @override
  String get startConversation => 'Start Conversation';

  @override
  String get errorLoadingConversations => 'Error loading conversations';

  @override
  String get retry => 'Retry';

  @override
  String get muteNotifications => 'Mute Notifications';

  @override
  String get archiveConversation => 'Archive Conversation';

  @override
  String get blockUser => 'Block User';

  @override
  String get deleteConversation => 'Delete Conversation';

  @override
  String get deleteConversationConfirmation =>
      'Are you sure you want to delete this conversation?';

  @override
  String get delete => 'Delete';

  @override
  String get lightTheme => 'Light Theme';

  @override
  String get darkTheme => 'Dark Theme';

  @override
  String get systemTheme => 'System Theme';

  @override
  String get guest => 'Guest';

  @override
  String get signOut => 'Sign Out';

  @override
  String get emailOrUsername => 'Email or Username';

  @override
  String get emailOrUsernameRequired => 'Email or username is required';

  @override
  String get username => 'Username';

  @override
  String get usernameHint => 'example_username';

  @override
  String get usernameRequired => 'Username is required';

  @override
  String get usernameMinLength => 'Username must be at least 3 characters';

  @override
  String get usernameMaxLength => 'Username must be at most 20 characters';

  @override
  String get usernameAllowedChars => 'Only letters, numbers, and _ are allowed';

  @override
  String get usernameNoLeadingTrailingSpace =>
      'Cannot start or end with a space';

  @override
  String get usernameAlreadyTaken => 'This username is already taken';

  @override
  String get continueAsGuest => 'Continue without signing up';

  @override
  String get usernameEmailNotFound => 'No email found for this username';

  @override
  String get usernameResolveFailed =>
      'Username could not be resolved. Please enter your email address.';

  @override
  String get next => 'Next';

  @override
  String get tcknLabel => 'T.R. Identity Number';

  @override
  String get tcknHint => '11-digit TCKN';

  @override
  String get tcknRequired => 'T.R. Identity Number is required';

  @override
  String get tckn11Digits => 'Must be 11 digits';

  @override
  String get tcknStartsWithZero => 'Cannot start with 0';

  @override
  String get invalidTcknK1 => 'Invalid TCKN (k1)';

  @override
  String get invalidTcknK2 => 'Invalid TCKN (k2)';

  @override
  String get phone => 'Phone';

  @override
  String get selectCountryCode => 'Select Country Code';

  @override
  String get localPhoneHint => 'Local number (e.g., 5XXXXXXXXX)';

  @override
  String get phoneLenTurkey => 'Must be 10 digits for Turkey (5XXXXXXXXX)';

  @override
  String get phoneLenGeneric => 'Enter a valid local number length';

  @override
  String get invalidPhoneFormat => 'Invalid phone format';

  @override
  String get sendingSms => 'Sending SMS...';

  @override
  String resendSmsIn(Object time) {
    return 'Resend ($time)';
  }

  @override
  String get resendSms => 'Resend SMS';

  @override
  String get sendSmsCode => 'Send SMS Code';

  @override
  String get smsCodeLabel => 'SMS Verification Code';

  @override
  String get smsCodeHint => 'Enter the 6-digit code';

  @override
  String get smsCodeRequired => 'SMS code is required';

  @override
  String get smsCodeSixDigits => 'SMS code must be 6 digits';

  @override
  String get smsCodeSent => 'SMS code sent. Please check your phone.';

  @override
  String smsInfoSentTo(Object phone) {
    return 'The SMS code was sent to $phone. If you did not receive it, check your spam.';
  }

  @override
  String smsSendError(Object error) {
    return 'An error occurred while sending SMS: $error';
  }

  @override
  String get completeRegistration => 'Complete Registration';

  @override
  String get pleaseAcceptAllAgreements =>
      'Please accept all agreements to continue';

  @override
  String get missingRegistrationData =>
      'Missing registration data. Please complete previous steps.';

  @override
  String guestContinueError(Object error) {
    return 'An error occurred during guest login: $error';
  }

  @override
  String get unexpectedAuthError => 'Unexpected authentication error';

  @override
  String get openText => 'Open Text';

  @override
  String get openInSeparateWindow => 'Open in a separate window';

  @override
  String get acceptPrivacyPolicy => 'I have read and accept the Privacy Policy';

  @override
  String get acceptKvkkNotice => 'I have read and accept the KVKK Notice';

  @override
  String get acceptTerms => 'I have read and accept the User Agreement';

  @override
  String nameMinLength(Object field, Object min) {
    return '$field must be at least $min characters';
  }

  @override
  String nameLettersOnly(Object field) {
    return '$field must contain letters only';
  }

  @override
  String get fieldFirstName => 'First Name';

  @override
  String get fieldLastName => 'Last Name';

  @override
  String get forgotPasswordDescription =>
      'Enter your email address or username; we\'ll send a reset link to your email.';

  @override
  String get sendResetEmail => 'Send Reset Email';

  @override
  String passwordResetEmailSent(Object email) {
    return 'Password reset email sent to $email';
  }

  @override
  String passwordResetEmailFailed(String error) {
    return 'Failed to send password reset email: $error';
  }

  @override
  String get reportUser => 'Report User';

  @override
  String get reportUserReason => 'Why are you reporting this user?';

  @override
  String get reportReasonSpam => 'Spam or harassment';

  @override
  String get reportReasonFakeProfile => 'Fake profile';

  @override
  String get reportReasonInappropriate => 'Inappropriate content';

  @override
  String get reportReasonFraud => 'Fraud';

  @override
  String get reportReasonOther => 'Other';

  @override
  String get report => 'Report';

  @override
  String get activeTicket => 'Active Ticket';

  @override
  String get totalSellers => 'Total Sellers';

  @override
  String get thisWeek => 'This Week';

  @override
  String get categories => 'Categories';

  @override
  String get concerts => 'Concerts';

  @override
  String get concertsDescription => 'Live music experience';

  @override
  String get sports => 'Sports';

  @override
  String get sportsDescription => 'Sports events';

  @override
  String get theater => 'Theater';

  @override
  String get theaterDescription => 'Performing arts';

  @override
  String get festivals => 'Festivals';

  @override
  String get festivalsDescription => 'Music and art festivals';

  @override
  String get version => 'Version';

  @override
  String get todaysEventQuestion => 'Which event will you join today?';

  @override
  String get searchEventsPlaceholder => 'Search events, artists, venues...';

  @override
  String passwordMinLength(String min) {
    return 'Password must be at least $min characters';
  }

  @override
  String passwordMaxLength(String max) {
    return 'Password must be at most $max characters';
  }

  @override
  String get passwordRequireUppercase => 'At least one uppercase letter';

  @override
  String get passwordRequireLowercase => 'At least one lowercase letter';

  @override
  String get passwordRequireNumber => 'At least one number';

  @override
  String get passwordRequireSpecial => 'At least one special character';

  @override
  String get passwordTooCommon => 'This password is too common';

  @override
  String get passwordNoSequential => 'Cannot contain sequential characters';

  @override
  String get passwordNoRepeating => 'Cannot contain repeating characters';

  @override
  String get passwordVeryWeak => 'Very Weak';

  @override
  String get passwordWeak => 'Weak';

  @override
  String get passwordFair => 'Fair';

  @override
  String get passwordGood => 'Good';

  @override
  String get passwordStrong => 'Strong';

  @override
  String get passwordStrength => 'Password Strength';

  @override
  String get passwordRequirements => 'Password Requirements';
}
