import '../../../core/errors/app_failure.dart';
import '../domain/entities/notification.dart';

class NotificationsState {
  const NotificationsState({
    this.items = const [],
    this.unreadCount = 0,
    this.pageNumber = 0,
    this.pageSize = 20,
    this.totalCount = 0,
    this.hasLoadedList = false,
    this.isLoadingList = false,
    this.isLoadingMore = false,
    this.isRefreshingUnread = false,
    this.isMarkingAll = false,
    this.listFailure,
  });

  final List<AppNotification> items;
  final int unreadCount;
  final int pageNumber;
  final int pageSize;
  final int totalCount;
  final bool hasLoadedList;
  final bool isLoadingList;
  final bool isLoadingMore;
  final bool isRefreshingUnread;
  final bool isMarkingAll;
  final AppFailure? listFailure;

  bool get hasMore => items.length < totalCount;

  NotificationsState copyWith({
    List<AppNotification>? items,
    int? unreadCount,
    int? pageNumber,
    int? pageSize,
    int? totalCount,
    bool? hasLoadedList,
    bool? isLoadingList,
    bool? isLoadingMore,
    bool? isRefreshingUnread,
    bool? isMarkingAll,
    AppFailure? listFailure,
    bool clearListFailure = false,
  }) => NotificationsState(
    items: items ?? this.items,
    unreadCount: unreadCount ?? this.unreadCount,
    pageNumber: pageNumber ?? this.pageNumber,
    pageSize: pageSize ?? this.pageSize,
    totalCount: totalCount ?? this.totalCount,
    hasLoadedList: hasLoadedList ?? this.hasLoadedList,
    isLoadingList: isLoadingList ?? this.isLoadingList,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    isRefreshingUnread: isRefreshingUnread ?? this.isRefreshingUnread,
    isMarkingAll: isMarkingAll ?? this.isMarkingAll,
    listFailure: clearListFailure ? null : listFailure ?? this.listFailure,
  );
}
