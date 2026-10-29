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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
