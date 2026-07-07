const { exec, spawn } = require("child_process");
const { promisify } = require("util");
const history = require("./history");
const terminal = require("./terminal");
const workspaces = require("./workspaces");
const dockActions = require("./dock_actions");
const config = require("./config");
const flutter = require("./flutter");
const { getProcessName } = require("./processes");

const execAsync = promisify(exec);

let activeShellProcesses = 0;

function shellEscape(value) {
  return `'${value.replace(/'/g, "'\\''")}'`;
}

function appleScriptEscape(value) {
  return value.replace(/\\/g, "\\\\").replace(/"/g, '\\"');
}

async function activateApp(name) {
  const processName = getProcessName(name);
  const appLiteral = appleScriptEscape(name);
  const processLiteral = appleScriptEscape(processName);

  const script = [
    `tell application "${appLiteral}" to activate`,
    'tell application "System Events"',
    `  if exists process "${processLiteral}" then`,
    `    tell process "${processLiteral}"`,
    "      set frontmost to true",
    "      repeat with w in windows",
    '        try',
    '          if value of attribute "AXMinimized" of w is true then',
    '            set value of attribute "AXMinimized" of w to false',
    "          end if",
    "        end try",
    "      end repeat",
    "    end tell",
    "  end if",
    "end tell",
  ].join("\n");

  await execAsync(`osascript -e ${shellEscape(script)}`);
}

async function openApp(name) {
  try {
    await activateApp(name);
    history.addEntry(`Activated ${name}`);
    terminal.append(`> activate "${name}"`);
  } catch {
    await execAsync(`open -a ${shellEscape(name)}`);
    history.addEntry(`Opened ${name}`);
    terminal.append(`> open -a "${name}"`);
  }
}

function attachShellChild(child, cmd) {
  activeShellProcesses++;
  terminal.setLive(true);

  child.stdout.on("data", (data) => terminal.appendChunk(data));
  child.stderr.on("data", (data) => terminal.appendChunk(data));

  const onFinished = (success) => {
    activeShellProcesses = Math.max(0, activeShellProcesses - 1);
    if (activeShellProcesses === 0) {
      terminal.setLive(false);
    }
    history.addEntry(success ? `Ran: ${cmd}` : `Failed: ${cmd}`, success);
  };

  child.on("close", (code) => onFinished(code === 0));
  child.on("error", () => onFinished(false));
}

function createMultipleDevicesError(devices) {
  const names = devices.map((device) => device.name).join(", ");
  const err = new Error(
    `More than one device is connected (${names}). Please specify a device.`,
  );
  err.code = "MULTIPLE_FLUTTER_DEVICES";
  err.devices = devices.map(flutter.normalizeDevice);
  return err;
}

async function resolveShellAction(action, options = {}) {
  if (action.type !== "shell" || !flutter.isFlutterRunCommand(action.cmd)) {
    return action;
  }

  if (options.deviceId) {
    return {
      ...action,
      cmd: flutter.buildFlutterRunCommand(action.cmd, options.deviceId),
    };
  }

  const devices = await flutter.listDevices(action.cwd);
  if (devices.length === 0) {
    throw new Error(
      "No Flutter devices found. Connect a device or start a simulator.",
    );
  }

  let deviceId = options.deviceId || config.getFlutterDeviceId();
  if (deviceId && !devices.some((device) => device.id === deviceId)) {
    deviceId = null;
  }

  if (!deviceId) {
    if (devices.length === 1) {
      deviceId = devices[0].id;
    } else {
      throw createMultipleDevicesError(devices);
    }
  }

  return {
    ...action,
    cmd: flutter.buildFlutterRunCommand(action.cmd, deviceId),
  };
}

async function runShell(cmd, cwd, options = {}) {
  const background = options.background !== false;
  terminal.append(cwd ? `> cd ${cwd} && ${cmd}` : `> ${cmd}`);

  if (background) {
    return new Promise((resolve) => {
      const child = spawn("sh", ["-c", cmd], {
        cwd: cwd || process.env.HOME,
        env: process.env,
      });

      attachShellChild(child, cmd);
      history.addEntry(`Started: ${cmd}`, true);
      resolve({ ok: true, background: true });
    });
  }

  return new Promise((resolve, reject) => {
    const child = spawn("sh", ["-c", cmd], {
      cwd: cwd || process.env.HOME,
      env: process.env,
    });

    child.stdout.on("data", (data) => terminal.appendChunk(data));
    child.stderr.on("data", (data) => terminal.appendChunk(data));

    child.on("close", (code) => {
      terminal.setLive(false);
      const label = code === 0 ? `Ran: ${cmd}` : `Failed: ${cmd}`;
      history.addEntry(label, code === 0);

      if (code === 0) {
        resolve({ ok: true });
      } else {
        reject(new Error(`Command exited with code ${code}`));
      }
    });

    child.on("error", (err) => {
      terminal.setLive(false);
      history.addEntry(`Failed: ${cmd}`, false);
      reject(err);
    });

    terminal.setLive(true);
  });
}

async function launchWorkspace(id, options = {}) {
  const definition = workspaces.getWorkspaceDefinition(id);
  if (!definition) {
    throw new Error(`Unknown workspace: ${id}`);
  }

  terminal.append(`> Launching workspace: ${definition.name}`);

  for (const rawAction of definition.actions) {
    const action = dockActions.resolveAction(rawAction);
    if (action.type === "open_app") {
      await openApp(action.name);
    } else if (action.type === "shell") {
      const resolved = await resolveShellAction(action, options);
      await runShell(resolved.cmd, resolved.cwd);
    }
  }

  history.addEntry(`Launched ${definition.name}`);
  return { ok: true, workspace: definition.name };
}

async function runDockAction(id, options = {}) {
  const action = dockActions.getActionById(id);
  if (!action) {
    throw new Error(`Unknown action: ${id}`);
  }

  if (action.type === "open_app") {
    await openApp(action.appName);
    return { ok: true };
  }

  if (action.type === "shell") {
    const resolved = await resolveShellAction(
      dockActions.resolveAction(action),
      options,
    );
    await runShell(resolved.cmd, resolved.cwd);
    return { ok: true };
  }

  throw new Error(`Unsupported action type: ${action.type}`);
}

async function runAction(action, payload = {}) {
  switch (action) {
    case "open_app":
      await openApp(payload.name);
      return { ok: true };

    case "shell":
      await runShell(payload.cmd, payload.cwd, {
        background: payload.background !== false,
      });
      return { ok: true };

    case "launch_workspace":
      return launchWorkspace(payload.id, { deviceId: payload.deviceId });

    case "run_dock_action":
      return runDockAction(payload.id, { deviceId: payload.deviceId });

    default:
      throw new Error(`Unknown action: ${action}`);
  }
}

module.exports = { runAction };
