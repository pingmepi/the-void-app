import 'package:flutter/material.dart';
import '../main.dart';

/// A glowing microphone button with an ethereal green glow effect
class GlowingMicButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isListening;
  final double size;

  const GlowingMicButton({
    super.key,
    required this.onTap,
    this.isListening = false,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    final outerRingSize = size * 1.4;
    final glowSpread = size * 0.2;
    final iconSize = size * 0.45;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: outerRingSize + glowSpread * 2,
        height: outerRingSize + glowSpread * 2,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow ring
            Container(
              width: outerRingSize,
              height: outerRingSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: VoidColors.accentDim.withValues(alpha:0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: VoidColors.accentGlow.withValues(alpha:0.15),
                    blurRadius: glowSpread,
                    spreadRadius: glowSpread * 0.3,
                  ),
                ],
              ),
            ),
            // Inner filled circle with mic icon
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: VoidColors.background,
                border: Border.all(
                  color: VoidColors.accent.withValues(alpha:0.8),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: VoidColors.accentGlow.withValues(alpha:0.3),
                    blurRadius: glowSpread * 0.8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                isListening ? Icons.stop : Icons.mic,
                size: iconSize,
                color: VoidColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated version of GlowingMicButton with pulsing glow effect
class AnimatedGlowingMicButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool isListening;
  final double size;

  const AnimatedGlowingMicButton({
    super.key,
    required this.onTap,
    this.isListening = false,
    this.size = 80,
  });

  @override
  State<AnimatedGlowingMicButton> createState() =>
      _AnimatedGlowingMicButtonState();
}

class _AnimatedGlowingMicButtonState extends State<AnimatedGlowingMicButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.15, end: 0.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final outerRingSize = widget.size * 1.4;
    final glowSpread = widget.size * 0.2;
    final iconSize = widget.size * 0.45;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return SizedBox(
            width: outerRingSize + glowSpread * 2,
            height: outerRingSize + glowSpread * 2,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow ring with animation
                Container(
                  width: outerRingSize,
                  height: outerRingSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: VoidColors.accentDim.withValues(alpha:0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: VoidColors.accentGlow
                            .withValues(alpha:_glowAnimation.value),
                        blurRadius: glowSpread * (1 + _glowAnimation.value),
                        spreadRadius: glowSpread * 0.3,
                      ),
                    ],
                  ),
                ),
                // Inner circle
                child!,
              ],
            ),
          );
        },
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: VoidColors.background,
            border: Border.all(
              color: VoidColors.accent.withValues(alpha:0.8),
              width: 2,
            ),
          ),
          child: Icon(
            widget.isListening ? Icons.stop : Icons.mic,
            size: iconSize,
            color: VoidColors.accent,
          ),
        ),
      ),
    );
  }
}

