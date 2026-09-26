import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gym_connect_app/core/theme/app_colors.dart';
import 'package:gym_connect_app/features/auth/domain/models/user_profile.dart';
import 'package:gym_connect_app/features/auth/domain/models/user_role.dart';
import 'package:gym_connect_app/features/auth/presentation/providers/auth_notifier.dart';
import 'package:gym_connect_app/features/workout/presentation/providers/fitness_profile_provider.dart';
import 'package:gym_connect_app/features/workout/presentation/providers/workout_notifier.dart';

class DesktopMemberPortalView extends ConsumerWidget {
  final UserProfile profile;

  const DesktopMemberPortalView({super.key, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutState = ref.watch(workoutNotifierProvider);
    final fitnessAsync = ref.watch(fitnessProfileProvider);
    final bodyType = fitnessAsync.asData?.value.bodyType.toUpperCase() ?? 'MESOMORPH';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMobileNoticeBanner(context, ref),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 360, child: _buildLeftAccountColumn(context)),
              const SizedBox(width: 24),
              Expanded(child: _buildRightWorkoutColumn(workoutState, bodyType)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileNoticeBanner(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.phone_iphone_rounded, color: AppColors.primary, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MEMBER MOBILE APP RECOMMENDED', style: GoogleFonts.oswald(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('Live QR gate entry, pedometer step counter, and active workout tracking are designed for smartphones.', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => ref.read(authNotifierProvider.notifier).switchActiveRole(UserRole.staff),
            icon: const Icon(Icons.point_of_sale_rounded, size: 14),
            label: const Text('Open Staff POS Desk'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              textStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => ref.read(authNotifierProvider.notifier).switchActiveRole(UserRole.owner),
            icon: const Icon(Icons.dashboard_rounded, size: 14),
            label: const Text('Gym Owner Portal'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: AppColors.border),
              textStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftAccountColumn(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
          child: Column(
            children: [
              CircleAvatar(radius: 36, backgroundColor: AppColors.primary.withValues(alpha: 0.2), child: Text(profile.fullName.isNotEmpty ? profile.fullName[0].toUpperCase() : 'M', style: GoogleFonts.oswald(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary))),
              const SizedBox(height: 12),
              Text(profile.fullName, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(profile.email, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)), child: Text('VIP ALL-ACCESS MEMBER', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary))),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MEMBERSHIP DETAILS', style: GoogleFonts.oswald(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 10),
              _buildDetailRow('Facility', profile.tenantName),
              _buildDetailRow('Status', 'Active • Good Standing'),
              _buildDetailRow('Next Renewal', '1st of Next Month'),
              _buildDetailRow('Monthly Fee', 'PKR 5,000'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
          Text(value, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildRightWorkoutColumn(WorkoutSessionState workoutState, String bodyType) {
    final routine = workoutState.routineDay;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('MY WORKOUT PROTOCOL SCHEDULE', style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)), child: Text('BODY TYPE: $bodyType', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary))),
            ],
          ),
          const SizedBox(height: 6),
          Text(routine?.title ?? 'Day 1 Training Split', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
          const Divider(color: AppColors.border, height: 24),
          if (routine != null && routine.exercises.isNotEmpty)
            ...routine.exercises.map((ex) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded, color: AppColors.primary, size: 16),
                  const SizedBox(width: 10),
                  Expanded(child: Text(ex.exercise.name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white))),
                  Text('${ex.targetSets} sets • ${ex.targetRepsRange} reps • ${ex.restSeconds}s rest', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ))
          else
            Text('Scheduled Rest & Recovery Day', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}
