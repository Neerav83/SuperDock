const express = require("express");
const history = require("./src/history");
const terminal = require("./src/terminal");
const system = require("./src/system");
const processes = require("./src/processes");
const workspaces = require("./src/workspaces");
const config = require("./src/config");
const { runAction } = require("./src/actions");

const app = express();
const PORT = process.env.PORT || 4545;
const HOST = process.env.HOST || "127.0.0.1";

app.use(express.json());

app.get("/status", (_req, res) => {
  res.json(system.getStatus());
});

app.get("/system", async (_req, res) => {
  try {
    const stats = await system.getSystemStats();
    res.json(stats);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get("/processes", async (_req, res) => {
  try {
    const list = await processes.getProcesses();
    res.json(list);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get("/history", (_req, res) => {
  const limit = parseInt(_req.query.limit || "10", 10);
  res.json(history.getHistory(limit));
});

app.get("/terminal", (_req, res) => {
  res.json(terminal.getOutput());
});

app.get("/workspaces", (_req, res) => {
  res.json(workspaces.listWorkspaces());
});

app.get("/config", (_req, res) => {
  res.json(config.getConfig());
});

app.put("/config", (req, res) => {
  try {
    res.json(config.setConfig(req.body || {}));
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

app.post("/run", async (req, res) => {
  const { action, payload } = req.body;

  if (!action) {
    return res.status(400).json({ error: "Missing action" });
  }

  try {
    const result = await runAction(action, payload || {});
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.listen(PORT, HOST, () => {
  console.log(`SuperDock Core running on http://${HOST}:${PORT}`);
});
