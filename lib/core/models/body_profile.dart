/// Biological sex, used only by the BMR formula.
///
/// Mifflin-St Jeor takes a different constant for each, which is why it is
/// asked at all. It is not used anywhere else in the app.
enum BodySex { male, female }

/// What the user wants out of tracking. Shifts the suggested targets.
enum FitnessGoal {
  loseWeight,
  maintainWeight,
  buildMuscle,
  beHealthier;

  String get label => switch (this) {
        FitnessGoal.loseWeight => 'Lose Weight',
        FitnessGoal.maintainWeight => 'Maintain Weight',
        FitnessGoal.buildMuscle => 'Build Muscle',
        FitnessGoal.beHealthier => 'Be Healthier',
      };

  String get description => switch (this) {
        FitnessGoal.loseWeight => 'Create a calorie deficit',
        FitnessGoal.maintainWeight => 'Keep a balanced lifestyle',
        FitnessGoal.buildMuscle => 'Gain strength and lean mass',
        FitnessGoal.beHealthier => 'Overall wellness',
      };

  /// Multiplier applied to maintenance calories.
  ///
  /// A modest deficit and surplus: 20% either side is the range usually
  /// described as sustainable, and an onboarding screen is the wrong place
  /// to push anything aggressive.
  double get calorieFactor => switch (this) {
        FitnessGoal.loseWeight => 0.80,
        FitnessGoal.maintainWeight => 1.00,
        FitnessGoal.buildMuscle => 1.10,
        FitnessGoal.beHealthier => 1.00,
      };

  /// Grams of protein per kg of body weight.
  ///
  /// Within the 1.6–2.2 g/kg band commonly cited for active people. Higher
  /// while building muscle, and higher than maintenance when losing weight
  /// because protein helps preserve lean mass in a deficit.
  double get proteinPerKg => switch (this) {
        FitnessGoal.loseWeight => 1.8,
        FitnessGoal.maintainWeight => 1.6,
        FitnessGoal.buildMuscle => 2.0,
        FitnessGoal.beHealthier => 1.6,
      };
}

/// The body details behind an estimate.
class BodyProfile {
  const BodyProfile({
    required this.sex,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.goal,
  });

  final BodySex sex;
  final int age;
  final double heightCm;
  final double weightKg;
  final FitnessGoal goal;

  /// Resting energy from Mifflin-St Jeor, the formula most widely used for
  /// this estimate today.
  ///
  ///   10 x kg  +  6.25 x cm  -  5 x years  +  (5 male / -161 female)
  double get basalRate {
    final double base = 10 * weightKg + 6.25 * heightCm - 5 * age;
    return switch (sex) {
      BodySex.male => base + 5,
      BodySex.female => base - 161,
    };
  }

  /// Maintenance calories.
  ///
  /// Assumes light activity (x1.375). The app does not ask about exercise,
  /// and guessing sedentary would under-feed anyone who moves at all.
  double get maintenanceCalories => basalRate * 1.375;

  /// Lowest calorie figure the app will ever suggest.
  ///
  /// The formula alone bottoms out near 600 kcal for the smallest body the
  /// sliders allow, which is below any responsible intake. Anyone who
  /// genuinely wants less can still drag the slider there; the app just will
  /// not propose it.
  static const double minimumSuggestedCalories = 1200;

  /// Suggested daily calories, rounded to something a person would say.
  double get suggestedCalories {
    final double raw = maintenanceCalories * goal.calorieFactor;
    final double rounded = (raw / 50).round() * 50.0;
    return rounded < minimumSuggestedCalories
        ? minimumSuggestedCalories
        : rounded;
  }

  /// Suggested daily protein in grams, rounded to the nearest 5.
  double get suggestedProtein {
    final double raw = weightKg * goal.proteinPerKg;
    return (raw / 5).round() * 5.0;
  }
}
