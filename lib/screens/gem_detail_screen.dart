import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/gems_controller.dart';
import '../main.dart';

/// Detail view for a single gem — full transcript, inline title edit, delete.
class GemDetailScreen extends ConsumerStatefulWidget {
  const GemDetailScreen({super.key, required this.gemId});

  final String gemId;

  @override
  ConsumerState<GemDetailScreen> createState() => _GemDetailScreenState();
}

class _GemDetailScreenState extends ConsumerState<GemDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final gem = ref.watch(gemsControllerProvider.notifier).getGem(widget.gemId);
    if (gem == null) {
      return Scaffold(
        backgroundColor: VoidColors.background,
        body: const Center(child: Text('Gem not found')),
      );
    }

    return Scaffold(
      backgroundColor: VoidColors.background,
      appBar: AppBar(
        backgroundColor: VoidColors.background,
        elevation: 0,
        leading: const BackButton(color: VoidColors.accent),
      ),
      body: const Center(child: Text('Detail placeholder')),
    );
  }
}
