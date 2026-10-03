import 'package:flutter/material.dart';

/// Caps body content width on large screens (iPad, landscape) and centres
/// it, so lists and detail pages don't stretch edge-to-edge into unreadable
/// full-width rows. Apple reviews on an iPad Air -- a phone layout blown up
/// to 1180pt is a Guideline 4.0 risk.
///
/// Use it to wrap a screen's scrollable body. It preserves the child's own
/// scrolling; it only constrains width.
class PageBody extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const PageBody({super.key, required this.child, this.maxWidth = 640});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
