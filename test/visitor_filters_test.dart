import 'package:flutter_test/flutter_test.dart';
import 'package:visitor_management/features/visitors/domain/visitor_filters.dart';
import 'package:visitor_management/features/visitors/domain/visitor_status.dart';

import 'support/visitor_factory.dart';

void main() {
  final visitors = [
    makeVisitor(id: '1', name: 'Rahul Sharma', mobile: '9876543210'),
    makeVisitor(
      id: '2',
      name: 'Anita Rao',
      mobile: '9123456780',
      project: 'Project B',
      status: VisitorStatus.checkedIn,
      createdAt: DateTime(2026, 10, 30, 11),
    ),
    makeVisitor(
      id: '3',
      name: 'Vendor Desk',
      mobile: '9000000001',
      visitorType: 'Vendor',
      project: 'Project C',
      status: VisitorStatus.checkedOut,
      createdAt: DateTime(2026, 10, 29, 8),
    ),
  ];

  test('search matches name or mobile and ignores case', () {
    final byName = filterVisitors(
      visitors,
      query: 'rahul',
      status: null,
      project: null,
    );
    final byMobile = filterVisitors(
      visitors,
      query: '9123',
      status: null,
      project: null,
    );

    expect(byName.map((visitor) => visitor.id), ['1']);
    expect(byMobile.map((visitor) => visitor.id), ['2']);
  });

  test('filters by status and project, newest first', () {
    final checkedIn = filterVisitors(
      visitors,
      query: '',
      status: VisitorStatus.checkedIn,
      project: 'Project B',
    );
    final all = filterVisitors(
      visitors,
      query: ' ',
      status: null,
      project: null,
    );

    expect(checkedIn.map((visitor) => visitor.id), ['2']);
    expect(all.map((visitor) => visitor.id), ['2', '1', '3']);
  });

  test('keeps previous days unless a day is selected', () {
    final today = DateTime(2026, 10, 30, 15);
    final onToday = filterVisitors(
      visitors,
      query: '',
      status: null,
      project: null,
      day: today,
    );
    final previousDay = filterVisitors(
      visitors,
      query: '',
      status: null,
      project: null,
      day: DateTime(2026, 10, 29),
    );
    final groups = groupVisitorsByDay(
      filterVisitors(visitors, query: '', status: null, project: null),
    );

    expect(onToday.map((visitor) => visitor.id), ['2', '1']);
    expect(previousDay.map((visitor) => visitor.id), ['3']);
    expect(groups.map((group) => group.visitors.first.id), ['2', '3']);
    expect(groups.last.day, DateTime(2026, 10, 29));
    expect(registrationCountsByDay(visitors)[DateTime(2026, 10, 30)], 2);
    expect(registrationCountsByDay(visitors)[DateTime(2026, 10, 29)], 1);
  });
}
