import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/app_messenger.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../data/visitor.dart';
import '../../domain/visitor_options.dart';
import '../../domain/visitor_status.dart';
import '../providers/visitor_providers.dart';
import '../visitor_messages.dart';
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: DropdownButtonFormField<String?>(
              initialValue: project,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Project'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All projects'),
                ),
                for (final item in VisitorOptions.projects)
                  DropdownMenuItem<String?>(value: item, child: Text(item)),
              ],
              onChanged: (value) {
                ref.read(visitorProjectFilterProvider.notifier).select(value);
              },
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

    return RefreshIndicator(
      onRefresh: () => _refresh(context),
      child: records.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 48),
                EmptyStateWidget(
                  icon: Icons.people_outline,
                  title: hasFilters
                      ? 'No matching visitors'
                      : 'No visitors yet',
                  message: hasFilters
                      ? 'Try a different name, mobile number, or filter.'
                      : 'Register a visitor to create their QR pass.',
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: records.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final visitor = records[index];
                return VisitorCard(
                  visitor: visitor,
                  onTap: () =>
                      context.push(AppRoutes.visitorDetails(visitor.id)),
                  onEdit: () => context.push(AppRoutes.visitorEdit(visitor.id)),
                  onDelete: () => _delete(visitor.id, visitor.name),
                );
              },
            ),
    );
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
