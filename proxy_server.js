// Lightweight MuscleWiki proxy server for local Flutter Web development
// Bypasses browser CORS restrictions by making server-to-server calls to MuscleWiki
import http from 'node:http';
import url from 'node:url';

const PORT = 5055;
const MUSCLEWIKI_BASE = 'https://api.musclewiki.com';
const DEFAULT_KEY = 'mw_KqJ0jODYaNb6EWVXfSEguIp5wc1bdq71FdLcMJGahEY';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, apikey, x-client-info, X-API-Key, x-api-key',
};

const server = http.createServer(async (req, res) => {
  // CORS Preflight
  if (req.method === 'OPTIONS') {
    res.writeHead(204, corsHeaders);
    res.end();
    return;
  }

  const parsedUrl = url.parse(req.url, true);

  if (parsedUrl.pathname === '/health') {
    res.writeHead(200, { ...corsHeaders, 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'ok', service: 'musclewiki-local-proxy', port: PORT }));
    return;
  }

  if (parsedUrl.pathname === '/musclewiki') {
    try {
      const params = new URLSearchParams(parsedUrl.query);
      const endpoint = params.get('endpoint') || 'exercises';
      const apiKey = params.get('apiKey') || params.get('rawKey') || req.headers['x-api-key'] || DEFAULT_KEY;

      params.delete('endpoint');
      params.delete('apiKey');
      params.delete('rawKey');

      const qs = params.toString();
      const targetUrl = `${MUSCLEWIKI_BASE}/${endpoint}${qs ? `?${qs}` : ''}`;

      console.log(`[Proxy] Forwarding -> ${targetUrl}`);

      const mwRes = await fetch(targetUrl, {
        method: 'GET',
        headers: {
          'X-API-Key': apiKey,
          'Accept': 'application/json',
        },
      });

      const data = await mwRes.text();

      res.writeHead(mwRes.status, {
        ...corsHeaders,
        'Content-Type': 'application/json',
        'X-Proxy-Status': mwRes.status.toString(),
      });
      res.end(data);
    } catch (err) {
      console.error('[Proxy Error]:', err);
      res.writeHead(502, { ...corsHeaders, 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: 'Proxy error', detail: String(err) }));
    }
    return;
  }

  res.writeHead(404, corsHeaders);
  res.end('Not Found');
});

server.listen(PORT, '127.0.0.1', () => {
  console.log(`MuscleWiki Local Proxy running on http://127.0.0.1:${PORT}/musclewiki`);
});
