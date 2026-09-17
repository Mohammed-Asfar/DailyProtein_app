import 'package:daily_protein/core/models/body_profile.dart';
import 'package:daily_protein/core/theme/app_theme.dart';
import 'package:daily_protein/features/onboarding/screens/onboarding_flow.dart';
import 'package:daily_protein/features/settings/data/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Records what onboarding writes without touching SharedPreferences.
class _FakeSettings extends SettingsController {
  double? savedProtein;
  double? savedCalories;
  FitnessGoal? savedGoal;
  bool completed = false;

  @override
  Future<void> load() async {}

  @override
  Future<void> setProteinGoal(double value) async => savedProtein = value;

  @override
  Future<void> setCalorieGoal(double value) async => savedCalories = value;

  @override
  Future<void> setFitnessGoal(FitnessGoal goal) async => savedGoal = goal;

  @override
  Future<void> completeOnboarding() async => completed = true;
}

/// Matches text inside a Text.rich span tree.
///
/// OnboardingTitle splits its heading into spans so half can take the
/// brand colour, and find.text does not look inside spans.
Finder _richText(String needle) => find.byWidgetPredicate((Widget w) {
  if (w is! Text || w.textSpan == null) return false;
  return w.textSpan!.toPlainText().contains(needle);
});

Widget _harness(
  _FakeSettings settings, {
  Size size = const Size(360, 760),
  Key? key,
}) {
  return ChangeNotifierProvider<SettingsController>.value(
    value: settings,
    child: MediaQuery(
      data: MediaQueryData(size: size),
      child: MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: OnboardingFlow(key: key),
      ),
    ),
  );
}

/// Walks welcome -> slides -> setup, leaving the first setup step showing.
Future<void> _toSetup(WidgetTester tester) async {
  await tester.tap(find.text('Get Started'));
  await tester.pumpAndSettle();
  // One tap per slide; the last one leaves the carousel.
  for (int i = 0; i < 3; i++) {
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
  }
}

/// Advances through the remaining setup steps and finishes.
Future<void> _finishSetup(WidgetTester tester) async {
  for (int i = 0; i < 3; i++) {
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
  }
  await tester.tap(find.text('Finish Setup'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('starts on the welcome screen', (WidgetTester tester) async {
    await tester.pumpWidget(_harness(_FakeSettings()));
    await tester.pumpAndSettle();

    expect(_richText('Eat Better'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });

  testWidgets('walks through every slide to setup', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_harness(_FakeSettings()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    expect(_richText('Effortlessly'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(_richText('Progress'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(_richText('Healthier You'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Your Gender'), findsOneWidget);
  });

  testWidgets('Skip jumps the slides but still reaches setup', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_harness(_FakeSettings()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    // Skipping the explanation must not skip the targets, which the app
    // cannot sensibly guess.
    expect(find.text('Your Gender'), findsOneWidget);
  });

  testWidgets('finishing writes both targets, the goal and the flag', (
    WidgetTester tester,
  ) async {
    final _FakeSettings settings = _FakeSettings();
    await tester.pumpWidget(_harness(settings));
    await tester.pumpAndSettle();

    await _toSetup(tester);
    await _finishSetup(tester);

    expect(settings.completed, isTrue);
    expect(settings.savedProtein, isNotNull);
    expect(settings.savedCalories, isNotNull);
    expect(settings.savedGoal, isNotNull);
  });

  testWidgets('the goal choice changes the saved targets', (
    WidgetTester tester,
  ) async {
    // Build Muscle should not produce the same numbers as Lose Weight, or
    // the question was pointless.
    final Map<String, (double?, double?)> saved =
        <String, (double?, double?)>{};

    for (final String label in <String>['Lose Weight', 'Build Muscle']) {
      final _FakeSettings settings = _FakeSettings();
      // A fresh key per run: without it the second pumpWidget reuses the
      // first flow's state and the walkthrough starts mid-way.
      await tester.pumpWidget(
        _harness(settings, key: ValueKey<String>(label)),
      );
      await tester.pumpAndSettle();

      await _toSetup(tester);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(label));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Finish Setup'));
      await tester.pumpAndSettle();

      saved[label] = (settings.savedCalories, settings.savedProtein);
    }

    expect(saved['Lose Weight']!.$1, isNot(saved['Build Muscle']!.$1));
    expect(saved['Lose Weight']!.$2, isNot(saved['Build Muscle']!.$2));
  });

  testWidgets('back returns to the previous setup step', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_harness(_FakeSettings()));
    await tester.pumpAndSettle();

    await _toSetup(tester);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(_richText('Your Goal?'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Your Gender'), findsOneWidget);
  });

  testWidgets('no screen overflows on a small phone', (
    WidgetTester tester,
  ) async {
    // 320x568 is about the smallest screen still in use. Every step gets
    // pumped and checked, because an overflow throws silently in release.
    await tester.pumpWidget(
      _harness(_FakeSettings(), size: const Size(320, 568)),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'welcome');

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    for (int slide = 0; slide < 3; slide++) {
      expect(tester.takeException(), isNull, reason: 'slide $slide');
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
    }

    for (int step = 0; step < 4; step++) {
      expect(tester.takeException(), isNull, reason: 'setup step $step');
      if (step < 3) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }
    }
  });
}
