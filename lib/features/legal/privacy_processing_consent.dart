import 'package:dopamine_assets/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/dopamine_theme.dart';

const privacyProcessingConsentRouteName = 'privacy_processing_consent';

const _prefsKey = 'dopamine_privacy_processing_consent_v1';

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
    final result = await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute<bool>(
        fullscreenDialog: true,
        settings: const RouteSettings(name: privacyProcessingConsentRouteName),
        builder: (_) => const _PrivacyProcessingConsentPage(),
      ),
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
  bool _agreed = false;

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
      appBar: AppBar(title: Text(l10n.privacyProcessingConsentTitle)),
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
                      const SizedBox(height: 16),
                      _Bullet(l10n.privacyProcessingConsentBullet1),
                      _Bullet(l10n.privacyProcessingConsentBullet2),
                      _Bullet(l10n.privacyProcessingConsentBullet3),
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _agreed,
                            onChanged: (v) =>
                                setState(() => _agreed = v ?? false),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text(
                                l10n.privacyProcessingConsentCheckbox,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _agreed ? _accept : null,
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
