# SuperDock

En macOS command center för utvecklare. SuperDock kombinerar en Flutter-dashboard med en lokal Node.js-backend som kan öppna appar, köra shell-kommandon, starta workspaces och visa systemstatus i realtid.

## Projektstruktur

```
superdock/
├── superdock-core/          # Node.js-backend (port 4545)
│   ├── index.js
│   └── src/
│       ├── actions.js       # Kör actions (open_app, shell, workspace)
│       ├── config.js        # Flutter/Git-projektsökvägar
│       ├── dock_actions.js  # Quick Actions-definitioner
│       ├── history.js       # Action-logg
│       ├── processes.js     # Aktiva appar
│       ├── store.js         # Persistens till ~/.superdock/
│       ├── system.js        # CPU, minne, disk
│       ├── terminal.js      # Terminaloutput + WebSocket
│       └── workspaces.js    # Workspace-definitioner + CRUD
└── superdock_ui/            # Flutter-app (macOS)
    └── lib/
        ├── app.dart
        ├── main.dart
        ├── core/            # theme, models, services
        ├── pages/           # dashboard_page.dart
        └── widgets/         # glass_card, dock_button, dialogs, etc.
```

All data sparas i `~/.superdock/data.json`:

- config (Flutter/Git-projektsökvägar)
- action-historik
- terminaloutput
- anpassade workspaces

## Krav

- macOS
- [Node.js](https://nodejs.org/) 18+
- [Flutter](https://flutter.dev/) 3.12+

## Kom igång

### 1. Starta backenden

```bash
cd superdock-core
npm install
npm start
```

Backenden körs på `http://127.0.0.1:4545`.

Miljövariabler (valfritt):

| Variabel | Beskrivning |
|----------|-------------|
| `PORT` | Port (standard `4545`) |
| `HOST` | Bind-adress (standard `127.0.0.1`) |
| `SUPERDOCK_FLUTTER_PROJECT` | Standard Flutter-projektsökväg |
| `SUPERDOCK_GIT_PROJECT` | Standard Git-projektsökväg |

### 2. Starta Flutter-appen

```bash
cd superdock_ui
flutter pub get
flutter run -d macos
```

Appen kan **auto-starta backenden** om den är offline (aktiveras i Settings). Systemdata pollas var 3:e sekund. Terminalen uppdateras via WebSocket (`/terminal/ws`).

> **Tips:** Starta om backenden efter koduppdateringar så att nya endpoints laddas.

## Settings (i appen)

| Inställning | Beskrivning |
|-------------|-------------|
| Backend URL | Standard `http://127.0.0.1:4545` |
| Backend core path | Sökväg till `superdock-core` (för auto-start) |
| Auto-start backend | Startar `node index.js` om backenden är offline |
| Flutter project path | Krävs för Flutter Run och Flutter Dev-workspace |
| Git project path | Krävs för Git Pull |

Inställningarna synkas till backendens `/config` vid sparning.

## API

| Metod | Endpoint | Beskrivning |
|-------|----------|-------------|
| `GET` | `/status` | Hostname, plattform |
| `GET` | `/system` | CPU, minne, disk, uptime, sparklines |
| `GET` | `/processes` | Spårade aktiva appar |
| `GET` | `/processes/all` | Alla GUI-processer |
| `GET` | `/actions` | Quick Actions |
| `GET` | `/history` | Senaste actions (`?limit=10`) |
| `GET` | `/terminal` | Terminaloutput |
| `WS` | `/terminal/ws` | Live terminalstream |
| `GET` | `/workspaces` | Workspaces |
| `POST` | `/workspaces` | Skapa workspace |
| `PUT` | `/workspaces/:id` | Uppdatera workspace |
| `DELETE` | `/workspaces/:id` | Ta bort workspace |
| `GET` | `/config` | Backend-konfiguration |
| `PUT` | `/config` | Uppdatera config |
| `POST` | `/run` | Kör action |

### Actions (`POST /run`)

```json
{ "action": "run_dock_action", "payload": { "id": "vscode" } }
```

```json
{ "action": "launch_workspace", "payload": { "id": "flutter-dev" } }
```

```json
{ "action": "open_app", "payload": { "name": "Visual Studio Code" } }
```

```json
{ "action": "shell", "payload": { "cmd": "git pull", "cwd": "/path/to/repo" } }
```

### Config (`PUT /config`)

```json
{
  "flutterProjectPath": "/Users/you/projects/my_flutter_app",
  "gitProjectPath": "/Users/you/projects/my_repo"
}
```

## Funktioner

- **Dashboard** — Quick Actions, workspaces, recent actions, terminal
- **Workspaces-vy** — fokus på workspaces + terminal
- **Actions-vy** — fokus på Quick Actions + historik
- **Quick Actions** — hämtas från backend (`GET /actions`)
- **Workspaces** — skapa via `+ New Workspace`, redigera/radera med **long-press**
- **System Overview** — live CPU, minne, disk med sparklines
- **Active Processes** — "View all processes" visar alla GUI-appar
- **Terminal** — WebSocket-stream vid shell-körning
- **Tangentbordsgenvägar** — ⌘1–⌘4 för de första workspaces

### Standard-workspaces

| ID | Namn |
|----|------|
| `flutter-dev` | Flutter Dev |
| `ai-mode` | AI Mode |
| `server-mode` | Server Mode |
| `design-mode` | Design Mode |

## Utveckling

Backenden är byggd för macOS och använder `open`, `osascript`, `pgrep`, `top`, `vm_stat` och `docker`.

Flutter kommunicerar via `SuperDockApi` i `superdock_ui/lib/core/services/api.dart`.

Quick Actions konfigureras i `superdock-core/src/dock_actions.js`. Workspaces kan ändras i UI:t eller direkt i den sparade datan under `~/.superdock/data.json`.
