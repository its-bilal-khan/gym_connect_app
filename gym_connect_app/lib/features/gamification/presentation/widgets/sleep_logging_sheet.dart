import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../data/sleep_tracker_service.dart';
import '../providers/sleep_tracker_provider.dart';

class SleepLoggingSheet extends ConsumerStatefulWidget {
  final String? tenantId;
  const SleepLoggingSheet({super.key, this.tenantId});

  static Future<void> show(BuildContext context, {String? tenantId}) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SleepLoggingSheet(tenantId: tenantId),
    );
  }

  @override
  ConsumerState<SleepLoggingSheet> createState() => _SleepLoggingSheetState();
}

class _SleepLoggingSheetState extends ConsumerState<SleepLoggingSheet> {
  double _manualHours = 7.5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final sleepState = ref.watch(sleepTrackerProvider);
    final estimatedPoints = SleepDataResult.calculatePoints(_manualHours, SleepSource.manual);

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('LOG SLEEP RECOVERY', style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const Spacer(),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: sleepState.isSyncing
                ? null
                : () async {
                    final navigator = Navigator.of(context);
                    await ref.read(sleepTrackerProvider.notifier).syncSensorSleep(tenantId: widget.tenantId);
                    if (mounted) navigator.pop();
                  },
            icon: sleepState.isSyncing
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : const Icon(Icons.sync_rounded, color: Colors.black),
            label: Text(
              sleepState.isSyncing ? 'SYNCING HEALTH SENSORS...' : 'AUTO-SYNC FROM HEALTHKIT / CONNECT',
              style: GoogleFonts.oswald(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(child: Divider(color: AppColors.border)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text('OR MANUAL ENTRY', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
              ),
              const Expanded(child: Divider(color: AppColors.border)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Sleep Duration:', style: GoogleFonts.inter(fontSize: 13, color: Colors.white)),
              Text('${_manualHours.toStringAsFixed(1)} Hours (+ $estimatedPoints pts)', style: GoogleFonts.oswald(fontSize: 15, fontWeight: FontWeight.bold, color: accent)),
            ],
          ),
          Slider(
            value: _manualHours,
            min: 0.0,
            max: 14.0,
            divisions: 28,
            activeColor: accent,
            inactiveColor: Colors.white12,
            onChanged: (val) => setState(() => _manualHours = val),
          ),
          Text(
            'Anti-Cheat Rule: Verified sensor sleep awards up to 10 points. Manual self-reports are capped at 3 points.',
            style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              await ref.read(sleepTrackerProvider.notifier).logManualSleep(_manualHours, tenantId: widget.tenantId);
              if (mounted) navigator.pop();
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: accent),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('SAVE MANUAL SLEEP', style: GoogleFonts.oswald(fontSize: 13, fontWeight: FontWeight.bold, color: accent)),
          ),
        ],
      ),
    );
  }
}
