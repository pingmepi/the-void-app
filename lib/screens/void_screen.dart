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
    final voidState = ref.watch(voidControllerProvider);
    final speechState = ref.watch(speechControllerProvider);
    final transcript = ref.watch(transcriptProvider);
    final countdownSeconds = ref.watch(countdownSecondsProvider);

    // Use speech controller's transcript for real-time updates
    final displayTranscript = speechState.transcript.isNotEmpty
        ? speechState.transcript
        : transcript;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'The Void',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getStatusText(voidState, speechState),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _getStatusColor(voidState),
                        ),
                  ),
                ],
              ),
            ),

            // Main content area
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Waveform during active listening (before any words captured)
                    if (voidState == VoidState.listening && displayTranscript.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            WaveformVisualizer(
                              isActive: true,
                              color: Colors.red[400]!,
                              barCount: 9,
                              width: 180,
                              height: 60,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Listening...',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[500],
                                  ),
                            ),
                          ],
                        ),
                      )
                    // Transcript display (when we have words or in countdown)
                    else if (voidState.isTranscriptVisible ||
                             (voidState == VoidState.listening && displayTranscript.isNotEmpty))
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Mini waveform above transcript while still recording
                            if (voidState == VoidState.listening)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: WaveformVisualizer(
                                  isActive: true,
                                  color: Colors.red[400]!,
                                  barCount: 5,
                                  width: 80,
                                  height: 30,
                                ),
                              ),
                            TranscriptDisplay(transcript: displayTranscript),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Main interaction area based on state
                    _buildMainContent(context, ref, voidState, countdownSeconds),

                    // Error display
                    if (speechState.error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Text(
                          speechState.error!,
                          style: TextStyle(color: Colors.red[400], fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Ephemeral by default. Intentional by choice.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
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
  ) {
    switch (state) {
      case VoidState.idle:
        return _buildStartButton(context, ref);
      case VoidState.listening:
      case VoidState.transcribing:
        return _buildListeningIndicator(context, ref);
      case VoidState.countdown:
        return VoidTimerWidget(
          countdownSeconds: countdownSeconds ?? 10,
          onRescue: () {
            ref.read(voidControllerProvider.notifier).rescueNote(null);
          },
        );
      case VoidState.voided:
      case VoidState.saved:
        return _buildStateIndicator(context, state);
    }
  }

  Widget _buildStartButton(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        ref.read(speechControllerProvider.notifier).startRecording();
      },
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.mic,
            size: 48,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildListeningIndicator(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Animated listening indicator
        GestureDetector(
          onTap: () {
            ref.read(speechControllerProvider.notifier).stopRecording();
          },
          child: Container(
            width: 120,
            height: 120,
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
                size: 48,
                color: Colors.red[400],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Tap to stop',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[500],
              ),
        ),
      ],
    );
  }

  Widget _buildStateIndicator(BuildContext context, VoidState state) {
    final isVoided = state == VoidState.voided;
    return Column(
      children: [
        Icon(
          isVoided ? Icons.delete_forever : Icons.check_circle,
          size: 64,
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

