# GymConnect Project Rules & Architectural Constraints

## 1. Zero Hardcoded Fake / Mock Data (STRICT)
- **NEVER** hardcode fake, dummy, or mock data directly inside Dart/Flutter code files (e.g., hardcoded products lists, fake reviews, static user subscriptions, fake transformation stories).
- **Zero Dummy Notifications & Zero Fake Announcements:**
  - All in-app alerts, notifications, and announcements **MUST** originate from live database records (`notifications`, real unpaid `invoices`, real `payment_proofs` pending owner review, or real `store_orders`).
  - **NEVER** hardcode fake facility announcements (e.g. fake extended hours) or fake store product arrival alerts in notification repositories.
  - **NEVER** include simulation or test buttons (e.g. "TEST ALERT" or fake "SHAKE" simulator buttons) that push dummy items into the notification stream.
  - When no real notifications exist, the list **MUST** remain clean and empty (`[]`).
  - Keep **NOTHING** dummy anywhere in the app unless explicitly requested by the user.
- All application data **MUST** be fetched from and written to live Supabase database tables via dedicated repositories and Riverpod providers.
- If initial/sample data is needed for development or onboarding, it **MUST** be injected into the PostgreSQL database using SQL seed scripts (`.sql` files).
- Even database seed data **MUST** be realistic, authentic, and professional (real gym supplements, realistic Pakistani & international pricing, authentic transformation protocols)—never cheap or unrealistic placeholder text.
- The UI must always handle real database states (`loading`, `error`, `empty`, `data`).

## 2. UI/UX & Branding Master Rules
- **Color Palette:** `#09090B` (Scaffold background), `#18181B` (Surface/Cards), `#CCFF00` (Neon Volt primary accent), `#FFFFFF` (Primary text), `#A1A1AA` (Secondary text).
- **Typography:** `Oswald` for headings/metrics, `Inter` for body/descriptions.
- **Component Shapes:** `BorderRadius.circular(16)` globally.
- **File Length Limit:** Keep widgets small. If a widget exceeds 150 lines, break it down into modular components.

## 3. Security & Clean Architecture
- **Tokens:** Strictly use `flutter_secure_storage` for session tokens.
- **Secrets:** Never commit or hardcode secrets in source code; use `.env`.
- **State Management:** Separate business logic and database queries from UI using Riverpod.

## 4. Platform Separation & Device Architecture (STRICT)
- **Desktop / Web App (`width >= 800px`):**
  - **Purpose:** Dedicated Enterprise Gym Operations & Full POS Workstation.
  - **Primary Audiences:** Gym Owner, Staff / Receptionist, Super Admin.
  - **UI Standard:** Professional multi-column desktop layout (metrics grid, data tables, split-screen POS register with right-side live cart drawer, Workout Protocol Studio). NEVER stretch single-column mobile widgets across a widescreen monitor.
  - **No Phone Hardware Gimmicks on Desktop:** Never render phone-specific features (e.g., pedometer step counters, phone-shaking gestures, mobile gate pass cards) as primary desktop screens.
  - **Member & Guest on Desktop:** Display a clean, professional Desktop Member Portal with membership status, payment history, and a clear prompt that mobile workouts, QR gate pass, and step tracking belong on the iOS/Android mobile app.
- **Mobile App (`width < 800px`):**
  - **Purpose:** Member Super App (Dynamic QR gate pass, Health Connect pedometer, AI workout coach) + Gym Owner Mobile Lite (quick revenue glance and proof-of-payment approval notifications).
  - **Strict Lightweight Rule:** NEVER bloat the mobile app with full desktop POS terminals, heavy multi-day workout studio builders, or large inventory audits. Mobile must remain fast, snappy, and thumb-friendly.

## 5. Dual-View Listing Standard: Grid & List Views (STRICT)
- **Wherever items, cards, or entities are listed in the app** (e.g. Workout Protocol Studio exercises, Exercise Video Management Studio, Exercise Catalog pickers, Store Products catalog, Member directory, Staff rosters):
  - **MUST Provide Two Views:**
    1. **Grid View (`Icons.grid_view_rounded`):** Responsive multi-column layout showing rich dashboard cards, tags, badges, and media previews.
    2. **List View (`Icons.view_list_rounded`):** High-density, horizontal structured row/card layout for linear reading, inline parameters editing, and reordering.
  - **View Toggle Switch:** Always provide a sleek segmented toggle control (`List` / `Grid`) in the section toolbar or header so users can toggle between Grid View and List View seamlessly.
  - Never force only a single listing layout when presenting multi-item collections.

## 6. Runtime Dynamic Theme Accent Detection (STRICT)
- **Zero Static Color Hardcoding for Accents:**
  - **NEVER** hardcode static neon green (`#CCFF00`) or fixed colors into widget trees, borders, icons, buttons, or badges.
- **Dynamic Runtime Resolution:**
  - Whenever ANY module, widget, dialog, or screen is developed, it **MUST** dynamically resolve and use the currently selected theme accent color at runtime via:
    1. `Theme.of(context).colorScheme.primary` or `AppColors.accent(context)`
    2. Or `AppColors.primary` / `AppColors.primaryAccent` (which dynamically returns the active tenant preset color updated in real-time by `appThemeNotifierProvider`).
- **Universal Real-Time Reflection:**
  - When a gym owner/tenant selects a theme color (Neon Volt, Electric Blue, Soft Yellow, or Lavender), all modules across the application (Dashboard metrics, POS workstations, Workout Protocol Studio, Store catalog, Dialogs, Check-in, Khata) **MUST** immediately reflect the selected color in real-time.

## 7. Universal Mini View Standard (STRICT)
- **Mandatory Mini View for Every Module:**
  - Whenever ANY new module, screen, or workstation is built in the application, it **MUST** have a corresponding Mini View representation ready for use in navigation hover tooltips, bento workstation previews, and modal sheets.
  - You must never ask the user whether a mini view is needed—build it as an integral part of the module.
- **Exact UI & Fidelity Standard:**
  - Mini views **MUST** look exactly like the original full module UI (using `ScaledLivePreview` or live scaled layout rendering), not an arbitrary or unrelated placeholder.
- **Automatic Real-Time State & Design Reflection:**
  - Mini views must embed or directly replicate the live module's widget tree and Riverpod providers. Any design updates, theme accent switches, or live database updates (Supabase streams/providers) occurring in the module **MUST** automatically reflect inside its mini view in real-time with zero manual syncing.



