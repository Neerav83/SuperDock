const { exec, spawn } = require("child_process");
const { promisify } = require("util");
const history = require("./history");
const terminal = require("./terminal");
const workspaces = require("./workspaces");

const execAsync = promisify(exec);

function shellEscape(value) {
  return `'${value.replace(/'/g, "'\\''")}'`;
}

async function openApp(name) {
  await execAsync(`open -a ${shellEscape(name)}`);
  history.addEntry(`Opened ${name}`);
  terminal.append(`> open -a "${name}"`);
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
  const workspace = workspaces.getWorkspace(id);
  if (!workspace) {
    throw new Error(`Unknown workspace: ${id}`);
  }

  terminal.append(`> Launching workspace: ${workspace.name}`);

  for (const action of workspace.actions) {
    if (action.type === "open_app") {
      await openApp(action.name);
    } else if (action.type === "shell") {
      await runShell(action.cmd, action.cwd);
    }
  }

  history.addEntry(`Launched ${workspace.name}`);
  return { ok: true, workspace: workspace.name };
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
