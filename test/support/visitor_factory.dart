import 'package:visitor_management/features/visitors/data/visitor.dart';
import 'package:visitor_management/features/visitors/domain/visitor_status.dart';

Visitor makeVisitor({
  String id = '1',
  String name = 'Rahul Sharma',
  String mobile = '9876543210',
  String? email = 'rahul@example.com',
  String visitorType = 'Customer',
  String project = 'Project A',
  String purpose = 'Site Visit',
  VisitorStatus status = VisitorStatus.registered,
  DateTime? createdAt,
  DateTime? checkInTime,
  DateTime? checkOutTime,
}) {
  return Visitor(
    id: id,
    name: name,
    mobile: mobile,
    email: email,
    visitorType: visitorType,
    project: project,
    purpose: purpose,
    status: status,
    createdAt: createdAt ?? DateTime(2026, 10, 30, 9),
    checkInTime: checkInTime,
    checkOutTime: checkOutTime,
  );
}
