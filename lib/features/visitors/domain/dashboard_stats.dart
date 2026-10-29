import '../../../core/utils/app_dates.dart';
import 'visitor_status.dart';
import '../data/visitor.dart';

class DashboardStats {
  const DashboardStats({
    required this.registeredToday,
    required this.currentlyCheckedIn,
    required this.checkedOutToday,
  });

  final int registeredToday;
  final int currentlyCheckedIn;
  final int checkedOutToday;
}

DashboardStats computeDashboardStats(List<Visitor> visitors, DateTime now) {
  var registeredToday = 0;
  var currentlyCheckedIn = 0;
  var checkedOutToday = 0;

  for (final visitor in visitors) {
    if (isSameLocalDay(visitor.createdAt, now)) {
      registeredToday++;
    }
    if (visitor.status == VisitorStatus.checkedIn) {
      currentlyCheckedIn++;
    }
    final checkOutTime = visitor.checkOutTime;
    if (checkOutTime != null && isSameLocalDay(checkOutTime, now)) {
      checkedOutToday++;
    }
  }

  return DashboardStats(
    registeredToday: registeredToday,
    currentlyCheckedIn: currentlyCheckedIn,
    checkedOutToday: checkedOutToday,
  );
}
