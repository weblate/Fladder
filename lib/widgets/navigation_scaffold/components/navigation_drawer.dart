import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:auto_route/auto_route.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import 'package:fladder/models/collection_types.dart';
import 'package:fladder/models/item_base_model.dart';
import 'package:fladder/models/view_model.dart';
import 'package:fladder/providers/dashboard_mode_provider.dart';
import 'package:fladder/providers/playlist_provider.dart';
import 'package:fladder/providers/settings/client_settings_provider.dart';
import 'package:fladder/routes/auto_router.gr.dart';
import 'package:fladder/screens/metadata/refresh_metadata.dart';
import 'package:fladder/screens/shared/animated_fade_size.dart';
import 'package:fladder/theme.dart';
import 'package:fladder/util/adaptive_layout/adaptive_layout.dart';
import 'package:fladder/util/color_extensions.dart';
import 'package:fladder/util/fladder_image.dart';
import 'package:fladder/util/localization_helper.dart';
import 'package:fladder/widgets/navigation_scaffold/components/adaptive_fab.dart';
import 'package:fladder/widgets/navigation_scaffold/components/destination_model.dart';
import 'package:fladder/widgets/navigation_scaffold/components/drawer_list_button.dart';
import 'package:fladder/widgets/navigation_scaffold/components/music_dashboard_nav_items.dart';
import 'package:fladder/widgets/navigation_scaffold/components/settings_user_icon.dart';
import 'package:fladder/widgets/shared/item_actions.dart';

class NestedNavigationDrawer extends ConsumerWidget {
  final bool isExpanded;
  final Function(bool expanded) toggleExpanded;
  final List<DestinationModel> destinations;
  final AdaptiveFab? actionButton;
  final List<ViewModel> views;
  final String currentLocation;
  const NestedNavigationDrawer(
      {this.isExpanded = false,
      required this.toggleExpanded,
      required this.actionButton,
      required this.destinations,
      required this.views,
      required this.currentLocation,
      super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useLibraryPosters = ref.watch(clientSettingsProvider.select((value) => value.usePosterForLibrary));
    final musicDashboard = ref.watch(musicDashboardModeProvider);

    final playLists = ref.watch(playlistProvider.select((value) => value.collections));

    final musicItems = MusicLibraryItem.fromViews(context, views, false, ref);

    return NavigationDrawer(
      key: const Key('navigation_drawer'),
      backgroundColor: isExpanded ? Colors.transparent : null,
      surfaceTintColor: isExpanded ? Colors.transparent : null,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(28, AdaptiveLayout.of(context).isDesktop || kIsWeb ? 0 : 16, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  context.localized.navigation,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                onPressed: () => toggleExpanded(false),
                icon: const Icon(IconsaxPlusLinear.sidebar_left),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: actionButton != null ? 8 : 0),
          child: AnimatedFadeSize(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: actionButton?.extended,
            ),
          ),
        ),
        ...destinations.map(
          (destination) => DrawerListButton(
            label: destination.label,
            selected: context.router.current.name == destination.route?.routeName,
            selectedIcon: destination.selectedIcon!,
            icon: destination.icon!,
            onPressed: () {
              destination.action!();
              Scaffold.of(context).closeDrawer();
            },
          ),
        ),
        if (!musicDashboard && views.isNotEmpty) ...{
          const Divider(indent: 28, endIndent: 28),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
            child: Text(
              context.localized.library(2),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ...views.map(
            (library) {
              var selected = context.router.currentUrl.contains(library.id);
              final Widget? posterIcon = useLibraryPosters
                  ? ClipRRect(
                      borderRadius: FladderTheme.smallShape.borderRadius,
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: FladderImage(
                          image: library.imageData?.primary,
                          placeHolder: Card(
                            child: Icon(
                              selected ? library.collectionType.icon : library.collectionType.iconOutlined,
                            ),
                          ),
                        ),
                      ),
                    )
                  : null;
              return DrawerListButton(
                label: library.name,
                selected: selected,
                actions: [
                  ItemActionButton(
                    label: Text(context.localized.scanLibrary),
                    icon: const Icon(IconsaxPlusLinear.refresh),
                    action: () => showRefreshPopup(context, library.id, library.name),
                  ),
                ],
                onPressed: () {
                  context.router.push(LibrarySearchRoute(viewModelId: library.id));
                  Scaffold.of(context).closeDrawer();
                },
                selectedIcon: posterIcon ?? Icon(library.collectionType.icon),
                icon: posterIcon ?? Icon(library.collectionType.iconOutlined),
              );
            },
          ),
        } else if (musicDashboard) ...[
          const Divider(indent: 28, endIndent: 28),
          ...musicItems.map(
            (e) {
              return DrawerListButton(
                label: e.label,
                selected: context.router.currentUrl.contains(e.pathKey),
                onPressed: () {
                  e.onTap();
                  Scaffold.of(context).closeDrawer();
                },
                selectedIcon: e.selectedIcon,
                icon: e.icon,
              );
            },
          ),
          const Divider(indent: 28, endIndent: 28),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
            child: Text(
              context.localized.mediaTypePlaylist(2),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ...playLists.entries.map(
            (entry) {
              final derivePosterColor = ref.watch(clientSettingsProvider.select((value) => value.dynamicPosterColors));
              final backgroundColor = derivePosterColor
                  ? entry.key.name.toColor.harmonizeWith(Theme.of(context).colorScheme.surface)
                  : Theme.of(context).colorScheme.surface;
              final Widget? posterIcon = useLibraryPosters
                  ? SizedBox.square(
                      dimension: 48,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: FladderTheme.smallShape.borderRadius,
                          color: backgroundColor,
                        ),
                        clipBehavior: Clip.hardEdge,
                        padding: const EdgeInsets.all(2),
                        child: ClipRRect(
                          borderRadius: FladderTheme.smallShape.borderRadius,
                          child: FladderImage(
                            image: entry.key.images?.primary,
                            placeHolder: Container(
                              color: backgroundColor,
                              child: Icon(
                                FladderItemType.playlist.icon,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    )
                  : null;
              return DrawerListButton(
                label: entry.key.name,
                selected: context.router.currentUrl.contains(entry.key.id),
                onPressed: () {
                  entry.key.navigateTo(context);
                  Scaffold.of(context).closeDrawer();
                },
                selectedIcon: posterIcon ?? Icon(entry.key.type.selectedicon),
                icon: posterIcon ?? Icon(entry.key.type.icon),
              );
            },
          ),
        ],
        const Divider(indent: 28, endIndent: 28),
        if (isExpanded)
          Transform.translate(
            offset: const Offset(-8, 0),
            child: DrawerListButton(
              label: context.localized.settings,
              selectedIcon: const Icon(IconsaxPlusBold.setting_3),
              selected: currentLocation.contains(const SettingsRoute().routeName),
              icon: const SizedBox(width: 35, height: 35, child: SettingsUserIcon()),
              onPressed: () {
                switch (AdaptiveLayout.layoutModeOf(context)) {
                  case LayoutMode.single:
                    const SettingsRoute().push(context);
                    break;
                  case LayoutMode.dual:
                    context.router.push(const ClientSettingsRoute());
                    break;
                }
                Scaffold.of(context).closeDrawer();
              },
            ),
          )
        else
          DrawerListButton(
            label: context.localized.settings,
            selectedIcon: const Icon(IconsaxPlusBold.setting_2),
            icon: const Icon(IconsaxPlusLinear.setting_2),
            selected: currentLocation.contains(const SettingsRoute().routeName),
            onPressed: () {
              switch (AdaptiveLayout.layoutModeOf(context)) {
                case LayoutMode.single:
                  const SettingsRoute().push(context);
                  break;
                case LayoutMode.dual:
                  context.router.push(const ClientSettingsRoute());
                  break;
              }
              Scaffold.of(context).closeDrawer();
            },
          ),
        if (AdaptiveLayout.of(context).isDesktop || kIsWeb) const SizedBox(height: 8),
      ],
    );
  }
}
