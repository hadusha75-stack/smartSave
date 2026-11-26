import 'package:flutter/material.dart';

/// App logo used at the top of auth screens.
/// Shows a savings icon and the app name.
class AuthLogo extends StatelessWidget {
  final bool large;
  const AuthLogo({super.key, this.large = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconSize = large ? 72.0 : 52.0;
    final titleSize = large ? 32.0 : 24.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: iconSize + 24,
          height: iconSize + 24,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            Icons.savings_rounded,
            size: iconSize,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'SaveSmart',
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.w800,
            color: colorScheme.primary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Your savings, your goals',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
