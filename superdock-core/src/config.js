const store = require("./store");

function getConfig() {
  return { ...store.getData().config };
}

function setConfig(updates) {
  store.update((data) => {
    if ("flutterProjectPath" in updates) {
      const value = updates.flutterProjectPath;
      data.config.flutterProjectPath =
        typeof value === "string" && value.trim() ? value.trim() : null;
    }
    if ("gitProjectPath" in updates) {
      const value = updates.gitProjectPath;
      data.config.gitProjectPath =
        typeof value === "string" && value.trim() ? value.trim() : null;
    }
    if ("flutterDeviceId" in updates) {
      const value = updates.flutterDeviceId;
      data.config.flutterDeviceId =
        typeof value === "string" && value.trim() ? value.trim() : null;
    }
    if ("activeWorkspaceId" in updates) {
      const value = updates.activeWorkspaceId;
      data.config.activeWorkspaceId =
        typeof value === "string" && value.trim() ? value.trim() : null;
    }
  });
  return getConfig();
}

function getFlutterProjectPath() {
  return store.getData().config.flutterProjectPath;
}

function getGitProjectPath() {
  return store.getData().config.gitProjectPath;
}

function getFlutterDeviceId() {
  return store.getData().config.flutterDeviceId;
}

function getActiveWorkspaceId() {
  return store.getData().config.activeWorkspaceId;
}

module.exports = {
  getConfig,
  setConfig,
  getFlutterProjectPath,
  getGitProjectPath,
  getFlutterDeviceId,
  getActiveWorkspaceId,
};
