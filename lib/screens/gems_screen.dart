import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/auth_controller.dart';
import '../controllers/gems_controller.dart';
import '../main.dart';
import '../models/gem_note.dart';
import '../services/auth_service.dart';
import '../widgets/gem_card.dart';
import 'gem_detail_screen.dart';

class GemsScreen extends ConsumerWidget {
  const GemsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gems = ref.watch(sortedGemsProvider);
    final isLoggedIn = ref.watch(isLoggedInProvider);

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
      body: gems.isEmpty ? _buildEmptyState() : _buildGemsList(context, ref, gems),
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
            ],
          ),
        ),
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
