# GymConnect Project Rules & Architectural Constraints

## 1. Zero Hardcoded Fake / Mock Data (STRICT)
- **NEVER** hardcode fake, dummy, or mock data directly inside Dart/Flutter code files (e.g., hardcoded products lists, fake reviews, static user subscriptions, fake transformation stories).
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
