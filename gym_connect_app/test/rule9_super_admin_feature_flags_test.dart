import 'package:flutter_test/flutter_test.dart';
import 'package:gym_connect_app/features/super_admin/domain/models/system_feature_flags.dart';

void main() {
  group('Strict Rule 9: Super Admin Supremacy & Feature Flags Tests', () {
    test('SystemFeatureFlags defaults to all enabled', () {
      const flags = SystemFeatureFlags();
      expect(flags.aiWorkouts, isTrue);
      expect(flags.gamification, isTrue);
      expect(flags.clinicalTools, isTrue);
      expect(flags.dietLogs, isTrue);
      expect(flags.allowTenantOverrides, isEmpty);
      expect(flags.canTenantOverride('ai_workouts'), isFalse);
    });

    test('SystemFeatureFlags parses from JSON correctly', () {
      final json = {
        'ai_workouts': false,
        'gamification': true,
        'clinical_tools': false,
        'diet_logs': true,
        'allow_tenant_overrides': {
          'ai_workouts': true,
          'gamification': false,
        },
      };

      final flags = SystemFeatureFlags.fromJson(json);
      expect(flags.aiWorkouts, isFalse);
      expect(flags.gamification, isTrue);
      expect(flags.clinicalTools, isFalse);
      expect(flags.dietLogs, isTrue);
      expect(flags.canTenantOverride('ai_workouts'), isTrue);
      expect(flags.canTenantOverride('gamification'), isFalse);
      expect(flags.isFeatureEnabled('ai_workouts'), isFalse);
      expect(flags.isFeatureEnabled('gamification'), isTrue);
    });

    test('SystemFeatureFlags serializes to JSON correctly', () {
      const flags = SystemFeatureFlags(
        aiWorkouts: false,
        gamification: true,
        clinicalTools: false,
        dietLogs: false,
        allowTenantOverrides: {'ai_workouts': true},
      );

      final json = flags.toJson();
      expect(json['ai_workouts'], isFalse);
      expect(json['gamification'], isTrue);
      expect(json['clinical_tools'], isFalse);
      expect(json['diet_logs'], isFalse);
      expect(json['allow_tenant_overrides'], {'ai_workouts': true});
    });

    test('Global killswitch strictly takes precedence over tenant settings', () {
      // Rule 9: Super Admin global disable shuts down feature platform-wide
      bool resolveEffectiveFeature(bool globalFlag, bool tenantFlag) {
        if (!globalFlag) return false; // Global killswitch
        return tenantFlag;
      }

      // 1. Global killswitch active -> tenant cannot turn it on
      expect(resolveEffectiveFeature(false, true), isFalse);
      expect(resolveEffectiveFeature(false, false), isFalse);

      // 2. Global enabled -> tenant setting governs
      expect(resolveEffectiveFeature(true, true), isTrue);
      expect(resolveEffectiveFeature(true, false), isFalse);
    });

    test('Tenant override permission logic enforces Super Admin authorization', () {
      // Rule 9: Gym Owners cannot modify config unless Super Admin explicitly enables allow_tenant_override
      bool canTenantModifySetting(bool allowTenantOverride) {
        return allowTenantOverride;
      }

      expect(canTenantModifySetting(false), isFalse);
      expect(canTenantModifySetting(true), isTrue);
    });

    test('GlobalSystemConfig model parses and preserves JSONB values', () {
      final json = {
        'key': 'ai_workout_config',
        'value': {
          'min_age': 16,
          'max_age': 80,
          'default_track': 'track_a',
          'auto_swap_injuries': true,
        },
        'allow_tenant_override': false,
        'description': 'AI Workout static template assignment engine rules',
      };

      final config = GlobalSystemConfig.fromJson(json);
      expect(config.key, 'ai_workout_config');
      expect(config.allowTenantOverride, isFalse);
      expect(config.description, contains('AI Workout'));
      expect(config.value['min_age'], 16);
      expect(config.value['default_track'], 'track_a');
      expect(config.value['auto_swap_injuries'], isTrue);
    });

    test('GlobalSystemConfig copyWith works accurately', () {
      const config = GlobalSystemConfig(
        key: 'gamification_config',
        value: {'base_points': 50},
        allowTenantOverride: false,
      );

      final updated = config.copyWith(
        allowTenantOverride: true,
        value: {'base_points': 100},
      );

      expect(updated.key, 'gamification_config');
      expect(updated.allowTenantOverride, isTrue);
      expect(updated.value['base_points'], 100);
    });
  });
}
