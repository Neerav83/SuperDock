const store = require("./store");
const config = require("./config");

const DEFAULT_ACTIONS = [
  {
    id: "vscode",
    title: "VS Code",
    icon: "code",
    accentColor: "#3B82F6",
    status: "Open",
    type: "open_app",
    appName: "Visual Studio Code",
  },
  {
    id: "cursor",
    title: "Cursor",
    icon: "auto_awesome",
    accentColor: "#A855F7",
    status: "Open",
    type: "open_app",
    appName: "Cursor",
  },
  {
    id: "docker",
    title: "Docker",
    icon: "dns",
    accentColor: "#22D3EE",
    status: "Start",
    type: "open_app",
    appName: "Docker",
  },
  {
    id: "figma",
    title: "Figma",
    icon: "design_services",
    accentColor: "#F97316",
    status: "Open",
    type: "open_app",
    appName: "Figma",
  },
  {
    id: "terminal",
    title: "Terminal",
    icon: "terminal",
    accentColor: "#4ADE80",
    status: "Open",
    type: "open_app",
    appName: "Terminal",
  },
  {
    id: "flutter-run",
    title: "Flutter Run",
    icon: "play_arrow",
    accentColor: "#A855F7",
    status: "Run Project",
    type: "shell",
    cmd: "flutter run",
    usesFlutterProject: true,
  },
  {
    id: "git-pull",
    title: "Git Pull",
    icon: "download",
    accentColor: "#F97316",
    status: "Update",
    type: "shell",
    cmd: "git pull",
    usesGitProject: true,
  },
  {
    id: "simulator",
    title: "Simulator",
    icon: "phone_iphone",
    accentColor: "#3B82F6",
    status: "Open",
    type: "open_app",
    appName: "Simulator",
  },
  {
    id: "xcode",
    title: "Xcode",
    icon: "apple",
    accentColor: "#3B82F6",
    status: "Open",
    type: "open_app",
    appName: "Xcode",
  },
  {
    id: "safari",
    title: "Safari",
    icon: "language",
    accentColor: "#22D3EE",
    status: "Open",
    type: "open_app",
    appName: "Safari",
  },
];

const DEFAULT_WORKSPACES = {
  "flutter-dev": {
    id: "flutter-dev",
    name: "Flutter Dev",
    description: "VS Code, Simulator, Flutter run",
    shortcut: "⌘1",
    icon: "phone_iphone",
    accentColor: "#A855F7",
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
    icon: "auto_awesome",
    accentColor: "#A855F7",
    actions: [
      { type: "open_app", name: "Cursor" },
      { type: "open_app", name: "Terminal" },
    ],
  },
  "server-mode": {
    id: "server-mode",
    name: "Server Mode",
    description: "Docker, Terminal, Docker logs",
    shortcut: "⌘3",
    icon: "storage",
    accentColor: "#3B82F6",
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
    icon: "brush",
    accentColor: "#F97316",
    actions: [
      { type: "open_app", name: "Figma" },
      { type: "open_app", name: "Safari" },
      { type: "open_app", name: "Preview" },
    ],
  },
};

function listActions() {
  const stored = store.getData().actions;
  return stored ?? DEFAULT_ACTIONS;
}

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

  if (action.type === "shell" && action.useGitProject) {
    const cwd = config.getGitProjectPath();
    if (!cwd) {
      throw new Error("Git project path is not configured. Set it in Settings.");
    }
    return { type: "shell", cmd: action.cmd, cwd };
  }

  return action;
}

function getActionById(id) {
  return listActions().find((action) => action.id === id) || null;
}

module.exports = {
  DEFAULT_ACTIONS,
  DEFAULT_WORKSPACES,
  listActions,
  resolveAction,
  getActionById,
};
