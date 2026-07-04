import 'package:flutter/material.dart';
import 'package:uts/core/services/connectivity_service.dart';
import 'package:uts/core/di/injection_container.dart';
import 'package:uts/core/constants/app_colors.dart';
import 'package:uts/core/constants/app_dimensions.dart';

class ConnectivityBannerWidget extends StatefulWidget {
  final Widget child;

  const ConnectivityBannerWidget({super.key, required this.child});

  @override
  State<ConnectivityBannerWidget> createState() =>
      _ConnectivityBannerWidgetState();
}

class _ConnectivityBannerWidgetState extends State<ConnectivityBannerWidget> {
  final connectivityService = sl<ConnectivityService>();
  bool _showBanner = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ConnectionStatus>(
      stream: connectivityService.connectionStream,
      initialData: ConnectionStatus.online,
      builder: (context, snapshot) {
        final isOffline = snapshot.data == ConnectionStatus.offline;

        // Add a slight delay before showing the banner to avoid flickering
        if (isOffline && !_showBanner) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _showBanner = true);
          });
        } else if (!isOffline && _showBanner) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _showBanner = false);
          });
        }

        return Stack(
          children: [
            widget.child,
            AnimatedPositioned(
              duration:
                  const Duration(milliseconds: AppDimensions.motionMediumMs),
              curve: Curves.easeOutCubic,
              top: _showBanner
                  ? MediaQuery.of(context).padding.top
                  : -(MediaQuery.of(context).padding.top + 60),
              left: 0,
              right: 0,
              child: Material(
                color: Colors.transparent,
                child: Semantics(
                  liveRegion: true,
                  label: 'Status koneksi offline',
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.space16,
                      vertical: AppDimensions.space8,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDimensions.space12,
                      horizontal: AppDimensions.space16,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusSM),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.danger.withValues(alpha: 0.28),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.wifi_off_rounded,
                          color: Colors.white,
                          size: AppDimensions.iconMD,
                        ),
                        SizedBox(width: AppDimensions.space12),
                        Flexible(
                          child: Text(
                            'Koneksi internet terputus',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
