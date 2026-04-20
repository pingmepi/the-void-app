import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../controllers/auth_controller.dart';
import '../controllers/gems_controller.dart';
import '../main.dart';
import '../models/gem_note.dart';
import '../services/auth_service.dart';
import '../widgets/gem_card.dart';
import 'gem_detail_screen.dart';

class GemsScreen extends ConsumerStatefulWidget {
  const GemsScreen({super.key});

  @override
  ConsumerState<GemsScreen> createState() => _GemsScreenState();
}

class _GemsScreenState extends ConsumerState<GemsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<GemNote> _filter(List<GemNote> gems) {
    final q = _query.toLowerCase().trim();
    if (q.isEmpty) return gems;
    return gems.where((g) {
      return (g.title ?? '').toLowerCase().contains(q) ||
          g.transcript.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final allGems = ref.watch(sortedGemsProvider);
    final isLoggedIn = ref.watch(isLoggedInProvider);
    final gems = _filter(allGems);

    final Widget body;
    if (allGems.isEmpty) {
      body = _buildEmptyState();
    } else {
      body = Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: gems.isEmpty
                ? _buildNoResults()
                : _buildGemsList(context, ref, gems),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: VoidColors.background,
      appBar: AppBar(
        backgroundColor: VoidColors.background,
        elevation: 0,
        leading: const BackButton(color: VoidColors.accent),
        centerTitle: true,
        title: Text(
          'your gems',
          style: TextStyle(
            color: VoidColors.accent,
            fontFamily: 'serif',
            fontStyle: FontStyle.italic,
            fontSize: 18,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          if (isLoggedIn)
            IconButton(
              key: const Key('account_button'),
              icon: Icon(
                Icons.account_circle_outlined,
                color: VoidColors.accent.withAlpha(180),
              ),
              onPressed: () => _showAccountSheet(context, ref),
            ),
        ],
      ),
      body: body,
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _query = v),
        style: TextStyle(
          color: VoidColors.textPrimary,
          fontFamily: 'serif',
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: 'search transcripts...',
          hintStyle: TextStyle(
            color: VoidColors.textFaded,
            fontFamily: 'serif',
            fontStyle: FontStyle.italic,
            fontSize: 14,
          ),
          prefixIcon: Icon(Icons.search, color: VoidColors.textFaded, size: 18),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close, color: VoidColors.textFaded, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                )
              : null,
          filled: true,
          fillColor: VoidColors.backgroundLight,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                BorderSide(color: VoidColors.textGhost.withValues(alpha: 0.5)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                BorderSide(color: VoidColors.textGhost.withValues(alpha: 0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                BorderSide(color: VoidColors.accent.withValues(alpha: 0.5)),
          ),
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Text(
        'no gems match "$_query"',
        style: TextStyle(
          color: VoidColors.textFaded,
          fontFamily: 'serif',
          fontStyle: FontStyle.italic,
          fontSize: 15,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome,
            size: 48,
            color: VoidColors.textFaded,
          ),
          const SizedBox(height: 16),
          Text(
            'Nothing rescued yet',
            style: TextStyle(
              color: VoidColors.textSecondary,
              fontFamily: 'serif',
              fontStyle: FontStyle.italic,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Speak something worth keeping.',
            style: TextStyle(
              color: VoidColors.textFaded,
              fontFamily: 'serif',
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGemsList(
    BuildContext context,
    WidgetRef ref,
    List<GemNote> gems,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: gems.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, index) {
        final gem = gems[index];
        return GemCard(
          gem: gem,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GemDetailScreen(gemId: gem.id),
            ),
          ),
          onDelete: () => _confirmDelete(context, ref, gem.id),
        );
      },
    );
  }

  void _showAccountSheet(BuildContext context, WidgetRef ref) {
    final email = ref.read(currentUserEmailProvider) ?? 'Unknown';

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: VoidColors.backgroundLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
              const SizedBox(height: 24),
              Icon(
                Icons.account_circle,
                size: 48,
                color: VoidColors.accent.withAlpha(150),
              ),
              const SizedBox(height: 12),
              Text(
                email,
                style: TextStyle(
                  color: VoidColors.textPrimary,
                  fontFamily: 'serif',
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  key: const Key('sign_out_button'),
                  onPressed: () async {
                    Navigator.pop(context); // close sheet
                    await AuthService.signOut();
                    if (context.mounted) {
                      Navigator.pop(context); // pop GemsScreen back to home
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: VoidColors.textFaded),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'Sign out',
                    style: TextStyle(
                      color: VoidColors.textSecondary,
                      fontFamily: 'serif',
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Delete account
              TextButton(
                key: const Key('delete_account_button'),
                onPressed: () {
                  Navigator.pop(context); // close sheet first
                  _confirmDeleteAccount(context, ref);
                },
                child: Text(
                  'Delete account',
                  style: TextStyle(
                    color: Colors.red.shade400.withAlpha(180),
                    fontFamily: 'serif',
                    fontSize: 13,
                  ),
                ),
              ),
              // Privacy policy
              TextButton(
                key: const Key('account_privacy_policy_link'),
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
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: VoidColors.backgroundLight,
        title: Text(
          'Delete your account?',
          style: TextStyle(
            color: VoidColors.textPrimary,
            fontFamily: 'serif',
          ),
        ),
        content: Text(
          'All your gems will be permanently deleted. This cannot be undone.',
          style: TextStyle(
            color: VoidColors.textSecondary,
            fontFamily: 'serif',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: VoidColors.textFaded),
            ),
          ),
          TextButton(
            key: const Key('confirm_delete_account_button'),
            onPressed: () async {
              Navigator.pop(context); // close dialog
              try {
                await AuthService.deleteAccount();
                // Wipe local secure storage so transcripts don't remain
                // visible on this device after account deletion.
                await ref
                    .read(gemsControllerProvider.notifier)
                    .clearAllLocalData();
                if (context.mounted) {
                  Navigator.pop(context); // pop GemsScreen back to home
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to delete account. Please try again.',
                        style: TextStyle(fontFamily: 'serif'),
                      ),
                      backgroundColor: VoidColors.backgroundLight,
                    ),
                  );
                }
              }
            },
            child: Text(
              'Delete forever',
              style: TextStyle(color: Colors.red.shade300),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String gemId) {
    showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: VoidColors.backgroundLight,
        title: Text(
          'Delete this gem?',
          style: TextStyle(
            color: VoidColors.textPrimary,
            fontFamily: 'serif',
          ),
        ),
        content: Text(
          'This moment will be lost forever.',
          style: TextStyle(
            color: VoidColors.textSecondary,
            fontFamily: 'serif',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Keep',
              style: TextStyle(color: VoidColors.textFaded),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(gemsControllerProvider.notifier).deleteGem(gemId);
              Navigator.pop(context);
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Colors.red.shade300),
            ),
          ),
        ],
      ),
    );
  }
}
