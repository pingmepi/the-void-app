import 'package:flutter/material.dart';

/// Widget displaying the countdown timer and rescue button
class VoidTimerWidget extends StatelessWidget {
  final int countdownSeconds;
  final VoidCallback onRescue;

  const VoidTimerWidget({
    super.key,
    required this.countdownSeconds,
    required this.onRescue,
  });

  @override
  Widget build(BuildContext context) {
    final isLowTime = countdownSeconds <= 10;
    final timerColor = isLowTime ? Colors.red : Colors.white;

    return Column(
      children: [
        // Countdown display
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: timerColor,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              '$countdownSeconds',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: timerColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Rescue button
        ElevatedButton.icon(
          onPressed: onRescue,
          icon: const Icon(Icons.save),
          label: const Text('Rescue'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 16,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Info text
        Text(
          'Tap to save before it dissolves',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[500],
              ),
        ),
      ],
    );
  }
}

