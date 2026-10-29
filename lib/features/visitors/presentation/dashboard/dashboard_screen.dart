import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_dates.dart';
import '../../../../core/widgets/app_messenger.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../data/visitor.dart';
import '../../domain/dashboard_stats.dart';
import '../providers/visitor_providers.dart';
import '../visitor_messages.dart';
import '../widgets/dashboard_stat_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitors = ref.watch(visitorsProvider);
    final stats = ref.watch(dashboardStatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Visitor Management')),
      body: _body(context, ref, visitors, stats),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Visitor>> visitors,
    DashboardStats? stats,
  ) {
    if (!visitors.hasValue && visitors.isLoading) {
      return const LoadingView();
    }
    if (!visitors.hasValue && visitors.hasError) {
      return ErrorStateWidget(
        message: readableError(visitors.error!),
        onRetry: () => _refresh(context, ref),
      );
    }
    if (stats == null) return const LoadingView();

    return RefreshIndicator(
      onRefresh: () => _refresh(context, ref),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Text('Today', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(
            formatDisplayDate(DateTime.now()),
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Counts use this phone’s local date.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          DashboardStatCard(
            key: const Key('stat-registered-today'),
            label: 'Total visitors today',
            value: stats.registeredToday,
            icon: Icons.person_add_alt_1,
            color: AppTheme.registered,
          ),
          const SizedBox(height: 12),
          DashboardStatCard(
            key: const Key('stat-checked-in'),
            label: 'Currently checked in',
            value: stats.currentlyCheckedIn,
            icon: Icons.login,
            color: AppTheme.checkedIn,
          ),
          const SizedBox(height: 12),
          DashboardStatCard(
            key: const Key('stat-checked-out'),
            label: 'Checked out today',
            value: stats.checkedOutToday,
            icon: Icons.logout,
            color: AppTheme.checkedOut,
          ),
          const SizedBox(height: 24),
          CustomButton(
            label: 'Register visitor',
            icon: Icons.person_add_alt,
            onPressed: () => context.push(AppRoutes.visitorNew),
          ),
          const SizedBox(height: 12),
          CustomButton(
            label: 'Scan QR code',
            icon: Icons.qr_code_scanner,
            outlined: true,
            onPressed: () => context.go(AppRoutes.scan),
          ),
        ],
      ),
    );
  }

  Future<void> _refresh(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(visitorsProvider.notifier).refresh();
    } catch (error) {
      if (context.mounted) showAppMessage(context, readableError(error));
    }
  }
}
