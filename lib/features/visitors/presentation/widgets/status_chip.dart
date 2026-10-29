import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/visitor_status.dart';

Color statusColor(VisitorStatus status) {
  switch (status) {
    case VisitorStatus.registered:
      return AppTheme.registered;
    case VisitorStatus.checkedIn:
      return AppTheme.checkedIn;
    case VisitorStatus.checkedOut:
      return AppTheme.checkedOut;
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final VisitorStatus status;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    return Chip(
      visualDensity: VisualDensity.compact,
      label: Text(status.label),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.35)),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
    );
  }
}
