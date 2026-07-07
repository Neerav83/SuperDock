const { exec, spawn } = require("child_process");
const { promisify } = require("util");
const fs = require("fs");
const history = require("./history");
const terminal = require("./terminal");
const workspaces = require("./workspaces");
const dockActions = require("./dock_actions");
const config = require("./config");
const flutter = require("./flutter");
const { getProcessName } = require("./processes");

const execAsync = promisify(exec);

let activeShellProcesses = 0;

const APP_LAUNCH_ALIASES = {
  "Visual Studio Code": ["Visual Studio Code", "Code"],
};

const IDE_LAUNCHERS = {
  "Visual Studio Code": { cli: "code", aliases: ["Visual Studio Code", "Code"] },
  Cursor: { cli: "cursor", aliases: ["Cursor"] },
};

function shellEscape(value) {
  return `'${value.replace(/'/g, "'\\''")}'`;
}

function appleScriptEscape(value) {
  return value.replace(/\\/g, "\\\\").replace(/"/g, '\\"');
}

function execWithTimeout(command, timeoutMs = 5000) {
  return new Promise((resolve, reject) => {
    const child = exec(command, (error, stdout, stderr) => {
      if (error) reject(error);
      else resolve({ stdout, stderr });
    });

    const timer = setTimeout(() => {
      child.kill();
      reject(new Error(`Command timed out after ${timeoutMs}ms`));
    }, timeoutMs);

    child.on("exit", () => clearTimeout(timer));
  });
}

async function focusApp(name) {
  const appLiteral = appleScriptEscape(name);
  const processLiteral = appleScriptEscape(getProcessName(name));
  const script = [
    `tell application "${appLiteral}" to activate`,
    'tell application "System Events"',
    `  if exists process "${processLiteral}" then`,
    `    set frontmost of process "${processLiteral}" to true`,
    "  end if",
    "end tell",
  ].join("\n");

  await execWithTimeout(`osascript -e ${shellEscape(script)}`, 3000);
}

async function openApp(name, options = {}) {
  const projectPath = options.path?.trim() || null;
  const launcher = IDE_LAUNCHERS[name];
  const candidates = launcher?.aliases ?? APP_LAUNCH_ALIASES[name] ?? [name];

  if (projectPath && launcher && fs.existsSync(projectPath)) {
    terminal.append(`> open ${name} at ${projectPath}`);

    if (launcher.cli) {
      try {
        await execWithTimeout(`${launcher.cli} ${shellEscape(projectPath)}`, 8000);
        history.addEntry(`Opened ${name} at ${projectPath}`, true);
        setImmediate(() => {
          focusApp(name).catch(() => {});
        });
        return;
      } catch (_) {
        // Fall back to open -a below.
      }
    }

    let lastError = null;
    for (const candidate of candidates) {
      try {
        await execWithTimeout(
          `open -a ${shellEscape(candidate)} ${shellEscape(projectPath)}`,
          8000,
        );
        history.addEntry(`Opened ${name} at ${projectPath}`, true);
        setImmediate(() => {
          focusApp(name).catch(() => {});
        });
        return;
      } catch (err) {
        lastError = err;
      }
    }

    history.addEntry(`Failed to open ${name} at ${projectPath}`, false);
    throw lastError ?? new Error(`Could not open ${name} at ${projectPath}`);
  }

  terminal.append(`> open -a "${name}"`);

  let opened = false;
  let lastError = null;

  for (const candidate of candidates) {
    try {
      await execWithTimeout(`open -a ${shellEscape(candidate)}`, 5000);
      opened = true;
      break;
    } catch (err) {
      lastError = err;
    }
  }

  if (!opened) {
    history.addEntry(`Failed to open ${name}`, false);
    throw lastError ?? new Error(`Could not open ${name}`);
  }

  history.addEntry(`Opened ${name}`, true);

  setImmediate(() => {
    focusApp(name).catch(() => {});
  });
}

function defaultProjectPathForIde() {
  return (
    config.getFlutterProjectPath()?.trim() ||
    config.getGitProjectPath()?.trim() ||
    null
  );
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

  workspaces.applyWorkspaceContext(definition);
  const context = { projectPath: definition.projectPath?.trim() || null };

  terminal.append(`> Launching workspace: ${definition.name}`);

  for (const rawAction of definition.actions) {
    const action = dockActions.resolveAction(rawAction, context);
    if (action.type === "open_app") {
      await openApp(action.name, { path: context.projectPath });
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
    const path = IDE_LAUNCHERS[action.appName]
      ? defaultProjectPathForIde()
      : null;
    await openApp(action.appName, { path });
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
      await openApp(payload.name, { path: payload.path });
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
