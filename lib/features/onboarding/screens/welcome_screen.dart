import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/onboarding_parts.dart';

/// The very first screen: the logo, the promise, one button.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    // Always dark, whatever the device is set to: the logo is drawn for a
    // dark ground and the first screen should look the same for everyone.
    return Theme(
      data: AppTheme.dark,
      child: Builder(builder: _buildBody),
    );
  }

  Widget _buildBody(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            children: <Widget>[
              const Spacer(flex: 2),
              // The launcher artwork, so the first screen matches the icon
              // the user just tapped.
              Image.asset(
                'assets/branding/app_icon.png',
                height: 168,
                width: 168,
                // A missing asset must not take the app down on first run.
                errorBuilder: (BuildContext context, Object error,
                        StackTrace? stack) =>
                    const OnboardingBadge(icon: Icons.restaurant_rounded),
              ),
              const SizedBox(height: AppSpacing.xl),
              const OnboardingTitle(
                title: 'Eat Better',
                highlight: 'Live Healthier',
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Track your meals, reach your goals and build a healthier you.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const Spacer(flex: 3),
              OnboardingButton(label: 'Get Started', onPressed: onStart),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
