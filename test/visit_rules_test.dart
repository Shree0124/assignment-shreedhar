import 'package:flutter_test/flutter_test.dart';
import 'package:visitor_management/features/visitors/domain/visit_rules.dart';
import 'package:visitor_management/features/visitors/domain/visitor_status.dart';

void main() {
  group('VisitRules', () {
    test('allows check-in only from Registered', () {
      expect(VisitRules.canCheckIn(VisitorStatus.registered), isTrue);
      expect(VisitRules.canCheckIn(VisitorStatus.checkedIn), isFalse);
      expect(VisitRules.canCheckIn(VisitorStatus.checkedOut), isFalse);
      expect(VisitRules.checkInBlockReason(VisitorStatus.registered), isNull);
      expect(
        VisitRules.checkInBlockReason(VisitorStatus.checkedIn),
        'This visitor is already checked in.',
      );
      expect(
        VisitRules.checkInBlockReason(VisitorStatus.checkedOut),
        contains('cannot be checked in again'),
      );
    });

    test('allows check-out only from Checked In', () {
      expect(VisitRules.canCheckOut(VisitorStatus.checkedIn), isTrue);
      expect(VisitRules.canCheckOut(VisitorStatus.registered), isFalse);
      expect(VisitRules.canCheckOut(VisitorStatus.checkedOut), isFalse);
      expect(
        VisitRules.checkOutBlockReason(VisitorStatus.registered),
        'Check-in is required before check-out.',
      );
      expect(
        VisitRules.checkOutBlockReason(VisitorStatus.checkedOut),
        'This visitor is already checked out.',
      );
    });
  });
}
