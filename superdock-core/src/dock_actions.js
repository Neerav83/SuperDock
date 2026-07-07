const store = require("./store");
const config = require("./config");
const fs = require("fs");
const path = require("path");

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
    projectPath: null,
    actions: [
      { type: "open_app", name: "Visual Studio Code" },
      { type: "open_app", name: "Simulator" },
      { type: "shell", cmd: "flutter run", usesFlutterProject: true },
    ],
  },
  "ai-mode": {
    id: "ai-mode",
    name: "AI Mode",
    description: "Cursor, Claude, Terminal",
    shortcut: "⌘2",
    icon: "auto_awesome",
    accentColor: "#A855F7",
    projectPath: null,
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
    projectPath: null,
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
    projectPath: null,
    actions: [
      { type: "open_app", name: "Figma" },
      { type: "open_app", name: "Safari" },
      { type: "open_app", name: "Preview" },
    ],
  },
};

function slugify(value) {
  return value
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

function getActionsMap() {
  const stored = store.getData().actions;
  if (!stored) return null;
  return stored;
}

function saveActionsMap(map) {
  store.update((data) => {
    data.actions = map;
  });
}

function listActions() {
  const stored = getActionsMap();
  if (!stored) return DEFAULT_ACTIONS;
  return Object.values(stored);
}

function createAction(payload) {
  let map = getActionsMap();
  if (!map) {
    map = {};
    for (const action of DEFAULT_ACTIONS) {
      map[action.id] = action;
    }
  } else {
    map = { ...map };
  }

  const id = payload.id?.trim() || slugify(payload.title || "action");

  if (!payload.title?.trim()) {
    throw new Error("Action title is required");
  }
  if (map[id]) {
    throw new Error(`Action "${id}" already exists`);
  }

  if (!payload.type || !["open_app", "shell"].includes(payload.type)) {
    throw new Error("Action type must be 'open_app' or 'shell'");
  }

  if (payload.type === "open_app" && !payload.appName?.trim()) {
    throw new Error("App name is required for open_app action");
  }

  if (payload.type === "shell" && !payload.cmd?.trim()) {
    throw new Error("Command is required for shell action");
  }

  const action = {
    id,
    title: payload.title.trim(),
    icon: payload.icon || "extension",
    accentColor: payload.accentColor || "#3B82F6",
    status: payload.status?.trim() || "Run",
    type: payload.type,
  };

  if (payload.type === "open_app") {
    action.appName = payload.appName.trim();
  } else if (payload.type === "shell") {
    action.cmd = payload.cmd.trim();
    if (payload.usesFlutterProject) {
      action.usesFlutterProject = true;
    }
    if (payload.usesGitProject) {
      action.usesGitProject = true;
    }
    if (payload.cwd?.trim()) {
      action.cwd = payload.cwd.trim();
    }
  }

  map[id] = action;
  saveActionsMap(map);
  return action;
}

function updateAction(id, payload) {
  let map = getActionsMap();
  if (!map) {
    map = {};
    for (const action of DEFAULT_ACTIONS) {
      map[action.id] = action;
    }
  } else {
    map = { ...map };
  }

  const existing = map[id];
  if (!existing) {
    throw new Error(`Unknown action: ${id}`);
  }

  const isDefault = DEFAULT_ACTIONS.some((a) => a.id === id);
  if (isDefault) {
    throw new Error("Cannot modify default actions");
  }

  const updated = {
    ...existing,
    title: payload.title?.trim() || existing.title,
    icon: payload.icon || existing.icon,
    accentColor: payload.accentColor || existing.accentColor,
    status: payload.status?.trim() || existing.status,
  };

  if (payload.type === "open_app" && payload.appName?.trim()) {
    updated.appName = payload.appName.trim();
  } else if (payload.type === "shell") {
    if (payload.cmd?.trim()) {
      updated.cmd = payload.cmd.trim();
    }
    if ("usesFlutterProject" in payload) {
      updated.usesFlutterProject = payload.usesFlutterProject;
    }
    if ("usesGitProject" in payload) {
      updated.usesGitProject = payload.usesGitProject;
    }
    if ("cwd" in payload) {
      updated.cwd = payload.cwd?.trim() || undefined;
    }
  }

  map[id] = updated;
  saveActionsMap(map);
  return updated;
}

function deleteAction(id) {
  let map = getActionsMap();
  if (!map) {
    map = {};
    for (const action of DEFAULT_ACTIONS) {
      map[action.id] = action;
    }
  } else {
    map = { ...map };
  }

  if (!map[id]) {
    throw new Error(`Unknown action: ${id}`);
  }

  const isDefault = DEFAULT_ACTIONS.some((a) => a.id === id);
  if (isDefault) {
    throw new Error("Cannot delete default actions");
  }

  delete map[id];
  saveActionsMap(map);
  return { ok: true };
}

function usesFlutterProject(action) {
  return action.usesFlutterProject === true || action.useFlutterProject === true;
}

function usesGitProject(action) {
  return action.usesGitProject === true || action.useGitProject === true;
}

function requireFlutterProjectPath() {
  const cwd = config.getFlutterProjectPath();
  if (!cwd) {
    throw new Error(
      "Flutter project path is not configured. Set it in Settings.",
    );
  }
  if (!fs.existsSync(cwd)) {
    throw new Error(`Flutter project path does not exist: ${cwd}`);
  }
  const pubspec = path.join(cwd, "pubspec.yaml");
  if (!fs.existsSync(pubspec)) {
    throw new Error(`No pubspec.yaml found in ${cwd}`);
  }
  return cwd;
}

function requireGitProjectPath() {
  const cwd = config.getGitProjectPath();
  if (!cwd) {
    throw new Error("Git project path is not configured. Set it in Settings.");
  }
  if (!fs.existsSync(cwd)) {
    throw new Error(`Git project path does not exist: ${cwd}`);
  }
  return cwd;
}

function requireProjectPath(projectPath, kind) {
  const cwd = projectPath?.trim();
  if (!cwd) {
    throw new Error("Workspace project path is not configured.");
  }
  if (!fs.existsSync(cwd)) {
    throw new Error(`Workspace project path does not exist: ${cwd}`);
  }
  if (kind === "flutter") {
    const pubspec = path.join(cwd, "pubspec.yaml");
    if (!fs.existsSync(pubspec)) {
      throw new Error(`No pubspec.yaml found in ${cwd}`);
    }
  }
  return cwd;
}

function resolveAction(action, context = {}) {
  const workspacePath = context.projectPath?.trim() || null;

  if (action.type === "shell" && usesFlutterProject(action)) {
    const cwd = workspacePath
      ? requireProjectPath(workspacePath, "flutter")
      : requireFlutterProjectPath();
    return { type: "shell", cmd: action.cmd, cwd };
  }

  if (action.type === "shell" && usesGitProject(action)) {
    const cwd = workspacePath
      ? requireProjectPath(workspacePath, "git")
      : requireGitProjectPath();
    return { type: "shell", cmd: action.cmd, cwd };
  }

  if (action.type === "shell" && action.cwd) {
    return { type: "shell", cmd: action.cmd, cwd: action.cwd };
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
  createAction,
  updateAction,
  deleteAction,
  resolveAction,
  requireFlutterProjectPath,
  getActionById,
};
