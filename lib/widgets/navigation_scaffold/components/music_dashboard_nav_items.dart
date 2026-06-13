import 'package:flutter/material.dart';

import 'package:auto_route/auto_route.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import 'package:fladder/jellyfin/jellyfin_open_api.enums.swagger.dart';
import 'package:fladder/models/collection_types.dart';
import 'package:fladder/models/item_base_model.dart';
import 'package:fladder/models/items/playlist_model.dart';
import 'package:fladder/models/library_filter_model.dart';
import 'package:fladder/models/view_model.dart';
import 'package:fladder/routes/auto_router.gr.dart';
import 'package:fladder/screens/library_search/widgets/library_views.dart';
import 'package:fladder/screens/metadata/refresh_metadata.dart';
import 'package:fladder/theme.dart';
import 'package:fladder/util/color_extensions.dart';
import 'package:fladder/util/fladder_image.dart';
import 'package:fladder/util/localization_helper.dart';
import 'package:fladder/widgets/navigation_scaffold/components/navigation_button.dart';
import 'package:fladder/widgets/shared/custom_tooltip.dart';
import 'package:fladder/widgets/shared/item_actions.dart';
import 'package:fladder/widgets/shared/modal_bottom_sheet.dart';

List<Widget> buildMusicDashboardNavItems(
  BuildContext context,
  List<ViewModel> views,
  Map<PlaylistModel, bool?> playLists,
  bool expanded,
  WidgetRef ref,
) {
  final musicViews = views.where((view) => view.collectionType == CollectionType.music).map((e) => e.id).toList();

  return [
    CombinedViewNavigationItem(
      label: context.localized.musicAlbum(2),
      expandedSideBar: expanded,
      usePostersForLibrary: false,
      shouldExpand: expanded,
      pathKey: "albums",
      selectedIcon: Icon(FladderItemType.musicAlbum.selectedicon),
      icon: Icon(FladderItemType.musicAlbum.icon),
      onTap: () {
        ref.read(libraryViewTypeProvider.notifier).state = LibraryViewTypes.grid;
        context.pushRoute(
          LibrarySearchRoute(
            viewModelId: "${musicViews.join(",")},albums",
            key: const Key("albums-nav-item"),
          ).withFilter(
            const LibraryFilterModel(
              types: {
                FladderItemType.musicAlbum: true,
              },
            ),
          ),
        );
      },
    ),
    CombinedViewNavigationItem(
      label: context.localized.track(2),
      expandedSideBar: expanded,
      usePostersForLibrary: false,
      shouldExpand: expanded,
      pathKey: "tracks",
      selectedIcon: Icon(FladderItemType.audio.selectedicon),
      icon: Icon(FladderItemType.audio.icon),
      onTap: () {
        ref.read(libraryViewTypeProvider.notifier).state = LibraryViewTypes.list;
        context.pushRoute(
          LibrarySearchRoute(
            viewModelId: "${musicViews.join(",")},tracks",
            key: const Key("tracks-nav-item"),
          ).withFilter(
            const LibraryFilterModel(
              types: {
                FladderItemType.audio: true,
              },
            ),
          ),
        );
      },
    ),
    CombinedViewNavigationItem(
      label: context.localized.mediaTypeArtists(2),
      expandedSideBar: expanded,
      usePostersForLibrary: false,
      shouldExpand: expanded,
      pathKey: "artists",
      selectedIcon: Icon(FladderItemType.person.selectedicon),
      icon: Icon(FladderItemType.person.icon),
      onTap: () {
        ref.read(libraryViewTypeProvider.notifier).state = LibraryViewTypes.grid;
        context.pushRoute(
          LibrarySearchRoute(
            viewModelId: "${musicViews.join(",")},artists",
            key: const Key("artists-nav-item"),
          ).withFilter(
            const LibraryFilterModel(
              types: {
                FladderItemType.person: true,
              },
            ),
          ),
        );
      },
    ),
    const Divider(
      indent: 32,
      endIndent: 32,
    ),
    ...playLists.entries.map(
      (entry) => CombinedViewNavigationItem(
        label: entry.key.name,
        expandedSideBar: expanded,
        usePostersForLibrary: false,
        shouldExpand: expanded,
        pathKey: entry.key.id,
        selectedIcon: Icon(FladderItemType.playlist.selectedicon),
        icon: Icon(FladderItemType.playlist.icon),
        customIcon: SizedBox.square(
          dimension: 45,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: FladderTheme.smallShape.borderRadius,
              color: entry.key.name.toColor.harmonizeWith(Theme.of(context).colorScheme.surface),
            ),
            clipBehavior: Clip.hardEdge,
            padding: const EdgeInsets.all(2),
            child: ClipRRect(
              borderRadius: FladderTheme.smallShape.borderRadius,
              child: FladderImage(
                image: entry.key.images?.primary,
                placeHolder: Container(
                  color: entry.key.name.toColor.harmonizeWith(Theme.of(context).colorScheme.surface),
                  child: Icon(
                    FladderItemType.playlist.icon,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        onTap: () {
          ref.read(libraryViewTypeProvider.notifier).state = LibraryViewTypes.list;
          entry.key.navigateTo(context);
        },
      ),
    )
  ];
}

class CombinedViewNavigationItem extends ConsumerWidget {
  final String label;
  final String pathKey;
  final bool expandedSideBar;
  final bool usePostersForLibrary;
  final bool shouldExpand;
  final Icon selectedIcon;
  final Icon icon;
  final Widget? customIcon;
  final VoidCallback? onTap;
  const CombinedViewNavigationItem({
    super.key,
    required this.label,
    required this.pathKey,
    required this.expandedSideBar,
    required this.usePostersForLibrary,
    required this.shouldExpand,
    required this.selectedIcon,
    required this.icon,
    this.customIcon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = context.router.currentUrl.contains(pathKey);
    return CustomTooltip(
      tooltipContent: expandedSideBar
          ? null
          : Container(
              decoration: BoxDecoration(
                borderRadius: FladderTheme.smallShape.borderRadius,
                color: Theme.of(context).colorScheme.surface,
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ),
      position: TooltipPosition.right,
      child: NavigationButton(
        label: label,
        selected: selected,
        onPressed: onTap,
        horizontal: true,
        expanded: shouldExpand,
        selectedIcon: selectedIcon,
        icon: icon,
        customIcon: customIcon,
      ),
    );
  }
}

class ViewNavigationItem extends ConsumerWidget {
  final ViewModel view;
  final bool expandedSideBar;
  final bool usePostersForLibrary;
  final bool shouldExpand;
  final TooltipPosition toolTipPosition;
  const ViewNavigationItem({
    required this.view,
    required this.expandedSideBar,
    required this.usePostersForLibrary,
    required this.shouldExpand,
    this.toolTipPosition = TooltipPosition.right,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = context.router.currentUrl.contains(view.id);
    final actions = [
      ItemActionButton(
        label: Text(context.localized.scanLibrary),
        icon: const Icon(IconsaxPlusLinear.refresh),
        action: () => showRefreshPopup(context, view.id, view.name),
      )
    ];
    return CustomTooltip(
      tooltipContent: expandedSideBar
          ? null
          : Container(
              decoration: BoxDecoration(
                borderRadius: FladderTheme.smallShape.borderRadius,
                color: Theme.of(context).colorScheme.surface,
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  view.name,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ),
      position: toolTipPosition,
      child: view.toNavigationButton(
        selected,
        true,
        shouldExpand,
        () => view.navigateToView(context),
        onSecondaryTapDown: (details) => showItemContextMenu(
          context,
          ref,
          details.globalPosition,
          actions,
        ),
        onLongPress: () => showBottomSheetPill(
          context: context,
          content: (context, scrollController) => ListView(
            shrinkWrap: true,
            controller: scrollController,
            children: actions.listTileItems(context, useIcons: true),
          ),
        ),
        customIcon: usePostersForLibrary
            ? Container(
                decoration: BoxDecoration(
                  borderRadius: FladderTheme.smallShape.borderRadius,
                ),
                clipBehavior: Clip.hardEdge,
                child: SizedBox.square(
                  dimension: 45,
                  child: FladderImage(
                    image: view.imageData?.primary,
                    placeHolder: Card(
                      child: Icon(
                        selected ? view.collectionType.icon : view.collectionType.iconOutlined,
                      ),
                    ),
                  ),
                ),
              )
            : null,
        trailing: actions,
      ),
    );
  }
}
