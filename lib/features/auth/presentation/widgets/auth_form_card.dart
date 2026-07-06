import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/widgets/app_surface_card.dart';

class AuthFormCard extends StatelessWidget {
  const AuthFormCard({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppDimensions.space24),
      child: child,
    );
  }
}
