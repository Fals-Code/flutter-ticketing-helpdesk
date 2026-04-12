import 'package:flutter/material.dart';
import 'package:uts/core/services/connectivity_service.dart';
import 'package:uts/core/di/injection_container.dart';

class ConnectivityBannerWidget extends StatelessWidget {
  final Widget child;

  const ConnectivityBannerWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final connectivityService = sl<ConnectivityService>();

    return StreamBuilder<ConnectionStatus>(
      stream: connectivityService.connectionStream,
      initialData: ConnectionStatus.online,
      builder: (context, snapshot) {
        final isOffline = snapshot.data == ConnectionStatus.offline;

        return Stack(
          children: [
            child,
            if (isOffline)
              Positioned(
                top: MediaQuery.of(context).padding.top,
                left: 0,
                right: 0,
                child: Material(
                  color: Colors.red.shade600,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_off, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Tidak ada koneksi internet',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
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
