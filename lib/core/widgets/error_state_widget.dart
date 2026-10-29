import 'package:flutter/material.dart';

import 'custom_button.dart';
import 'empty_state_widget.dart';

class ErrorStateWidget extends StatelessWidget {
  const ErrorStateWidget({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.cloud_off,
      title: 'Could not load visitors',
      message: message,
      action: onRetry == null
          ? null
          : CustomButton(label: 'Try again', onPressed: onRetry),
    );
  }
}
