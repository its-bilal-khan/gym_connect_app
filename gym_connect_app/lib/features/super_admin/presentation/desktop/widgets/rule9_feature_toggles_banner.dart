import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/super_admin_feature_flags_sheet.dart';

/// Banner widget representing Strict Rule 9 Feature Toggling & System Config in Super Admin Workstation.
class Rule9FeatureTogglesBanner extends StatelessWidget {
  const Rule9FeatureTogglesBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.amberAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.tune_rounded, color: Colors.amberAccent, size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FEATURE TOGGLING & SUPREMACY (STRICT RULE 9)',
                  style: GoogleFonts.oswald(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: Colors.amberAccent,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Centralized management of global module killswitches (AI Workouts, Gamification, Diet, Tools) and allow_tenant_override policy.',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: () => SuperAdminFeatureFlagsSheet.show(context),
            icon: const Icon(Icons.settings_suggest_rounded, size: 18),
            label: Text(
              'CONFIGURE TOGGLES',
              style: GoogleFonts.oswald(fontWeight: FontWeight.bold, letterSpacing: 0.8),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amberAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}
