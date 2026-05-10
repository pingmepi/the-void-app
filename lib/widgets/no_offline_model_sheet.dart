import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/void_controller.dart';
import '../main.dart';
import 'e2e_id.dart';

/// Shown when [VoidState.errorNoOfflineModel] is active.
///
/// Directs the user to install the on-device speech recognition model so that
/// audio never leaves the device. Tapping "Open settings" deep-links to the
/// Google App's offline speech recognition settings (Android); falls back to
/// the system voice-input settings page if the Google App is unavailable.
class NoOfflineModelSheet extends ConsumerWidget {
  const NoOfflineModelSheet({super.key});

  static Future<void> _openSettings() async {
    // Google App offline speech recognition settings (Android-specific)
    final googleSpeechUri = Uri.parse(
      'intent:#Intent;action=com.google.android.voicesearch.OFFLINE_TRIGGER;'
      'package=com.google.android.googlequicksearchbox;end',
    );
    if (await canLaunchUrl(googleSpeechUri)) {
      await launchUrl(googleSpeechUri, mode: LaunchMode.externalApplication);
      return;
    }

    // Fallback: Android voice-input settings
    final voiceSettingsUri = Uri.parse(
      'intent:#Intent;action=android.settings.VOICE_INPUT_SETTINGS;end',
    );
    if (await canLaunchUrl(voiceSettingsUri)) {
      await launchUrl(voiceSettingsUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF151221),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: VoidColors.textFaded,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 28),

          Icon(Icons.mic_off_outlined, size: 48, color: VoidColors.accent),
          const SizedBox(height: 16),

          Text(
            'Your voice stays on your phone.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: VoidColors.textPrimary,
              fontSize: 20,
              fontFamily: 'serif',
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),

          Text(
            'To keep it that way, install the on-device speech model.\n\n'
            'Settings → Google → Voice → Offline speech recognition → '
            'add your language.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: VoidColors.textSecondary,
              fontSize: 14,
              fontFamily: 'serif',
              height: 1.6,
            ),
          ),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            child: e2eId(
              'no-model-open-settings',
              FilledButton(
                onPressed: _openSettings,
                style: FilledButton.styleFrom(
                  backgroundColor: VoidColors.accent,
                  foregroundColor: const Color(0xFF0D0B14),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Open settings',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          e2eId(
            'no-model-cancel',
            TextButton(
              onPressed: () =>
                  ref.read(voidControllerProvider.notifier).reset(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: VoidColors.textFaded,
                  fontSize: 13,
                  fontFamily: 'serif',
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
