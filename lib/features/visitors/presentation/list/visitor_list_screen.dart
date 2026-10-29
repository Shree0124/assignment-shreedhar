import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/utils/app_dates.dart';
import '../../../../core/widgets/app_messenger.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../data/visitor.dart';
import '../../domain/visitor_filters.dart';
import '../../domain/visitor_options.dart';
import '../../domain/visitor_status.dart';
import '../providers/visitor_providers.dart';
import '../visitor_messages.dart';
import '../widgets/visitor_calendar.dart';
import '../widgets/visitor_card.dart';

class VisitorListScreen extends ConsumerStatefulWidget {
  const VisitorListScreen({super.key});

  @override
  ConsumerState<VisitorListScreen> createState() => _VisitorListScreenState();
}

class _VisitorListScreenState extends ConsumerState<VisitorListScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visitors = ref.watch(visitorsProvider);
    final filtered = ref.watch(filteredVisitorsProvider);
    final status = ref.watch(visitorStatusFilterProvider);
    final project = ref.watch(visitorProjectFilterProvider);
    final query = ref.watch(visitorSearchQueryProvider);
    final selectedDay = ref.watch(visitorDayFilterProvider);
    final searching = query.trim().isNotEmpty;
    final counts = registrationCountsByDay(
      filterVisitors(
        visitors.value ?? const <Visitor>[],
        query: '',
        status: status,
        project: project,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitors'),
        actions: [
          IconButton(
            tooltip: 'Register visitor',
            onPressed: () => context.push(AppRoutes.visitorNew),
            icon: const Icon(Icons.person_add_alt),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: CustomTextField(
              controller: _searchController,
              label: 'Search name or mobile',
              prefixIcon: Icons.search,
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                ref.read(visitorSearchQueryProvider.notifier).setQuery(value);
              },
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _StatusChip(
                  label: 'All',
                  selected: status == null,
                  onSelected: () {
                    ref.read(visitorStatusFilterProvider.notifier).select(null);
                  },
                ),
                for (final item in VisitorStatus.values)
                  _StatusChip(
                    label: item.label,
                    selected: status == item,
                    onSelected: () {
                      ref
                          .read(visitorStatusFilterProvider.notifier)
                          .select(item);
                    },
                  ),
              ],
            ),
          ),
          Expanded(
            child: _list(
              context,
              visitors,
              filtered,
              query: query,
              status: status,
              project: project,
              day: selectedDay,
              searching: searching,
              counts: counts,
            ),
          ),
        ],
      ),
    );
  }

  Widget _list(
    BuildContext context,
    AsyncValue<List<Visitor>> visitors,
    List<Visitor> records, {
    required String query,
    required VisitorStatus? status,
    required String? project,
    required DateTime day,
    required bool searching,
    required Map<DateTime, int> counts,
  }) {
    if (!visitors.hasValue && visitors.isLoading) {
      return const LoadingView();
    }
    if (!visitors.hasValue && visitors.hasError) {
      return ErrorStateWidget(
        message: readableError(visitors.error!),
        onRetry: () => _refresh(context),
      );
    }

    final hasFilters =
        query.trim().isNotEmpty ||
        status != null ||
        (project != null && project.isNotEmpty);
    final now = DateTime.now();
    final entries = searching
        ? <Object>[
            for (final group in groupVisitorsByDay(records)) ...[
              relativeDayLabel(group.day, now),
              ...group.visitors,
            ],
          ]
        : records.cast<Object>();

    final noneAtAll = (visitors.value ?? const <Visitor>[]).isEmpty;
    final dayLabel = relativeDayLabel(day, now);

    return RefreshIndicator(
      onRefresh: () => _refresh(context),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          if (visitors.hasValue) ...[
            VisitorCalendar(
              selectedDay: day,
              counts: counts,
              onDaySelected: (selected) {
                ref.read(visitorDayFilterProvider.notifier).select(selected);
              },
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    searching ? 'Matches from every day' : dayLabel,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  searching
                      ? '${records.length} found'
                      : '${records.length} ${records.length == 1 ? 'visitor' : 'visitors'}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF5E6A66),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AppDropdown<String?>(
              label: 'Project',
              icon: Icons.apartment_outlined,
              value: project,
              items: [
                const AppDropdownOption<String?>(
                  value: null,
                  label: 'All projects',
                ),
                for (final item in VisitorOptions.projects)
                  AppDropdownOption<String?>(value: item, label: item),
              ],
              onChanged: (value) {
                ref.read(visitorProjectFilterProvider.notifier).select(value);
              },
            ),
            const SizedBox(height: 12),
          ],
          if (records.isEmpty)
            EmptyStateWidget(
              icon: Icons.event_available_outlined,
              title: noneAtAll
                  ? 'No visitors yet'
                  : hasFilters
                  ? 'No matching visitors'
                  : 'Nothing on this day',
              message: searching
                  ? 'No visitors match that name or mobile number.'
                  : hasFilters
                  ? 'Try another status or project, or pick a different day.'
                  : _emptyDayMessage(day, now),
            )
          else
            for (final entry in entries) _entry(entry),
        ],
      ),
    );
  }

  Widget _entry(Object entry) {
    if (entry is String) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
        child: Text(
          entry,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF5E6A66),
          ),
        ),
      );
    }
    final visitor = entry as Visitor;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: VisitorCard(
        visitor: visitor,
        onTap: () => context.push(AppRoutes.visitorDetails(visitor.id)),
        onEdit: () => context.push(AppRoutes.visitorEdit(visitor.id)),
        onDelete: () => _delete(visitor.id, visitor.name),
      ),
    );
  }

  String _emptyDayMessage(DateTime day, DateTime now) {
    if (isSameLocalDay(day, now)) return 'Nobody was registered today.';
    final yesterday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 1));
    if (isSameLocalDay(day, yesterday)) {
      return 'Nobody was registered yesterday.';
    }
    return 'Nobody was registered on ${formatDisplayDate(day)}.';
  }

  Future<void> _refresh(BuildContext context) async {
    try {
      await ref.read(visitorsProvider.notifier).refresh();
    } catch (error) {
      if (context.mounted) showAppMessage(context, readableError(error));
    }
  }

  Future<void> _delete(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete visitor'),
          content: Text('Delete $name? This removes their record and QR pass.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(visitorsProvider.notifier).delete(id);
      if (mounted) showAppMessage(context, 'Visitor deleted.');
    } catch (error) {
      if (mounted) showAppMessage(context, readableError(error));
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
      ),
    );
  }
}
