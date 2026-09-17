import '../models/onboarding_page.dart';

/// The intro slides, in order.
///
/// Titles are split so the second half can take the brand colour, which is
/// what gives these screens their look.
const List<OnboardingPage> onboardingPages = <OnboardingPage>[
  OnboardingPage(
    art: SlideArtKind.meal,
    title: 'Track Your Meals',
    highlight: 'Effortlessly',
    body: 'Log your food, get instant nutrition insights and stay on top of '
        'your goals.',
    dark: false,
  ),
  OnboardingPage(
    art: SlideArtKind.progress,
    title: 'See Your',
    highlight: 'Progress',
    body: 'Visualise your nutrition, build better habits, and reach your '
        'goals faster.',
    dark: true,
  ),
  OnboardingPage(
    art: SlideArtKind.goals,
    title: 'A',
    highlight: 'Healthier You',
    body: "Whatever your goal is, we're here to support your journey.",
    dark: false,
  ),
];
