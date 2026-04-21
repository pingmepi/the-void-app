import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/auth_controller.dart';
import '../controllers/void_controller.dart';
import '../main.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../widgets/email_auth_form.dart';

/// Bottom sheet shown when the user taps Rescue without being signed in.
///
/// On web: OAuth causes a full-page redirect. The current transcript is
/// persisted to secure storage before navigating, so it can be saved
/// automatically after the user returns.
///
/// On native: OAuth uses a native dialog — no page reload, gem saves
/// immediately after sign-in completes.
///
/// Returns `true` via Navigator.pop when auth completes on native.
/// On web the sheet is dismissed and the page redirects.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Listen for auth state changes (native OAuth completes without redirect)
    _listenForAuth();
  }

  void _listenForAuth() {
    ref.listenManual(authStateProvider, (_, next) {
      next.whenData((authState) {
        if (authState.event.name == 'signedIn' && mounted) {
          Navigator.of(context).pop(true);
        }
      });
    });
  }

  Future<void> _persistPendingRescueIfWeb() async {
    if (!kIsWeb) return;
    final session = ref.read(voidControllerProvider).session;
    if (session != null && session.transcript.isNotEmpty) {
      final storageService = ref.read(storageServiceProvider);
      await storageService.savePendingRescue(
        transcript: session.transcript,
        durationSeconds: session.recordingDuration.inSeconds,
      );
    }
  }

  Future<void> _signIn(Future<void> Function() signInFn) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _persistPendingRescueIfWeb();

      await signInFn();

      // On web: page will redirect — nothing more to do here.
      // On native: _listenForAuth will handle pop when signedIn fires.
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Sign-in failed. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: VoidColors.textFaded,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 28),

          // Icon
          Icon(
            Icons.auto_awesome,
            size: 48,
            color: VoidColors.accent,
          ),
          const SizedBox(height: 16),

          // Headline
          Text(
            'Save your gem',
            style: TextStyle(
              color: VoidColors.textPrimary,
              fontSize: 22,
              fontFamily: 'serif',
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            'Sign in to preserve this moment\nacross all your devices.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: VoidColors.textSecondary,
              fontSize: 14,
              fontFamily: 'serif',
              height: 1.5,
            ),
          ),

          // Web redirect notice
          if (kIsWeb) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: VoidColors.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: VoidColors.accent.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16,
                      color: VoidColors.accent.withValues(alpha: 0.7)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your transcript is saved. After sign-in you\'ll be redirected back and your gem will be saved automatically.',
                      style: TextStyle(
                        color: VoidColors.accent.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontFamily: 'serif',
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 28),

          // Error message
          if (_error != null) ...[
            Text(
              _error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
          ],

          // Email/password form
          EmailAuthForm(
            onBeforeSubmit: _persistPendingRescueIfWeb,
            onAuthenticated: () {
              if (mounted) Navigator.of(context).pop(true);
            },
          ),

          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: Divider(color: VoidColors.textFaded.withValues(alpha: 0.3))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'or',
                  style: TextStyle(color: VoidColors.textFaded, fontSize: 12),
                ),
              ),
              Expanded(child: Divider(color: VoidColors.textFaded.withValues(alpha: 0.3))),
            ],
          ),
          const SizedBox(height: 16),

          // Google Sign-In button
          _SignInButton(
            icon: Icons.g_mobiledata,
            label: 'Continue with Google',
            isLoading: _isLoading,
            onTap: () => _signIn(AuthService.signInWithGoogle),
          ),

          // Apple Sign-In button (all platforms — Apple supports web OAuth too)
          const SizedBox(height: 12),
          _SignInButton(
            icon: Icons.apple,
            label: 'Continue with Apple',
            isLoading: _isLoading,
            onTap: () => _signIn(AuthService.signInWithApple),
          ),

          const SizedBox(height: 20),

          // Dismiss
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
            child: Text(
              'Not now',
              style: TextStyle(
                color: VoidColors.textFaded,
                fontSize: 13,
                fontFamily: 'serif',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignInButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isLoading;
  final VoidCallback onTap;

  const _SignInButton({
    required this.icon,
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : onTap,
        icon: isLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: VoidColors.accent,
                ),
              )
            : Icon(icon, color: VoidColors.accent),
        label: Text(
          label,
          style: TextStyle(
            color: VoidColors.textPrimary,
            fontFamily: 'serif',
            fontSize: 15,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(color: VoidColors.accent.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
