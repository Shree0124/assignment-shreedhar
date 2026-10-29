import '../../../core/utils/app_dates.dart';
import '../data/visitor.dart';
import 'visitor_status.dart';

List<Visitor> filterVisitors(
  List<Visitor> visitors, {
  required String query,
  VisitorStatus? status,
  String? project,
  DateTime? day,
}) {
  final needle = query.trim().toLowerCase();
  final filtered = visitors.where((visitor) {
    final matchesQuery =
        needle.isEmpty ||
        visitor.name.toLowerCase().contains(needle) ||
        visitor.mobile.contains(needle);
    final matchesStatus = status == null || visitor.status == status;
    final matchesProject =
        project == null || project.isEmpty || visitor.project == project;
    final matchesDay = day == null || isSameLocalDay(visitor.createdAt, day);
    return matchesQuery && matchesStatus && matchesProject && matchesDay;
  }).toList();

  filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return filtered;
}

/// Local registration-day counts. Keys are midnight on the device calendar.
Map<DateTime, int> registrationCountsByDay(List<Visitor> visitors) {
  final counts = <DateTime, int>{};
  for (final visitor in visitors) {
    final local = visitor.createdAt.toLocal();
    final day = DateTime(local.year, local.month, local.day);
    counts.update(day, (count) => count + 1, ifAbsent: () => 1);
  }
  return counts;
}

class VisitorDayGroup {
  const VisitorDayGroup({required this.day, required this.visitors});

  final DateTime day;
  final List<Visitor> visitors;
}

/// Groups an already date-sorted list into local calendar days, newest first.
List<VisitorDayGroup> groupVisitorsByDay(List<Visitor> visitors) {
  final groups = <VisitorDayGroup>[];
  DateTime? currentDay;
  final bucket = <Visitor>[];

  void flush() {
    final day = currentDay;
    if (day == null || bucket.isEmpty) return;
    groups.add(VisitorDayGroup(day: day, visitors: List.of(bucket)));
    bucket.clear();
  }

  for (final visitor in visitors) {
    final local = visitor.createdAt.toLocal();
    final day = DateTime(local.year, local.month, local.day);
    final previous = currentDay;
    if (previous == null || !isSameLocalDay(previous, day)) {
      flush();
      currentDay = day;
    }
    bucket.add(visitor);
  }
  flush();
  return groups;
}
