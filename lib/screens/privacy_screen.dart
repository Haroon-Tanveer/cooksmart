import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/common.dart';

/// The privacy policy, shown in-app.
///
/// It is the same text as PRIVACY.md in the project root, which is the version to
/// host and link from the Play Console listing. Keep the two in step.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CookBackground(
      child: Column(
        children: <Widget>[
          _Bar(onBack: () => Navigator.of(context).pop()),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
              children: <Widget>[
                _Section(
                  'Your data',
                  'CookSmart has no account, no sign-in and no server of its own. '
                  'We do not use analytics, advertising or crash reporting, and we '
                  'do not collect or sell personal information.',
                ),
                _Section(
                  'What stays on your phone',
                  'Your ingredient lists, favourites, saved recipes and the endpoint '
                  'you have chosen are stored only on this device, in its private '
                  'app storage. Removing the app deletes all of it.',
                ),
                _Section(
                  'Optional live recipe generation',
                  'If you turn on live generation, the ingredients and dish you ask '
                  'for are sent to an AI service through a small proxy that you run '
                  'yourself on your own computer. Your API key stays in that proxy '
                  'and is never part of this app. Turn live generation off and '
                  'nothing leaves your phone at all.',
                ),
                _Section(
                  'Food photographs',
                  'The recipe photographs bundled with the app come from TheMealDB '
                  'and Wikipedia, under their respective licences. Per-image credits '
                  'are listed with the app source. Recipes written by the AI service '
                  'get a photograph looked up from the same sources.',
                ),
                _Section(
                  'Children',
                  'CookSmart is intended for a general audience. It collects no data '
                  'from anyone, including children.',
                ),
                _Section(
                  'Changes',
                  'If this policy changes, the updated text will appear in this screen '
                      'and in the release notes for the version you have installed.',
                ),
                _Section(
                  'Contact',
                  'Questions about this policy can go to the address on the Play '
                      'Store listing for this app.',
                ),
                SizedBox(height: 8),
                Text(
                  'Last updated 29 September 2026',
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
          Text(
            'Privacy',
            style: cookText(size: 22, weight: FontWeight.w800, color: CookColors.white),
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
            style: cookText(size: 13.5, color: CookColors.muted, height: 1.55),
          ),
        ],
      ),
    );
  }
}
