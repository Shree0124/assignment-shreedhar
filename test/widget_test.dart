import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visitor_management/app.dart';
import 'package:visitor_management/features/visitors/data/visitor.dart';
import 'package:visitor_management/features/visitors/domain/visitor_status.dart';
import 'package:visitor_management/features/visitors/presentation/providers/visitor_providers.dart';

import 'support/visitor_factory.dart';

void main() {
  testWidgets('dashboard shows today counts from the visitor list', (
    tester,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 9);
    final yesterday = today.subtract(const Duration(days: 1));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          visitorsProvider.overrideWith(
            () => _StaticVisitors([
              makeVisitor(id: '1', createdAt: today),
              makeVisitor(
                id: '2',
                createdAt: yesterday,
                status: VisitorStatus.checkedIn,
                checkInTime: yesterday,
              ),
              makeVisitor(
                id: '3',
                createdAt: yesterday,
                status: VisitorStatus.checkedOut,
                checkInTime: yesterday,
                checkOutTime: today,
              ),
            ]),
          ),
        ],
        child: const VisitorApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Visitor Management'), findsOneWidget);
    expect(_statValue('stat-registered-today'), findsOneWidget);
    expect(_statValue('stat-checked-in'), findsOneWidget);
    expect(_statValue('stat-checked-out'), findsOneWidget);
  });
}

Finder _statValue(String key) {
  return find.descendant(of: find.byKey(Key(key)), matching: find.text('1'));
}

class _StaticVisitors extends VisitorsNotifier {
  _StaticVisitors(this._visitors);

  final List<Visitor> _visitors;

  @override
  Future<List<Visitor>> build() async => _visitors;
}
