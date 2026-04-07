import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Widget displaying the countdown timer and rescue button
class VoidTimerWidget extends StatelessWidget {
  final int countdownSeconds;
  final int totalTime;
  final VoidCallback onRescue;

  const VoidTimerWidget({
    super.key,
    required this.countdownSeconds,
    this.totalTime = 10,
    required this.onRescue,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final lowTimeThreshold = math.max(1, (totalTime / 3).ceil());
    final isLowTime = countdownSeconds <= lowTimeThreshold;
    final timerColor = isLowTime ? colorScheme.error : colorScheme.onSurface;
    final trackColor = colorScheme.onSurface.withValues(alpha: 0.20);
    final infoColor = colorScheme.onSurfaceVariant;

    // Calculate progress: decreases as time runs out
    // When countdownSeconds == 10, progress = 1.0 (full circle)
    // When countdownSeconds == 0, progress = 0.0 (empty, note dissolves)
    final double progress = totalTime > 0
        ? countdownSeconds.clamp(0, totalTime).toDouble() / totalTime.toDouble()
        : 0.0;

    // Avoid an initial "fill up" animation when the countdown first appears.
    final animationDuration =
        countdownSeconds >= totalTime ? Duration.zero : const Duration(seconds: 1);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;

        // Size the ring relative to available width so it works on small phones
        // and still looks intentional on tablets.
        final ringSize = (maxW * 0.55).clamp(180.0, 280.0);
        final strokeWidth = (ringSize * 0.05).clamp(6.0, 10.0);
        final numberSize = (ringSize * 0.40).clamp(48.0, 96.0);
        final gap = (ringSize * 0.18).clamp(16.0, 28.0);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Countdown display with circular progress indicator
            SizedBox(
              width: ringSize,
              height: ringSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Positioned.fill forces the indicator to fill the full
                  // ring size — Stack passes loose constraints so without
                  // this the CircularProgressIndicator renders at 36px.
                  Positioned.fill(
                    child: Transform.rotate(
                      // Draw from 12 o'clock for a more intuitive countdown.
                      angle: -math.pi / 2,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(end: progress),
                        duration: animationDuration,
                        curve: Curves.linear,
                        builder: (context, value, child) {
                          return CircularProgressIndicator(
                            value: value,
                            strokeWidth: strokeWidth,
                            backgroundColor: trackColor,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(timerColor),
                            strokeCap: StrokeCap.round,
                          );
                        },
                      ),
                    ),
                  ),
                  // Countdown number display
                  Text(
                    '$countdownSeconds',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontSize: numberSize,
                          height: 1,
                          color: timerColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            SizedBox(height: gap),

            // Rescue button
            FilledButton.icon(
              onPressed: onRescue,
              icon: const Icon(Icons.save),
              label: const Text('Rescue'),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.onSurface,
                foregroundColor: colorScheme.surface,
                padding: EdgeInsets.symmetric(
                  horizontal: (ringSize * 0.20).clamp(18.0, 32.0),
                  vertical: (ringSize * 0.10).clamp(12.0, 16.0),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Info text
            Text(
              'Tap to save before it dissolves',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: infoColor,
                  ),
            ),
          ],
        );
      },
    );
  }
}

