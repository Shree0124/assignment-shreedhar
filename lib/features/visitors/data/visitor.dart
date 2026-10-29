import '../../../core/utils/app_dates.dart';
import '../domain/visitor_status.dart';

class VisitorDraft {
  const VisitorDraft({
    required this.name,
    required this.mobile,
    required this.email,
    required this.visitorType,
    required this.project,
    required this.purpose,
  });

  final String name;
  final String mobile;
  final String? email;
  final String visitorType;
  final String project;
  final String purpose;
}

class Visitor {
  const Visitor({
    required this.id,
    required this.name,
    required this.mobile,
    required this.email,
    required this.visitorType,
    required this.project,
    required this.purpose,
    required this.status,
    required this.createdAt,
    required this.checkInTime,
    required this.checkOutTime,
  });

  final String id;
  final String name;
  final String mobile;
  final String? email;
  final String visitorType;
  final String project;
  final String purpose;
  final VisitorStatus status;
  final DateTime createdAt;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;

  Visitor copyWithDetails(VisitorDraft draft) {
    return Visitor(
      id: id,
      name: draft.name,
      mobile: draft.mobile,
      email: draft.email,
      visitorType: draft.visitorType,
      project: draft.project,
      purpose: draft.purpose,
      status: status,
      createdAt: createdAt,
      checkInTime: checkInTime,
      checkOutTime: checkOutTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mobile': mobile,
      'email': email,
      'visitor_type': visitorType,
      'project': project,
      'purpose': purpose,
      'status': status.label,
      'created_at': formatLocalIso(createdAt),
      'check_in_time': checkInTime == null
          ? null
          : formatLocalIso(checkInTime!),
      'check_out_time': checkOutTime == null
          ? null
          : formatLocalIso(checkOutTime!),
    };
  }

  static Visitor? tryFromJson(Object? raw) {
    if (raw is! Map) return null;
    try {
      return Visitor.fromJson(Map<String, dynamic>.from(raw));
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  factory Visitor.fromJson(Map<String, dynamic> json) {
    final createdAt = parseApiDate(
      _optional(json, const ['created_at', 'createdAt']),
    );
    if (createdAt == null) {
      throw const FormatException('Missing created_at');
    }

    return Visitor(
      id: _required(json, const ['_id', 'id']),
      name: _required(json, const ['name']),
      mobile: _required(json, const [
        'mobile',
        'mobile_number',
        'mobileNumber',
      ]),
      email: _optional(json, const ['email']),
      visitorType: _required(json, const ['visitor_type', 'visitorType']),
      project: _required(json, const ['project']),
      purpose: _required(json, const ['purpose']),
      status: VisitorStatus.parse(_required(json, const ['status'])),
      createdAt: createdAt,
      checkInTime: parseApiDate(
        _optional(json, const ['check_in_time', 'checkInTime']),
      ),
      checkOutTime: parseApiDate(
        _optional(json, const ['check_out_time', 'checkOutTime']),
      ),
    );
  }
}

String _required(Map<String, dynamic> json, List<String> keys) {
  final value = _optional(json, keys);
  if (value == null) {
    throw FormatException('Missing ${keys.first}');
  }
  return value;
}

String? _optional(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') continue;
    return text;
  }
  return null;
}
