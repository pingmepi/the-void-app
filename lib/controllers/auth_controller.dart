import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';

/// Streams Supabase auth state changes.
///
/// Safe to read before (or without) `Supabase.initialize` — in E2E builds
/// without credentials, `Supabase.instance.client` throws. We catch that and
/// return an empty stream so screens that watch this provider (e.g. VoidScreen
/// via [isLoggedInProvider]) can still build.
final authStateProvider = StreamProvider<AuthState>((ref) {
  try {
    return Supabase.instance.client.auth.onAuthStateChange;
  } catch (_) {
    return const Stream<AuthState>.empty();
  }
});

/// Whether the user is currently signed in.
/// Rebuilds whenever [authStateProvider] emits (sign-in, sign-out, refresh).
final isLoggedInProvider = Provider<bool>((ref) {
  ref.watch(authStateProvider); // trigger rebuild on auth change
  return AuthService.isLoggedIn;
});

/// The current user's Supabase ID, or null if not signed in.
final currentUserIdProvider = Provider<String?>((ref) {
  ref.watch(authStateProvider);
  return AuthService.userId;
});

/// The current user's email, or null if not signed in.
final currentUserEmailProvider = Provider<String?>((ref) {
  ref.watch(authStateProvider);
  return AuthService.userEmail;
});
