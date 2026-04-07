import 'package:supabase_flutter/supabase_flutter.dart';

/// Global Supabase client accessor — shorthand for Supabase.instance.client.
SupabaseClient get supabase => Supabase.instance.client;
