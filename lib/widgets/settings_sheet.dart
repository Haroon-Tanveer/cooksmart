import 'package:flutter/material.dart';

import '../screens/privacy_screen.dart';
import '../services/groq_config.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'common.dart';

/// Bottom sheet for the live-AI settings.
///
/// The Gemini key deliberately lives in the proxy, so this only ever holds a
/// base URL. That is also why the sheet is worded around an *endpoint* rather
/// than a key field.
class SettingsSheet extends StatefulWidget {
  const SettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SettingsSheet(),
    );
  }

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  TextEditingController? _endpoint;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // CookScope.of() registers a dependency on the inherited widget, so it may
    // only be called once initState has finished. The field is only seeded once
    // because the text field belongs to the user once they start typing.
    _endpoint ??= TextEditingController(text: CookScope.of(context).config.baseUrl);
  }

  @override
  void dispose() {
    _endpoint?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = CookScope.of(context);
    final config = state.config;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: CookColors.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          border: Border(top: BorderSide(color: CookColors.line)),
        ),
        padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: CookColors.line,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: <Widget>[
                  Text(
                    'Live AI',
                    style: cookText(
                      size: 20,
                      weight: FontWeight.w800,
                      color: CookColors.white,
                    ),
                  ),
                  const Spacer(),
                  _StatusPill(
                    live: config.isLive,
                    busy: state.isBusy,
                    label: !config.isConfigured
                        ? 'no endpoint'
                        : state.isBusy
                            ? 'working'
                            : (config.isLive ? 'on' : 'off'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              CookSurface(
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Use live generation',
                        style: cookText(
                          size: 15,
                          weight: FontWeight.w600,
                          color: CookColors.text,
                        ),
                      ),
                    ),
                    Switch(
                      value: config.liveEnabled,
                      activeThumbColor: CookColors.orange,
                      onChanged: (v) {
                        state.setLiveEnabled(v);
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Gemini writes new recipes and dish ideas. The bundled library of 191 '
                'recipes works with this off, and the app opens that way by default.',
                style: cookText(size: 13, color: CookColors.muted, height: 1.5),
              ),
              const SizedBox(height: 6),
              Text(
                'Your key stays on your own machine, inside the proxy server, and is never '
                'part of this app.',
                style: cookText(size: 13, color: CookColors.muted, height: 1.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Endpoint',
                style: cookText(
                  size: 12,
                  weight: FontWeight.w700,
                  color: CookColors.muted2,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),
              CookSurface(
                color: CookColors.surface2,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _endpoint,
                        keyboardType: TextInputType.url,
                        autocorrect: false,
                        style: cookText(size: 14, color: CookColors.white),
                        cursorColor: CookColors.orange,
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          hintText: 'https://your-proxy.example',
                        ),
                        onSubmitted: (value) {
                          state.updateEndpoint(value);
                          _endpoint?.text = state.config.baseUrl;
                        },
                      ),
                    ),
                    // Nothing to save until something has been typed, and an empty
                    // endpoint would only turn live generation off again.
                    if ((_endpoint?.text ?? '').trim().isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          state.updateEndpoint(_endpoint?.text ?? '');
                          _endpoint?.text = state.config.baseUrl;
                          showCookToast(context, 'Endpoint saved');
                        },
                        child: const Padding(
                          padding: EdgeInsets.only(left: 10),
                          child: Icon(
                            Icons.check_rounded,
                            size: 20,
                            color: CookColors.orange,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                GroqConfig.describeEndpoint(config.baseUrl),
                style: cookText(size: 11.5, color: CookColors.muted2),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _PresetChip(
                    label: 'Gemini proxy :8787',
                    onTap: () {
                      state.useProxyEndpoint();
                      _endpoint?.text = state.config.baseUrl;
                    },
                  ),
                  _PresetChip(
                    label: 'Offline mock :8788',
                    onTap: () {
                      state.useMockEndpoint();
                      _endpoint?.text = state.config.baseUrl;
                    },
                  ),
                ],
              ),
              if (state.liveError != null) ...<Widget>[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0x1AFF8A3D),
                    borderRadius: BorderRadius.circular(CookRadius.sm),
                    border: Border.all(color: const Color(0x3DFF8A3D)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: CookColors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.liveError!,
                          style: cookText(
                            size: 12.5,
                            color: CookColors.orangeSoft,
                            height: 1.45,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: state.clearLiveError,
                        child: const Icon(
                          Icons.close_rounded,
                          size: 15,
                          color: CookColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              GhostButton(
                label: state.isBusy ? 'Testing...' : 'Test connection',
                onPressed: state.isBusy
                    ? null
                    : () async {
                        final error = await state.testConnection();
                        if (!context.mounted) return;
                        showCookToast(
                          context,
                          error ?? 'Connected to the AI service',
                        );
                      },
              ),
              const SizedBox(height: 10),
              Text(
                'Start the proxy with:\n'
                r'$env:GEMINI_API_KEY = "AIza..."   # PowerShell' '\n'
                'node tool/server/gemini_proxy.js',
                style: cookText(size: 11, color: CookColors.muted2, height: 1.6),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () {
                  // Hold the navigator itself: the sheet's own context is gone
                  // once it has been popped, so pushing on it would throw.
                  final navigator = Navigator.of(context);
                  navigator.pop();
                  navigator.push(
                    MaterialPageRoute<void>(builder: (_) => const PrivacyScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                    color: CookColors.surface,
                    borderRadius: BorderRadius.circular(CookRadius.md),
                    border: Border.all(color: CookColors.line),
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.shield_outlined,
                        size: 18,
                        color: CookColors.orangeSoft,
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          'Privacy policy',
                          style: cookText(
                            size: 14,
                            weight: FontWeight.w700,
                            color: CookColors.text,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: CookColors.muted2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.live, required this.busy, required this.label});

  final bool live;
  final bool busy;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = busy
        ? CookColors.orangeSoft
        : (live ? const Color(0xFF6FD08C) : CookColors.muted2);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: cookText(
              size: 10.5,
              weight: FontWeight.w800,
              color: color,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: CookColors.surface2,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: CookColors.line),
        ),
        child: Text(
          label,
          style: cookText(size: 12, weight: FontWeight.w600, color: CookColors.text),
        ),
      ),
    );
  }
}
