import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/body_profile.dart';
import '../../../core/theme/app_spacing.dart';
import '../../settings/data/settings_controller.dart';
import '../widgets/onboarding_parts.dart';
import '../widgets/setup_steps.dart';

/// The personalisation half of onboarding: body details, goal, then the two
/// targets those produce.
///
/// One screen with four steps rather than four routes, because every step
/// reads and writes the same draft profile and the estimate has to follow
/// the user's edits as they go.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  static const int _stepCount = 4;

  int _step = 0;

  // Draft profile. Defaults are unremarkable middle values rather than
  // anything suggestive.
  BodySex _sex = BodySex.male;
  int _age = 25;
  double _heightCm = 170;
  double _weightKg = 70;
  FitnessGoal _goal = FitnessGoal.maintainWeight;

  /// Targets start from the estimate and stop following it once the user
  /// moves a slider, so returning to an earlier step cannot silently undo a
  /// deliberate choice.
  double? _calories;
  double? _protein;

  BodyProfile get _profile => BodyProfile(
        sex: _sex,
        age: _age,
        heightCm: _heightCm,
        weightKg: _weightKg,
        goal: _goal,
      );

  double get _calorieTarget => _calories ?? _profile.suggestedCalories;
  double get _proteinTarget => _protein ?? _profile.suggestedProtein;

  void _back() {
    if (_step == 0) return;
    setState(() => _step--);
  }

  Future<void> _next() async {
    if (_step < _stepCount - 1) {
      setState(() => _step++);
      return;
    }
    await _finish();
  }

  Future<void> _finish() async {
    final SettingsController settings = context.read<SettingsController>();

    await settings.setProteinGoal(_proteinTarget);
    await settings.setCalorieGoal(_calorieTarget);
    await settings.setFitnessGoal(_goal);
    await settings.completeOnboarding();

    widget.onFinished();
  }

  String get _buttonLabel =>
      _step == _stepCount - 1 ? 'Finish Setup' : 'Next';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.xl,
                AppSpacing.sm,
              ),
              child: Row(
                children: <Widget>[
                  IconButton(
                    onPressed: _step == 0 ? null : _back,
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    iconSize: 18,
                  ),
                  Expanded(
                    child: OnboardingProgress(
                      step: _step + 1,
                      total: _stepCount,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.lg,
                ),
                child: _buildStep(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: OnboardingButton(
                label: _buttonLabel,
                onPressed: _next,
                icon: _step == _stepCount - 1
                    ? null
                    : Icons.arrow_forward_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    return switch (_step) {
      0 => BodyDetailsStep(
          sex: _sex,
          age: _age,
          heightCm: _heightCm,
          weightKg: _weightKg,
          onSexChanged: (BodySex value) => setState(() => _sex = value),
          onAgeChanged: (int value) => setState(() => _age = value),
          onHeightChanged: (double value) =>
              setState(() => _heightCm = value),
          onWeightChanged: (double value) =>
              setState(() => _weightKg = value),
        ),
      1 => GoalStep(
          selected: _goal,
          onChanged: (FitnessGoal value) => setState(() => _goal = value),
        ),
      2 => TargetStep(
          title: 'Set Your Daily',
          highlight: 'Calorie Goal',
          body: "We've estimated your needs based on your details. You can "
              'adjust it anytime.',
          value: _calorieTarget,
          min: 1200,
          max: 4000,
          step: 50,
          unit: 'kcal/day',
          hintIcon: Icons.lightbulb_outline_rounded,
          hint: _calorieHint,
          onChanged: (double value) => setState(() => _calories = value),
        ),
      _ => TargetStep(
          title: 'Set Your',
          highlight: 'Protein Goal',
          body: 'Protein helps you stay full, build muscle and maintain a '
              'healthy body.',
          value: _proteinTarget,
          min: 40,
          max: 250,
          step: 5,
          unit: 'protein per day',
          suffix: ' g',
          hintIcon: Icons.fitness_center_rounded,
          hint: 'Recommended: 1.6 – 2.2 g per kg of body weight for most '
              'people.',
          onChanged: (double value) => setState(() => _protein = value),
        ),
    };
  }

  String get _calorieHint => switch (_goal) {
        FitnessGoal.loseWeight =>
          'A moderate deficit below your maintenance level.',
        FitnessGoal.buildMuscle =>
          'A small surplus above maintenance to support growth.',
        _ => 'This is your daily calorie target to maintain your current '
            'weight.',
      };
}
