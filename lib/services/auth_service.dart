import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

/// Wraps Supabase Auth operations.
///
/// OAuth flow on web causes a full-page redirect (browser limitation).
/// The app handles this by persisting any pending rescue to secure storage
/// before redirecting, then resuming on return.
class AuthService {
  AuthService._();

  static Future<void> signInWithGoogle() async {
    await supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      // On web: redirect back to current page (Supabase handles token from URL hash)
      // On native: use custom URL scheme
      redirectTo: kIsWeb ? null : 'com.thevoidapp://login-callback',
    );
  }

  static Future<void> signInWithApple() async {
    await supabase.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: kIsWeb ? null : 'com.thevoidapp://login-callback',
    );
  }

  static Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  /// Permanently deletes the current user's account via the `delete-account`
  /// Edge Function, then signs out locally.
  ///
  /// Throws on network error or if the function returns a non-2xx status.
  static Future<void> deleteAccount() async {
    await supabase.functions.invoke(
      'delete-account',
      method: HttpMethod.post,
    );
    // Local sign-out — session is already invalidated server-side
    try {
      await supabase.auth.signOut();
    } catch (_) {}
  }

  /// Returns the current user, or null if Supabase isn't initialized or no
  /// session exists. The try-catch makes this safe to call in tests and during
  /// early app startup before [Supabase.initialize] completes.
  static User? get currentUser {
    try {
      return supabase.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  static bool get isLoggedIn => currentUser != null;

  static String? get userId => currentUser?.id;

  static String? get userEmail => currentUser?.email;

  static Stream<AuthState> get authStateStream =>
      supabase.auth.onAuthStateChange;
}
