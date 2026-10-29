import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/app_messenger.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../domain/visitor_validators.dart';
import '../providers/visitor_providers.dart';

class QrScannerScreen extends StatelessWidget {
  const QrScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!TickerMode.valuesOf(context).enabled) return const SizedBox.shrink();
    return const _LiveScanner();
  }
}

class _LiveScanner extends ConsumerStatefulWidget {
  const _LiveScanner();

  @override
  ConsumerState<_LiveScanner> createState() => _LiveScannerState();
}

class _LiveScannerState extends ConsumerState<_LiveScanner> {
  late final MobileScannerController _controller;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      formats: const [BarcodeFormat.qrCode],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR code')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Point the camera at a visitor pass. The code contains the visitor ID.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    MobileScanner(
                      controller: _controller,
                      onDetect: _onDetect,
                      errorBuilder: (context, error) {
                        final denied =
                            error.errorCode ==
                            MobileScannerErrorCode.permissionDenied;
                        return ColoredBox(
                          color: Theme.of(context).colorScheme.surface,
                          child: EmptyStateWidget(
                            icon: Icons.no_photography_outlined,
                            title: denied
                                ? 'Camera permission needed'
                                : 'Camera unavailable',
                            message: denied
                                ? 'Allow camera access to scan visitor QR codes. You can enable it in system settings.'
                                : error.errorDetails?.message ??
                                      'This device could not start the camera.',
                          ),
                        );
                      },
                    ),
                    const IgnorePointer(
                      child: Center(
                        child: SizedBox(
                          width: 220,
                          height: 220,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              border: Border.fromBorderSide(
                                BorderSide(color: Colors.white, width: 3),
                              ),
                              borderRadius: BorderRadius.all(
                                Radius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy) return;
    final raw = capture.barcodes.isEmpty
        ? null
        : capture.barcodes.first.rawValue?.trim();
    if (raw == null || raw.isEmpty) return;

    _busy = true;
    if (!isVisitorId(raw)) {
      if (mounted) {
        showAppMessage(context, 'This QR code is not a visitor pass.');
      }
      await Future<void>.delayed(const Duration(seconds: 2));
      _busy = false;
      return;
    }

    try {
      await _controller.stop();
      final visitor = await ref.read(visitorRepositoryProvider).fetchById(raw);
      final notifier = ref.read(visitorsProvider.notifier);
      notifier.upsert(visitor);
      try {
        await notifier.refresh();
      } catch (_) {
        // Keep the scanned visitor in memory if the full list cannot reload.
      }
      final stillThere = ref
          .read(visitorsProvider)
          .value
          ?.any((item) => item.id == visitor.id);
      if (stillThere != true) notifier.upsert(visitor);
      if (!mounted) return;
      await context.push(AppRoutes.visitorDetails(visitor.id));
    } on ApiException catch (error) {
      if (mounted) showAppMessage(context, error.message);
    } catch (_) {
      if (mounted) {
        showAppMessage(context, 'Unable to look up this visitor.');
      }
    } finally {
      _busy = false;
      if (mounted) {
        try {
          await _controller.start();
        } on MobileScannerException {
          // The camera is already running, or this tab was closed.
        }
      }
    }
  }
}
