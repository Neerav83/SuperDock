const os = require("os");
const { execFile } = require("child_process");
const { promisify } = require("util");

const execFileAsync = promisify(execFile);

const HISTORY_SIZE = 12;
const history = {
  cpu: [],
  memory: [],
  disk: [],
};

function pushHistory(key, value) {
  history[key].push(value);
  if (history[key].length > HISTORY_SIZE) {
    history[key].shift();
  }
}

function formatUptime(seconds) {
  const days = Math.floor(seconds / 86400);
  const hours = Math.floor((seconds % 86400) / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);

  const parts = [];
  if (days > 0) parts.push(`${days}d`);
  if (hours > 0) parts.push(`${hours}h`);
  parts.push(`${minutes}m`);
  return parts.join(" ");
}

async function getCpuUsage() {
  try {
    const { stdout } = await execFileAsync("top", ["-l", "1", "-s", "0", "-n", "0"]);
    const match = stdout.match(/CPU usage:\s+([\d.]+)% user,\s+([\d.]+)% sys,\s+([\d.]+)% idle/);
    if (match) {
      const user = parseFloat(match[1]);
      const sys = parseFloat(match[2]);
      return Math.round(user + sys);
    }
  } catch {
    // fall through
  }

  const [load] = os.loadavg();
  return Math.min(100, Math.round((load / os.cpus().length) * 100));
}

async function getMemoryUsage() {
  try {
    const { stdout } = await execFileAsync("vm_stat");
    const pageSize = 16384;
    const values = {};

    for (const line of stdout.split("\n")) {
      const match = line.match(/^\s*([^:]+):\s+(\d+)/);
      if (match) values[match[1].trim()] = parseInt(match[2], 10);
    }

    const used =
      (values["Pages active"] || 0) +
      (values["Pages wired down"] || 0) +
      (values["Pages occupied by compressor"] || 0);
    const total = os.totalmem() / pageSize;
    return Math.round((used / total) * 100);
  } catch {
    const used = os.totalmem() - os.freemem();
    return Math.round((used / os.totalmem()) * 100);
  }
}

async function getDiskUsage() {
  try {
    const { stdout } = await execFileAsync("df", ["-k", "/"]);
    const line = stdout.split("\n")[1];
    const parts = line.split(/\s+/);
    const used = parseInt(parts[2], 10);
    const total = parseInt(parts[1], 10);
    return Math.round((used / total) * 100);
  } catch {
    return 0;
  }
}

async function getSystemStats() {
  const [cpu, memory, disk] = await Promise.all([
    getCpuUsage(),
    getMemoryUsage(),
    getDiskUsage(),
  ]);

  pushHistory("cpu", cpu);
  pushHistory("memory", memory);
  pushHistory("disk", disk);

  return {
    cpu,
    memory,
    disk,
    uptime: formatUptime(os.uptime()),
    sparklines: {
      cpu: [...history.cpu],
      memory: [...history.memory],
      disk: [...history.disk],
    },
  };
}

function getStatus() {
  return {
    connected: true,
    hostname: os.hostname(),
    platform: os.platform(),
    arch: os.arch(),
  };
}

module.exports = { getSystemStats, getStatus };
