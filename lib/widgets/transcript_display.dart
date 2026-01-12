import 'package:flutter/material.dart';

/// Widget to display the current transcript
class TranscriptDisplay extends StatelessWidget {
  final String transcript;

  const TranscriptDisplay({
    super.key,
    required this.transcript,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey[800]!,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transcript',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.grey[500],
                  letterSpacing: 1.2,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            transcript.isEmpty ? 'Listening...' : transcript,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                  height: 1.6,
                ),
            maxLines: 8,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

