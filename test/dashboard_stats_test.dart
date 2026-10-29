import 'package:flutter_test/flutter_test.dart';
import 'package:visitor_management/features/visitors/domain/dashboard_stats.dart';
import 'package:visitor_management/features/visitors/domain/visitor_status.dart';

import 'support/visitor_factory.dart';

void main() {
  final today = DateTime(2026, 10, 30, 15);
  final morning = DateTime(2026, 10, 30, 9);
  final yesterday = DateTime(2026, 10, 29, 18);

  test(
    'counts registrations, current check-ins, and check-outs for the local day',
    () {
      final stats = computeDashboardStats([
        makeVisitor(id: 'today', createdAt: morning),
        makeVisitor(
          id: 'still-in',
          createdAt: yesterday,
          status: VisitorStatus.checkedIn,
          checkInTime: yesterday,
        ),
        makeVisitor(
          id: 'out-today',
          createdAt: yesterday,
          status: VisitorStatus.checkedOut,
          checkInTime: yesterday,
          checkOutTime: DateTime(2026, 10, 30, 11),
        ),
        makeVisitor(
          id: 'out-yesterday',
          createdAt: DateTime(2026, 10, 28, 10),
          status: VisitorStatus.checkedOut,
          checkInTime: DateTime(2026, 10, 28, 11),
          checkOutTime: yesterday,
        ),
      ], today);

      expect(stats.registeredToday, 1);
      expect(stats.currentlyCheckedIn, 1);
      expect(stats.checkedOutToday, 1);
    },
  );

  test('a visitor registered today still counts after check-out', () {
    final stats = computeDashboardStats([
      makeVisitor(
        id: 'done-today',
        createdAt: morning,
        status: VisitorStatus.checkedOut,
        checkInTime: DateTime(2026, 10, 30, 10),
        checkOutTime: DateTime(2026, 10, 30, 12),
      ),
    ], today);

    expect(stats.registeredToday, 1);
    expect(stats.currentlyCheckedIn, 0);
    expect(stats.checkedOutToday, 1);
  });
}
