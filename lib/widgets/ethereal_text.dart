import 'package:flutter/material.dart';
import '../main.dart';

/// A single piece of ethereal floating text with fade and position
class EtherealText extends StatelessWidget {
  final String text;
  final double opacity;
  final double fontSize;
  final FontStyle fontStyle;
  final Alignment alignment;
  final Offset offset;

  const EtherealText({
    super.key,
    required this.text,
    this.opacity = 0.3,
    this.fontSize = 20,
    this.fontStyle = FontStyle.italic,
    this.alignment = Alignment.center,
    this.offset = Offset.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Align(
        alignment: alignment,
        child: Transform.translate(
          offset: offset,
          child: Text(
            text,
            style: TextStyle(
              color: VoidColors.textFaded.withValues(alpha:opacity),
              fontSize: fontSize,
              fontStyle: fontStyle,
              fontFamily: 'serif',
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

/// Background layer with scattered ethereal text elements
class EtherealBackground extends StatelessWidget {
  const EtherealBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final height = size.height;

    return Stack(
      children: [
        // "Fleeting" - top area, small and faded
        EtherealText(
          text: 'Fleeting',
          opacity: 0.15,
          fontSize: 16,
          alignment: Alignment.topCenter,
          offset: Offset(0, height * 0.15),
        ),
        // "Memory is" - left side
        EtherealText(
          text: 'Memory is',
          opacity: 0.25,
          fontSize: 22,
          alignment: Alignment.centerLeft,
          offset: Offset(24, -height * 0.08),
        ),
        // "a fragile thing." - right side, below memory
        EtherealText(
          text: 'a fragile thing.',
          opacity: 0.35,
          fontSize: 24,
          alignment: Alignment.centerRight,
          offset: Offset(-24, height * 0.02),
        ),
        // "Preserve" - bottom left
        EtherealText(
          text: 'Preserve',
          opacity: 0.2,
          fontSize: 18,
          alignment: Alignment.bottomLeft,
          offset: Offset(24, -height * 0.18),
        ),
      ],
    );
  }
}

/// Scattered large ghost text for the listening screen background
class ListeningBackground extends StatelessWidget {
  const ListeningBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Stack(
      children: [
        // Large ghostly background text
        Positioned(
          top: size.height * 0.05,
          right: -size.width * 0.3,
          child: Text(
            'Memory is a',
            style: TextStyle(
              color: VoidColors.textGhost.withValues(alpha:0.15),
              fontSize: size.width * 0.18,
              fontFamily: 'serif',
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Positioned(
          bottom: size.height * 0.15,
          left: -size.width * 0.2,
          child: Text(
            'Preserved remains',
            style: TextStyle(
              color: VoidColors.textGhost.withValues(alpha:0.12),
              fontSize: size.width * 0.14,
              fontFamily: 'serif',
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }
}

