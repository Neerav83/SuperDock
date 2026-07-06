let flutterProjectPath = process.env.SUPERDOCK_FLUTTER_PROJECT || null;

function getConfig() {
  return { flutterProjectPath };
}

function setConfig(updates) {
  if ("flutterProjectPath" in updates) {
    const value = updates.flutterProjectPath;
    flutterProjectPath =
      typeof value === "string" && value.trim() ? value.trim() : null;
  }
  return getConfig();
}

function getFlutterProjectPath() {
  return flutterProjectPath;
}

module.exports = { getConfig, setConfig, getFlutterProjectPath };
