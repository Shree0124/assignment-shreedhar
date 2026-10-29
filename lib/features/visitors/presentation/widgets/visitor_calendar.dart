import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_dates.dart';

const _weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

class VisitorCalendar extends StatefulWidget {
  const VisitorCalendar({
    super.key,
    required this.selectedDay,
    required this.counts,
    required this.onDaySelected,
  });

  final DateTime selectedDay;
  final Map<DateTime, int> counts;
  final ValueChanged<DateTime> onDaySelected;

  @override
  State<VisitorCalendar> createState() => _VisitorCalendarState();
}

class _VisitorCalendarState extends State<VisitorCalendar> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    _month = _monthOf(widget.selectedDay);
  }

  @override
  void didUpdateWidget(VisitorCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!isSameLocalDay(oldWidget.selectedDay, widget.selectedDay)) {
      _month = _monthOf(widget.selectedDay);
    }
  }

  DateTime _monthOf(DateTime day) {
    final local = day.toLocal();
    return DateTime(local.year, local.month);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final currentMonth = DateTime(today.year, today.month);
    final canGoForward = _month.isBefore(currentMonth);
    final canGoBack = _month.isAfter(DateTime(2020));
    final onToday = isSameLocalDay(widget.selectedDay, today);
    final days = _monthCells(_month);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Previous month',
                  onPressed: canGoBack
                      ? () => setState(() {
                          _month = DateTime(_month.year, _month.month - 1);
                        })
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    formatMonthYear(_month),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.ink,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onToday
                      ? null
                      : () => widget.onDaySelected(today),
                  child: const Text('Today'),
                ),
                IconButton(
                  tooltip: 'Next month',
                  onPressed: canGoForward
                      ? () => setState(() {
                          _month = DateTime(_month.year, _month.month + 1);
                        })
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                for (final label in _weekdays)
                  Expanded(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: const Color(0xFF8A938F),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: days.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisExtent: 46,
              ),
              itemBuilder: (context, index) {
                final day = days[index];
                if (day == null) return const SizedBox.shrink();
                final future = day.isAfter(today);
                final selected = isSameLocalDay(day, widget.selectedDay);
                final isToday = isSameLocalDay(day, today);
                final count = widget.counts[day] ?? 0;
                return _DayCell(
                  day: day.day,
                  count: count,
                  selected: selected,
                  isToday: isToday,
                  enabled: !future,
                  onTap: future ? null : () => widget.onDaySelected(day),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class VisitorWeekStrip extends StatelessWidget {
  const VisitorWeekStrip({
    super.key,
    required this.counts,
    required this.onDaySelected,
  });

  final Map<DateTime, int> counts;
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = [
      for (var offset = 6; offset >= 0; offset--)
        today.subtract(Duration(days: offset)),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 14, 8, 12),
        child: Row(
          children: [
            for (final day in days)
              Expanded(
                child: _DayCell(
                  day: day.day,
                  count: counts[day] ?? 0,
                  selected: isSameLocalDay(day, today),
                  isToday: isSameLocalDay(day, today),
                  enabled: true,
                  caption: _weekday(day),
                  onTap: () => onDaySelected(day),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _weekday(DateTime day) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[day.weekday - 1];
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.count,
    required this.selected,
    required this.isToday,
    required this.enabled,
    required this.onTap,
    this.caption,
  });

  final int day;
  final int count;
  final bool selected;
  final bool isToday;
  final bool enabled;
  final VoidCallback? onTap;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final foreground = !enabled
        ? const Color(0xFFC5CBC8)
        : selected
        ? Colors.white
        : AppTheme.ink;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (caption != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  caption!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF8A938F),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppTheme.seed : null,
                shape: BoxShape.circle,
                border: isToday && !selected
                    ? Border.all(color: AppTheme.seed, width: 1.4)
                    : null,
              ),
              child: Text(
                '$day',
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: count > 0 ? AppTheme.seed : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<DateTime?> _monthCells(DateTime month) {
  final first = DateTime(month.year, month.month);
  final leading = first.weekday - 1;
  final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
  final total = ((leading + daysInMonth + 6) ~/ 7) * 7;
  return [
    for (var index = 0; index < total; index++)
      if (index < leading || index >= leading + daysInMonth)
        null
      else
        DateTime(month.year, month.month, index - leading + 1),
  ];
}
