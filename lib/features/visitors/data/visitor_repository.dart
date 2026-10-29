import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/app_dates.dart';
import '../domain/visitor_status.dart';
import 'visitor.dart';

class VisitorRepository {
  VisitorRepository(this._dio);

  final Dio _dio;

  Future<List<Visitor>> fetchAll() {
    _ensureConfigured();
    return guardApi(() async {
      final response = await _dio.get<dynamic>('visitors');
      final data = response.data;
      if (data is! List) {
        throw const ApiException(
          'The server returned an unexpected visitor list.',
        );
      }

      final visitors = <Visitor>[];
      for (final item in data) {
        final visitor = Visitor.tryFromJson(item);
        if (visitor != null) visitors.add(visitor);
      }

      if (data.isNotEmpty && visitors.isEmpty) {
        throw const ApiException(
          'The server returned visitor records that could not be read.',
        );
      }
      return visitors;
    });
  }

  Future<Visitor> fetchById(String id) {
    _ensureConfigured();
    return guardApi(() async {
      final response = await _dio.get<dynamic>(_visitorPath(id));
      return _readVisitor(response.data);
    });
  }

  Future<Visitor> create(VisitorDraft draft) {
    _ensureConfigured();
    return guardApi(() async {
      final response = await _dio.post<dynamic>(
        'visitors',
        data: {
          'name': draft.name,
          'mobile': draft.mobile,
          'email': draft.email,
          'visitor_type': draft.visitorType,
          'project': draft.project,
          'purpose': draft.purpose,
          'status': VisitorStatus.registered.label,
          'created_at': formatLocalIso(DateTime.now()),
          'check_in_time': null,
          'check_out_time': null,
        },
      );
      return _readVisitor(response.data);
    });
  }

  Future<Visitor> update(Visitor visitor) {
    _ensureConfigured();
    return guardApi(() async {
      final response = await _dio.put<dynamic>(
        _visitorPath(visitor.id),
        data: visitor.toJson(),
      );
      return _readVisitor(response.data, fallback: visitor);
    });
  }

  Future<void> delete(String id) {
    _ensureConfigured();
    return guardApi(() async {
      await _dio.delete<dynamic>(_visitorPath(id));
    });
  }

  Future<Visitor> checkIn(Visitor visitor, DateTime time) {
    return update(
      Visitor(
        id: visitor.id,
        name: visitor.name,
        mobile: visitor.mobile,
        email: visitor.email,
        visitorType: visitor.visitorType,
        project: visitor.project,
        purpose: visitor.purpose,
        status: VisitorStatus.checkedIn,
        createdAt: visitor.createdAt,
        checkInTime: time,
        checkOutTime: visitor.checkOutTime,
      ),
    );
  }

  Future<Visitor> checkOut(Visitor visitor, DateTime time) {
    return update(
      Visitor(
        id: visitor.id,
        name: visitor.name,
        mobile: visitor.mobile,
        email: visitor.email,
        visitorType: visitor.visitorType,
        project: visitor.project,
        purpose: visitor.purpose,
        status: VisitorStatus.checkedOut,
        createdAt: visitor.createdAt,
        checkInTime: visitor.checkInTime,
        checkOutTime: time,
      ),
    );
  }

  Visitor _readVisitor(Object? data, {Visitor? fallback}) {
    if (data == null || (data is String && data.trim().isEmpty)) {
      if (fallback != null) return fallback;
    }

    final parsed = Visitor.tryFromJson(data);
    if (parsed != null) return parsed;

    if (data is Map && fallback != null) {
      final merged = {...fallback.toJson(), ...Map<String, dynamic>.from(data)};
      final recovered = Visitor.tryFromJson(merged);
      if (recovered != null) return recovered;
    }

    throw const ApiException(
      'The server returned an unexpected visitor record.',
    );
  }

  String _visitorPath(String id) => 'visitors/${Uri.encodeComponent(id)}';

  void _ensureConfigured() {
    if (ApiConfig.isConfigured) return;
    throw const ApiException(
      'Add your MockAPI base URL in lib/core/config/api_config.dart, then restart the app.',
    );
  }
}
