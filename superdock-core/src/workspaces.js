const config = require("./config");

const WORKSPACES = {
  "flutter-dev": {
    id: "flutter-dev",
    name: "Flutter Dev",
    description: "VS Code, Simulator, Flutter run",
    shortcut: "⌘1",
    actions: [
      { type: "open_app", name: "Visual Studio Code" },
      { type: "open_app", name: "Simulator" },
      { type: "shell", cmd: "flutter run", useFlutterProject: true },
    ],
  },
  "ai-mode": {
    id: "ai-mode",
    name: "AI Mode",
    description: "Cursor, Claude, Terminal",
    shortcut: "⌘2",
    actions: [
      { type: "open_app", name: "Cursor" },
      { type: "open_app", name: "Claude" },
      { type: "open_app", name: "Terminal" },
    ],
  },
  "server-mode": {
    id: "server-mode",
    name: "Server Mode",
    description: "Docker, Terminal, Docker logs",
    shortcut: "⌘3",
    actions: [
      { type: "open_app", name: "Docker" },
      { type: "open_app", name: "Terminal" },
      {
        type: "shell",
        cmd: "docker compose logs --tail=30 2>/dev/null || docker ps",
      },
    ],
  },
  "design-mode": {
    id: "design-mode",
    name: "Design Mode",
    description: "Figma, Safari, Preview",
    shortcut: "⌘4",
    actions: [
      { type: "open_app", name: "Figma" },
      { type: "open_app", name: "Safari" },
      { type: "open_app", name: "Preview" },
    ],
  },
};

function resolveAction(action) {
  if (action.type === "shell" && action.useFlutterProject) {
    const cwd = config.getFlutterProjectPath();
    if (!cwd) {
      throw new Error(
        "Flutter project path is not configured. Set it in Settings.",
      );
    }
    return { type: "shell", cmd: action.cmd, cwd };
  }

  return action;
}

function getWorkspaceDefinition(id) {
  return WORKSPACES[id] || null;
}

function getWorkspace(id) {
  const workspace = getWorkspaceDefinition(id);
  if (!workspace) return null;

  return {
    ...workspace,
    actions: workspace.actions.map(resolveAction),
  };
}

function listWorkspaces() {
  return Object.values(WORKSPACES).map(
    ({ id, name, description, shortcut }) => ({
      id,
      name,
      description,
      shortcut,
    }),
  );
}

module.exports = {
  getWorkspace,
  getWorkspaceDefinition,
  listWorkspaces,
  resolveAction,
};
