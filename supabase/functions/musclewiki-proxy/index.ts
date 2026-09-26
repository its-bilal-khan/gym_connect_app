import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const MUSCLEWIKI_BASE = "https://api.musclewiki.com";
const DEFAULT_KEY = "mw_KqJ0jODYaNb6EWVXfSEguIp5wc1bdq71FdLcMJGahEY";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, apikey, x-client-info, X-API-Key, x-api-key",
};

serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  try {
    const url = new URL(req.url);
    const params = url.searchParams;

    // Read API key: Supabase secret > request header > query param > default key
    const apiKey =
      Deno.env.get("MUSCLEWIKI_API_KEY") ||
      req.headers.get("x-api-key") ||
      req.headers.get("X-API-Key") ||
      params.get("apiKey") ||
      params.get("rawKey") ||
      DEFAULT_KEY;

    // Build the target MuscleWiki URL from the "endpoint" param
    // Example: ?endpoint=exercises/1/videos&gender=male
    const endpoint = params.get("endpoint") || "exercises";
    params.delete("endpoint");
    params.delete("apiKey");
    params.delete("rawKey");

    // Build query string from remaining params
    const queryString = params.toString();
    const targetUrl = `${MUSCLEWIKI_BASE}/${endpoint}${queryString ? `?${queryString}` : ""}`;

    // Server-to-server call — no CORS restrictions
    const mwResponse = await fetch(targetUrl, {
      method: "GET",
      headers: {
        "X-API-Key": apiKey,
        "Accept": "application/json",
      },
    });

    const body = await mwResponse.text();

    return new Response(body, {
      status: mwResponse.status,
      headers: {
        ...corsHeaders,
        "Content-Type": "application/json",
        "X-Proxy-Status": mwResponse.status.toString(),
      },
    });
  } catch (err) {
    return new Response(
      JSON.stringify({ error: "Proxy error", detail: String(err) }),
      { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});
