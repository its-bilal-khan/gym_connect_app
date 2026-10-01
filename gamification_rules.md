# GymConnect Gamification, AI & Anti-Cheat Engine (Master Document)

## 1. AI Profiling & Dynamic Workout Generation
*   **Target Body Types:** System initially routes users into 3 core goals: Lean/Slim (Weight Loss), V-Shape (Athletics/Calisthenics), or Heavyweight Builder.
*   **Progressive Onboarding:** Install par sirf basic questions (Weight, Age, Goal). Detail profiling (Body fat, Dimensions) dashboard par as a gamified task (+50 points) show hogi.
*   **Overweight / Beginner Track:** Heavy/overweight users ke liye workout algorithm purposely easy aur low-intensity exercises se start karega taake log thak kar app na chorein. Core focus sirf healthy weight loss par hoga.
*   **Injury Filter:** Onboarding mein "Medical Conditions" (e.g., knee pain, back ache) ka input lazmi hoga taake AI dangerous exercises filter out kar de.
*   **The "Swap" Feature:** Agar koi machine busy hai ya user ko exercise se problem hai, wo "Swap" button use kar ke alternate exercise le sakta hai bina points lose kiye.

## 2. Technical Logic: Scoring & Streak Management
*   **80% Threshold Rule:** Daily streak maintain karne ke liye prescribed tasks (Workout + Cardio + Diet + Sleep) ka minimum 80% complete karna lazmi hai.
*   **Weighted Points Formula (How it works):**
    *   **Workout Completion:** Sets aur Reps poore karne par maximum points (e.g., +50 Points). Agar 10 mein se 2 exercises chori, toh points deduct honge. Weight (kg) kitna uthaya, is se leaderboard ke points ka koi link nahi, effort par points milenge.
    *   **Cardio / Steps:** Apple HealthKit/Google Fit se auto-sync hone par full points (+20). Agar manually type kiya toh minimum points.
    *   **Diet Proof System:** Agar user daily meal ki picture as proof upload karega toh extra points (+15). Agar sirf text mein manually mark karega "I ate my diet", toh penalty nahi hogi but sirf nominal points milenge (+2).
    *   **Sleep Tracking:** Auto-sync via OS sensors. Secondary priority but important for full daily streak completion.
    *   **Penalty:** Bina inform kiye gym na aane ya tasks ignore karne par negative marking (-10 points) hogi.
*   **Adaptive AI (Auto-Calibration):** Agar user lagatar 3 din tak apna Step ya Sleep target miss karta hai, toh AI system khud target ko thoda low kar dega (e.g., 10k steps se 6k steps) taake user demotivate na ho.

## 3. Leaderboard, Reset & The "Veteran Multiplier"
*   **Hall of Fame (Lifetime Streak):** User ki continuous check-in streak (e.g., "60 Days 🔥") kabhi reset nahi hogi. Yeh uski profile par hamesha zinda rahegi.
*   **Monthly Leaderboard Reset:** Top 3 free gym rewards ke liye Leaderboard har mahine ki 1st tareekh ko zero (0) se start hoga taake naye users bhi race mein shamil ho sakein.
*   **The Streak Multiplier (For Old Users):** Jab leaderboard reset hoga, toh jo users pichle 1, 2, ya 3 mahine se apni streak maintain kar rahe hain, unko ek "Multiplier" milega. (Example: Agar ek bande ki 2 mahine ki streak hai, toh naye mahine mein uske har 10 points automatically 12 ya 15 points count honge). Is se purane members hamesha top par fight mein rahenge.
*   **Qualification Baseline:** Top 3 mein aane ke liye sirf app open rakhna kafi nahi. Har user ko mahine mein ek minimum limit (e.g., Minimum 18 Gym Visits + Workout Completion) pass karni hogi. Jo baseline pass nahi karega, wo Top 3 rewards ke liye qualify hi nahi hoga.
*   **Universal Gym Rewards:** Har gym owner platform ki taraf se bound hoga ke Top 3 members ko free membership ya equivalent rewards de, yeh SaaS ka core system rule hoga.

## 4. Anti-Cheat & Video Micro-Clip Engine
*   **Gate / POS Check-in Lock:** Workout logging aur points tab tak active nahi honge jab tak user physical gym aakar RFID gate scan ya POS par attendance mark nahi karta.
*   **Smart Video Recording:** System poora 1 ghanta record nahi karega. User har exercise ke ek set ki sirf 5-10 second ki recording karega jahan AI/Trainer guide karega.
*   **Local Rendering (FFmpeg):** Yeh chote 5-10 second ke clips user ke mobile phone par hi background mein merge honge aur ek 1 se 1:30 minute ki final video banegi.
*   **Explore Tab / Marketing Feed:** Yeh final merged video user ki profile mein save hogi. Jo users Top Performer/Leaderboard par honge, unki videos app ke public "Explore Tab" (Reels jesa scrolling view) mein feature hongi. Yeh gym owners ke liye zabardast free marketing aur community motivation ka kaam karegi, aur cheating ka proof bhi ban jayegi.
*   **Flagged Items:** Gym owner ke dashboard par ek "Flagged" tab hoga jahan wo shak hone par logo ki upload ki gayi diet pictures ya videos ko review karke points manually cancel kar sakta hai.