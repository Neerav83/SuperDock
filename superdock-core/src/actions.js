const { exec, spawn } = require("child_process");
const { promisify } = require("util");
const history = require("./history");
const terminal = require("./terminal");
const workspaces = require("./workspaces");
const { getProcessName } = require("./processes");

const execAsync = promisify(exec);

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

async function runShell(cmd, cwd) {
  terminal.setLive(true);
  terminal.append(`> ${cmd}`);

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
  });
}

async function launchWorkspace(id) {
  const definition = workspaces.getWorkspaceDefinition(id);
  if (!definition) {
    throw new Error(`Unknown workspace: ${id}`);
  }

  terminal.append(`> Launching workspace: ${definition.name}`);

  for (const rawAction of definition.actions) {
    const action = workspaces.resolveAction(rawAction);
    if (action.type === "open_app") {
      await openApp(action.name);
    } else if (action.type === "shell") {
      await runShell(action.cmd, action.cwd);
    }
  }

  history.addEntry(`Launched ${definition.name}`);
  return { ok: true, workspace: definition.name };
}

async function runAction(action, payload = {}) {
  switch (action) {
    case "open_app":
      await openApp(payload.name);
      return { ok: true };

    case "shell":
      await runShell(payload.cmd, payload.cwd);
      return { ok: true };

    case "launch_workspace":
      return launchWorkspace(payload.id);

    default:
      throw new Error(`Unknown action: ${action}`);
  }
}

module.exports = { runAction };
