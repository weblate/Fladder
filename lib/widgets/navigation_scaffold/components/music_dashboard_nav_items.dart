import 'package:flutter/material.dart';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import 'package:fladder/jellyfin/jellyfin_open_api.enums.swagger.dart';
import 'package:fladder/models/collection_types.dart';
import 'package:fladder/models/item_base_model.dart';
import 'package:fladder/models/library_filter_model.dart';
import 'package:fladder/models/view_model.dart';
import 'package:fladder/routes/auto_router.gr.dart';
import 'package:fladder/screens/metadata/refresh_metadata.dart';
import 'package:fladder/theme.dart';
import 'package:fladder/util/fladder_image.dart';
import 'package:fladder/util/localization_helper.dart';
import 'package:fladder/widgets/navigation_scaffold/components/navigation_button.dart';
import 'package:fladder/widgets/shared/custom_tooltip.dart';
import 'package:fladder/widgets/shared/item_actions.dart';
import 'package:fladder/widgets/shared/modal_bottom_sheet.dart';

List<Widget> buildMusicDashboardNavItems(
  BuildContext context,
  List<ViewModel> views,
  bool expanded,
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
