import '../data/visitor.dart';
import 'visitor_status.dart';

List<Visitor> filterVisitors(
  List<Visitor> visitors, {
  required String query,
  VisitorStatus? status,
  String? project,
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
    return matchesQuery && matchesStatus && matchesProject;
  }).toList();

  filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return filtered;
}
