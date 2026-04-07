import 'package:flutter/material.dart';

/// Widget to display the current transcript with auto-scroll
class TranscriptDisplay extends StatefulWidget {
  final String transcript;
  final double maxHeight;
  final EdgeInsetsGeometry margin;

  const TranscriptDisplay({
    super.key,
    required this.transcript,
    this.maxHeight = 120, // ~3 lines of text
    this.margin = EdgeInsets.zero,
  });

  @override
  State<TranscriptDisplay> createState() => _TranscriptDisplayState();
}

class _TranscriptDisplayState extends State<TranscriptDisplay> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(TranscriptDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-scroll to bottom when transcript changes
    if (widget.transcript != oldWidget.transcript) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final paddingValue = (width * 0.05).clamp(14.0, 20.0);

    return Container(
      margin: widget.margin,
      padding: EdgeInsets.all(paddingValue),
      decoration: BoxDecoration(
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.18),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Transcript',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  letterSpacing: 1.2,
                ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: widget.maxHeight),
            child: ShaderMask(
              shaderCallback: (Rect bounds) {
                return LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    colorScheme.onSurface,
                    colorScheme.onSurface,
                    colorScheme.onSurface,
                  ],
                  stops: const [0.0, 0.1, 0.9, 1.0],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const ClampingScrollPhysics(),
                child: Text(
                  widget.transcript.isEmpty ? 'Listening...' : widget.transcript,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface,
                        height: 1.6,
                      ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

