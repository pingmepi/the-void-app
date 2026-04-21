import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart';
import '../services/auth_service.dart';
import 'e2e_id.dart';

/// Reusable email/password auth form: sign in, sign up, and password reset.
///
/// [onAuthenticated] fires when a sign-in/sign-up call resolves without error.
/// The parent is responsible for anything that must happen before that call
/// (e.g. persisting a pending rescue on web).
class EmailAuthForm extends StatefulWidget {
  const EmailAuthForm({
    super.key,
    required this.onAuthenticated,
    this.onBeforeSubmit,
  });

  final VoidCallback onAuthenticated;

  /// Called just before the network request. Awaited. Use for side-effects
  /// like persisting volatile state before a potential redirect.
  final Future<void> Function()? onBeforeSubmit;

  @override
  State<EmailAuthForm> createState() => _EmailAuthFormState();
}

enum _Mode { signIn, signUp }

class _EmailAuthFormState extends State<EmailAuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  _Mode _mode = _Mode.signIn;
  bool _loading = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Email is required';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? v) {
    final s = v ?? '';
    if (s.isEmpty) return 'Password is required';
    if (s.length < 6) return 'At least 6 characters';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });
    try {
      await widget.onBeforeSubmit?.call();
      if (_mode == _Mode.signIn) {
        await AuthService.signInWithEmail(
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
        );
      } else {
        await AuthService.signUpWithEmail(
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
        );
      }
      if (!mounted) return;
      widget.onAuthenticated();
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Something went wrong. Please try again.';
        });
      }
    }
  }

  Future<void> _sendReset() async {
    final email = _emailCtrl.text.trim();
    if (_validateEmail(email) != null) {
      setState(() => _error = 'Enter your email above first');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });
    try {
      await AuthService.sendPasswordReset(email);
      if (mounted) {
        setState(() {
          _loading = false;
          _info = 'Reset link sent. Check your inbox.';
        });
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSignIn = _mode == _Mode.signIn;
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          e2eId('email_input', TextFormField(
            key: const Key('email_input'),
            controller: _emailCtrl,
            enabled: !_loading,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            style: TextStyle(color: VoidColors.textPrimary, fontSize: 14),
            decoration: _decoration('Email'),
            validator: _validateEmail,
          )),
          const SizedBox(height: 10),
          e2eId('password_input', TextFormField(
            key: const Key('password_input'),
            controller: _passwordCtrl,
            enabled: !_loading,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            style: TextStyle(color: VoidColors.textPrimary, fontSize: 14),
            decoration: _decoration('Password'),
            validator: _validatePassword,
            onFieldSubmitted: (_) => _submit(),
          )),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              key: const Key('auth_error_message'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ],
          if (_info != null) ...[
            const SizedBox(height: 10),
            Text(
              _info!,
              key: const Key('auth_info_message'),
              textAlign: TextAlign.center,
              style: TextStyle(color: VoidColors.accent, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: e2eId('email_submit_button', OutlinedButton(
              key: const Key('email_submit_button'),
              onPressed: _loading ? null : _submit,
              style: OutlinedButton.styleFrom(
                backgroundColor: VoidColors.accent.withValues(alpha: 0.08),
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: VoidColors.accent.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _loading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: VoidColors.accent,
                      ),
                    )
                  : Text(
                      isSignIn ? 'Sign in' : 'Create account',
                      style: TextStyle(
                        color: VoidColors.textPrimary,
                        fontFamily: 'serif',
                        fontSize: 14,
                      ),
                    ),
            )),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              e2eId('toggle_mode_button', TextButton(
                key: const Key('toggle_mode_button'),
                onPressed: _loading
                    ? null
                    : () => setState(() {
                          _mode = isSignIn ? _Mode.signUp : _Mode.signIn;
                          _error = null;
                          _info = null;
                        }),
                child: Text(
                  isSignIn ? 'Create account' : 'Have an account? Sign in',
                  style: TextStyle(
                    color: VoidColors.textFaded,
                    fontSize: 12,
                    fontFamily: 'serif',
                  ),
                ),
              )),
              if (isSignIn)
                e2eId('forgot_password_button', TextButton(
                  key: const Key('forgot_password_button'),
                  onPressed: _loading ? null : _sendReset,
                  child: Text(
                    'Forgot password?',
                    style: TextStyle(
                      color: VoidColors.textFaded,
                      fontSize: 12,
                      fontFamily: 'serif',
                    ),
                  ),
                )),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: VoidColors.textFaded, fontSize: 13),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: VoidColors.accent.withValues(alpha: 0.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: VoidColors.accent.withValues(alpha: 0.6)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.6),
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}
