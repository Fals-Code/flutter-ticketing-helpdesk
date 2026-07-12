import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uts/shared/theme/app_theme.dart';
import 'package:uts/shared/theme/extensions/app_motion.dart';
import 'package:uts/shared/theme/extensions/app_radius.dart';
import 'package:uts/shared/theme/extensions/app_spacing.dart';

void main() {
  group('AppTheme design tokens', () {
    testWidgets('injects tokens into the light theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) {
              expect(context.spacing.lg, 16);
              expect(context.radius.card, 12);
              expect(
                context.motion.fast,
                const Duration(milliseconds: 180),
              );
              expect(context.motion.standardCurve, Curves.easeOutCubic);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });

    testWidgets('injects tokens into the dark theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Builder(
            builder: (context) {
              expect(context.spacing.xl, 24);
              expect(context.radius.sheet, 16);
              expect(
                context.motion.transition,
                const Duration(milliseconds: 300),
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });

    testWidgets('uses safe defaults when extensions are missing',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Builder(
            builder: (context) {
              expect(context.spacing.md, 12);
              expect(context.radius.button, 8);
              expect(
                context.motion.page,
                const Duration(milliseconds: 400),
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });
  });
}
