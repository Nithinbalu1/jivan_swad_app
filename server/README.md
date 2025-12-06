# AI Proxy (server)

This directory runs a small AI proxy that forwards prompts to an upstream provider (OpenAI or Ollama) so client apps don't need to hold private API keys.

Quick setup

1. Copy `.env.sample` to `.env` and add your keys (do NOT commit `.env`).

```
cp .env.sample .env
# edit .env and set OPENAI_API_KEY or OLLAMA_API_KEY
```

2. Install dependencies and start the proxy:

```powershell
cd server
npm install
npm start
```
Run continuously (recommended)
------------------------------

Option 1 — PM2 (recommended, cross-platform via Node):

- Install PM2 globally:

```powershell
npm install -g pm2
```

- From the `server` folder start the app using the included ecosystem file:

```powershell
cd D:\Network_project\jivan_swad_app\jivan_swad_app\server
pm2 start ecosystem.config.js
pm2 save
```

- To have PM2 resurrect on system restart, run the startup command PM2 suggests and follow its output. On Windows you can use the `pm2-windows-service` package or use NSSM (instructions below).

Option 2 — Install as a Windows Service (NSSM):

- Download `nssm` from https://nssm.cc/ and place `nssm.exe` somewhere on your PATH (or use the full path to the exe).
- Install the service (run PowerShell as Administrator):

```powershell
# Example; adjust paths to your node.exe and project
nssm install jivan-swad-ai-proxy "C:\Program Files\nodejs\node.exe" "D:\Network_project\jivan_swad_app\jivan_swad_app\server\index.js"
nssm set jivan-swad-ai-proxy AppDirectory "D:\Network_project\jivan_swad_app\jivan_swad_app\server"
nssm set jivan-swad-ai-proxy Start SERVICE_AUTO_START
nssm start jivan-swad-ai-proxy
```

- NSSM will run the Node process as a Windows service and restart it automatically on crash or reboot.

Notes and troubleshooting
-------------------------
- Use `pm2 logs jivan-swad-ai-proxy` to tail logs when using PM2.
- If using PM2 on Windows you may prefer `pm2-windows-service` to integrate with the service manager.
- The proxy exposes a health/status endpoint at `/api/ai/status` — use it to verify the service is up.

3. Test the proxy (PowerShell):

```powershell
#$body = @{ prompt = 'Hello' } | ConvertTo-Json
#Invoke-RestMethod -Uri 'http://localhost:8787/api/ai/chat' -Method Post -ContentType 'application/json' -Body $body
```

Endpoints
- `GET /api/ai/chat` — informational HTML page
- `POST /api/ai/chat` — accepts JSON `{ "prompt": "..." }` and returns `{ "answer": "..." }`
- `GET /api/ai/status` — returns JSON with active provider and key presence (does not expose keys)

Notes
- Keep your API keys secret; do not commit `.env`.
- Use `10.0.2.2` as host when testing from Android emulator.
AI proxy server for Jivan Swad app

This small Express server forwards prompts to OpenAI's Chat Completions API so the client app doesn't embed the secret API key.

Setup (local)

1. Install dependencies:
   npm install

2. Create a `.env` file in `server/` (copy `.env.sample`) and set your key:
   - For OpenAI (Chat Completions):
     `OPENAI_API_KEY=sk-...`
   - For Google Generative (Gemini / Vertex):
     `GEMINI_API_KEY=your_google_api_key`

   The proxy prefers `OPENAI_API_KEY` when present; otherwise it will use `GEMINI_API_KEY`.

3. Start the server (Windows PowerShell example):

   $env:OPENAI_API_KEY="sk-..."; npm start

   # or for Gemini/Google key:
   $env:GEMINI_API_KEY="AIzaSy..."; npm start

4. Test the endpoint (POST JSON {"prompt":"Hello"} to `/api/ai/chat`).

5. Update your Flutter app to call the proxy endpoint, e.g. `http://localhost:8787/api/ai/chat`.

Security

- Restrict CORS to your app's origin in production.
- Do not expose API keys in client code or commit them to git.
- Add authentication/rate-limiting in production to prevent abuse.
- For Google/Gemini use a restricted API key or a service-account-based setup for production.
