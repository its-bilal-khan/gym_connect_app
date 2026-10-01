import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gym_connect_app/core/theme/app_colors.dart';
import 'package:gym_connect_app/features/gamification/domain/models/vision_ai_config.dart';

/// Modular sliders group for Vision AI Live Trainer thresholds.
class VisionAiSliderGroup extends StatelessWidget {
  final VisionAiConfig config;
  final ValueChanged<double> onSquatDepthChanged;
  final ValueChanged<double> onPushupDepthChanged;
  final ValueChanged<int> onBadPostureDelayChanged;
  final ValueChanged<double> onTtsCooldownChanged;
  final ValueChanged<int> onMicroClipDurationChanged;

  const VisionAiSliderGroup({
    super.key,
    required this.config,
    required this.onSquatDepthChanged,
    required this.onPushupDepthChanged,
    required this.onBadPostureDelayChanged,
    required this.onTtsCooldownChanged,
    required this.onMicroClipDurationChanged,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Column(
      children: [
        _buildSliderCard(
          context: context,
          accent: accent,
          title: 'SQUAT DEPTH STRICTNESS (PARALLEL ANGLE)',
          valueLabel: '${config.squatDepthAngle.toStringAsFixed(0)}°',
          description: 'Max knee angle required to register deep squat (lower is stricter).',
          value: config.squatDepthAngle,
          min: 70.0,
          max: 110.0,
          divisions: 40,
          onChanged: onSquatDepthChanged,
        ),
        const SizedBox(height: 12),
        _buildSliderCard(
          context: context,
          accent: accent,
          title: 'PUSHUP DEPTH THRESHOLD',
          valueLabel: '${config.pushupDepthAngle.toStringAsFixed(0)}°',
          description: 'Elbow flexion required to validate chest-to-floor repetition.',
          value: config.pushupDepthAngle,
          min: 60.0,
          max: 100.0,
          divisions: 40,
          onChanged: onPushupDepthChanged,
        ),
        const SizedBox(height: 12),
        _buildSliderCard(
          context: context,
          accent: accent,
          title: 'BAD POSTURE ALERT DELAY',
          valueLabel: '${config.badPostureTriggerMs} ms',
          description: 'Time user must remain in half-rep state before audio coaching fires.',
          value: config.badPostureTriggerMs.toDouble(),
          min: 400.0,
          max: 3000.0,
          divisions: 26,
          onChanged: (v) => onBadPostureDelayChanged(v.toInt()),
        ),
        const SizedBox(height: 12),
        _buildSliderCard(
          context: context,
          accent: accent,
          title: 'VOICE COACH AUDIO COOLDOWN',
          valueLabel: '${config.ttsCooldownSeconds.toStringAsFixed(1)} s',
          description: 'Minimum quiet time between repeated voice commands to prevent audio spam.',
          value: config.ttsCooldownSeconds,
          min: 1.0,
          max: 8.0,
          divisions: 35,
          onChanged: onTtsCooldownChanged,
        ),
        const SizedBox(height: 12),
        _buildSliderCard(
          context: context,
          accent: accent,
          title: 'SET 1 MICRO-CLIP DURATION',
          valueLabel: '${config.microClipDurationSec} s',
          description: 'Length of automated micro-clip recorded for explore feed & social reels.',
          value: config.microClipDurationSec.toDouble(),
          min: 3.0,
          max: 20.0,
          divisions: 17,
          onChanged: (v) => onMicroClipDurationChanged(v.toInt()),
        ),
      ],
    );
  }

  Widget _buildSliderCard({
    required BuildContext context,
    required Color accent,
    required String title,
    required String valueLabel,
    required String description,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.oswald(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accent.withValues(alpha: 0.4)),
                ),
                child: Text(
                  valueLabel,
                  style: GoogleFonts.oswald(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(description, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            activeColor: accent,
            inactiveColor: Colors.white12,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
