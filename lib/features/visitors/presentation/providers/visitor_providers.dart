import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/visitor.dart';
import '../../data/visitor_repository.dart';
import '../../domain/dashboard_stats.dart';
import '../../domain/visit_rules.dart';
import '../../domain/visitor_filters.dart';
import '../../domain/visitor_status.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = createDio(ApiConfig.baseUrl);
  ref.onDispose(() => dio.close());
  return dio;
});

final visitorRepositoryProvider = Provider<VisitorRepository>((ref) {
  return VisitorRepository(ref.watch(dioProvider));
});

final visitorsProvider = AsyncNotifierProvider<VisitorsNotifier, List<Visitor>>(
  VisitorsNotifier.new,
);

class VisitorsNotifier extends AsyncNotifier<List<Visitor>> {
  @override
  Future<List<Visitor>> build() {
    return ref.watch(visitorRepositoryProvider).fetchAll();
  }

  Future<void> refresh() async {
    final hadValue = state.hasValue;
    if (!hadValue) {
      state = const AsyncLoading();
    }

    final next = await AsyncValue.guard(
      () => ref.read(visitorRepositoryProvider).fetchAll(),
    );
    if (next.hasError && hadValue) {
      Error.throwWithStackTrace(
        next.error!,
        next.stackTrace ?? StackTrace.current,
      );
    }
    state = next;
  }

  Future<Visitor> register(VisitorDraft draft) async {
    final created = await ref.read(visitorRepositoryProvider).create(draft);
    _put(created);
    return created;
  }

  Future<Visitor> updateVisitor(Visitor visitor) async {
    final updated = await ref.read(visitorRepositoryProvider).update(visitor);
    _put(updated);
    return updated;
  }

  Future<void> delete(String id) async {
    await ref.read(visitorRepositoryProvider).delete(id);
    final current = state.value ?? const <Visitor>[];
    state = AsyncData([
      for (final visitor in current)
        if (visitor.id != id) visitor,
    ]);
  }

  Future<Visitor> checkIn(String id) async {
    final visitor = _require(id);
    final reason = VisitRules.checkInBlockReason(visitor.status);
    if (reason != null) throw VisitRuleException(reason);
    final updated = await ref
        .read(visitorRepositoryProvider)
        .checkIn(visitor, DateTime.now());
    _put(updated);
    return updated;
  }

  Future<Visitor> checkOut(String id) async {
    final visitor = _require(id);
    final reason = VisitRules.checkOutBlockReason(visitor.status);
    if (reason != null) throw VisitRuleException(reason);
    final updated = await ref
        .read(visitorRepositoryProvider)
        .checkOut(visitor, DateTime.now());
    _put(updated);
    return updated;
  }

  void upsert(Visitor visitor) => _put(visitor);

  Visitor _require(String id) {
    final current = state.value;
    if (current == null) {
      throw const ApiException('Visitor records are not loaded yet.');
    }
    for (final visitor in current) {
      if (visitor.id == id) return visitor;
    }
    throw const ApiException('Visitor not found.');
  }

  void _put(Visitor visitor) {
    final current = state.value ?? const <Visitor>[];
    final exists = current.any((item) => item.id == visitor.id);
    state = AsyncData([
      for (final item in current)
        if (item.id == visitor.id) visitor else item,
      if (!exists) visitor,
    ]);
  }
}

class VisitorSearchQuery extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String value) => state = value;
}

final visitorSearchQueryProvider = NotifierProvider<VisitorSearchQuery, String>(
  VisitorSearchQuery.new,
);

class VisitorStatusFilter extends Notifier<VisitorStatus?> {
  @override
  VisitorStatus? build() => null;

  void select(VisitorStatus? status) => state = status;
}

final visitorStatusFilterProvider =
    NotifierProvider<VisitorStatusFilter, VisitorStatus?>(
      VisitorStatusFilter.new,
    );

class VisitorProjectFilter extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? project) => state = project;
}

final visitorProjectFilterProvider =
    NotifierProvider<VisitorProjectFilter, String?>(VisitorProjectFilter.new);

final filteredVisitorsProvider = Provider<List<Visitor>>((ref) {
  final visitors = ref.watch(visitorsProvider).value ?? const <Visitor>[];
  return filterVisitors(
    visitors,
    query: ref.watch(visitorSearchQueryProvider),
    status: ref.watch(visitorStatusFilterProvider),
    project: ref.watch(visitorProjectFilterProvider),
  );
});

final dashboardStatsProvider = Provider<DashboardStats?>((ref) {
  final visitors = ref.watch(visitorsProvider).value;
  if (visitors == null) return null;
  return computeDashboardStats(visitors, DateTime.now());
});

final visitorByIdProvider = Provider.family<Visitor?, String>((ref, id) {
  final visitors = ref.watch(visitorsProvider).value;
  if (visitors == null) return null;
  for (final visitor in visitors) {
    if (visitor.id == id) return visitor;
  }
  return null;
});
