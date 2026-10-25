import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:fladder/util/frontmost_route.dart';

class TabBackGesture extends StatefulWidget {
  final bool enabled;
  final VoidCallback onBack;
  final Widget child;
  const TabBackGesture({
    required this.enabled,
    required this.onBack,
    required this.child,
    super.key,
  });

  @override
  State<TabBackGesture> createState() => _TabBackGestureState();
}

class _TabBackGestureState extends State<TabBackGesture> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 160),
  );
  SwipeEdge _edge = SwipeEdge.left;
  double? _commitStart;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _progress.dispose();
    super.dispose();
  }

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
    final accepts = widget.enabled && !backEvent.isButtonEvent && isFrontmostRoute(context);
    if (accepts) {
      _edge = backEvent.swipeEdge;
      _progress.value = 0;
    }
    return accepts;
  }

  @override
  void handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) => _progress.value = backEvent.progress;

  @override
  void handleCancelBackGesture() => unawaited(_progress.animateBack(0));

  @override
  void handleCommitBackGesture() {
    _commitStart = _progress.value;
    unawaited(
      _progress.animateTo(1).then((_) {
        if (!mounted) return;
        widget.onBack();
        _commitStart = null;
        _progress.value = 0;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      builder: (context, child) {
        final eased = Curves.easeOut.transform(_progress.value);
        final direction = _edge == SwipeEdge.left ? 1 : -1;
        final commitStart = _commitStart;
        final opacity =
            commitStart == null || commitStart >= 1 ? 1.0 : ((1 - _progress.value) / (1 - commitStart)).clamp(0.0, 1.0);
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(direction * eased * math.min(32, MediaQuery.sizeOf(context).width * 0.08), 0),
            child: Transform.scale(
              scale: 1 - 0.1 * eased,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32 * eased),
                clipBehavior: eased == 0 ? Clip.none : Clip.antiAlias,
                child: child,
              ),
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}
