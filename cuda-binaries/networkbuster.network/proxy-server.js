import httpProxy from 'http-proxy';
import http from 'http';
import https from 'https';

const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:3001';
const PROXY_PORT = process.env.PROXY_PORT || 3000;
const FRONTEND_URL = process.env.FRONTEND_URL || 'http://192.168.1.180:5173';

// Create proxy
const proxy = httpProxy.createProxyServer({
  target: BACKEND_URL,
  changeOrigin: true,
  ws: true,
  xfwd: true,
  logLevel: 'info'
});

// Error handling
proxy.on('error', (err, req, res) => {
  console.error('Proxy error:', err);
  res.writeHead(502, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ error: 'Bad Gateway', message: err.message }));
});

// Create HTTP server
const server = http.createServer((req, res) => {
  // Add CORS headers
  res.setHeader('Access-Control-Allow-Origin', FRONTEND_URL);
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, PATCH, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.setHeader('Access-Control-Allow-Credentials', 'true');

  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  // Log requests
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url} -> ${BACKEND_URL}`);

  // Forward all requests to backend
  proxy.web(req, res);
});

// WebSocket support
server.on('upgrade', (req, socket, head) => {
  console.log(`[WebSocket] Upgrading ${req.url}`);
  proxy.ws(req, socket, head);
});

server.listen(PROXY_PORT, '0.0.0.0', () => {
  console.log(`\n🔄 Network Proxy Server`);
  console.log(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`);
  console.log(`✓ Listening on all interfaces: http://0.0.0.0:${PROXY_PORT}`);
  console.log(`✓ Network access: http://192.168.1.180:${PROXY_PORT}`);
  console.log(`✓ Localhost: http://localhost:${PROXY_PORT}`);
  console.log(`✓ Forwarding to: ${BACKEND_URL}`);
  console.log(`✓ Frontend at: ${FRONTEND_URL}`);
  console.log(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n`);
});

export default server;
