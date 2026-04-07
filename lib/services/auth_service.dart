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

  static User? get currentUser => supabase.auth.currentUser;

  static bool get isLoggedIn => currentUser != null;

  static String? get userId => currentUser?.id;

  static String? get userEmail => currentUser?.email;

  static Stream<AuthState> get authStateStream =>
      supabase.auth.onAuthStateChange;
}
