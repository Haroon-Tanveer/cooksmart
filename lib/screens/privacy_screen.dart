import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// The privacy policy, shown in-app.
///
/// The text comes from the localisations so an Arabic reader is not reading
/// English legal text, which matters for a policy the store links to. It mirrors
/// privacy.html in the repository; keep the two in step.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = L.of(context);
    return CookBackground(
      child: Column(
        children: <Widget>[
          _Bar(onBack: () => Navigator.of(context).pop()),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
              children: <Widget>[
                _Section(l10n.yourData, l10n.yourDataBody),
                _Section(l10n.staysOnPhone, l10n.staysOnPhoneBody),
                _Section(l10n.optionalLive, l10n.optionalLiveBody),
                _Section(l10n.foodPhotos, l10n.foodPhotosBody),
                _Section(l10n.children, l10n.childrenBody),
                _Section(l10n.yourRights, l10n.yourRightsBody),
                _Section(l10n.policyChanges, l10n.policyChangesBody),
                _Section(l10n.contact, l10n.contactBody),
                const SizedBox(height: 8),
                Text(
                  l10n.policyLastUpdated,
                  style: cookText(size: 12, color: CookColors.muted2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Row(
        children: <Widget>[
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: CookColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: CookColors.line),
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                size: 20,
                color: CookColors.text,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              L.of(context).privacyPolicy,
              style: cookText(size: 22, weight: FontWeight.w800, color: CookColors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.body);

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: cookText(size: 16, weight: FontWeight.w800, color: CookColors.white),
          ),
          const SizedBox(height: 7),
          Text(
            body,
            style: cookText(size: 13.5, color: CookColors.muted, height: 1.6),
          ),
        ],
      ),
    );
  }
}
