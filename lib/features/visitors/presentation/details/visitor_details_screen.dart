import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/utils/app_dates.dart';
import '../../../../core/widgets/app_messenger.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../data/visitor.dart';
import '../../domain/visit_rules.dart';
import '../../domain/visitor_status.dart';
import '../providers/visitor_providers.dart';
import '../visitor_messages.dart';
import '../widgets/status_chip.dart';

class VisitorDetailsScreen extends ConsumerStatefulWidget {
  const VisitorDetailsScreen({super.key, required this.visitorId});

  final String visitorId;

  @override
  ConsumerState<VisitorDetailsScreen> createState() =>
      _VisitorDetailsScreenState();
}

class _VisitorDetailsScreenState extends ConsumerState<VisitorDetailsScreen> {
  var _updating = false;

  @override
  Widget build(BuildContext context) {
    final visitors = ref.watch(visitorsProvider);
    final visitor = ref.watch(visitorByIdProvider(widget.visitorId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitor details'),
        actions: [
          if (visitor != null)
            IconButton(
              tooltip: 'Edit',
              onPressed: () => context.push(AppRoutes.visitorEdit(visitor.id)),
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body: _body(context, visitors, visitor),
    );
  }

  Widget _body(
    BuildContext context,
    AsyncValue<List<Visitor>> visitors,
    Visitor? visitor,
  ) {
    if (visitor == null && visitors.isLoading && !visitors.hasValue) {
      return const LoadingView();
    }
    if (visitor == null && visitors.hasError && !visitors.hasValue) {
      return ErrorStateWidget(
        message: readableError(visitors.error!),
        onRetry: () => ref.read(visitorsProvider.notifier).refresh(),
      );
    }
    if (visitor == null) {
      return const EmptyStateWidget(
        icon: Icons.person_off_outlined,
        title: 'Visitor not found',
        message: 'This QR code or record does not match a saved visitor.',
      );
    }

    final canCheckIn = VisitRules.canCheckIn(visitor.status);
    final canCheckOut = VisitRules.canCheckOut(visitor.status);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        visitor.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    StatusChip(status: visitor.status),
                  ],
                ),
                const SizedBox(height: 16),
                _InfoRow(label: 'Mobile', value: visitor.mobile),
                _InfoRow(
                  label: 'Email',
                  value: visitor.email ?? 'Not provided',
                ),
                _InfoRow(label: 'Type', value: visitor.visitorType),
                _InfoRow(label: 'Project', value: visitor.project),
                _InfoRow(label: 'Purpose', value: visitor.purpose),
                _InfoRow(
                  label: 'Registered',
                  value: formatDisplayDateTime(visitor.createdAt),
                ),
                if (visitor.checkInTime != null)
                  _InfoRow(
                    label: 'Checked in',
                    value: formatDisplayDateTime(visitor.checkInTime!),
                  ),
                if (visitor.checkOutTime != null)
                  _InfoRow(
                    label: 'Checked out',
                    value: formatDisplayDateTime(visitor.checkOutTime!),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Visitor pass',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: QrImageView(
                    data: visitor.id,
                    size: 200,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ID ${visitor.id}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (canCheckIn)
          CustomButton(
            label: 'Check in',
            icon: Icons.login,
            loading: _updating,
            onPressed: () => _checkIn(visitor.id),
          ),
        if (canCheckOut)
          CustomButton(
            label: 'Check out',
            icon: Icons.logout,
            loading: _updating,
            onPressed: () => _checkOut(visitor.id),
          ),
        if (visitor.status == VisitorStatus.checkedOut)
          const EmptyStateWidget(
            icon: Icons.task_alt,
            title: 'Visit complete',
            message: 'This registration has already been checked out.',
          ),
      ],
    );
  }

  Future<void> _checkIn(String id) async {
    setState(() => _updating = true);
    try {
      await ref.read(visitorsProvider.notifier).checkIn(id);
      if (mounted) showAppMessage(context, 'Visitor checked in.');
    } catch (error) {
      if (mounted) showAppMessage(context, readableError(error));
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _checkOut(String id) async {
    setState(() => _updating = true);
    try {
      await ref.read(visitorsProvider.notifier).checkOut(id);
      if (mounted) showAppMessage(context, 'Visitor checked out.');
    } catch (error) {
      if (mounted) showAppMessage(context, readableError(error));
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}
