# SuperDock

En macOS command center för utvecklare. SuperDock kombinerar en Flutter-dashboard med en lokal Node.js-backend som kan öppna appar, köra shell-kommandon, starta workspaces och visa systemstatus i realtid.

## Projektstruktur

```
superdock/
├── superdock-core/     # Node.js-backend (port 4545)
└── superdock_ui/       # Flutter-app (macOS)
```

### Backend (`superdock-core`)

```
superdock-core/
├── index.js
└── src/
    ├── actions.js      # open_app, shell, launch_workspace
    ├── history.js      # Action-logg
    ├── terminal.js     # Terminaloutput
    ├── system.js       # CPU, minne, disk, uptime
    ├── processes.js    # Aktiva appar
    └── workspaces.js   # Workspace-definitioner
```

### Flutter (`superdock_ui`)

```
superdock_ui/lib/
├── main.dart
├── app.dart
├── core/
│   ├── theme/
│   ├── models/
│   └── services/
├── widgets/
└── pages/
    └── dashboard_page.dart
```

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

Backenden körs på `http://localhost:4545`.

### 2. Starta Flutter-appen

```bash
cd superdock_ui
flutter pub get
flutter run -d macos
```

Appen pollar backenden var 3:e sekund. Om backenden inte är igång visas "Offline" i topbaren.

## API

| Metod | Endpoint | Beskrivning |
|-------|----------|-------------|
| `GET` | `/status` | Hostname, plattform, anslutningsstatus |
| `GET` | `/system` | CPU, minne, disk, uptime och sparklines |
| `GET` | `/processes` | Aktiva appar (Docker, Cursor, VS Code, Terminal) |
| `GET` | `/history` | Senaste actions (`?limit=10`) |
| `GET` | `/terminal` | Terminaloutput (live vid shell-kommandon) |
| `GET` | `/workspaces` | Tillgängliga workspaces |
| `POST` | `/run` | Kör en action |

### Actions (`POST /run`)

```json
{ "action": "open_app", "payload": { "name": "Visual Studio Code" } }
```

```json
{ "action": "shell", "payload": { "cmd": "git pull" } }
```

```json
{ "action": "launch_workspace", "payload": { "id": "flutter-dev" } }
```

Tillgängliga workspace-id:n: `flutter-dev`, `ai-mode`, `server-mode`, `design-mode`.

## Funktioner

- **Quick Actions** — öppna appar eller kör shell-kommandon med ett klick
- **Workspaces** — starta fördefinierade uppsättningar av appar
- **System Overview** — live CPU, minne och disk med sparklines
- **Active Processes** — visar vilka appar som körs just nu
- **Recent Actions** — logg över senaste kommandon
- **Terminal Output** — stdout/stderr från shell-kommandon i realtid

## Utveckling

Backenden är byggd för macOS och använder `open`, `pgrep`, `top`, `vm_stat` och `docker` för systemintegration.

Flutter-appen kommunicerar med backenden via `SuperDockApi` i `superdock_ui/lib/core/services/api.dart`. API-URL:en är `http://localhost:4545` som standard.
