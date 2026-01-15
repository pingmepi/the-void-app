import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';
import '../models/void_state.dart';
import '../controllers/void_controller.dart';
import '../controllers/speech_controller.dart';
import '../widgets/void_timer_widget.dart';
import '../widgets/ethereal_text.dart';
import '../widgets/glowing_mic_button.dart';

/// Main screen for The Void app - Ethereal voice capture experience
class VoidScreen extends ConsumerWidget {
  const VoidScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voidState = ref.watch(voidControllerProvider.select((s) => s.status));
    final speechState = ref.watch(speechControllerProvider);
    final transcript = ref.watch(transcriptProvider);
    final countdownSeconds = ref.watch(countdownSecondsProvider);

    // Use speech controller's transcript for real-time updates
    final displayTranscript = speechState.transcript.isNotEmpty
        ? speechState.transcript
        : transcript;

    return Scaffold(
      backgroundColor: VoidColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            final micButtonSize = (math.min(width, height) * 0.18).clamp(70.0, 100.0);

            // Decide which screen to show based on state
            if (voidState == VoidState.idle) {
              return _buildLandingScreen(context, ref, micButtonSize, height);
            } else if (voidState == VoidState.listening ||
                voidState == VoidState.transcribing) {
              return _buildListeningScreen(
                context,
                ref,
                micButtonSize,
                height,
                displayTranscript,
              );
            } else if (voidState == VoidState.countdown) {
              return _buildCountdownScreen(
                context,
                ref,
                countdownSeconds ?? 10,
                displayTranscript,
              );
            } else {
              return _buildResultScreen(context, ref, voidState);
            }
          },
        ),
      ),
    );
  }

  /// Landing screen - ethereal floating text with glowing mic button
  Widget _buildLandingScreen(
    BuildContext context,
    WidgetRef ref,
    double micButtonSize,
    double screenHeight,
  ) {
    return Stack(
      children: [
        // Background ethereal text
        const EtherealBackground(),

        // Main content
        Positioned.fill(
          child: Column(
            children: [
              const Spacer(flex: 5),

              // Mic button in center
              AnimatedGlowingMicButton(
                onTap: () {
                  ref.read(speechControllerProvider.notifier).startRecording();
                },
                size: micButtonSize,
              ),

              const Spacer(flex: 3),

              // Bottom tagline
              Padding(
                padding: EdgeInsets.only(bottom: screenHeight * 0.08),
                child: Column(
                  children: [
                    Text(
                      'LISTEN TO THE',
                      style: TextStyle(
                        color: VoidColors.textFaded,
                        fontSize: 12,
                        letterSpacing: 4,
                        fontFamily: 'serif',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'what remains.',
                      style: TextStyle(
                        color: VoidColors.textSecondary.withOpacity(0.5),
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        fontFamily: 'serif',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Listening screen - stacked transcript text with glowing mic
  Widget _buildListeningScreen(
    BuildContext context,
    WidgetRef ref,
    double micButtonSize,
    double screenHeight,
    String transcript,
  ) {
    return Stack(
      children: [
        // Background ghost text
        const ListeningBackground(),

        // Main content
        Positioned.fill(
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Transcript display area - stacked text with varying opacity
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: _buildStackedTranscript(context, transcript),
                ),
              ),

              // Mic button
              Padding(
                padding: EdgeInsets.only(bottom: screenHeight * 0.12),
                child: GlowingMicButton(
                  onTap: () {
                    ref.read(speechControllerProvider.notifier).stopRecording();
                  },
                  isListening: true,
                  size: micButtonSize,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build the stacked transcript display with varying opacity
  Widget _buildStackedTranscript(BuildContext context, String transcript) {
    if (transcript.isEmpty) {
      return Center(
        child: Text(
          '...fragments of the lost data...',
          style: TextStyle(
            color: VoidColors.textSecondary.withOpacity(0.6),
            fontSize: 16,
            fontStyle: FontStyle.italic,
            fontFamily: 'serif',
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Split transcript into phrases for stacked display
    final words = transcript.split(' ');
    final phrases = <String>[];

    // Group words into phrases of 3-6 words
    for (var i = 0; i < words.length; i += 4) {
      final end = math.min(i + 4, words.length);
      phrases.add(words.sublist(i, end).join(' '));
    }

    // Take last 5 phrases for display
    final displayPhrases = phrases.length > 5
        ? phrases.sublist(phrases.length - 5)
        : phrases;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var i = 0; i < displayPhrases.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              displayPhrases[i],
              style: TextStyle(
                color: VoidColors.accent.withOpacity(
                  0.3 + (i / displayPhrases.length) * 0.7,
                ),
                fontSize: 18 + (i * 2),
                fontFamily: 'serif',
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  /// Countdown screen
  Widget _buildCountdownScreen(
    BuildContext context,
    WidgetRef ref,
    int countdownSeconds,
    String transcript,
  ) {
    return Stack(
      children: [
        const ListeningBackground(),
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Show transcript preview
                if (transcript.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: Text(
                      transcript.length > 100
                          ? '${transcript.substring(0, 100)}...'
                          : transcript,
                      style: TextStyle(
                        color: VoidColors.textSecondary,
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        fontFamily: 'serif',
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                VoidTimerWidget(
                  countdownSeconds: countdownSeconds,
                  onRescue: () {
                    ref.read(voidControllerProvider.notifier).rescueNote(null);
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Result screen (saved or voided)
  Widget _buildResultScreen(
    BuildContext context,
    WidgetRef ref,
    VoidState state,
  ) {
    final isVoided = state == VoidState.voided;
    return Stack(
      children: [
        const EtherealBackground(),
        Positioned.fill(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isVoided ? Icons.blur_on : Icons.auto_awesome,
                size: 64,
                color: isVoided
                    ? VoidColors.textFaded
                    : VoidColors.accent,
              ),
              const SizedBox(height: 24),
              Text(
                isVoided ? 'Dissolved into the void' : 'Preserved as a Gem',
                style: TextStyle(
                  color: isVoided
                      ? VoidColors.textSecondary
                      : VoidColors.accent,
                  fontSize: 20,
                  fontStyle: FontStyle.italic,
                  fontFamily: 'serif',
                ),
              ),
              const SizedBox(height: 48),
              // Tap to continue
              GestureDetector(
                onTap: () {
                  ref.read(voidControllerProvider.notifier).reset();
                },
                child: Text(
                  'Tap to continue',
                  style: TextStyle(
                    color: VoidColors.textFaded,
                    fontSize: 14,
                    fontFamily: 'serif',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

