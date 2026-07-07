const { execFile } = require("child_process");
const { promisify } = require("util");

const execFileAsync = promisify(execFile);

function isFlutterRunCommand(cmd) {
  return /^\s*flutter\s+run\b/.test(cmd);
}

function normalizeDevice(device) {
  return {
    id: device.id,
    name: device.name,
    platform: device.targetPlatform,
    emulator: device.emulator === true,
    sdk: device.sdk || null,
  };
}

function buildFlutterRunCommand(cmd, deviceId) {
  if (!deviceId) return cmd;
  if (/\s-d\s/.test(cmd) || /--device-id=/.test(cmd)) return cmd;

  const parts = cmd.trim().split(/\s+/);
  const runIndex = parts.indexOf("run");
  if (runIndex >= 0) {
    parts.splice(runIndex + 1, 0, "-d", deviceId);
    return parts.join(" ");
  }

  return `${cmd} -d ${deviceId}`;
}

async function listDevices(cwd) {
  try {
    const { stdout } = await execFileAsync("flutter", ["devices", "--machine"], {
      cwd,
      env: process.env,
      maxBuffer: 10 * 1024 * 1024,
      timeout: 60000,
    });

    const trimmed = stdout.trim();
    if (!trimmed) return [];

    const devices = JSON.parse(trimmed);
    if (!Array.isArray(devices)) return [];

    return devices.filter((device) => device.isSupported !== false);
  } catch (err) {
    throw new Error(`Could not list Flutter devices: ${err.message}`);
  }
}

module.exports = {
  isFlutterRunCommand,
  normalizeDevice,
  buildFlutterRunCommand,
  listDevices,
};
