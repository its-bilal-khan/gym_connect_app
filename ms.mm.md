# GymConnect Enterprise SaaS (Ultimate Master Blueprint)

## Module 1: Desktop App (Electron.js)
- **Secondary Screen (Gate Display)**
  - Displays 10-sec Dynamic QR for Entry
- **Local Database**
  - SQLite for Offline-First Data & Background Syncing
- **Role-Based Reception Dashboard**
  - **Staff Mode:** Member Registration, Fee Collection, Attendance Check-ins
  - **Admin Mode:** Full Financials, Analytics, & Business Reports
- **Enhanced POS, Billing & Inventory**
  - **Hardware Integrations:** Thermal Printer (Receipts), Cash Drawer Auto-Kick, Barcode Scanner
  - **Billing Actions:** Walk-in / Drop-in Fees, Split Payments (Cash + Card)
  - **Khata System:** "Add to Member Bill" for udhaar (Credit)
  - **Inventory:** Low Stock Alerts for supplements
  - **Advanced Reporting:** Z-Report (End of Day Shift Tally), Defaulters & Dues List, Revenue Breakdown, Petty Cash Tracker
- **Hardware Trigger**
  - Sends Local API signal to ESP32 to open the Gate Lock

## Module 2: Multi-Role Mobile App (Flutter Super App)
- **Role-Switching Engine**
  - Auto-Detects Role (Owner, Staff, Member, or Public)
- **1. Gym Owner View (The Boss)**
  - **Security:** Biometric App Lock (FaceID/Fingerprint) for Financial Reports
  - **Live Operations:** Live Camera Feed (RTSP Stream Player)
  - **Business Dashboard:** Revenue, Attrition Rate, Active Members
  - **Anti-Theft:** Real-time Push Alerts for Voided/Deleted Invoices by staff
  - **Smart Actions:** Long-press Member Name to Auto-WhatsApp reminders
  - **Management:** Manage Public Profile, Photos, and Store Inventory
- **2. Gym Member View (The VIP)**
  - **Ultra-Fast Access & Security**
    - Device ID Lock (Anti-Cheat / No Sharing)
    - In-App QR Scanner
    - "Shake to Show QR" & Mobile Home Screen Widgets
  - **Online Payments**
    - Pay Monthly Dues via App (JazzCash/Cards) & Auto-unlock Gate Access
  - **Virtual AI Trainer (The Core USP & Member Addiction Engine)**
    - Goal Onboarding (Visual Body Type UI Cards)
    - 90-Day Smart Calendar (Auto-loads Today's Routine)
    - **[UX UPDATE] Zero-Friction UX & Dopamine Loops:**
      - **1. The "One-Tap" Daily Action:** No searching required. A giant "Start Today's Workout" button automatically queues the daily routine (e.g., Chest & Triceps). 
      - **2. PIP (Picture-in-Picture) Auto-Play Videos:** Silent, looping videos of the exercise form auto-playing directly on the workout screen to eliminate the need for external YouTube searches.
      - **3. Haptic Feedback & The "Done" Button:** A satisfying green tick and solid phone vibration (Zeigarnik effect / dopamine hit) upon completing a set to motivate the next one.
      - **4. Rest Timer & Visual Progression:** Auto-starting 60s timer after a set that flashes at zero, combined with a live progress bar (e.g., "70% Workout Complete") to prevent mid-workout drop-offs.
    - Daily Action Screen (Grouped Exercises like Chest -> Triceps)
    - Instant Video & Image Pop-ups (PIP Mode)
    - Active Workout Mode (Start Button, Swipe Navigation, Sets/Reps tracker)
    - Smart Features: Auto-offline Video Caching (For basement gyms), Haptic Feedback (Vibrations) for Rest Timer, Progressive Overload suggestions
  - **Motivation, Health & Gamification**
    - **[NEW] Live Pedometer & Step Tracker:** Native Flutter background step counting for outdoor walks/runs with real-time distance (km) and calorie burn estimation.
    - Transformation Videos Feed & Daily Tips
    - Google Fit & Apple Health Sync (Fallback/Sync for external data)
    - 7-Day Streak Badges, PR Confetti Animations, & Leaderboards
  - **In-App Store (E-commerce)**
    - Order Supplements & Gear for In-Gym Pickup
  - **Verified Reviews**
    - Write Ratings & Reviews (Locked: Only for their officially enrolled gym)
  - **Dynamic Branding**
    - Gym Specific Logos & Primary Colors load automatically
- **3. Public User View (The Marketplace)**
  - **Discovery UX**
    - Airbnb-Style Map View with swipeable gym interior cards
    - Real-time Distance, ETA, and Gym Profiles
  - **Frictionless Conversion**
    - Claim "24-Hour Temporary QR Guest Pass" instantly
    - Buy Membership Online directly from the app
  - **Trust & Marketing**
    - View Average Star Ratings & Read Verified-Only Reviews
    - FOMO Engine: Locked AI Trainer Preview to encourage sign-ups

## Module 3: Cloud Backend (Supabase)
- **Database Architecture**
  - Multi-Tenant Database (Tenant IDs for Gym Isolation)
  - Role-Level Security (RLS) Policies
  - PostGIS Extension (For GPS Location & Nearby Gyms matching)
  - **[NEW] Daily Step Logs:** Dedicated historical table to track day-by-day step counts, distance, and calories for member analytics.
- **System Audit Logs (The Watchdog)**
  - Immutable hidden logs for all CRUD operations (Tracks who deleted/edited what)
- **Automation (Edge Functions)**
  - Payment Webhooks Listener (Auto-updates paid status)
  - Subscription Expiry Lockouts
  - WhatsApp/SMS Automations (Automated Fee Reminders, Welcome Messages)
- **Storage**
  - Vercel Blob (Hosting for Exercise Videos & Product Images)

## Module 4: Gym Hardware Setup
- **Access Control**
  - ESP32 Wi-Fi Relay Module
  - Magnetic Gate Lock
- **Backup Access**
  - USB Fingerprint Scanner

## Module 5: Super Admin Web Panel (Your Mothership)
- **Global Dashboard**
  - Total SaaS Revenue & Active Tenants metrics
- **Tenant Management**
  - Launch/Onboard New Gyms (Generate Tenant IDs)
  - Suspend or Lock Gyms for non-payment
- **God Mode (Impersonation Engine)**
  - "Log in as" any specific Owner, Staff, or Member without their password for troubleshooting
- **Global Audit Log Viewer**
  - Searchable system logs across the entire network