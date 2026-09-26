-- ======================================================================================
-- MIGRATION: Tenant Brand Theme Locking & Change Requests
-- Supports permanent brand color locking and Super Admin review queue
-- ======================================================================================

-- 1. Ensure tenants table default branding includes theme_locked flag and request payload
ALTER TABLE IF EXISTS tenants 
ALTER COLUMN branding SET DEFAULT '{
    "primary_color": "#CCFF00",
    "surface_color": "#18181B",
    "background_color": "#09090B",
    "theme_locked": false,
    "locked_at": null,
    "pending_theme_request": null
}'::jsonb;

-- 2. Comment explaining the branding schema
COMMENT ON COLUMN tenants.branding IS 'JSONB branding payload holding primary_color, theme_locked, locked_at, and pending_theme_request';
