const { execFile } = require("child_process");
const { promisify } = require("util");

const execFileAsync = promisify(execFile);

const APP_PROCESS_NAMES = {
  "Visual Studio Code": "Code",
  Docker: "Docker",
  Cursor: "Cursor",
  Terminal: "Terminal",
  Figma: "Figma",
  Simulator: "Simulator",
  Xcode: "Xcode",
  Safari: "Safari",
};

const TRACKED_APPS = [
  { name: "Docker", processName: "Docker", detailFn: getDockerDetail },
  { name: "Cursor", processName: "Cursor", detailFn: () => "Active" },
  { name: "Visual Studio Code", processName: "Code", detailFn: () => "Active" },
  { name: "Terminal", processName: "Terminal", detailFn: getTerminalDetail },
];

function getProcessName(appName) {
  return APP_PROCESS_NAMES[appName] ?? appName;
}

async function isRunning(processName) {
  try {
    await execFileAsync("pgrep", ["-x", processName]);
    return true;
  } catch {
    return false;
  }
}

async function getDockerDetail() {
  try {
    const { stdout } = await execFileAsync("docker", ["ps", "-q"]);
    const count = stdout.trim() ? stdout.trim().split("\n").length : 0;
    return count === 1 ? "1 container" : `${count} containers`;
  } catch {
    return "Not running";
  }
}

async function getTerminalDetail() {
  try {
    const { stdout } = await execFileAsync("pgrep", ["-x", "Terminal"]);
    const count = stdout.trim() ? stdout.trim().split("\n").length : 0;
    return count === 1 ? "1 window" : `${count} windows`;
  } catch {
    return "Not running";
  }
}

async function getProcesses() {
  const results = await Promise.all(
    TRACKED_APPS.map(async (app) => {
      const running = await isRunning(app.processName);
      const detail = running ? await app.detailFn() : "Not running";
      return {
        name: app.name,
        detail,
        active: running,
      };
    }),
  );

  return results.filter((p) => p.active);
}

module.exports = { getProcesses, isRunning, getProcessName };
