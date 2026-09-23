import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import 'providers/step_tracker_notifier.dart';

class StepTrackerFullScreen extends ConsumerStatefulWidget {
  const StepTrackerFullScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const StepTrackerFullScreen()),
    );
  }

  @override
  ConsumerState<StepTrackerFullScreen> createState() => _StepTrackerFullScreenState();
}

class _StepTrackerFullScreenState extends ConsumerState<StepTrackerFullScreen> {
  int _targetGoal = 10000;

  @override
  Widget build(BuildContext context) {
    final stepData = ref.watch(stepTrackerProvider);
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final progress = (stepData.steps / _targetGoal).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('STEP COUNTER & CADENCE', style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildCircularGauge(stepData.steps, progress, accent),
            const SizedBox(height: 20),
            _buildMetricsGrid(stepData),
            const SizedBox(height: 20),
            _buildHourlyChart(stepData.steps, accent),
            const SizedBox(height: 18),
            _buildSensorControl(stepData, accent),
            const SizedBox(height: 16),
            _buildGoalSelector(accent),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularGauge(int steps, double progress, Color accent) {
    return Container(
      width: 210,
      height: 210,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.surface, border: Border.all(color: AppColors.border)),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 180,
            height: 180,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 14,
              backgroundColor: AppColors.background,
              color: AppColors.primaryAccent,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.directions_walk_rounded, color: AppColors.primaryAccent, size: 26),
              const SizedBox(height: 4),
              Text('$steps', style: GoogleFonts.oswald(fontSize: 34, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              Text('GOAL: $_targetGoal', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
              Text('${(progress * 100).toInt()}% COMPLETED', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(StepTrackingData s) {
    return Row(
      children: [
        _metricTile('DISTANCE', '${s.distanceKm} km', Icons.straighten_rounded),
        const SizedBox(width: 10),
        _metricTile('CALORIES', '${s.caloriesBurned} kcal', Icons.local_fire_department_rounded),
        const SizedBox(width: 10),
        _metricTile('ACTIVE TIME', '${(s.steps / 100).toInt()} mins', Icons.timer_rounded),
      ],
    );
  }

  Widget _metricTile(String label, String val, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppColors.primaryAccent),
            const SizedBox(height: 6),
            Text(val, style: GoogleFonts.oswald(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            Text(label, style: GoogleFonts.inter(fontSize: 9, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildHourlyChart(int totalSteps, Color accent) {
    final morning = (totalSteps * 0.35).toInt();
    final afternoon = (totalSteps * 0.45).toInt();
    final evening = (totalSteps * 0.20).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TODAY\'S ACTIVITY DISTRIBUTION', style: GoogleFonts.oswald(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          _barRow('Morning (06:00 - 12:00)', morning, totalSteps > 0 ? morning / totalSteps : 0.0, accent),
          const SizedBox(height: 8),
          _barRow('Afternoon (12:00 - 17:00)', afternoon, totalSteps > 0 ? afternoon / totalSteps : 0.0, accent),
          const SizedBox(height: 8),
          _barRow('Evening (17:00 - 22:00)', evening, totalSteps > 0 ? evening / totalSteps : 0.0, accent),
        ],
      ),
    );
  }

  Widget _barRow(String label, int count, double frac, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
            Text('$count steps', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(value: frac, backgroundColor: AppColors.background, color: accent, minHeight: 6, borderRadius: BorderRadius.circular(3)),
      ],
    );
  }

  Widget _buildSensorControl(StepTrackingData s, Color accent) {
    final isPaused = s.isPaused;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(isPaused ? Icons.pause_circle_filled_rounded : Icons.sensors_rounded, color: isPaused ? Colors.amber : Colors.greenAccent, size: 22),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isPaused ? 'TRACKING PAUSED' : 'HARDWARE LIVE SYNC', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  Text(isPaused ? 'Pedometer recording paused' : 'Active accelerometer motion sensor', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: isPaused ? accent : Colors.amber, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              HapticFeedback.lightImpact();
              ref.read(stepTrackerProvider.notifier).togglePauseResume();
            },
            child: Text(isPaused ? 'RESUME' : 'PAUSE', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalSelector(Color accent) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [6000, 8000, 10000, 12000].map((goal) => ChoiceChip(
        label: Text('${goal ~/ 1000}k', style: GoogleFonts.inter(fontSize: 11, color: _targetGoal == goal ? Colors.black : AppColors.textPrimary)),
        selected: _targetGoal == goal,
        selectedColor: accent,
        backgroundColor: AppColors.surface,
        onSelected: (val) => setState(() => _targetGoal = goal),
      )).toList(),
    );
  }
}
