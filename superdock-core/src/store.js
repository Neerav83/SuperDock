const fs = require("fs");
const path = require("path");
const os = require("os");

const DATA_DIR = path.join(os.homedir(), ".superdock");
const DATA_FILE = path.join(DATA_DIR, "data.json");

let data = null;
let saveTimer = null;

function ensureDir() {
  if (!fs.existsSync(DATA_DIR)) {
    fs.mkdirSync(DATA_DIR, { recursive: true });
  }
}

function defaultData() {
  return {
    config: {
      flutterProjectPath: process.env.SUPERDOCK_FLUTTER_PROJECT || null,
      gitProjectPath: process.env.SUPERDOCK_GIT_PROJECT || null,
      flutterDeviceId: null,
      activeWorkspaceId: null,
    },
    history: [],
    terminal: {
      lines: ["> SuperDock Core ready", "Waiting for commands..."],
      live: false,
    },
    workspaces: null,
    actions: null,
  };
}

function load() {
  ensureDir();
  if (!fs.existsSync(DATA_FILE)) {
    data = defaultData();
    flush();
    return data;
  }

  try {
    const raw = fs.readFileSync(DATA_FILE, "utf8");
    data = { ...defaultData(), ...JSON.parse(raw) };
  } catch {
    data = defaultData();
    flush();
  }

  return data;
}

function flush() {
  ensureDir();
  fs.writeFileSync(DATA_FILE, JSON.stringify(data, null, 2));
}

function scheduleSave() {
  if (saveTimer) clearTimeout(saveTimer);
  saveTimer = setTimeout(() => {
    saveTimer = null;
    flush();
  }, 200);
}

function getData() {
  if (!data) load();
  return data;
}

function update(mutator) {
  const current = getData();
  mutator(current);
  scheduleSave();
  return current;
}

module.exports = { getData, update, load, DATA_FILE };
