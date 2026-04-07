import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/gems_controller.dart';
import '../main.dart';
import '../models/gem_note.dart';
import '../widgets/gem_card.dart';
import 'gem_detail_screen.dart';

class GemsScreen extends ConsumerWidget {
  const GemsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gems = ref.watch(sortedGemsProvider);

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
      separatorBuilder: (_, __) => const SizedBox(height: 8),
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
