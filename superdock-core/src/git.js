const { execFile } = require("child_process");
const { promisify } = require("util");
const fs = require("fs");
const path = require("path");

const execFileAsync = promisify(execFile);

function normalizeStatus(index, workTree) {
  if (index === "?" && workTree === "?") return "untracked";
  if (workTree === "D" || index === "D") return "deleted";
  if (workTree === "M" || index === "M") return "modified";
  if (index === "A") return "added";
  return "changed";
}

function canStage(index, workTree) {
  if (index === "!" || workTree === "!") return false;
  if (index === "?" && workTree === "?") return true;
  if (workTree === "M" || workTree === "D") return true;
  if (index === " " && workTree !== " ") return true;
  return false;
}

function parsePorcelainLine(line) {
  if (line.length < 4) return null;

  const index = line[0];
  const workTree = line[1];
  let filePath = line.slice(3);

  if (filePath.includes(" -> ")) {
    filePath = filePath.split(" -> ").pop();
  }

  if (!canStage(index, workTree)) return null;

  return {
    path: filePath.replace(/\/+$/, ""),
    status: normalizeStatus(index, workTree),
  };
}

function isDirectoryEntry(cwd, filePath) {
  if (!filePath || filePath.endsWith("/")) return true;

  try {
    return fs.statSync(path.join(cwd, filePath)).isDirectory();
  } catch {
    return false;
  }
}

async function listAddableFiles(cwd) {
  const projectPath = cwd?.trim();
  if (!projectPath) {
    throw new Error("Git project path is not configured.");
  }
  if (!fs.existsSync(projectPath)) {
    throw new Error(`Git project path does not exist: ${projectPath}`);
  }

  const { stdout } = await execFileAsync(
    "git",
    ["status", "--porcelain", "-uall"],
    {
      cwd: projectPath,
      maxBuffer: 10 * 1024 * 1024,
    },
  );

  const files = [];
  for (const line of stdout.split("\n")) {
    if (!line.trim()) continue;
    const parsed = parsePorcelainLine(line);
    if (!parsed || isDirectoryEntry(projectPath, parsed.path)) continue;
    files.push(parsed);
  }

  return files;
}

module.exports = {
  listAddableFiles,
};
