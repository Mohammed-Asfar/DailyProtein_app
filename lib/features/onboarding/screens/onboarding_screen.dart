import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../data/onboarding_pages.dart';
import '../models/onboarding_page.dart';
import '../widgets/onboarding_parts.dart';
import '../widgets/slide_art.dart';

/// The intro carousel: what the app does, before anything is asked of the
/// user.
class IntroCarouselScreen extends StatefulWidget {
  const IntroCarouselScreen({
    super.key,
    required this.onDone,
    required this.onSkip,
  });

  /// Reached the end of the slides.
  final VoidCallback onDone;

  /// Skipped the slides. Both land in the same place; kept separate so the
  /// caller can tell the two apart.
  final VoidCallback onSkip;

  @override
  State<IntroCarouselScreen> createState() => _IntroCarouselScreenState();
}

class _IntroCarouselScreenState extends State<IntroCarouselScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_index == onboardingPages.length - 1) {
      widget.onDone();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Each slide carries its own brightness, so the page is themed from the
    // slide rather than from the device. Animated so swiping between a light
    // and a dark slide fades rather than snaps.
    final OnboardingPage page = onboardingPages[_index];

    return AnimatedTheme(
      data: page.dark ? AppTheme.dark : AppTheme.light,
      duration: const Duration(milliseconds: 280),
      child: Builder(
        builder: (BuildContext context) {
          final ThemeData theme = Theme.of(context);

          // AnimatedTheme already tweens scaffoldBackgroundColor, so the
          // Scaffold alone gives the cross-fade between a light and a dark
          // slide.
          return Scaffold(
            body: SafeArea(
              child: Column(
                children: <Widget>[
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      child: TextButton(
                        onPressed: widget.onSkip,
                        child: const Text('Skip'),
                      ),
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: onboardingPages.length,
                      onPageChanged: (int page) =>
                          setState(() => _index = page),
                      itemBuilder: (BuildContext context, int page) =>
                          _Slide(page: onboardingPages[page]),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Row(
                      children: <Widget>[
                        OnboardingDots(
                          count: onboardingPages.length,
                          index: _index,
                        ),
                        const Spacer(),
                        // Round rather than full width: the slides can be
                        // skipped, so this should not read as the only way
                        // forward.
                        FloatingActionButton(
                          onPressed: _next,
                          elevation: 2,
                          shape: const CircleBorder(),
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          child: const Icon(Icons.arrow_forward_rounded),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({required this.page});

  final OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        children: <Widget>[
          const SizedBox(height: AppSpacing.lg),
          switch (page.art) {
            SlideArtKind.meal => const MealArt(),
            SlideArtKind.progress => const ProgressArt(),
            SlideArtKind.goals => const GoalsArt(),
          },
          const SizedBox(height: AppSpacing.xxl),
          OnboardingTitle(title: page.title, highlight: page.highlight),
          const SizedBox(height: AppSpacing.md),
          Text(
            page.body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
