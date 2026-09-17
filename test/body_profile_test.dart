import 'package:daily_protein/core/models/body_profile.dart';
import 'package:flutter_test/flutter_test.dart';

BodyProfile _profile({
  BodySex sex = BodySex.male,
  int age = 25,
  double heightCm = 175,
  double weightKg = 70,
  FitnessGoal goal = FitnessGoal.maintainWeight,
}) {
  return BodyProfile(
    sex: sex,
    age: age,
    heightCm: heightCm,
    weightKg: weightKg,
    goal: goal,
  );
}

void main() {
  group('basal rate', () {
    test('matches Mifflin-St Jeor for a man', () {
      // 10*70 + 6.25*175 - 5*30 + 5 = 1648.75
      expect(
        _profile(age: 30).basalRate,
        closeTo(1648.75, 0.01),
      );
    });

    test('matches Mifflin-St Jeor for a woman', () {
      // 10*60 + 6.25*165 - 5*30 - 161 = 1320.25
      expect(
        _profile(sex: BodySex.female, age: 30, heightCm: 165, weightKg: 60)
            .basalRate,
        closeTo(1320.25, 0.01),
      );
    });

    test('the sex constant is the only difference', () {
      // 5 vs -161 is a 166 kcal gap, and nothing else in the formula changes.
      final double male = _profile().basalRate;
      final double female = _profile(sex: BodySex.female).basalRate;
      expect(male - female, closeTo(166, 0.01));
    });

    test('falls with age and rises with size', () {
      expect(_profile(age: 40).basalRate, lessThan(_profile(age: 20).basalRate));
      expect(
        _profile(weightKg: 90).basalRate,
        greaterThan(_profile(weightKg: 60).basalRate),
      );
      expect(
        _profile(heightCm: 190).basalRate,
        greaterThan(_profile(heightCm: 160).basalRate),
      );
    });
  });

  group('suggested calories', () {
    test('sit either side of maintenance according to the goal', () {
      final double maintain =
          _profile(goal: FitnessGoal.maintainWeight).suggestedCalories;
      final double lose =
          _profile(goal: FitnessGoal.loseWeight).suggestedCalories;
      final double build =
          _profile(goal: FitnessGoal.buildMuscle).suggestedCalories;

      expect(lose, lessThan(maintain));
      expect(build, greaterThan(maintain));
    });

    test('the deficit and surplus stay moderate', () {
      // Guards against anything aggressive creeping into the factors: an
      // onboarding screen should not propose a crash diet.
      final double maintain =
          _profile(goal: FitnessGoal.maintainWeight).suggestedCalories;
      final double lose =
          _profile(goal: FitnessGoal.loseWeight).suggestedCalories;

      expect(lose / maintain, greaterThan(0.75));
      expect(lose / maintain, lessThan(0.95));
    });

    test('round to a figure a person would say', () {
      for (final FitnessGoal goal in FitnessGoal.values) {
        final double value = _profile(goal: goal).suggestedCalories;
        expect(value % 50, 0, reason: '$goal produced $value');
      }
    });

    test('stay plausible across the input range', () {
      // Every combination the sliders allow must land somewhere sane; a
      // negative or absurd target would be worse than no estimate.
      for (final BodySex sex in BodySex.values) {
        for (final int age in <int>[13, 45, 90]) {
          for (final double height in <double>[120, 170, 220]) {
            for (final double weight in <double>[30, 100, 200]) {
              final double value = _profile(
                sex: sex,
                age: age,
                heightCm: height,
                weightKg: weight,
              ).suggestedCalories;

              // The floor matters most at the small end, where the raw
              // formula drops under 700 kcal.
              expect(
                value,
                greaterThanOrEqualTo(BodyProfile.minimumSuggestedCalories),
                reason: '$sex $age $height $weight gave $value',
              );
              expect(value, lessThan(6000));
            }
          }
        }
      }
    });
  });

  group('suggested protein', () {
    test('scales with body weight', () {
      expect(
        _profile(weightKg: 90).suggestedProtein,
        greaterThan(_profile(weightKg: 60).suggestedProtein),
      );
    });

    test('is highest when building muscle', () {
      final double build =
          _profile(goal: FitnessGoal.buildMuscle).suggestedProtein;
      for (final FitnessGoal goal in FitnessGoal.values) {
        expect(build, greaterThanOrEqualTo(_profile(goal: goal).suggestedProtein));
      }
    });

    test('exceeds maintenance when losing weight', () {
      // Protein helps preserve lean mass in a deficit, so it goes up rather
      // than down when calories come off.
      expect(
        _profile(goal: FitnessGoal.loseWeight).suggestedProtein,
        greaterThan(_profile(goal: FitnessGoal.maintainWeight).suggestedProtein),
      );
    });

    test('stays within the commonly cited band', () {
      for (final FitnessGoal goal in FitnessGoal.values) {
        final BodyProfile profile = _profile(goal: goal, weightKg: 70);
        final double perKg = profile.suggestedProtein / 70;
        expect(perKg, greaterThanOrEqualTo(1.5), reason: '$goal');
        expect(perKg, lessThanOrEqualTo(2.3), reason: '$goal');
      }
    });

    test('rounds to the nearest 5', () {
      for (final double weight in <double>[52, 63.5, 81, 97]) {
        final double value = _profile(weightKg: weight).suggestedProtein;
        expect(value % 5, 0, reason: '$weight produced $value');
      }
    });
  });
}
