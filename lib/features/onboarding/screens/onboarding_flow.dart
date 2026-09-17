import 'package:flutter/material.dart';

import 'onboarding_screen.dart';
import 'setup_screen.dart';
import 'welcome_screen.dart';

/// The whole first-launch experience: welcome, intro slides, then setup.
///
/// Held as one widget with an index rather than pushed routes, so the system
/// back gesture cannot drop the user into a half-configured app. Moving
/// backwards inside setup is handled by that screen's own control.
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key, this.onFinished});

  /// Optional notification that the flow is done. The app root swaps this
  /// screen out by watching the settings flag, which the setup screen writes
  /// before this fires, so most callers do not need it.
  final VoidCallback? onFinished;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  _Stage _stage = _Stage.welcome;

  void _go(_Stage stage) => setState(() => _stage = stage);

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      child: switch (_stage) {
        _Stage.welcome => WelcomeScreen(
            key: const ValueKey<String>('welcome'),
            onStart: () => _go(_Stage.intro),
          ),
        // Skipping the slides still lands in setup: the targets are the part
        // the app cannot sensibly guess on its own.
        _Stage.intro => IntroCarouselScreen(
            key: const ValueKey<String>('intro'),
            onDone: () => _go(_Stage.setup),
            onSkip: () => _go(_Stage.setup),
          ),
        _Stage.setup => SetupScreen(
            key: const ValueKey<String>('setup'),
            onFinished: widget.onFinished ?? () {},
          ),
      },
    );
  }
}

enum _Stage { welcome, intro, setup }
