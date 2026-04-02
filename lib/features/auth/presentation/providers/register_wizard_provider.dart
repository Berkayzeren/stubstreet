import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Registration wizard aggregated state
/// Why: We split registration into 3 screens. This model carries data across routes safely.
class RegisterWizardState {
  // Account step
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String password;

  // Identity & contact step
  final String tckn;
  final String phoneNumber;
  final String? verificationId; // Firebase phone verification session id
  final String smsCode;

  // Agreements step
  final bool acceptedPrivacy;
  final bool acceptedKvkk;
  final bool acceptedTerms;

  const RegisterWizardState({
    this.firstName = '',
    this.lastName = '',
    this.username = '',
    this.email = '',
    this.password = '',
    this.tckn = '',
    this.phoneNumber = '',
    this.verificationId,
    this.smsCode = '',
    this.acceptedPrivacy = false,
    this.acceptedKvkk = false,
    this.acceptedTerms = false,
  });

  RegisterWizardState copyWith({
    String? firstName,
    String? lastName,
    String? username,
    String? email,
    String? password,
    String? tckn,
    String? phoneNumber,
    String? verificationId,
    String? smsCode,
    bool? acceptedPrivacy,
    bool? acceptedKvkk,
    bool? acceptedTerms,
  }) {
    return RegisterWizardState(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      tckn: tckn ?? this.tckn,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      verificationId: verificationId ?? this.verificationId,
      smsCode: smsCode ?? this.smsCode,
      acceptedPrivacy: acceptedPrivacy ?? this.acceptedPrivacy,
      acceptedKvkk: acceptedKvkk ?? this.acceptedKvkk,
      acceptedTerms: acceptedTerms ?? this.acceptedTerms,
    );
  }
}

/// State controller for RegisterWizard
/// Teaching note: Using Riverpod keeps navigation simple while ensuring data survives screen rebuilds.
class RegisterWizardNotifier extends StateNotifier<RegisterWizardState> {
  RegisterWizardNotifier() : super(const RegisterWizardState());

  void setAccount({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
  }) {
    state = state.copyWith(
      firstName: firstName,
      lastName: lastName,
      username: username,
      email: email,
      password: password,
    );
  }

  void setIdentity({
    required String tckn,
    required String phoneNumber,
  }) {
    state = state.copyWith(
      tckn: tckn,
      phoneNumber: phoneNumber,
    );
  }

  void setVerification({String? verificationId, String? smsCode}) {
    state = state.copyWith(
      verificationId: verificationId ?? state.verificationId,
      smsCode: smsCode ?? state.smsCode,
    );
  }

  void setAgreements({
    required bool privacy,
    required bool kvkk,
    required bool terms,
  }) {
    state = state.copyWith(
      acceptedPrivacy: privacy,
      acceptedKvkk: kvkk,
      acceptedTerms: terms,
    );
  }

  void reset() {
    state = const RegisterWizardState();
  }
}

final registerWizardProvider = StateNotifierProvider<RegisterWizardNotifier, RegisterWizardState>((ref) {
  return RegisterWizardNotifier();
});
