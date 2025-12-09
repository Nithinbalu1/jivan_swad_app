github repo : https://github.com/Nithinbalu1/jivan_swad_app

# Jivan Swad — Flutter app with AI assistant

Welcome — this repository contains the Jivan Swad Flutter app (a tea catalog and ordering app) and a small Node.js AI proxy server that forwards prompts to an upstream AI provider (OpenAI or Ollama). The proxy keeps API keys off the client and returns assistant replies to the app.

This README gives a friendly, step-by-step guide from zero → running the app with the AI assistant locally, including Firebase setup, starting the server, and options to run it continuously.

If you prefer a shorter quick-start, see `server/AI_SETUP_FULL.txt` which lists all commands in one place.

## What you'll get running this repo
- A working Flutter app that shows a product catalog, allows login, and includes an in-app AI assistant.
- A Node.js proxy (`server/index.js`) that forwards chat prompts to Ollama or OpenAI using keys stored in `server/.env`.
- Firestore-backed chat sync for users with role `customer`.

## Prerequisites (install first)
- Node.js and npm — https://nodejs.org/
- Flutter SDK — https://flutter.dev/docs/get-started/install
- Git and an editor (VS Code recommended) — https://code.visualstudio.com/
- Firebase project (Firestore + Authentication) — https://console.firebase.google.com/
- Android Studio if you want to run on Android / emulator — https://developer.android.com/studio

Optional but recommended:
- PM2 (process manager) for long-running server: https://pm2.keymetrics.io/
- NSSM if you want a Windows Service: https://nssm.cc/

## Quick setup (recommended order)

1. Clone the repo and open it in your IDE

```powershell
git clone https://github.com/Nithinbalu1/jivan_swad_app
cd jivan_swad_app
```

2. Install server dependencies

```powershell
cd server
npm install
```

3. Install Flutter packages

```powershell
cd ..
flutter pub get
```

4. Create server `.env` and add your AI keys

```powershell
cd server
copy .env.sample .env
# open server/.env and set one of the following:
# OPENAI_API_KEY=sk-...
# or
# OLLAMA_API_KEY=...
# optionally set PREFERRED_PROVIDER=ollama or openai
```

5. Configure Firebase for the app

- Create a Firebase project and enable Authentication and Firestore.
- Add an app in Firebase and generate `firebase_options.dart` (use `flutterfire` CLI or paste config manually).
- Ensure Firestore has a `users` collection. For chat sync, give a test user a document with `role: "customer"`.

## Starting the AI proxy (development)

To quickly run the proxy in the foreground while developing:

```powershell
cd server
npm start
# or: node index.js
```

Open `http://localhost:8787/api/ai/status` to confirm which provider is active and whether keys are present.

Test the chat endpoint from PowerShell:

```powershell
$body = '{ "prompt": "Hello, test" }'
Invoke-RestMethod -Uri 'http://localhost:8787/api/ai/chat' -Method Post -ContentType 'application/json' -Body $body
```

You should receive `{"answer":"..."}` on success.

## Running the proxy continuously (recommended for local server)

Option A — PM2 (cross-platform, recommended):

```powershell
npm install -g pm2        # one-time
cd server
pm2 start ecosystem.config.js
pm2 save
pm2 logs jivan-swad-ai-proxy --lines 200
```

Option B — NSSM (Windows native service):

Run PowerShell as Administrator and run:

```powershell
nssm install jivan-swad-ai-proxy "C:\Program Files\nodejs\node.exe" "D:\Network_project\jivan_swad_app\jivan_swad_app\server\index.js"
nssm set jivan-swad-ai-proxy AppDirectory "D:\Network_project\jivan_swad_app\jivan_swad_app\server"
nssm start jivan-swad-ai-proxy
```

Option C — Docker: build the provided Dockerfile (or create one) and run the container exposing port 8787.

## Running the Flutter app locally

1. Accept Android licenses (if developing for Android)

```powershell
echo y | flutter doctor --android-licenses
flutter doctor
```

2. Start an emulator or connect a device

```powershell
flutter emulators           # list available emulators
flutter emulators --launch <id>
flutter run                 # runs app on the active device/emulator
```

Notes about network mapping:
- When running the Flutter Web build, the app connects to `http://localhost:8787`.
- When running on an Android emulator, the app uses `http://10.0.2.2:8787` (this mapping is implemented in `lib/screens/ai_assistant.dart`).
- For real devices or iOS simulators use your host machine IP address.

## AI assistant behavior

- The assistant prompt is built in the client (`_buildPrompt`) and includes a short catalog excerpt so responses are grounded in your app data.
- If a signed-in user has `role: "customer"` in Firestore, messages are synced to `ai_chats/<uid>/messages`.

## Troubleshooting / common issues

- If the browser shows `XMLHttpRequest error`: confirm web client uses `http://localhost:8787` (not `10.0.2.2`) and that the proxy is running and CORS enabled (server uses `cors()` by default).
- If the AI times out: check server logs (`pm2 logs` or terminal), confirm upstream provider (Ollama/OpenAI) is reachable, and inspect `server/index.js` logs for upstream errors.
- If Firestore chat doesn’t sync: ensure `users/<uid>.role` is set to `customer` and that Firestore rules permit writes for that user.

## Where to find setup scripts and docs
- `server/AI_SETUP.txt` — step-by-step plain text guide (includes Android setup and links).
- `server/AI_SETUP_FULL.txt` — full command dump for copy/paste.
- `server/ecosystem.config.js` — PM2 config.
- `server/index.js` — AI proxy.
- `lib/screens/ai_assistant.dart` — Flutter assistant UI & client-side prompt logic.

---
If you'd like, I can also:
- Add a `run-pm2.ps1` to automate PM2 setup and startup on Windows.
- Convert the `AI_SETUP_FULL.txt` into a GitHub-friendly `AI_SETUP.md`.
- Create a Docker Compose file for local testing.

Tell me which one you prefer and I'll add it.
