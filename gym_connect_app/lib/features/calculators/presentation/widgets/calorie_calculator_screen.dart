import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/calculator_models.dart';

class CalorieCalculatorScreen extends StatefulWidget {
  const CalorieCalculatorScreen({super.key});

  @override
  State<CalorieCalculatorScreen> createState() =>
      _CalorieCalculatorScreenState();
}

class _CalorieCalculatorScreenState extends State<CalorieCalculatorScreen> {
  Gender _gender = Gender.male;
  UnitSystem _unitSystem = UnitSystem.metric;
  ActivityLevel _activityLevel = ActivityLevel.moderatelyActive;
  CalorieGoal _goal = CalorieGoal.maintain;

  double _weightKg = 75;
  double _heightCm = 175;
  int _age = 25;

  // Imperial helpers
  double _weightLbs = 165;
  int _heightFeet = 5;
  int _heightInches = 9;

  CalorieResult? _result;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _calculate() {
    final double wKg = _unitSystem == UnitSystem.metric
        ? _weightKg
        : CalorieCalculatorEngine.lbsToKg(_weightLbs);
    final double hCm = _unitSystem == UnitSystem.metric
        ? _heightCm
        : CalorieCalculatorEngine.feetInchesToCm(_heightFeet, _heightInches);

    final input = CalorieInput(
      gender: _gender,
      unitSystem: _unitSystem,
      weightKg: wKg,
      heightCm: hCm,
      age: _age,
      activityLevel: _activityLevel,
      goal: _goal,
    );

    setState(() {
      _result = CalorieCalculatorEngine.calculate(input);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'CALORIE CALCULATOR',
          style: GoogleFonts.oswald(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.0,
          ),
        ),
        centerTitle: true,
      ),
      body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _buildInputPanel(),
          ),
        ),
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _buildResultPanel(),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildInputPanel(),
          const SizedBox(height: 20),
          _buildResultPanel(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildInputPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Details',
          style: GoogleFonts.oswald(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Enter your stats to get personalized results',
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 18),
        _buildGenderToggle(),
        const SizedBox(height: 14),
        _buildUnitToggle(),
        const SizedBox(height: 14),
        _buildAgeSlider(),
        const SizedBox(height: 14),
        _buildWeightSlider(),
        const SizedBox(height: 14),
        _buildHeightSlider(),
        const SizedBox(height: 14),
        _buildActivityDropdown(),
        const SizedBox(height: 14),
        _buildGoalSelector(),
      ],
    );
  }

  Widget _buildGenderToggle() {
    return _sectionCard(
      child: Row(
        children: [
          _segmentBtn(
            label: 'Male',
            icon: Icons.male_rounded,
            selected: _gender == Gender.male,
            onTap: () {
              setState(() => _gender = Gender.male);
              _calculate();
            },
          ),
          const SizedBox(width: 10),
          _segmentBtn(
            label: 'Female',
            icon: Icons.female_rounded,
            selected: _gender == Gender.female,
            onTap: () {
              setState(() => _gender = Gender.female);
              _calculate();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUnitToggle() {
    return _sectionCard(
      child: Row(
        children: [
          _segmentBtn(
            label: 'Metric (kg/cm)',
            selected: _unitSystem == UnitSystem.metric,
            onTap: () {
              if (_unitSystem != UnitSystem.metric) {
                setState(() {
                  _unitSystem = UnitSystem.metric;
                  _weightKg = CalorieCalculatorEngine.lbsToKg(_weightLbs).roundToDouble().clamp(30.0, 200.0);
                  _heightCm = CalorieCalculatorEngine.feetInchesToCm(_heightFeet, _heightInches).clamp(120.0, 220.0);
                });
                _calculate();
              }
            },
          ),
          const SizedBox(width: 10),
          _segmentBtn(
            label: 'Imperial (lbs/ft)',
            selected: _unitSystem == UnitSystem.imperial,
            onTap: () {
              if (_unitSystem != UnitSystem.imperial) {
                setState(() {
                  _unitSystem = UnitSystem.imperial;
                  _weightLbs = CalorieCalculatorEngine.kgToLbs(_weightKg).roundToDouble().clamp(66.0, 440.0);
                  final (ft, inch) = CalorieCalculatorEngine.cmToFeetInches(_heightCm);
                  _heightFeet = ft.clamp(4, 7);
                  _heightInches = inch.clamp(0, 11);
                });
                _calculate();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAgeSlider() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Age', style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_age years',
                  style: GoogleFonts.oswald(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: _sliderTheme,
            child: Slider(
              value: _age.toDouble(),
              min: 14,
              max: 80,
              divisions: 66,
              onChanged: (v) {
                setState(() => _age = v.round());
                _calculate();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightSlider() {
    final isMetric = _unitSystem == UnitSystem.metric;
    final value = isMetric ? _weightKg : _weightLbs;
    final min = isMetric ? 30.0 : 66.0;
    final max = isMetric ? 200.0 : 440.0;
    final unit = isMetric ? 'kg' : 'lbs';

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Weight', style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${value.round()} $unit',
                  style: GoogleFonts.oswald(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: _sliderTheme,
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: (max - min).round(),
              onChanged: (v) {
                setState(() {
                  if (isMetric) {
                    _weightKg = v;
                    _weightLbs = CalorieCalculatorEngine.kgToLbs(v).roundToDouble().clamp(66.0, 440.0);
                  } else {
                    _weightLbs = v;
                    _weightKg = CalorieCalculatorEngine.lbsToKg(v).roundToDouble().clamp(30.0, 200.0);
                  }
                });
                _calculate();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeightSlider() {
    if (_unitSystem == UnitSystem.imperial) {
      return _sectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Height', style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "$_heightFeet' $_heightInches\"",
                    style: GoogleFonts.oswald(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text('Feet', style: GoogleFonts.inter(
                          fontSize: 11, color: AppColors.textSecondary)),
                      SliderTheme(
                        data: _sliderTheme,
                        child: Slider(
                          value: _heightFeet.toDouble(),
                          min: 4,
                          max: 7,
                          divisions: 3,
                          onChanged: (v) {
                            setState(() {
                              _heightFeet = v.round();
                              _heightCm = CalorieCalculatorEngine.feetInchesToCm(_heightFeet, _heightInches).clamp(120.0, 220.0);
                            });
                            _calculate();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text('Inches', style: GoogleFonts.inter(
                          fontSize: 11, color: AppColors.textSecondary)),
                      SliderTheme(
                        data: _sliderTheme,
                        child: Slider(
                          value: _heightInches.toDouble(),
                          min: 0,
                          max: 11,
                          divisions: 11,
                          onChanged: (v) {
                            setState(() {
                              _heightInches = v.round();
                              _heightCm = CalorieCalculatorEngine.feetInchesToCm(_heightFeet, _heightInches).clamp(120.0, 220.0);
                            });
                            _calculate();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Height', style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_heightCm.round()} cm',
                  style: GoogleFonts.oswald(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: _sliderTheme,
            child: Slider(
              value: _heightCm,
              min: 120,
              max: 220,
              divisions: 100,
              onChanged: (v) {
                setState(() {
                  _heightCm = v;
                  final (f, i) = CalorieCalculatorEngine.cmToFeetInches(v);
                  _heightFeet = f.clamp(4, 7);
                  _heightInches = i.clamp(0, 11);
                });
                _calculate();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityDropdown() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Activity Level', style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 8),
          ...ActivityLevel.values.map((level) {
            final isSelected = _activityLevel == level;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: InkWell(
                onTap: () {
                  setState(() => _activityLevel = level);
                  _calculate();
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.5)
                          : AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        size: 18,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              level.label,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.white,
                              ),
                            ),
                            Text(
                              level.description,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGoalSelector() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Goal', style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 8),
          Row(
            children: CalorieGoal.values.map((g) {
              final isSelected = _goal == g;
              final color = g == CalorieGoal.lose
                  ? Colors.redAccent
                  : (g == CalorieGoal.gain
                      ? Colors.greenAccent
                      : AppColors.primary);
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: g != CalorieGoal.gain ? 8 : 0),
                  child: InkWell(
                    onTap: () {
                      setState(() => _goal = g);
                      _calculate();
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withValues(alpha: 0.15)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? color.withValues(alpha: 0.6)
                              : AppColors.border,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          g.label,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected ? color : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultPanel() {
    if (_result == null) return const SizedBox.shrink();
    final res = _result!;

    return Column(
      children: [
        _buildCalorieGauge(res),
        const SizedBox(height: 18),
        _buildMetricRow(res),
        const SizedBox(height: 18),
        _buildMacroBreakdown(res),
      ],
    );
  }

  Widget _buildCalorieGauge(CalorieResult res) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            'YOUR DAILY CALORIES',
            style: GoogleFonts.oswald(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(
              begin: res.targetCalories.toDouble(),
              end: res.targetCalories.toDouble(),
            ),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            builder: (context, animValue, _) {
              return SizedBox(
                width: 220,
                height: 220,
                child: CustomPaint(
                  painter: _CalorieGaugePainter(
                    value: animValue.round(),
                    maxValue: 5000,
                    progress: 1.0,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${animValue.round()}',
                          style: GoogleFonts.oswald(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'kcal / day',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(CalorieResult res) {
    return Row(
      children: [
        Expanded(
          child: _resultMetricCard(
            label: 'BMR',
            value: '${res.bmr}',
            unit: 'kcal',
            color: Colors.cyanAccent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _resultMetricCard(
            label: 'TDEE',
            value: '${res.tdee}',
            unit: 'kcal',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _resultMetricCard(
            label: 'TARGET',
            value: '${res.targetCalories}',
            unit: 'kcal',
            color: _goal == CalorieGoal.lose
                ? Colors.redAccent
                : (_goal == CalorieGoal.gain
                    ? Colors.greenAccent
                    : AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _resultMetricCard({
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.oswald(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            unit,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroBreakdown(CalorieResult res) {
    final total = res.protein * 4 + res.carbs * 4 + res.fat * 9;
    final proteinPct = total > 0 ? (res.protein * 4 / total * 100) : 0.0;
    final carbsPct = total > 0 ? (res.carbs * 4 / total * 100) : 0.0;
    final fatPct = total > 0 ? (res.fat * 9 / total * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MACRONUTRIENT BREAKDOWN',
            style: GoogleFonts.oswald(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 14),
          // Stacked bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  Expanded(
                    flex: proteinPct.round(),
                    child: Container(color: Colors.redAccent),
                  ),
                  Expanded(
                    flex: carbsPct.round(),
                    child: Container(color: AppColors.primary),
                  ),
                  Expanded(
                    flex: fatPct.round(),
                    child: Container(color: Colors.amber),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _macroItem(
                  label: 'Protein',
                  grams: '${res.protein}g',
                  pct: '${proteinPct.round()}%',
                  color: Colors.redAccent,
                ),
              ),
              Expanded(
                child: _macroItem(
                  label: 'Carbs',
                  grams: '${res.carbs}g',
                  pct: '${carbsPct.round()}%',
                  color: AppColors.primary,
                ),
              ),
              Expanded(
                child: _macroItem(
                  label: 'Fat',
                  grams: '${res.fat}g',
                  pct: '${fatPct.round()}%',
                  color: Colors.amber,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _macroItem({
    required String label,
    required String grams,
    required String pct,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          grams,
          style: GoogleFonts.oswald(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          pct,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }

  Widget _segmentBtn({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.15)
                : AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18,
                    color: selected ? AppColors.primary : AppColors.textSecondary),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  SliderThemeData get _sliderTheme => SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.border,
        thumbColor: AppColors.primary,
        overlayColor: AppColors.primary.withValues(alpha: 0.15),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      );
}

class _CalorieGaugePainter extends CustomPainter {
  final int value;
  final int maxValue;
  final double progress;

  _CalorieGaugePainter({
    required this.value,
    required this.maxValue,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const startAngle = 2.35;
    const sweepAngle = 4.7;

    // Background arc
    final bgPaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    // Value arc with gradient
    final valueFraction = (value / maxValue).clamp(0.0, 1.0);
    final valueSweep = sweepAngle * valueFraction * progress;

    final gradientPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle,
        colors: const [
          Color(0xFFCCFF00),
          Color(0xFFFF6B35),
          Color(0xFFFF3D00),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      valueSweep,
      false,
      gradientPaint,
    );

    // Tick marks
    for (int i = 0; i <= 20; i++) {
      final angle = startAngle + (sweepAngle * i / 20);
      final isMajor = i % 5 == 0;
      final outerR = radius + 8;
      final innerR = radius + (isMajor ? 2 : 4);

      final outerPoint = Offset(
        center.dx + outerR * math.cos(angle),
        center.dy + outerR * math.sin(angle),
      );
      final innerPoint = Offset(
        center.dx + innerR * math.cos(angle),
        center.dy + innerR * math.sin(angle),
      );

      canvas.drawLine(
        outerPoint,
        innerPoint,
        Paint()
          ..color = isMajor ? Colors.white30 : Colors.white12
          ..strokeWidth = isMajor ? 1.5 : 0.8,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CalorieGaugePainter old) =>
      old.value != value || old.progress != progress;
}
