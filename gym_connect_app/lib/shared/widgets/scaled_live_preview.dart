import 'package:flutter/material.dart';

/// A universal widget that takes ANY live module widget and renders it as a
/// scaled-down, crisp, real-time mini preview.
///
/// Because it embeds the ACTUAL widget inside a fixed virtual canvas and
/// scales it via [FittedBox], it:
/// 1. Exactly replicates the original module UI and layout.
/// 2. Automatically reflects whenever the module's state, theme, or design changes.
/// 3. Prevents any unwanted interaction via [IgnorePointer] so it behaves purely
///    as a live preview.
class ScaledLivePreview extends StatelessWidget {
  final Widget child;
  final double virtualWidth;
  final double virtualHeight;
  final BoxFit fit;
  final Alignment alignment;

  const ScaledLivePreview({
    super.key,
    required this.child,
    this.virtualWidth = 1100,
    this.virtualHeight = 580,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: FittedBox(
        fit: fit,
        alignment: alignment,
        child: SizedBox(
          width: virtualWidth,
          height: virtualHeight,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              size: Size(virtualWidth, virtualHeight),
            ),
            child: IgnorePointer(
              ignoring: true,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
