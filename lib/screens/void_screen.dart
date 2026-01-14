import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/void_state.dart';
import '../controllers/void_controller.dart';
import '../controllers/speech_controller.dart';
import '../widgets/void_timer_widget.dart';
import '../widgets/transcript_display.dart';
import '../widgets/waveform_visualizer.dart';

/// Main screen for The Void app
class VoidScreen extends ConsumerWidget {
  const VoidScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voidState = ref.watch(voidControllerProvider.select((s) => s.status));
    final speechState = ref.watch(speechControllerProvider);
    final transcript = ref.watch(transcriptProvider);
    final countdownSeconds = ref.watch(countdownSecondsProvider);

    final colorScheme = Theme.of(context).colorScheme;

    // Use speech controller's transcript for real-time updates
    final displayTranscript = speechState.transcript.isNotEmpty
        ? speechState.transcript
        : transcript;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            // Responsive layout values (clamped for consistency).
            final horizontalPadding = (width * 0.06).clamp(16.0, 28.0);
            final verticalPadding = (height * 0.03).clamp(16.0, 28.0);
            const maxContentWidth = 640.0;
            final contentWidth = math.min(width, maxContentWidth);

            final primaryButtonSize =
                (math.min(contentWidth, height) * 0.22).clamp(96.0, 140.0);
            final primaryIconSize =
                (primaryButtonSize * 0.40).clamp(36.0, 56.0);

            final transcriptMaxHeight =
                (height * 0.22).clamp(110.0, 170.0); // prevents tall overflow

            final waveformLargeWidth =
                (contentWidth * 0.35).clamp(150.0, 220.0);
            final waveformLargeHeight =
                (waveformLargeWidth * 0.32).clamp(44.0, 72.0);
            final waveformSmallWidth =
                (contentWidth * 0.16).clamp(72.0, 96.0);
            final waveformSmallHeight =
                (waveformSmallWidth * 0.36).clamp(24.0, 36.0);

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: maxContentWidth),
                child: SizedBox(
                  height: height,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Header
                        Padding(
                          padding: EdgeInsets.only(top: verticalPadding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'The Void',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _getStatusText(voidState, speechState),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: _getStatusColor(voidState),
                                    ),
                              ),
                            ],
                          ),
                        ),

                        // Main content area
                        Expanded(
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Waveform during active listening (before any words captured)
                                  if (voidState == VoidState.listening &&
                                      displayTranscript.isEmpty)
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        WaveformVisualizer(
                                          isActive: true,
                                          color: colorScheme.error,
                                          barCount: 9,
                                          width: waveformLargeWidth,
                                          height: waveformLargeHeight,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Listening...',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color:
                                                    colorScheme.onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    )
                                  // Transcript display (when we have words or in countdown)
                                  else if (voidState.isTranscriptVisible ||
                                      (voidState == VoidState.listening &&
                                          displayTranscript.isNotEmpty))
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Mini waveform above transcript while still recording
                                        if (voidState == VoidState.listening)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(bottom: 12.0),
                                            child: WaveformVisualizer(
                                              isActive: true,
                                              color: colorScheme.error,
                                              barCount: 5,
                                              width: waveformSmallWidth,
                                              height: waveformSmallHeight,
                                            ),
                                          ),
                                        TranscriptDisplay(
                                          transcript: displayTranscript,
                                          maxHeight: transcriptMaxHeight,
                                        ),
                                      ],
                                    ),

                                  const SizedBox(height: 24),

                                  // Main interaction area based on state
                                  _buildMainContent(
                                    context,
                                    ref,
                                    voidState,
                                    countdownSeconds,
                                    primaryButtonSize,
                                    primaryIconSize,
                                  ),

                                  // Error display
                                  if (speechState.error != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12.0),
                                      child: Text(
                                        speechState.error!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: colorScheme.error),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Footer
                        Padding(
                          padding: EdgeInsets.only(bottom: verticalPadding),
                          child: Text(
                            'Ephemeral by default. Intentional by choice.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _getStatusText(VoidState state, SpeechControllerState speechState) {
    if (state == VoidState.listening) {
      return speechState.transcript.isEmpty
          ? 'Listening for your thoughts...'
          : 'Recording...';
    }
    return state.displayName;
  }

  Color _getStatusColor(VoidState state) {
    switch (state) {
      case VoidState.listening:
        return Colors.red[400]!;
      case VoidState.countdown:
        return Colors.orange[400]!;
      case VoidState.saved:
        return Colors.green[400]!;
      default:
        return Colors.grey[400]!;
    }
  }

  Widget _buildMainContent(
    BuildContext context,
    WidgetRef ref,
    VoidState state,
    int? countdownSeconds,
    double primaryButtonSize,
    double primaryIconSize,
  ) {
    switch (state) {
      case VoidState.idle:
        return _buildStartButton(
          context,
          ref,
          primaryButtonSize,
          primaryIconSize,
        );
      case VoidState.listening:
      case VoidState.transcribing:
        return _buildListeningIndicator(
          context,
          ref,
          primaryButtonSize,
          primaryIconSize,
        );
      case VoidState.countdown:
        return VoidTimerWidget(
          countdownSeconds: countdownSeconds ?? 10,
          onRescue: () {
            ref.read(voidControllerProvider.notifier).rescueNote(null);
          },
        );
      case VoidState.voided:
      case VoidState.saved:
        return _buildStateIndicator(context, state, primaryIconSize);
    }
  }

  Widget _buildStartButton(
    BuildContext context,
    WidgetRef ref,
    double size,
    double iconSize,
  ) {
    return GestureDetector(
      onTap: () {
        ref.read(speechControllerProvider.notifier).startRecording();
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.mic,
            size: iconSize,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildListeningIndicator(
    BuildContext context,
    WidgetRef ref,
    double size,
    double iconSize,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        // Animated listening indicator
        GestureDetector(
          onTap: () {
            ref.read(speechControllerProvider.notifier).stopRecording();
          },
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red.withAlpha(50),
              border: Border.all(
                color: Colors.red[400]!,
                width: 3,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.stop,
                size: iconSize,
                color: Colors.red[400],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Tap to stop',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildStateIndicator(
    BuildContext context,
    VoidState state,
    double iconSize,
  ) {
    final isVoided = state == VoidState.voided;
    return Column(
      children: [
        Icon(
          isVoided ? Icons.delete_forever : Icons.check_circle,
          size: (iconSize * 1.2).clamp(56.0, 72.0),
          color: isVoided ? Colors.grey[600] : Colors.green[400],
        ),
        const SizedBox(height: 16),
        Text(
          isVoided ? 'Gone forever' : 'Saved to Gems',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: isVoided ? Colors.grey[600] : Colors.green[400],
              ),
        ),
      ],
    );
  }
}

