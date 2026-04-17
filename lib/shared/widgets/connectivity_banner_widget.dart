import 'package:flutter/material.dart';
import 'package:uts/core/services/connectivity_service.dart';
import 'package:uts/core/di/injection_container.dart';

class ConnectivityBannerWidget extends StatefulWidget {
  final Widget child;

  const ConnectivityBannerWidget({super.key, required this.child});

  @override
  State<ConnectivityBannerWidget> createState() => _ConnectivityBannerWidgetState();
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
              duration: const Duration(milliseconds: 400),
              curve: Curves.fastOutSlowIn,
              top: _showBanner ? MediaQuery.of(context).padding.top : -(MediaQuery.of(context).padding.top + 60),
              left: 0,
              right: 0,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 12),
                      Text(
                        'Koneksi Internet Terputus',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
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
