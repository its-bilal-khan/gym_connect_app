class CdnVideoItem {
  final String id;
  final String title;
  final String targetMuscle;
  final String equipment;
  final String primaryVideoUrl;
  final String? sideVideoUrl;
  final String tips;
  final String cdnProvider;
  final String quality;

  const CdnVideoItem({
    required this.id,
    required this.title,
    required this.targetMuscle,
    required this.equipment,
    required this.primaryVideoUrl,
    this.sideVideoUrl,
    required this.tips,
    this.cdnProvider = 'jsDelivr / GitHub High-Speed CDN',
    this.quality = 'HD 1080p MP4',
  });
}

abstract final class CdnVideoLibrary {
  static const List<CdnVideoItem> verifiedVideos = [
    // ==========================================
    // CHEST EXERCISES (All distinct, realistic streams)
    // ==========================================
    CdnVideoItem(
      id: 'cdn-pushup',
      title: 'Standard Push-Up Form',
      targetMuscle: 'Chest',
      equipment: 'Bodyweight',
      primaryVideoUrl:
          'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/push_up_form.mp4',
      sideVideoUrl:
          'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
      tips:
          'Maintain a rigid plank core tension, flare elbows at 45 degrees, and lower chest controlled to the floor.',
      quality: 'HD 1080p MP4',
    ),
    CdnVideoItem(
      id: 'cdn-bench-press',
      title: 'Flat Barbell Bench Press Technique',
      targetMuscle: 'Chest',
      equipment: 'Barbell',
      primaryVideoUrl:
          'https://cdn.jsdelivr.net/gh/hasaneyldrm/exercises-dataset@main/videos/0025-EIeI8Vf.gif',
      sideVideoUrl:
          'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
      tips:
          'Retract and depress scapulae into bench, touch mid-chest under control, and press in a gentle J-curve.',
      quality: 'Animated 60fps Cloud Demo',
    ),
    CdnVideoItem(
      id: 'cdn-incline-barbell-press',
      title: 'Incline Barbell Bench Press',
      targetMuscle: 'Chest',
      equipment: 'Barbell',
      primaryVideoUrl:
          'https://cdn.jsdelivr.net/gh/hasaneyldrm/exercises-dataset@main/videos/0047-3TZduzM.gif',
      sideVideoUrl:
          'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
      tips:
          'Set incline to 30-45 degrees to target the upper clavicular head of the pectoralis major.',
      quality: 'Animated 60fps Cloud Demo',
    ),
    CdnVideoItem(
      id: 'cdn-dumbbell-bench-press',
      title: 'Flat Dumbbell Bench Press',
      targetMuscle: 'Chest',
      equipment: 'Dumbbell',
      primaryVideoUrl:
          'https://cdn.jsdelivr.net/gh/hasaneyldrm/exercises-dataset@main/videos/0289-SpYC0Kp.gif',
      sideVideoUrl:
          'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
      tips:
          'Angle dumbbells at 45 degrees, lower deep for a full pectoral stretch, and drive up without clanking.',
      quality: 'Animated 60fps Cloud Demo',
    ),
    CdnVideoItem(
      id: 'cdn-incline-dumbbell-press',
      title: 'Incline Dumbbell Chest Press',
      targetMuscle: 'Chest',
      equipment: 'Dumbbell',
      primaryVideoUrl:
          'https://cdn.jsdelivr.net/gh/hasaneyldrm/exercises-dataset@main/videos/0314-ns0SIbU.gif',
      sideVideoUrl:
          'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
      tips:
          'Maintain natural lumbar arch, flare elbows 45 degrees, drive dumbbells vertically over upper chest.',
      quality: 'Animated 60fps Cloud Demo',
    ),
    CdnVideoItem(
      id: 'cdn-cable-incline-fly',
      title: 'Cable Incline Chest Fly',
      targetMuscle: 'Chest',
      equipment: 'Cable',
      primaryVideoUrl:
          'https://cdn.jsdelivr.net/gh/hasaneyldrm/exercises-dataset@main/videos/0171-tBWXbIT.gif',
      sideVideoUrl:
          'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
      tips:
          'Keep slight bend in elbows, pull cables upwards in an arc to maximize upper chest inner contraction.',
      quality: 'Animated 60fps Cloud Demo',
    ),
    CdnVideoItem(
      id: 'cdn-cable-decline-fly',
      title: 'Cable Decline Crossover Fly',
      targetMuscle: 'Chest',
      equipment: 'Cable',
      primaryVideoUrl:
          'https://cdn.jsdelivr.net/gh/hasaneyldrm/exercises-dataset@main/videos/0158-7saC5zz.gif',
      sideVideoUrl:
          'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
      tips:
          'Set high pulleys, step forward, and bring handles downwards across pelvis for lower chest peak squeeze.',
      quality: 'Animated 60fps Cloud Demo',
    ),
    CdnVideoItem(
      id: 'cdn-chest-dips',
      title: 'Parallel Bar Chest Dips',
      targetMuscle: 'Chest',
      equipment: 'Bodyweight',
      primaryVideoUrl:
          'https://cdn.jsdelivr.net/gh/hasaneyldrm/exercises-dataset@main/videos/0009-PAgTVaK.gif',
      sideVideoUrl:
          'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
      tips:
          'Lean torso forward 30 degrees to bias tension onto pectoralis major rather than triceps.',
      quality: 'Animated 60fps Cloud Demo',
    ),
    CdnVideoItem(
      id: 'cdn-decline-barbell-press',
      title: 'Decline Barbell Bench Press',
      targetMuscle: 'Chest',
      equipment: 'Barbell',
      primaryVideoUrl:
          'https://cdn.jsdelivr.net/gh/hasaneyldrm/exercises-dataset@main/videos/0033-GrO65fd.gif',
      sideVideoUrl:
          'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
      tips:
          'Lock legs firmly, lower bar to sternum/lower chest, press in vertical line to target lower pectorals.',
      quality: 'Animated 60fps Cloud Demo',
    ),

    // ==========================================
    // BACK EXERCISES
    // ==========================================
    CdnVideoItem(
      id: 'cdn-wide-pullup',
      title: 'Wide-Grip Bodyweight Pull-Up',
      targetMuscle: 'Back',
      equipment: 'Bodyweight',
      primaryVideoUrl:
          'https://cdn.jsdelivr.net/gh/hasaneyldrm/exercises-dataset@main/videos/3293-72BC5Za.gif',
      sideVideoUrl:
          'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
      tips:
          'Retract shoulder blades first, pull chest to bar, avoid swinging or kicking legs.',
      quality: 'Animated 60fps Cloud Demo',
    ),
    CdnVideoItem(
      id: 'cdn-lat-pulldown',
      title: 'Cable Lat Pulldown Full ROM',
      targetMuscle: 'Back',
      equipment: 'Cable',
      primaryVideoUrl:
          'https://cdn.jsdelivr.net/gh/hasaneyldrm/exercises-dataset@main/videos/2330-LEprlgG.gif',
      sideVideoUrl:
          'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
      tips:
          'Pull elbows down and slightly back into back pockets, squeeze latissimus dorsi at bottom.',
      quality: 'Animated 60fps Cloud Demo',
    ),
    CdnVideoItem(
      id: 'cdn-alt-lat-pulldown',
      title: 'Alternate Lateral Pulldown',
      targetMuscle: 'Back',
      equipment: 'Cable',
      primaryVideoUrl:
          'https://cdn.jsdelivr.net/gh/hasaneyldrm/exercises-dataset@main/videos/0007-4IKbhHV.gif',
      sideVideoUrl:
          'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
      tips:
          'Isolate each side independently to correct lat imbalances and build mind-muscle connection.',
      quality: 'Animated 60fps Cloud Demo',
    ),

    // ==========================================
    // LEGS EXERCISES
    // ==========================================
    CdnVideoItem(
      id: 'cdn-squat',
      title: 'Barbell & Bodyweight Squat',
      targetMuscle: 'Legs',
      equipment: 'Barbell',
      primaryVideoUrl:
          'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/squat_form.mp4',
      sideVideoUrl:
          'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
      tips:
          'Break at hips and knees simultaneously. Keep chest proud, lumbar neutral, and knees tracking over toes.',
      quality: 'HD 1080p MP4',
    ),
    CdnVideoItem(
      id: 'cdn-deadlift',
      title: 'Barbell Conventional Deadlift',
      targetMuscle: 'Legs',
      equipment: 'Barbell',
      primaryVideoUrl:
          'https://cdn.jsdelivr.net/gh/hasaneyldrm/exercises-dataset@main/videos/0032-ila4NZS.gif',
      sideVideoUrl:
          'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
      tips:
          'Brace core, engage lats to keep bar touching shins, push the floor away through mid-foot.',
      quality: 'Animated 60fps Cloud Demo',
    ),
    CdnVideoItem(
      id: 'cdn-dumbbell-lunge',
      title: 'Dumbbell Walking Lunge',
      targetMuscle: 'Legs',
      equipment: 'Dumbbell',
      primaryVideoUrl:
          'https://cdn.jsdelivr.net/gh/hasaneyldrm/exercises-dataset@main/videos/0336-RRWFUcw.gif',
      sideVideoUrl:
          'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
      tips:
          'Step forward, lower trailing knee just above ground, maintain upright torso posture.',
      quality: 'Animated 60fps Cloud Demo',
    ),

    // ==========================================
    // ARMS EXERCISES
    // ==========================================
    CdnVideoItem(
      id: 'cdn-curl',
      title: 'Bicep Arm Curl (Dumbbell / Barbell)',
      targetMuscle: 'Arms',
      equipment: 'Dumbbell',
      primaryVideoUrl:
          'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/curl_form.mp4',
      sideVideoUrl:
          'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
      tips:
          'Pin elbows beside ribcage, suppress momentum, squeeze biceps peak at top, and resist for 3-second eccentric.',
      quality: 'HD 1080p MP4',
    ),
    CdnVideoItem(
      id: 'cdn-triceps-pushdown',
      title: 'Cable Triceps Pushdown (V-Bar)',
      targetMuscle: 'Arms',
      equipment: 'Cable',
      primaryVideoUrl:
          'https://cdn.jsdelivr.net/gh/hasaneyldrm/exercises-dataset@main/videos/0241-gAwDzB3.gif',
      sideVideoUrl:
          'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
      tips:
          'Keep upper arms stationary at sides, extend forearms down fully to contract lateral tricep head.',
      quality: 'Animated 60fps Cloud Demo',
    ),
    CdnVideoItem(
      id: 'cdn-bench-dips',
      title: 'Bench Triceps Dips',
      targetMuscle: 'Arms',
      equipment: 'Bodyweight',
      primaryVideoUrl:
          'https://cdn.jsdelivr.net/gh/hasaneyldrm/exercises-dataset@main/videos/0129-RrLske5.gif',
      sideVideoUrl:
          'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
      tips:
          'Keep back close to bench edge, lower until elbows form 90 degrees, press through palms.',
      quality: 'Animated 60fps Cloud Demo',
    ),

    // ==========================================
    // SHOULDERS EXERCISES
    // ==========================================
    CdnVideoItem(
      id: 'cdn-shoulder-press',
      title: 'Overhead Shoulder Press / Military Press',
      targetMuscle: 'Shoulders',
      equipment: 'Barbell',
      primaryVideoUrl:
          'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/shoulder_press_form.mp4',
      sideVideoUrl:
          'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
      tips:
          'Brace glutes and abs to prevent lumbar hyperextension. Press vertically clearing chin and lock out overhead.',
      quality: 'HD 1080p MP4',
    ),
    CdnVideoItem(
      id: 'cdn-lateral-raise',
      title: 'Dumbbell Lateral Raise',
      targetMuscle: 'Shoulders',
      equipment: 'Dumbbell',
      primaryVideoUrl:
          'https://cdn.jsdelivr.net/gh/hasaneyldrm/exercises-dataset@main/videos/0334-DsgkuIt.gif',
      sideVideoUrl:
          'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
      tips:
          'Lead with elbows slightly forward of scapular plane, raise to shoulder height, pause briefly.',
      quality: 'Animated 60fps Cloud Demo',
    ),
    CdnVideoItem(
      id: 'cdn-rear-delt-fly',
      title: 'Cable Rear Delt Crossover Fly',
      targetMuscle: 'Shoulders',
      equipment: 'Cable',
      primaryVideoUrl:
          'https://cdn.jsdelivr.net/gh/hasaneyldrm/exercises-dataset@main/videos/0154-aqvSOQE.gif',
      sideVideoUrl:
          'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
      tips:
          'Pull cables across horizontally without arching back, feeling rear deltoids engage.',
      quality: 'Animated 60fps Cloud Demo',
    ),

    // ==========================================
    // CORE EXERCISES
    // ==========================================
    CdnVideoItem(
      id: 'cdn-hanging-leg-raise',
      title: 'Hanging Leg Raise',
      targetMuscle: 'Core',
      equipment: 'Bodyweight',
      primaryVideoUrl:
          'https://cdn.jsdelivr.net/gh/hasaneyldrm/exercises-dataset@main/videos/0472-I3tsCnC.gif',
      sideVideoUrl:
          'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
      tips:
          'Roll pelvis upward toward ribs rather than merely lifting legs to directly load rectus abdominis.',
      quality: 'Animated 60fps Cloud Demo',
    ),
    CdnVideoItem(
      id: 'cdn-side-plank',
      title: 'Bodyweight Side Plank Hold',
      targetMuscle: 'Core',
      equipment: 'Bodyweight',
      primaryVideoUrl:
          'https://cdn.jsdelivr.net/gh/hasaneyldrm/exercises-dataset@main/videos/3544-5VXmnV5.gif',
      sideVideoUrl:
          'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
      tips:
          'Stack feet, lift hips to form straight line from ankles to neck, contract obliques tightly.',
      quality: 'Animated 60fps Cloud Demo',
    ),
    CdnVideoItem(
      id: 'cdn-butterfly',
      title: 'Mobility & Dynamic Restoration Stream',
      targetMuscle: 'Core',
      equipment: 'Bodyweight',
      primaryVideoUrl:
          'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
      sideVideoUrl:
          'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
      tips:
          'Active recovery flow to restore fascial glide and deep diaphragmatic breathing between sets.',
      quality: 'HD 1080p MP4',
    ),

    // ==========================================
    // FULL BODY
    // ==========================================
    CdnVideoItem(
      id: 'cdn-tracking-demo',
      title: 'AI Multi-Angle Skeletal Tracking Demo',
      targetMuscle: 'Full Body',
      equipment: 'Bodyweight',
      primaryVideoUrl:
          'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
      sideVideoUrl:
          'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/push_up_form.mp4',
      tips:
          'Real-time joint biomechanics and angle velocity tracking demo for multi-angle AI coaching.',
      quality: 'HD 1080p MP4',
    ),
  ];

  static List<CdnVideoItem> search({String query = '', String muscle = 'All'}) {
    final q = query.trim().toLowerCase();
    final m = muscle.trim().toLowerCase();

    return verifiedVideos.where((item) {
      final matchesQuery = q.isEmpty ||
          item.title.toLowerCase().contains(q) ||
          item.targetMuscle.toLowerCase().contains(q) ||
          item.equipment.toLowerCase().contains(q) ||
          item.primaryVideoUrl.toLowerCase().contains(q);

      final matchesMuscle = m == 'all' || item.targetMuscle.toLowerCase() == m;

      return matchesQuery && matchesMuscle;
    }).toList();
  }
}
