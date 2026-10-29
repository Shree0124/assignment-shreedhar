const _months = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Local calendar day comparison. Dashboard "today" uses this, not UTC.
bool isSameLocalDay(DateTime a, DateTime b) {
  final left = a.toLocal();
  final right = b.toLocal();
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

/// ISO-8601 with the device offset, for example `2026-10-26T10:30:00+05:30`.
String formatLocalIso(DateTime dateTime) {
  final local = dateTime.toLocal();
  final offset = local.timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final hours = offset.inHours.abs().toString().padLeft(2, '0');
  final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
  final date =
      '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
  final time =
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}:'
      '${local.second.toString().padLeft(2, '0')}';
  return '${date}T$time$sign$hours:$minutes';
}

String relativeDayLabel(DateTime day, DateTime now) {
  if (isSameLocalDay(day, now)) return 'Today';
  final yesterday = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(const Duration(days: 1));
  if (isSameLocalDay(day, yesterday)) return 'Yesterday';
  return formatDisplayDate(day);
}

String formatMonthYear(DateTime dateTime) {
  final local = dateTime.toLocal();
  return '${_months[local.month - 1]} ${local.year}';
}

String formatDisplayDate(DateTime dateTime) {
  final local = dateTime.toLocal();
  return '${local.day} ${_months[local.month - 1]} ${local.year}';
}

String formatDisplayDateTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';
  return '${formatDisplayDate(local)}, $hour:$minute $period';
}

DateTime? parseApiDate(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  return DateTime.tryParse(value.trim());
}
