import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../controllers/auth_controller.dart';
import '../main.dart';
import '../services/auth_service.dart';

/// Full-screen sign-in screen with The Void branding.
///
/// Used when an unauthenticated user navigates to gems — the intentional
/// "I want to sign in" path. [AuthScreen] (bottom sheet) remains for
/// the mid-rescue auth gate.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Auto-pop when auth completes (native OAuth — no page redirect)
    ref.listenManual(authStateProvider, (_, next) {
      next.whenData((authState) {
        if (authState.event.name == 'signedIn' && mounted) {
          Navigator.of(context).pop(true);
        }
      });
    });
  }

  Future<void> _signIn(Future<void> Function() signInFn) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await signInFn();
      // On native: authStateProvider listener handles pop.
      // On web: page redirects, nothing more to do.
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
    return Scaffold(
      backgroundColor: VoidColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Wordmark
              Text(
                'THE VOID',
                style: TextStyle(
                  color: VoidColors.accent,
                  fontSize: 32,
                  fontFamily: 'serif',
                  letterSpacing: 6,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Speak. Rescue what matters.\nLet the rest go.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: VoidColors.textSecondary,
                  fontSize: 14,
                  fontFamily: 'serif',
                  fontStyle: FontStyle.italic,
                  height: 1.6,
                ),
              ),

              const Spacer(flex: 2),

              // Error
              if (_error != null) ...[
                Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],

              // Google Sign-In
              _SignInButton(
                icon: Icons.g_mobiledata,
                label: 'Continue with Google',
                isLoading: _isLoading,
                onTap: () => _signIn(AuthService.signInWithGoogle),
              ),
              const SizedBox(height: 12),

              // Apple Sign-In
              _SignInButton(
                icon: Icons.apple,
                label: 'Continue with Apple',
                isLoading: _isLoading,
                onTap: () => _signIn(AuthService.signInWithApple),
              ),

              const SizedBox(height: 24),

              // Dismiss
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () => Navigator.of(context).pop(false),
                child: Text(
                  'Maybe later',
                  style: TextStyle(
                    color: VoidColors.textFaded,
                    fontSize: 13,
                    fontFamily: 'serif',
                  ),
                ),
              ),

              const Spacer(),

              // Privacy policy
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextButton(
                  key: const Key('privacy_policy_link'),
                  onPressed: () => launchUrl(
                    Uri.parse(AppConfig.privacyPolicyUrl),
                    mode: LaunchMode.externalApplication,
                  ),
                  child: Text(
                    'Privacy Policy',
                    style: TextStyle(
                      color: VoidColors.textFaded,
                      fontSize: 12,
                      fontFamily: 'serif',
                      decoration: TextDecoration.underline,
                      decorationColor: VoidColors.textFaded,
                    ),
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
