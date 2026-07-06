const WORKSPACES = {
  "flutter-dev": {
    id: "flutter-dev",
    name: "Flutter Dev",
    actions: [
      { type: "open_app", name: "Visual Studio Code" },
      { type: "open_app", name: "Simulator" },
    ],
  },
  "ai-mode": {
    id: "ai-mode",
    name: "AI Mode",
    actions: [
      { type: "open_app", name: "Cursor" },
      { type: "open_app", name: "Terminal" },
    ],
  },
  "server-mode": {
    id: "server-mode",
    name: "Server Mode",
    actions: [
      { type: "open_app", name: "Docker" },
      { type: "open_app", name: "Terminal" },
    ],
  },
  "design-mode": {
    id: "design-mode",
    name: "Design Mode",
    actions: [
      { type: "open_app", name: "Figma" },
      { type: "open_app", name: "Safari" },
    ],
  },
};

function getWorkspace(id) {
  return WORKSPACES[id] || null;
}

function listWorkspaces() {
  return Object.values(WORKSPACES);
}

module.exports = { getWorkspace, listWorkspaces };
