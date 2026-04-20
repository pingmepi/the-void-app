import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/gems_controller.dart';
import '../main.dart';
import '../widgets/gem_audio_player.dart';
import '../widgets/gem_card.dart';

class GemDetailScreen extends ConsumerStatefulWidget {
  const GemDetailScreen({super.key, required this.gemId});

  final String gemId;

  @override
  ConsumerState<GemDetailScreen> createState() => _GemDetailScreenState();
}

class _GemDetailScreenState extends ConsumerState<GemDetailScreen> {
  bool _isEditingTitle = false;
  late TextEditingController _titleController;
  late FocusNode _titleFocusNode;

  @override
  void initState() {
    super.initState();
    final gem = ref.read(gemsControllerProvider.notifier).getGem(widget.gemId);
    _titleController = TextEditingController(text: gem?.title ?? '');
    _titleFocusNode = FocusNode();
    _titleFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_titleFocusNode.hasFocus && _isEditingTitle) {
      _saveTitle();
    }
  }

  void _saveTitle() {
    final trimmed = _titleController.text.trim();
    if (trimmed.isNotEmpty) {
      ref
          .read(gemsControllerProvider.notifier)
          .updateGemTitle(widget.gemId, trimmed);
    }
    setState(() => _isEditingTitle = false);
  }

  @override
  void dispose() {
    _titleFocusNode.removeListener(_onFocusChange);
    _titleFocusNode.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gem = ref.watch(gemsControllerProvider.notifier).getGem(widget.gemId);
    if (gem == null) {
      // Gem was deleted — auto-pop
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
      return Scaffold(backgroundColor: VoidColors.background);
    }

    return Scaffold(
      backgroundColor: VoidColors.background,
      appBar: AppBar(
        backgroundColor: VoidColors.background,
        elevation: 0,
        leading: const BackButton(color: VoidColors.accent),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title area — tap to edit
              GestureDetector(
                key: const Key('gem_title_display'),
                onTap: () {
                  setState(() => _isEditingTitle = true);
                  _titleFocusNode.requestFocus();
                },
                child: _isEditingTitle
                    ? TextField(
                        controller: _titleController,
                        focusNode: _titleFocusNode,
                        onSubmitted: (_) => _saveTitle(),
                        style: TextStyle(
                          color: VoidColors.textPrimary,
                          fontFamily: 'serif',
                          fontStyle: FontStyle.italic,
                          fontSize: 22,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Name this gem...',
                          hintStyle: TextStyle(
                            color: VoidColors.textFaded,
                            fontFamily: 'serif',
                            fontStyle: FontStyle.italic,
                          ),
                          border: InputBorder.none,
                        ),
                      )
                    : Text(
                        gem.title?.isNotEmpty == true
                            ? gem.title!
                            : 'Tap to name this gem',
                        style: TextStyle(
                          color: gem.title?.isNotEmpty == true
                              ? VoidColors.textPrimary
                              : VoidColors.textFaded,
                          fontFamily: 'serif',
                          fontStyle: FontStyle.italic,
                          fontSize: 22,
                        ),
                      ),
              ),

              const SizedBox(height: 16),
              Divider(color: VoidColors.textGhost),
              const SizedBox(height: 16),

              // Date + duration row
              Row(
                children: [
                  Icon(Icons.schedule, size: 14, color: VoidColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    GemCard.formatDate(gem.savedAt),
                    style: TextStyle(
                      color: VoidColors.textSecondary,
                      fontSize: 13,
                      fontFamily: 'serif',
                    ),
                  ),
                  if (gem.durationSeconds != null) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.mic, size: 14, color: VoidColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      GemCard.formatDuration(gem.durationSeconds!),
                      style: TextStyle(
                        color: VoidColors.textSecondary,
                        fontSize: 13,
                        fontFamily: 'serif',
                      ),
                    ),
                  ],
                ],
              ),

              if (gem.audioUrl != null) ...[
                const SizedBox(height: 20),
                GemAudioPlayer(
                  audioUrl: gem.audioUrl!,
                  durationSeconds: gem.durationSeconds,
                ),
              ],

              const SizedBox(height: 24),

              // Full transcript
              Text(
                gem.transcript,
                style: TextStyle(
                  color: VoidColors.textPrimary,
                  fontSize: 16,
                  fontFamily: 'serif',
                  height: 1.7,
                  letterSpacing: 0.3,
                ),
              ),

              const SizedBox(height: 48),

              // Delete button
              Center(
                child: OutlinedButton.icon(
                  icon: Icon(Icons.delete_outline, color: Colors.red.shade300),
                  label: Text(
                    'Delete gem',
                    style: TextStyle(color: Colors.red.shade300),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: Colors.red.shade300.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _showDeleteDialog(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
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
            child: Text('Keep', style: TextStyle(color: VoidColors.textFaded)),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(gemsControllerProvider.notifier)
                  .deleteGem(widget.gemId);
              Navigator.pop(context); // close dialog
              Navigator.of(this.context).pop(); // pop detail screen
            },
            child: Text('Delete', style: TextStyle(color: Colors.red.shade300)),
          ),
        ],
      ),
    );
  }
}
