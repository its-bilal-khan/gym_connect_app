import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.8";

// ==============================================================================
// GYMCONNECT ENTERPRISE SAAS: MASTER WORKOUT TEMPLATE ASSIGNMENT SERVICE
// File: supabase/functions/generate-ai-workout/index.ts
//
// High-Reliability Architecture (Zero LLM / Zero External API Dependency):
// 1. Receives member biometric inputs (weight, height, age, medical injuries).
// 2. Invokes PostgreSQL RPC: rpc_assign_master_workout_template.
// 3. Database calculates silent BMI, assigns Master 90-Day Track A or Track B,
//    and automatically swaps contraindicated exercises using swap_group_id.
// 4. Returns deterministic, instant JSON response (< 50ms latency, 0 token cost).
// ==============================================================================

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, apikey, x-client-info",
};

interface AssignWorkoutPayload {
  userId: string;
  tenantId?: string;
  targetBodyType?: string;
  currentWeightKg?: number;
  heightCm?: number;
  age?: number;
  fitnessLevel?: string;
  medicalInjuries?: string[];
  overrideTrack?: "track_a" | "track_b";
}

serve(async (req: Request) => {
  // 1. Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey =
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
      Deno.env.get("SUPABASE_ANON_KEY") ??
      "";

    const authHeader = req.headers.get("Authorization");
    const supabase = createClient(supabaseUrl, supabaseServiceKey, {
      auth: {
        persistSession: false,
      },
      global: {
        headers: authHeader ? { Authorization: authHeader } : {},
      },
    });

    // 2. Parse incoming payload
    const body: AssignWorkoutPayload = await req.json().catch(() => ({}) as AssignWorkoutPayload);
    const userId = body.userId;

    if (!userId) {
      return new Response(
        JSON.stringify({ error: "Missing required parameter: userId" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 3. Invoke PostgreSQL Template Assignment & Injury Swap RPC
    const { data: rpcResult, error: rpcError } = await supabase.rpc(
      "rpc_assign_master_workout_template",
      {
        p_user_id: userId,
        p_tenant_id: body.tenantId || null,
        p_target_body_type: body.targetBodyType || null,
        p_current_weight_kg: body.currentWeightKg != null ? Number(body.currentWeightKg) : null,
        p_height_cm: body.heightCm != null ? Number(body.heightCm) : null,
        p_age: body.age != null ? Number(body.age) : null,
        p_fitness_level: body.fitnessLevel || "beginner",
        p_medical_injuries: body.medicalInjuries || [],
        p_override_track: body.overrideTrack || null,
      }
    );

    if (rpcError) {
      console.error("Error executing rpc_assign_master_workout_template:", rpcError);
      return new Response(
        JSON.stringify({
          error: "Failed to assign master workout template",
          details: rpcError.message,
        }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify(rpcResult),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err: any) {
    console.error("Unhandled exception in template assignment service:", err);
    return new Response(
      JSON.stringify({ error: "Internal Server Error", message: err?.message || String(err) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
