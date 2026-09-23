# Rule: No Hardcoded Fake / Mock Data in Source Code

## Core Policy
1. **Zero Hardcoded Data in Code:**
   - Under no circumstances should fake, mock, dummy, or static data arrays (e.g. hardcoded products, dummy reviews, fake subscription dates, hardcoded community transformations) be written directly inside Dart/Flutter code files.
   - All dynamic content must be retrieved from and saved to live Supabase database tables via dedicated repositories and Riverpod state management.

2. **Database Seeders for Initial/Sample Data:**
   - If initial data is required for local development, demoing, or onboarding, it MUST be inserted into the PostgreSQL database using SQL migration/seed scripts (`.sql` files).
   - The Flutter application code must only query and mutate the database.

3. **High Standard of Realism in Seed Data:**
   - Even when creating database seeder scripts, placeholder strings like "Lorem ipsum", "Product 1", or cheesy test values are strictly prohibited.
   - All seed data must be realistic, authentic, and professionally curated (e.g., real gym supplements with authentic brands, realistic Pakistani Rupee & international pricing, authentic transformation protocols with realistic body fat and weight metrics).

4. **Robust State Handling:**
   - The UI must always handle real database lifecycle states: `loading`, `error`, `empty` (with friendly empty state illustrations/prompts), and populated data.
