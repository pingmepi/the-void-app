import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../main.dart';

class GemAudioPlayer extends StatefulWidget {
  const GemAudioPlayer({
    super.key,
    required this.audioUrl,
    this.durationSeconds,
  });

  final String audioUrl;
  final int? durationSeconds;

  @override
  State<GemAudioPlayer> createState() => _GemAudioPlayerState();
}

class _GemAudioPlayerState extends State<GemAudioPlayer> {
  late final AudioPlayer _player;
  bool _loadError = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _fmt(Duration? d) {
    if (d == null) return '--:--';
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _togglePlayPause() async {
    if (_loadError) return;

    final processing = _player.processingState;

    if (processing == ProcessingState.idle) {
      try {
        await _player.setUrl(widget.audioUrl);
        await _player.play();
      } catch (_) {
        if (mounted) setState(() => _loadError = true);
      }
      return;
    }

    if (processing == ProcessingState.completed) {
      await _player.seek(Duration.zero);
      await _player.play();
      return;
    }

    _player.playing ? await _player.pause() : await _player.play();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlayerState>(
      stream: _player.playerStateStream,
      builder: (context, _) {
        final playing = _player.playing;
        final processing = _player.processingState;
        final busy = processing == ProcessingState.loading ||
            processing == ProcessingState.buffering;

        return Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 16, 8),
          decoration: BoxDecoration(
            border:
                Border.all(color: VoidColors.accent.withValues(alpha: 0.22)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Play / pause / loading / error
              SizedBox(
                width: 40,
                height: 40,
                child: busy
                    ? Padding(
                        padding: const EdgeInsets.all(8),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: VoidColors.accent,
                        ),
                      )
                    : _loadError
                        ? Icon(Icons.error_outline,
                            color: Colors.red.shade300, size: 28)
                        : IconButton(
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              playing
                                  ? Icons.pause_circle_outline
                                  : Icons.play_circle_outline,
                              color: VoidColors.accent,
                              size: 32,
                            ),
                            onPressed: _togglePlayPause,
                          ),
              ),
              const SizedBox(width: 8),
              // Slider + timestamps
              Expanded(
                child: StreamBuilder<Duration>(
                  stream: _player.positionStream,
                  builder: (context, posSnap) {
                    final position = posSnap.data ?? Duration.zero;
                    final total = _player.duration ??
                        (widget.durationSeconds != null
                            ? Duration(seconds: widget.durationSeconds!)
                            : null);
                    final progress = total != null && total.inMilliseconds > 0
                        ? (position.inMilliseconds / total.inMilliseconds)
                            .clamp(0.0, 1.0)
                        : 0.0;

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 2,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 5),
                            overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 12),
                            activeTrackColor: VoidColors.accent,
                            inactiveTrackColor:
                                VoidColors.accent.withValues(alpha: 0.2),
                            thumbColor: VoidColors.accent,
                            overlayColor:
                                VoidColors.accent.withValues(alpha: 0.15),
                          ),
                          child: Slider(
                            value: progress,
                            onChanged: total != null
                                ? (v) => _player.seek(Duration(
                                    milliseconds:
                                        (v * total.inMilliseconds).round()))
                                : null,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _fmt(position == Duration.zero &&
                                        processing == ProcessingState.idle
                                    ? null
                                    : position),
                                style: TextStyle(
                                  color: VoidColors.textSecondary,
                                  fontSize: 11,
                                  fontFamily: 'serif',
                                ),
                              ),
                              Text(
                                _fmt(total),
                                style: TextStyle(
                                  color: VoidColors.textSecondary,
                                  fontSize: 11,
                                  fontFamily: 'serif',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
