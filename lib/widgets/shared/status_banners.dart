import 'package:flutter/material.dart' hide ConnectionState;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import 'package:fladder/providers/connectivity_provider.dart';
import 'package:fladder/providers/incognito_mode_provider.dart';
import 'package:fladder/util/adaptive_layout/adaptive_layout.dart';
import 'package:fladder/util/localization_helper.dart';

class StatusBanners extends ConsumerWidget {
  const StatusBanners({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offlineMode = ref.watch(connectivityStatusProvider.select((value) => value == ConnectionState.offline));
    final incognitoMode = ref.watch(incognitoModeProvider);
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: AdaptiveLayout.of(context).statusBarHeight),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          if (offlineMode) const Expanded(child: OfflineBanner()),
          if (incognitoMode) const Expanded(child: IncognitoMode()),
        ],
      ),
    );
  }
}

class IncognitoMode extends ConsumerWidget {
  const IncognitoMode({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incognitoMode = ref.watch(incognitoModeProvider);
    final theme = Theme.of(context);
    final statusBarHeight = AdaptiveLayout.of(context).statusBarHeight;
    return IgnorePointer(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: incognitoMode ? 1 : 0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8).add(EdgeInsets.only(top: statusBarHeight)),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.secondaryContainer.withValues(alpha: 1),
                theme.colorScheme.secondaryContainer.withValues(alpha: 0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Row(
            spacing: 12,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                IconsaxPlusBold.eye_slash,
                color: theme.colorScheme.onSecondaryContainer,
                size: 20,
              ),
              Text(
                context.localized.incognitoMode,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOffline = ref.watch(connectivityStatusProvider.select((value) => value == ConnectionState.offline));
    final theme = Theme.of(context);
    final statusBarHeight = AdaptiveLayout.of(context).statusBarHeight;
    return IgnorePointer(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: isOffline ? 1 : 0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8).add(EdgeInsets.only(top: statusBarHeight)),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.errorContainer.withValues(alpha: 0.8),
                theme.colorScheme.errorContainer.withValues(alpha: 0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Row(
            spacing: 12,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                IconsaxPlusBold.cloud_cross,
                color: theme.colorScheme.onErrorContainer,
                size: 20,
              ),
              Text(
                context.localized.offline,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
