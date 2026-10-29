import 'visitor_status.dart';

class VisitRuleException implements Exception {
  const VisitRuleException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// One visit per registration: Registered, then Checked In, then Checked Out.
class VisitRules {
  const VisitRules._();

  static bool canCheckIn(VisitorStatus status) =>
      status == VisitorStatus.registered;

  static bool canCheckOut(VisitorStatus status) =>
      status == VisitorStatus.checkedIn;

  static String? checkInBlockReason(VisitorStatus status) {
    switch (status) {
      case VisitorStatus.registered:
        return null;
      case VisitorStatus.checkedIn:
        return 'This visitor is already checked in.';
      case VisitorStatus.checkedOut:
        return 'This visit is complete and cannot be checked in again.';
    }
  }

  static String? checkOutBlockReason(VisitorStatus status) {
    switch (status) {
      case VisitorStatus.checkedIn:
        return null;
      case VisitorStatus.registered:
        return 'Check-in is required before check-out.';
      case VisitorStatus.checkedOut:
        return 'This visitor is already checked out.';
    }
  }
}
