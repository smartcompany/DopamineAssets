import 'package:dopamine_assets/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/dopamine_theme.dart';

const privacyProcessingConsentRouteName = 'privacy_processing_consent';

const _prefsKey = 'dopamine_privacy_and_community_terms_v1';

Future<bool> isPrivacyProcessingConsentAccepted() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_prefsKey) ?? false;
}

Future<void> setPrivacyProcessingConsentAccepted() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_prefsKey, true);
}

Future<void> clearPrivacyProcessingConsent() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_prefsKey);
}

bool _dialogActive = false;

/// 동의하지 않으면 `false`. 호출부에서 로그아웃 처리.
Future<bool> ensurePrivacyProcessingConsent(BuildContext context) async {
  if (await isPrivacyProcessingConsentAccepted()) return true;
  if (!context.mounted) return false;
  if (_dialogActive) return false;
  _dialogActive = true;
  try {
    final result = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      routeSettings: const RouteSettings(name: privacyProcessingConsentRouteName),
      builder: (_) => const _PrivacyProcessingConsentPage(),
    );
    return result == true;
  } finally {
    _dialogActive = false;
  }
}

class _PrivacyProcessingConsentPage extends StatefulWidget {
  const _PrivacyProcessingConsentPage();

  @override
  State<_PrivacyProcessingConsentPage> createState() =>
      _PrivacyProcessingConsentPageState();
}

class _PrivacyProcessingConsentPageState
    extends State<_PrivacyProcessingConsentPage> {
  bool _agreedPrivacy = false;
  bool _agreedCommunity = false;

  bool get _canContinue => _agreedPrivacy && _agreedCommunity;

  Future<void> _accept() async {
    await setPrivacyProcessingConsentAccepted();
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 80,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, size: 28),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: DefaultTextStyle.merge(
          maxLines: 4,
          softWrap: true,
          overflow: TextOverflow.clip,
          textAlign: TextAlign.center,
          child: Text(l10n.privacyProcessingConsentTitle),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.privacyProcessingConsentLead,
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 20),
                      _SectionTitle(l10n.privacyProcessingConsentSectionPrivacy),
                      const SizedBox(height: 8),
                      _Bullet(l10n.privacyProcessingConsentBullet1),
                      _Bullet(l10n.privacyProcessingConsentBullet2),
                      _Bullet(l10n.privacyProcessingConsentBullet3),
                      const SizedBox(height: 12),
                      _ConsentCheckboxRow(
                        value: _agreedPrivacy,
                        label: l10n.privacyProcessingConsentCheckboxPrivacy,
                        onChanged: (v) =>
                            setState(() => _agreedPrivacy = v ?? false),
                      ),
                      const SizedBox(height: 20),
                      _SectionTitle(l10n.privacyProcessingConsentSectionCommunity),
                      const SizedBox(height: 8),
                      Text(
                        l10n.privacyProcessingConsentUgcIntro,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      _Bullet(l10n.privacyProcessingConsentUgcBullet1),
                      _Bullet(l10n.privacyProcessingConsentUgcBullet2),
                      _Bullet(l10n.privacyProcessingConsentUgcBullet3),
                      const SizedBox(height: 12),
                      _ConsentCheckboxRow(
                        value: _agreedCommunity,
                        label: l10n.privacyProcessingConsentCheckboxCommunity,
                        onChanged: (v) =>
                            setState(() => _agreedCommunity = v ?? false),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _canContinue ? _accept : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: DopamineTheme.neonGreen,
                    foregroundColor: Colors.black,
                  ),
                  child: Text(l10n.privacyProcessingConsentAgree),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(l10n.privacyProcessingConsentDecline),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConsentCheckboxRow extends StatelessWidget {
  const _ConsentCheckboxRow({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final bool value;
  final String label;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(label),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: DopamineTheme.textPrimary,
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
