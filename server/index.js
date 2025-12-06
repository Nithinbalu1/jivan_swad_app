// Load environment variables from .env (if present)
try {
  require('dotenv').config({ path: __dirname + '/.env' });
} catch (e) {
  // ignore if dotenv is not installed
}

const express = require('express');
const fetch = require('node-fetch'); // remove if on Node 18+ where fetch is global
const cors = require('cors');
const app = express();

app.use(cors());
app.use(express.json());

// Helper: fetch with timeout compatible with node-fetch@2 (no AbortController assumed)
function fetchWithTimeout(url, opts = {}, ms = 55_000) {
  return new Promise((resolve, reject) => {
    let didTimeOut = false;

    const timer = setTimeout(() => {
      didTimeOut = true;
      reject(new Error('Fetch timeout'));
    }, ms);

    fetch(url, opts)
      .then((res) => {
        if (!didTimeOut) {
          clearTimeout(timer);
          resolve(res);
        }
      })
      .catch((err) => {
        if (didTimeOut) return;
        clearTimeout(timer);
        reject(err);
      });
  });
}

// Log unhandled errors to help debugging crashes
process.on('uncaughtException', (err) => {
  console.error('UNCAUGHT EXCEPTION', err && err.stack ? err.stack : err);
});
process.on('unhandledRejection', (reason) => {
  console.error('UNHANDLED REJECTION', reason);
});

// Read keys and configuration from environment variables
const OPENAI_KEY      = process.env.OPENAI_API_KEY;
const OLLAMA_KEY      = process.env.OLLAMA_API_KEY;
const OLLAMA_BASE_URL = process.env.OLLAMA_BASE_URL || 'https://ollama.com/api';
const OLLAMA_MODEL    = process.env.OLLAMA_MODEL    || 'gpt-oss:120b';
const PREFERRED_PROVIDER = (process.env.PREFERRED_PROVIDER || '').toLowerCase();

function getProvider() {
  if (PREFERRED_PROVIDER) return PREFERRED_PROVIDER;
  // Prefer Ollama when its key is present (so developers using Ollama won't
  // unintentionally fall back to OpenAI when both keys exist).
  if (OLLAMA_KEY) return 'ollama';
  if (OPENAI_KEY) return 'openai';
  return 'none';
}

// Handle chat requests
app.post('/api/ai/chat', async (req, res) => {
  const { prompt } = req.body || {};
  if (!prompt) return res.status(400).json({ error: 'missing prompt' });

  const provider = getProvider();
  console.log('[AI proxy] incoming chat request; provider=', provider, 'promptLength=', (prompt || '').toString().length);
  if (provider === 'none') {
    return res.status(500).json({ error: 'no API key configured' });
  }

  // Ollama branch
  if (provider === 'ollama') {
    if (!OLLAMA_KEY) {
      return res.status(500).json({ error: 'server missing OLLAMA_API_KEY' });
    }
    try {
      const response = await fetchWithTimeout(`${OLLAMA_BASE_URL}/generate`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${OLLAMA_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model: OLLAMA_MODEL,
          prompt: prompt,
          stream: false
        }),
      }, 55_000);

      const json = await response.json().catch(() => null);

      if (!response.ok || !json) {
        console.error('Ollama upstream error', { status: response.status, body: json });
        return res.status(502).json({ error: 'upstream error', status: response.status, body: json });
      }

      // /generate returns the reply in json.response
      const answer = json.response || '';
      return res.json({ answer });
    } catch (err) {
      console.error('Ollama proxy error', err);
      return res.status(500).json({ error: 'server error' });
    }
  }

  // OpenAI branch (fallback)
  if (provider !== 'openai') {
    return res.status(400).json({ error: 'unsupported provider', provider });
  }
  if (!OPENAI_KEY) {
    return res.status(500).json({ error: 'server missing OPENAI_API_KEY' });
  }
  try {
    const response = await fetchWithTimeout('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${OPENAI_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-3.5-turbo',
        messages: [
          { role: 'system', content: 'You are an assistant for the Jivan Swad app.' },
          { role: 'user', content: prompt },
        ],
        temperature: 0.7,
        max_tokens: 500,
      }),
    }, 55_000);

    const json = await response.json().catch(() => null);

    if (!response.ok || !json) {
      console.error('OpenAI upstream error', { status: response.status, body: json });
      return res.status(502).json({ error: 'upstream error', status: response.status, body: json });
    }

    const answer = json?.choices?.[0]?.message?.content || json?.choices?.[0]?.text || '';
    return res.json({ answer });
  } catch (err) {
    console.error('OpenAI proxy error', err);
    return res.status(500).json({ error: 'server error' });
  }
});

// GET route to display usage instructions
app.get('/api/ai/chat', (_req, res) => {
  res.set('Content-Type', 'text/html');
  res.send(
    `<html><body style="font-family:system-ui,Segoe UI,Roboto,Helvetica,Arial,sans-serif;padding:24px">` +
      `<h2>AI Proxy (${getProvider()})</h2>` +
      `<p>This proxy accepts <strong>POST</strong> requests with JSON <code>{ "prompt": "..." }</code>.</p>` +
      `<p>Example curl:</p>` +
      `<pre>curl -X POST http://localhost:8787/api/ai/chat -H "Content-Type: application/json" -d '{"prompt":"Hello"}'</pre>` +
      `<p>POST is required; GET only shows this message.</p>` +
    `</body></html>`
  );
});

// Track start time for uptime reporting
const SERVER_START = Date.now();

// Status endpoint (safe): returns which provider will be used and whether keys are present.
app.get('/api/ai/status', (_req, res) => {
  const provider = getProvider();
  let version = null;
  try {
    // read package.json version if available
    // eslint-disable-next-line @typescript-eslint/no-var-requires
    const pkg = require('./package.json');
    version = pkg.version;
  } catch (e) {
    version = null;
  }

  const uptimeSeconds = Math.floor((Date.now() - SERVER_START) / 1000);

  res.json({
    provider,
    hasOpenAIKey: !!process.env.OPENAI_API_KEY,
    hasOllamaKey: !!process.env.OLLAMA_API_KEY,
    uptimeSeconds,
    version,
  });
});

// Start the server
const PORT = process.env.PORT || 8787;
app.listen(PORT, () => {
  console.log(`AI proxy listening on ${PORT}`);
});
