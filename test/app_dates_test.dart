import 'package:flutter_test/flutter_test.dart';
import 'package:visitor_management/core/utils/app_dates.dart';

void main() {
  test('formats a local timestamp with a numeric offset', () {
    final formatted = formatLocalIso(DateTime(2026, 10, 26, 10, 30, 0));
    expect(formatted, matches(RegExp(r'^2026-10-26T10:30:00[+-]\d{2}:\d{2}$')));
  });

  test('treats two times on the same local day as today', () {
    final morning = DateTime(2026, 10, 30, 0, 5);
    final evening = DateTime(2026, 10, 30, 23, 50);
    expect(isSameLocalDay(morning, evening), isTrue);
    expect(isSameLocalDay(morning, DateTime(2026, 10, 31, 0, 1)), isFalse);
  });

  test('parses an offset timestamp from the API', () {
    final parsed = parseApiDate('2026-10-26T10:30:00+05:30');
    expect(parsed, isNotNull);
    expect(parsed!.toUtc().toIso8601String(), '2026-10-26T05:00:00.000Z');
  });
}
