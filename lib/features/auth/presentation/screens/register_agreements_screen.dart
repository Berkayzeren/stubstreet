import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../../../../core/theme/app_theme.dart';
import '../../../legal/legal_texts.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/register_wizard_provider.dart';
import '../providers/auth_providers.dart';

class RegisterAgreementsScreen extends ConsumerStatefulWidget {
  const RegisterAgreementsScreen({super.key});

  @override
  ConsumerState<RegisterAgreementsScreen> createState() => _RegisterAgreementsScreenState();
}

class _RegisterAgreementsScreenState extends ConsumerState<RegisterAgreementsScreen> {
  bool _acceptedPrivacy = false;
  bool _acceptedKvkk = false;
  bool _acceptedTerms = false;
  bool _isLoading = false;
  final ScrollController _legalDialogScrollController = ScrollController();

  String _ua(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    return code.startsWith('tr') ? kUserAgreement : kUserAgreementEn;
    }
  String _pp(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    return code.startsWith('tr') ? kPrivacyPolicy : kPrivacyPolicyEn;
  }
  String _kv(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    return code.startsWith('tr') ? kKvkkNotice : kKvkkNoticeEn;
  }

  Future<void> _openLegal(String title, String content) async {
    if (_legalDialogScrollController.hasClients) {
      _legalDialogScrollController.jumpTo(0);
    }
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 700,
          height: 500,
          child: Scrollbar(
            controller: _legalDialogScrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _legalDialogScrollController,
              child: Text(content, style: const TextStyle(height: 1.4)),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.close)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _legalDialogScrollController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (!(_acceptedPrivacy && _acceptedKvkk && _acceptedTerms)) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseAcceptAllAgreements), backgroundColor: Colors.red),
      );
      return;
    }

    final w = ref.read(registerWizardProvider);
    if (w.firstName.isEmpty || w.email.isEmpty || w.password.isEmpty || w.tckn.isEmpty || w.phoneNumber.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.missingRegistrationData), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 1) Create account
      await ref.read(signUpNotifierProvider.notifier).signUp(
        w.email,
        w.password,
        firstName: w.firstName,
        lastName: w.lastName,
        username: w.username,
        phoneNumber: w.phoneNumber,
      );

      // 2) Link phone if possible
      final user = fb_auth.FirebaseAuth.instance.currentUser;
      if (user != null && w.verificationId != null && w.smsCode.isNotEmpty) {
        try {
          final cred = fb_auth.PhoneAuthProvider.credential(
            verificationId: w.verificationId!,
            smsCode: w.smsCode,
          );
          await user.linkWithCredential(cred);
        } catch (e) {
          debugPrint('Telefon linkleme uyarısı: $e');
        }
      }

      // 3) Securely store TCKN hash + last4 + acceptance timestamps
      if (user != null) {
        final tcHash = sha256.convert(utf8.encode(w.tckn)).toString();
        final tcLast4 = w.tckn.length >= 4 ? w.tckn.substring(w.tckn.length - 4) : w.tckn;
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'phoneNumber': w.phoneNumber,
          'phoneVerifiedAt': FieldValue.serverTimestamp(),
          'agreements': {
            'privacyAcceptedAt': FieldValue.serverTimestamp(),
            'kvkkAcceptedAt': FieldValue.serverTimestamp(),
            'termsAcceptedAt': FieldValue.serverTimestamp(),
          },
          'tcNoHash': tcHash,
          'tcNoLast4': tcLast4,
        });
      }

      // 4) Reset wizard and navigate home
      ref.read(registerWizardProvider.notifier).reset();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.registrationFailed}: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.termsAndConditions),
                subtitle: Text(''),
                trailing: TextButton(
                  onPressed: () => _openLegal(l10n.termsAndConditions, _ua(context)),
                  child: Text(l10n.selectLanguage),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.privacyPolicy),
                subtitle: Text(''),
                trailing: TextButton(
                  onPressed: () => _openLegal(l10n.privacyPolicy, _pp(context)),
                  child: Text(l10n.selectLanguage),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.kvkk),
                subtitle: Text(''),
                trailing: TextButton(
                  onPressed: () => _openLegal(l10n.kvkk, _kv(context)),
                  child: Text(l10n.selectLanguage),
                ),
              ),
              const Divider(),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _acceptedPrivacy,
                title: Text(l10n.acceptPrivacyPolicy),
                onChanged: (v) => setState(() => _acceptedPrivacy = v ?? false),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _acceptedKvkk,
                title: Text(l10n.acceptKvkkNotice),
                onChanged: (v) => setState(() => _acceptedKvkk = v ?? false),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _acceptedTerms,
                title: Text(l10n.acceptTerms),
                onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _finish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(l10n.completeRegistration),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
