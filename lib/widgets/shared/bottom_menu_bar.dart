import 'package:flutter/material.dart';

import 'package:fladder/screens/shared/animated_fade_size.dart';
import 'package:fladder/theme.dart';
import 'package:fladder/util/adaptive_layout/adaptive_layout.dart';
import 'package:fladder/widgets/shared/item_actions.dart';

class BottomMenuBar extends StatelessWidget {
  final List<ItemAction> actions;
  final FloatingActionButton? fabAction;
  final bool combined;
  final bool extended;
  const BottomMenuBar({
    super.key,
    required this.actions,
    this.fabAction,
    this.combined = false,
    this.extended = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16).add(AdaptiveLayout.adaptivePadding(context)),
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 4,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: FladderTheme.largeShape.borderRadius,
              ),
              child: Row(
                spacing: 0,
                children: [
                  AnimatedFadeSize(
                    duration: const Duration(milliseconds: 250),
                    alignment: Alignment.centerRight,
                    child: extended
                        ? Row(
                            children: [const SizedBox(width: 8), ...actions.reversed.map((e) => e.toButton())],
                          )
                        : const SizedBox.shrink(key: ValueKey('empty')),
                  ),
                  if (fabAction != null && combined)
                    SizedBox.square(
                      dimension: 48,
                      child: Theme(
                        data: theme.copyWith(
                          floatingActionButtonTheme: FloatingActionButtonThemeData(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            elevation: 0,
                            shape: FladderTheme.largeShape,
                          ),
                        ),
                        child: fabAction!,
                      ),
                    ),
                ],
              ),
            ),
            if (fabAction != null && !combined)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: fabAction!,
              ),
          ],
        ),
      ),
    );
  }
}
