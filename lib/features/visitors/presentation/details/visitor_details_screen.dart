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

    final accent = statusColor(visitor.status);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        _initials(visitor.name),
                        style: TextStyle(
                          color: accent,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            visitor.name,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          StatusChip(status: visitor.status),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Divider(),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.phone_outlined,
                  label: 'Mobile',
                  value: visitor.mobile,
                ),
                _InfoRow(
                  icon: Icons.mail_outline,
                  label: 'Email',
                  value: visitor.email ?? 'Not provided',
                ),
                _InfoRow(
                  icon: Icons.badge_outlined,
                  label: 'Type',
                  value: visitor.visitorType,
                ),
                _InfoRow(
                  icon: Icons.apartment_outlined,
                  label: 'Project',
                  value: visitor.project,
                ),
                _InfoRow(
                  icon: Icons.notes_outlined,
                  label: 'Purpose',
                  value: visitor.purpose,
                ),
                _InfoRow(
                  icon: Icons.event_outlined,
                  label: 'Registered',
                  value: formatDisplayDateTime(visitor.createdAt),
                ),
                if (visitor.checkInTime != null)
                  _InfoRow(
                    icon: Icons.login,
                    label: 'Checked in',
                    value: formatDisplayDateTime(visitor.checkInTime!),
                  ),
                if (visitor.checkOutTime != null)
                  _InfoRow(
                    icon: Icons.logout,
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
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              children: [
                Text(
                  'Visitor pass',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'Show this code at the gate',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F5F1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: DecoratedBox(
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
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  visitor.id,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF5E6A66),
                    letterSpacing: 0.4,
                  ),
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
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF5E6A66)),
          const SizedBox(width: 12),
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: const Color(0xFF5E6A66)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  String letter(String value) => value[0].toUpperCase();
  if (parts.length == 1) return letter(parts.first);
  return '${letter(parts.first)}${letter(parts.last)}';
}
