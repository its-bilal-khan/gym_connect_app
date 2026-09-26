import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/calculator_models.dart';

class MacroCalculatorScreen extends StatefulWidget {
  const MacroCalculatorScreen({super.key});

  @override
  State<MacroCalculatorScreen> createState() => _MacroCalculatorScreenState();
}

class _MacroCalculatorScreenState extends State<MacroCalculatorScreen>
    with SingleTickerProviderStateMixin {
  double _totalCalories = 2200;
  double _proteinPct = 30;
  double _carbsPct = 40;
  double _fatPct = 30;

  int _presetIndex = 0;
  MacroResult? _result;

  late AnimationController _animController;
  late Animation<double> _donutAnim;

  static const _presets = [
    ('Balanced', 30.0, 40.0, 30.0),
    ('High Protein', 40.0, 35.0, 25.0),
    ('Low Carb', 35.0, 20.0, 45.0),
    ('Keto', 25.0, 5.0, 70.0),
    ('Custom', -1.0, -1.0, -1.0),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _donutAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _calculate();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _applyPreset(int idx) {
    final preset = _presets[idx];
    setState(() {
      _presetIndex = idx;
      if (preset.$2 > 0) {
        _proteinPct = preset.$2;
        _carbsPct = preset.$3;
        _fatPct = preset.$4;
      }
    });
    _calculate();
  }

  void _calculate() {
    setState(() {
      _result = CalorieCalculatorEngine.calculateMacros(
        totalCalories: _totalCalories.round(),
        proteinPct: _proteinPct,
        carbsPct: _carbsPct,
        fatPct: _fatPct,
      );
    });
    _animController.forward(from: 0);
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
          'MACRO CALCULATOR',
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
          'Plan Settings',
          style: GoogleFonts.oswald(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Set your daily calories and macro ratios',
          style:
              GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 18),
        _buildCalorieInput(),
        const SizedBox(height: 14),
        _buildPresetChips(),
        const SizedBox(height: 14),
        _buildMacroSlider(
          label: 'Protein',
          value: _proteinPct,
          color: Colors.redAccent,
          icon: Icons.egg_rounded,
          onChanged: (v) {
            setState(() {
              _proteinPct = v;
              _presetIndex = 4; // Custom
            });
          },
        ),
        const SizedBox(height: 10),
        _buildMacroSlider(
          label: 'Carbs',
          value: _carbsPct,
          color: AppColors.primary,
          icon: Icons.grain_rounded,
          onChanged: (v) {
            setState(() {
              _carbsPct = v;
              _presetIndex = 4;
            });
          },
        ),
        const SizedBox(height: 10),
        _buildMacroSlider(
          label: 'Fat',
          value: _fatPct,
          color: Colors.amber,
          icon: Icons.water_drop_rounded,
          onChanged: (v) {
            setState(() {
              _fatPct = v;
              _presetIndex = 4;
            });
          },
        ),
        const SizedBox(height: 6),
        _buildTotalPctWarning(),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _calculate,
            icon: const Icon(Icons.calculate_rounded, size: 20),
            label: Text(
              'CALCULATE MACROS',
              style: GoogleFonts.oswald(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalorieInput() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Calories',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_totalCalories.round()} kcal',
                  style: GoogleFonts.oswald(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.border,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.15),
              trackHeight: 4,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: _totalCalories,
              min: 1000,
              max: 5000,
              divisions: 80,
              onChanged: (v) =>
                  setState(() => _totalCalories = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChips() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Diet Preset',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_presets.length, (i) {
              final isSelected = _presetIndex == i;
              return InkWell(
                onTap: () => _applyPreset(i),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                  ),
                  child: Text(
                    _presets[i].$1,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color:
                          isSelected ? AppColors.primary : Colors.white70,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroSlider({
    required String label,
    required double value,
    required Color color,
    required IconData icon,
    required ValueChanged<double> onChanged,
  }) {
    return _sectionCard(
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${value.round()}%',
                  style: GoogleFonts.oswald(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              inactiveTrackColor: AppColors.border,
              thumbColor: color,
              overlayColor: color.withValues(alpha: 0.15),
              trackHeight: 4,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: value,
              min: 0,
              max: 100,
              divisions: 100,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalPctWarning() {
    final total = _proteinPct + _carbsPct + _fatPct;
    final isValid = (total - 100).abs() < 0.5;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isValid
            ? Colors.green.withValues(alpha: 0.1)
            : AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isValid
              ? Colors.green.withValues(alpha: 0.3)
              : AppColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isValid
                ? Icons.check_circle_rounded
                : Icons.warning_amber_rounded,
            size: 16,
            color: isValid ? Colors.greenAccent : AppColors.warning,
          ),
          const SizedBox(width: 8),
          Text(
            isValid
                ? 'Macro split totals 100% ✓'
                : 'Total is ${total.round()}% — should be 100%',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isValid ? Colors.greenAccent : AppColors.warning,
            ),
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
        _buildDonutChart(res),
        const SizedBox(height: 18),
        _buildMacroDetailCards(res),
      ],
    );
  }

  Widget _buildDonutChart(MacroResult res) {
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
            'DAILY MACRO SPLIT',
            style: GoogleFonts.oswald(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: _donutAnim,
            builder: (context, _) {
              return SizedBox(
                width: 200,
                height: 200,
                child: CustomPaint(
                  painter: _MacroDonutPainter(
                    proteinPct: res.proteinPct,
                    carbsPct: res.carbsPct,
                    fatPct: res.fatPct,
                    progress: _donutAnim.value,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${res.totalCalories}',
                          style: GoogleFonts.oswald(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'kcal',
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
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendItem('Protein', Colors.redAccent),
              const SizedBox(width: 20),
              _legendItem('Carbs', AppColors.primary),
              const SizedBox(width: 20),
              _legendItem('Fat', Colors.amber),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style:
              GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildMacroDetailCards(MacroResult res) {
    return Row(
      children: [
        Expanded(
          child: _macroDetailCard(
            label: 'PROTEIN',
            grams: '${res.proteinGrams}g',
            calories: '${res.proteinCalories} kcal',
            pct: '${res.proteinPct.round()}%',
            color: Colors.redAccent,
            icon: Icons.egg_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _macroDetailCard(
            label: 'CARBS',
            grams: '${res.carbsGrams}g',
            calories: '${res.carbsCalories} kcal',
            pct: '${res.carbsPct.round()}%',
            color: AppColors.primary,
            icon: Icons.grain_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _macroDetailCard(
            label: 'FAT',
            grams: '${res.fatGrams}g',
            calories: '${res.fatCalories} kcal',
            pct: '${res.fatPct.round()}%',
            color: Colors.amber,
            icon: Icons.water_drop_rounded,
          ),
        ),
      ],
    );
  }

  Widget _macroDetailCard({
    required String label,
    required String grams,
    required String calories,
    required String pct,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            grams,
            style: GoogleFonts.oswald(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
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
            calories,
            style:
                GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
          ),
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              pct,
              style: GoogleFonts.oswald(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
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
}

class _MacroDonutPainter extends CustomPainter {
  final double proteinPct;
  final double carbsPct;
  final double fatPct;
  final double progress;

  _MacroDonutPainter({
    required this.proteinPct,
    required this.carbsPct,
    required this.fatPct,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeWidth = 20.0;
    const startAngle = -math.pi / 2;
    final total = proteinPct + carbsPct + fatPct;
    if (total <= 0) return;

    // Background ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    final segments = [
      (proteinPct / total, Colors.redAccent),
      (carbsPct / total, const Color(0xFFCCFF00)),
      (fatPct / total, Colors.amber),
    ];

    double currentAngle = startAngle;
    for (final seg in segments) {
      final sweepAngle = 2 * math.pi * seg.$1 * progress;
      final paint = Paint()
        ..color = seg.$2
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        currentAngle,
        sweepAngle,
        false,
        paint,
      );
      currentAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _MacroDonutPainter old) =>
      old.progress != progress ||
      old.proteinPct != proteinPct ||
      old.carbsPct != carbsPct ||
      old.fatPct != fatPct;
}
