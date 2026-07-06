const store = require("./store");
const { DEFAULT_WORKSPACES } = require("./dock_actions");
const { resolveAction } = require("./dock_actions");

function slugify(value) {
  return value
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

function getWorkspaceMap() {
  const stored = store.getData().workspaces;
  return stored ?? DEFAULT_WORKSPACES;
}

function saveWorkspaceMap(map) {
  store.update((data) => {
    data.workspaces = map;
  });
}

function getWorkspaceDefinition(id) {
  const map = getWorkspaceMap();
  return map[id] || null;
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
  return Object.values(getWorkspaceMap()).map(
    ({ id, name, description, shortcut, icon, accentColor, actions }) => ({
      id,
      name,
      description,
      shortcut,
      icon,
      accentColor,
      actions,
    }),
  );
}

function createWorkspace(payload) {
  const map = { ...getWorkspaceMap() };
  const id = payload.id?.trim() || slugify(payload.name || "workspace");

  if (!payload.name?.trim()) {
    throw new Error("Workspace name is required");
  }
  if (map[id]) {
    throw new Error(`Workspace "${id}" already exists`);
  }

  map[id] = {
    id,
    name: payload.name.trim(),
    description: payload.description?.trim() || "",
    shortcut: payload.shortcut?.trim() || null,
    icon: payload.icon || "grid_view",
    accentColor: payload.accentColor || "#3B82F6",
    actions: Array.isArray(payload.actions) ? payload.actions : [],
  };

  saveWorkspaceMap(map);
  return map[id];
}

function updateWorkspace(id, payload) {
  const map = { ...getWorkspaceMap() };
  const existing = map[id];
  if (!existing) {
    throw new Error(`Unknown workspace: ${id}`);
  }

  map[id] = {
    ...existing,
    name: payload.name?.trim() || existing.name,
    description:
      payload.description !== undefined
        ? payload.description.trim()
        : existing.description,
    shortcut:
      payload.shortcut !== undefined ? payload.shortcut?.trim() || null : existing.shortcut,
    icon: payload.icon || existing.icon,
    accentColor: payload.accentColor || existing.accentColor,
    actions: Array.isArray(payload.actions) ? payload.actions : existing.actions,
  };

  saveWorkspaceMap(map);
  return map[id];
}

function deleteWorkspace(id) {
  const map = { ...getWorkspaceMap() };
  if (!map[id]) {
    throw new Error(`Unknown workspace: ${id}`);
  }
  delete map[id];
  saveWorkspaceMap(map);
  return { ok: true };
}

module.exports = {
  getWorkspace,
  getWorkspaceDefinition,
  listWorkspaces,
  createWorkspace,
  updateWorkspace,
  deleteWorkspace,
  resolveAction,
};
