import 'dart:math' as math;

import 'package:fladder/jellyfin/jellyfin_open_api.swagger.dart';
import 'package:fladder/models/items/photos_model.dart';
import 'package:fladder/models/library_search/library_search_model.dart';
import 'package:fladder/models/playback/playback_queue_source.dart';
import 'package:fladder/providers/api_provider.dart';
import 'package:fladder/util/map_bool_helper.dart';

class PhotoQueueSource {
  final LibrarySearchModel libraryState;
  final List<String>? parentIds;
  final bool? recursive;
  final bool shuffle;
  final int limit;

  const PhotoQueueSource({
    required this.libraryState,
    required this.parentIds,
    required this.recursive,
    required this.shuffle,
    required this.limit,
  });

  Future<({List<PhotoModel> items, int totalCount})> fetchPhotos(
    ProviderReader read, {
    int? startIndex,
  }) async {
    final filters = libraryState.filters;
    final searchTerm = filters.searchQuery.isNotEmpty ? filters.searchQuery : null;
    final effectiveParentIds = (parentIds == null || parentIds!.isEmpty) ? [null] : parentIds!;

    final countFutures = effectiveParentIds.map((id) => _fetchFromJellyfin(
          read: read,
          parentId: id,
          searchTerm: searchTerm,
          startIndex: 0,
          localLimit: 0,
        ));

    final countResponses = await Future.wait(countFutures);

    int currentGlobalIndex = 0;
    int itemsNeeded = limit;
    int aggregatedTotalCount = 0;

    final targetStart = startIndex ?? 0;
    final targetEnd = targetStart + limit;

    final fetchFutures = <Future<({List<PhotoModel> items, int count})>>[];

    for (int i = 0; i < effectiveParentIds.length; i++) {
      final parentId = effectiveParentIds[i];
      final parentTotal = countResponses[i].count;
      aggregatedTotalCount += parentTotal;

      if (itemsNeeded <= 0) continue;

      final parentStart = currentGlobalIndex;
      final parentEnd = currentGlobalIndex + parentTotal;

      if (targetStart < parentEnd && targetEnd > parentStart) {
        final localStartIndex = math.max(0, targetStart - parentStart);
        final maxAvailable = parentTotal - localStartIndex;
        final localLimit = math.min(itemsNeeded, maxAvailable);

        fetchFutures.add(_fetchFromJellyfin(
          read: read,
          parentId: parentId,
          searchTerm: searchTerm,
          startIndex: localStartIndex,
          localLimit: localLimit,
        ));

        itemsNeeded -= localLimit;
      }

      currentGlobalIndex += parentTotal;
    }

    final fetchResponses = await Future.wait(fetchFutures);
    final finalItems = fetchResponses.expand((r) => r.items).toList();

    if (shuffle) {
      finalItems.shuffle();
    }

    return (items: finalItems, totalCount: aggregatedTotalCount);
  }

  Future<({List<PhotoModel> items, int count})> _fetchFromJellyfin({
    required ProviderReader read,
    required String? parentId,
    required String? searchTerm,
    required int startIndex,
    required int localLimit,
  }) async {
    final filters = libraryState.filters;

    final response = await read(jellyApiProvider).itemsGet(
      parentId: parentId,
      searchTerm: searchTerm,
      genres: filters.genres.included,
      tags: filters.tags.included,
      recursive: recursive,
      officialRatings: filters.officialRatings.included,
      years: filters.years.included,
      isMissing: false,
      limit: localLimit,
      startIndex: startIndex,
      collapseBoxSetItems: false,
      studioIds: filters.studios.included.map((e) => e.id).toList(),
      sortBy: shuffle ? [ItemSortBy.random] : filters.sortingOption.toSortBy,
      sortOrder: [filters.sortOrder.sortOrder],
      fields: [
        ItemFields.genres,
        ItemFields.parentid,
        ItemFields.tags,
        ItemFields.datecreated,
        ItemFields.datelastmediaadded,
        ItemFields.overview,
        ItemFields.originaltitle,
        ItemFields.customrating,
        ItemFields.primaryimageaspectratio,
      ],
      isFavorite: filters.favourites,
      filters: filters.itemFilters.included,
      includeItemTypes: filters.types.included.map((e) => e.dtoKind).expand((e) => e).toList(),
      enableImages: true,
      enableUserData: true,
      imageTypeLimit: 1,
    );

    final items = response.body?.items.whereType<PhotoModel>().toList() ?? [];
    final count = response.body?.totalRecordCount ?? items.length;

    return (items: items, count: count);
  }
}
