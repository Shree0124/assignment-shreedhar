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
import '../../domain/visitor_filters.dart';
import '../providers/visitor_providers.dart';
import '../visitor_messages.dart';
import '../widgets/dashboard_stat_card.dart';
import '../widgets/visitor_calendar.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitors = ref.watch(visitorsProvider);
    final stats = ref.watch(dashboardStatsProvider);

    return Scaffold(body: _body(context, ref, visitors, stats));
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const SafeArea(bottom: false, child: SizedBox(height: 8)),
          Text(
            'Front desk',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Visitor Management',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              color: const Color(0xFF142421),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            formatDisplayDate(DateTime.now()),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF5E6A66),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  label: 'Register',
                  icon: Icons.person_add_alt,
                  onPressed: () => context.push(AppRoutes.visitorNew),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  label: 'Scan',
                  icon: Icons.qr_code_scanner,
                  outlined: true,
                  onPressed: () => context.go(AppRoutes.scan),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'Today',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'New visitors today, people still inside, and those who left.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF5E6A66),
            ),
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Previous days',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.go(AppRoutes.visitors),
                child: const Text('Calendar'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'A dot means visitors were registered. Tap a day to open them.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          VisitorWeekStrip(
            counts: registrationCountsByDay(visitors.value ?? const []),
            onDaySelected: (day) {
              ref.read(visitorDayFilterProvider.notifier).select(day);
              context.go(AppRoutes.visitors);
            },
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

