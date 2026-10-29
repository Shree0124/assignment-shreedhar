import 'package:flutter_test/flutter_test.dart';
import 'package:visitor_management/features/visitors/data/visitor.dart';
import 'package:visitor_management/features/visitors/domain/visitor_status.dart';
import 'package:visitor_management/features/visitors/domain/visitor_validators.dart';

import 'support/visitor_factory.dart';

void main() {
  test('reads the sample visitor payload', () {
    final visitor = Visitor.fromJson({
      'id': 'VIS001',
      'name': 'Rahul Sharma',
      'mobile': '9876543210',
      'email': 'rahul@example.com',
      'visitor_type': 'Customer',
      'project': 'Project A',
      'purpose': 'Site Visit',
      'status': 'Registered',
      'created_at': '2026-10-26T10:00:00+05:30',
      'check_in_time': null,
      'check_out_time': null,
    });

    expect(visitor.id, 'VIS001');
    expect(
      Visitor.fromJson({
        '_id': '6ae3afa9f29a2303e89f9999',
        'id': 'ignore-this',
        'name': 'Rahul Sharma',
        'mobile': '9876543210',
        'visitor_type': 'Customer',
        'project': 'Project A',
        'purpose': 'Site Visit',
        'status': 'Registered',
        'created_at': '2026-10-30T02:10:00+05:30',
      }).id,
      '6ae3afa9f29a2303e89f9999',
    );
    expect(visitor.status, VisitorStatus.registered);
    expect(visitor.email, 'rahul@example.com');
    expect(visitor.checkInTime, isNull);
  });

  test('accepts a numeric id and skips a record with an unknown status', () {
    final visitor = Visitor.fromJson({
      'id': 12,
      'name': 'Anita Rao',
      'mobile': '9123456780',
      'visitor_type': 'Vendor',
      'project': 'Project B',
      'purpose': 'Delivery',
      'status': 'Checked In',
      'createdAt': '2026-10-26T10:00:00Z',
    });

    expect(visitor.id, '12');
    expect(visitor.status, VisitorStatus.checkedIn);
    expect(
      Visitor.tryFromJson({
        'id': 'x',
        'name': 'Bad',
        'mobile': '9999999999',
        'visitor_type': 'Other',
        'project': 'Project C',
        'purpose': 'Other',
        'status': 'Waiting',
        'created_at': '2026-10-26T10:00:00Z',
      }),
      isNull,
    );
  });

  test('round-trips visitor fields through JSON', () {
    final original = makeVisitor(
      createdAt: DateTime(2026, 10, 26, 10, 0, 0),
      checkInTime: DateTime(2026, 10, 26, 10, 30, 0),
    );
    final parsed = Visitor.fromJson(original.toJson());

    expect(parsed.id, original.id);
    expect(parsed.name, original.name);
    expect(parsed.status, original.status);
    expect(parsed.createdAt.toLocal().hour, 10);
    expect(parsed.checkInTime!.toLocal().minute, 30);
    expect(parsed.checkOutTime, isNull);
  });

  test('validates registration fields', () {
    expect(VisitorValidators.name('  '), 'Enter the visitor name.');
    expect(
      VisitorValidators.mobile('12345'),
      'Enter a 10-digit mobile number.',
    );
    expect(VisitorValidators.mobile('9876543210'), isNull);
    expect(VisitorValidators.email(''), isNull);
    expect(VisitorValidators.email('rahul@example.com'), isNull);
    expect(VisitorValidators.email('rahul'), 'Enter a valid email address.');
    expect(isVisitorId('VIS001'), isTrue);
    expect(isVisitorId('https://example.com'), isFalse);
    expect(isVisitorId(''), isFalse);
  });
}
