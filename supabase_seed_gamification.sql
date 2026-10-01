-- ==============================================================================
-- GYMCONNECT ENTERPRISE SAAS: GAMIFICATION & ANTI-CHEAT SEED SCRIPT
-- File: supabase_seed_gamification.sql
-- Description: Realistic production-grade test data for:
--              1. Member Fitness Profiles (Track A Dynamic vs Track B Low-Impact 90kg+)
--              2. Member Gamification Leaderboards (Points, Streaks, Multipliers)
--              3. Daily 80% Composite Logs & Native Sensor Syncs
--              4. Past Month Leaderboard Podium Archives with Automated Rewards
--              5. Member Workout Highlight Reels for Explore Shorts Feed
--              6. Owner Flagged Fraud Moderation Queue
-- ==============================================================================

-- 1. SEED FITNESS PROFILES WITH TRACK A & TRACK B ASSIGNMENTS
INSERT INTO user_fitness_profiles (
    user_id, height_cm, current_weight_kg, target_weight_kg,
    body_type, fitness_goal, experience_level, assigned_workout_track,
    current_step_target, base_step_target, consecutive_target_misses,
    medical_injuries, profile_completed
) VALUES
    -- Usman Ali: Veteran Mesomorph on Track A (Athletic Hypertrophy)
    ('30000000-0000-0000-0000-000000000001', 180.00, 78.50, 82.00, 'mesomorph', 'muscle_gain', 'advanced', 'track_a', 10000, 10000, 0, '{}', true),
    -- Zaid Ahmed: Ectomorph on Track A (Lean Bulking)
    ('30000000-0000-0000-0000-000000000002', 175.00, 68.00, 74.00, 'ectomorph', 'muscle_gain', 'intermediate', 'track_a', 8000, 8000, 0, '{}', true),
    -- Fahad Mustafa: Mesomorph on Track A with Knee Caution
    ('30000000-0000-0000-0000-000000000003', 178.00, 82.00, 80.00, 'mesomorph', 'general_fitness', 'intermediate', 'track_a', 10000, 10000, 0, '{"knee_caution"}', true),
    -- Daniyal Khan: Overweight 95kg Beginner on Track B (Low-Impact Beginner Progression)
    ('30000000-0000-0000-0000-000000000004', 172.00, 95.50, 78.00, 'endomorph', 'fat_loss', 'beginner', 'track_b', 6000, 8000, 1, '{"lower_back_pain"}', true),
    -- Arham Shah: Regular Member on Track A
    ('30000000-0000-0000-0000-000000000005', 182.00, 85.00, 80.00, 'endomorph', 'fat_loss', 'intermediate', 'track_a', 10000, 10000, 0, '{}', true)
ON CONFLICT (user_id) DO UPDATE SET
    assigned_workout_track = EXCLUDED.assigned_workout_track,
    current_step_target = EXCLUDED.current_step_target,
    medical_injuries = EXCLUDED.medical_injuries,
    profile_completed = true;

-- 2. SEED MEMBER GAMIFICATION (POINTS, STREAKS & VETERAN MULTIPLIERS)
INSERT INTO member_gamification (
    user_id, tenant_id, current_streak_days, longest_streak_days,
    total_points, monthly_points, streak_multiplier, monthly_workouts_completed,
    is_elite_qualified, daily_steps, daily_distance_km, daily_calories_burned, last_activity_date
) VALUES
    -- #1 Usman Ali: 150-Day Veteran (1.50x Multiplier, Qualified for Top 3)
    ('30000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 150, 150, 12850, 1850, 1.50, 22, true, 11450, 8.20, 540, CURRENT_DATE),
    -- #2 Zaid Ahmed: 35-Day Consistent (1.25x Multiplier, Qualified)
    ('30000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 35, 42, 6420, 1420, 1.25, 19, true, 8920, 6.40, 410, CURRENT_DATE),
    -- #3 Fahad Mustafa: 21-Day Streak (1.10x Multiplier, Qualified)
    ('30000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', 21, 28, 4890, 1180, 1.10, 18, true, 10240, 7.50, 490, CURRENT_DATE),
    -- #4 Daniyal Khan: New Beginner on Track B (7-Day Streak, In-Progress Qualification)
    ('30000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000001', 7, 7, 1240, 860, 1.00, 11, false, 6200, 4.30, 310, CURRENT_DATE),
    -- #5 Arham Shah: Regular Member (14-Day Streak)
    ('30000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000001', 14, 14, 2150, 790, 1.10, 10, false, 7800, 5.60, 380, CURRENT_DATE)
ON CONFLICT (user_id) DO UPDATE SET
    current_streak_days = EXCLUDED.current_streak_days,
    longest_streak_days = EXCLUDED.longest_streak_days,
    monthly_points = EXCLUDED.monthly_points,
    total_points = EXCLUDED.total_points,
    streak_multiplier = EXCLUDED.streak_multiplier,
    monthly_workouts_completed = EXCLUDED.monthly_workouts_completed,
    is_elite_qualified = EXCLUDED.is_elite_qualified,
    last_activity_date = CURRENT_DATE;

-- 3. SEED TODAY'S COMPOSITE DAILY GAMIFICATION LOGS (80% THRESHOLD EXAMPLES)
INSERT INTO daily_gamification_logs (
    tenant_id, user_id, log_date, device_id_used,
    workout_assigned_sets, workout_completed_sets, workout_completion_pct,
    step_target, step_actual, step_completion_pct, step_source,
    diet_logged_type, diet_proof_url,
    sleep_logged_hours, sleep_source, sleep_asleep_minutes,
    gate_checkin_verified, composite_completion_pct,
    points_awarded, streak_saved, notes
) VALUES
    -- Usman: 100% Sets + 11.4k Steps + Photo Proof + 7.5h HealthKit Sleep = 96.5% Composite (Streak Saved)
    ('00000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000001', CURRENT_DATE, 'DEV-IOS-IPHONE15PRO',
     16, 16, 100.00,
     10000, 11450, 100.00, 'healthkit',
     'photo_proof', 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500',
     7.5, 'healthkit', 450,
     true, 96.50,
     142, true, 'Elite Daily Protocol Executed'),

    -- Zaid: 14/16 Sets + 8.9k Steps + Self Check Diet + 6.8h Sleep = 85.0% Composite (Streak Saved)
    ('00000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000002', CURRENT_DATE, 'DEV-ANDROID-PIXEL8',
     16, 14, 87.50,
     8000, 8920, 100.00, 'health_connect',
     'self_check', NULL,
     6.8, 'health_connect', 408,
     true, 85.00,
     98, true, 'Solid Workout & Cardio Session'),

    -- Daniyal (Track B Beginner): 10/10 Low-Impact Sets + 6.2k Steps + Photo Proof = 88.0% Composite (Streak Saved)
    ('00000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000004', CURRENT_DATE, 'DEV-SAMSUNG-S23',
     10, 10, 100.00,
     6000, 6200, 100.00, 'health_connect',
     'photo_proof', 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=500',
     7.0, 'health_connect', 420,
     true, 88.00,
     85, true, 'Track B Beginner Day Complete')
ON CONFLICT (user_id, log_date) DO UPDATE SET
    composite_completion_pct = EXCLUDED.composite_completion_pct,
    points_awarded = EXCLUDED.points_awarded,
    streak_saved = EXCLUDED.streak_saved;

-- 4. SEED MONTHLY LEADERBOARD ARCHIVES (PREVIOUS MONTH TOP 3 PODIUM)
INSERT INTO monthly_leaderboard_archives (
    tenant_id, month_year, podium_rank, user_id,
    points_scored, streak_at_finish, reward_title, reward_type, reward_value,
    is_fulfilled, fulfilled_at
) VALUES
    -- August Podium Rank 1: Usman Ali (Won 1-Month Free Access, Auto-Fulfilled)
    ('00000000-0000-0000-0000-000000000001', '2026-08', 1, '30000000-0000-0000-0000-000000000001',
     2840, 120, '1-Month Free All-Access Pass', 'membership_extension', 30,
     true, date_trunc('month', NOW()) - interval '1 day'),

    -- August Podium Rank 2: Zaid Ahmed (Won 50% Off Renewal, Auto-Fulfilled)
    ('00000000-0000-0000-0000-000000000001', '2026-08', 2, '30000000-0000-0000-0000-000000000002',
     2310, 15, '50% Off Next Month Renewal', 'discount_voucher', 50,
     true, date_trunc('month', NOW()) - interval '1 day'),

    -- August Podium Rank 3: Fahad Mustafa (Won Titan Shaker & 2kg Tub, Auto-Fulfilled)
    ('00000000-0000-0000-0000-000000000001', '2026-08', 3, '30000000-0000-0000-0000-000000000003',
     1980, 8, 'Free Titan Whey Protein 2kg + Shaker', 'custom_reward', 0,
     true, date_trunc('month', NOW()) - interval '1 day')
ON CONFLICT (tenant_id, month_year, podium_rank) DO NOTHING;

-- 5. SEED MEMBER WORKOUT HIGHLIGHT REELS (EXPLORE SHORTS FEED)
INSERT INTO member_workout_reels (
    tenant_id, user_id, video_url, thumbnail_url,
    duration_seconds, routine_title, streak_days_at_record, is_public_explore, likes_count
) VALUES
    ('00000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000001',
     'https://assets.mixkit.co/videos/preview/mixkit-athlete-working-out-with-heavy-weights-in-a-gym-44141-large.mp4',
     'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=500',
     68, 'Heavy Barbell Hypertrophy - Set Highlights', 148, true, 34),

    ('00000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000002',
     'https://assets.mixkit.co/videos/preview/mixkit-man-doing-pull-ups-in-a-gym-43754-large.mp4',
     'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=500',
     55, 'Calisthenics Back & Biceps Precision', 33, true, 19)
ON CONFLICT DO NOTHING;

-- 6. SEED OWNER FLAGGED FRAUD QUEUE (MODERATION TESTING)
INSERT INTO gamification_flagged_queue (
    tenant_id, user_id, proof_type, proof_url, points_awarded, status, flagged_reason
) VALUES
    ('00000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000005',
     'diet_photo', 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500',
     15, 'pending_review', 'Routine Diet Meal Verification')
ON CONFLICT DO NOTHING;
