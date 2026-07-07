const http = require("http");
const express = require("express");
const { WebSocketServer } = require("ws");
const store = require("./src/store");
const history = require("./src/history");
const terminal = require("./src/terminal");
const system = require("./src/system");
const processes = require("./src/processes");
const workspaces = require("./src/workspaces");
const dockActions = require("./src/dock_actions");
const config = require("./src/config");
const flutter = require("./src/flutter");
const { runAction } = require("./src/actions");

store.load();

const app = express();
const PORT = process.env.PORT || 4545;
const HOST = process.env.HOST || "127.0.0.1";

app.use(express.json());

app.get("/status", (_req, res) => {
  res.json(system.getStatus());
});

app.get("/meta", (_req, res) => {
  res.json({
    apiVersion: 4,
    backgroundShell: true,
    flutterDevices: true,
    workspaceProjectPath: true,
  });
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

app.get("/processes/all", async (_req, res) => {
  try {
    const list = await processes.getAllProcesses();
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

app.get("/actions", (_req, res) => {
  res.json(dockActions.listActions());
});

app.post("/actions", (req, res) => {
  try {
    res.status(201).json(dockActions.createAction(req.body || {}));
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

app.put("/actions/:id", (req, res) => {
  try {
    res.json(dockActions.updateAction(req.params.id, req.body || {}));
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

app.delete("/actions/:id", (req, res) => {
  try {
    res.json(dockActions.deleteAction(req.params.id));
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

app.get("/workspaces", (_req, res) => {
  res.json(workspaces.listWorkspaces());
});

app.post("/workspaces", (req, res) => {
  try {
    res.status(201).json(workspaces.createWorkspace(req.body || {}));
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

app.put("/workspaces/:id", (req, res) => {
  try {
    res.json(workspaces.updateWorkspace(req.params.id, req.body || {}));
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

app.delete("/workspaces/:id", (req, res) => {
  try {
    res.json(workspaces.deleteWorkspace(req.params.id));
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

app.get("/config", (_req, res) => {
  res.json(config.getConfig());
});

app.get("/flutter/devices", async (_req, res) => {
  try {
    const cwd = dockActions.requireFlutterProjectPath();
    const devices = await flutter.listDevices(cwd);
    res.json({
      devices: devices.map(flutter.normalizeDevice),
      preferredDeviceId: config.getFlutterDeviceId(),
    });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

app.post("/workspaces/:id/activate", (req, res) => {
  try {
    res.json(workspaces.activateWorkspace(req.params.id));
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
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
    if (err.code === "MULTIPLE_FLUTTER_DEVICES") {
      return res.status(409).json({
        error: err.message,
        code: err.code,
        devices: err.devices,
      });
    }
    res.status(500).json({ error: err.message });
  }
});

const server = http.createServer(app);

const wss = new WebSocketServer({ server, path: "/terminal/ws" });

terminal.setBroadcaster((output) => {
  const message = JSON.stringify(output);
  for (const client of wss.clients) {
    if (client.readyState === 1) {
      client.send(message);
    }
  }
});

wss.on("connection", (socket) => {
  socket.send(JSON.stringify(terminal.getOutput()));
});

server.listen(PORT, HOST, () => {
  console.log(`SuperDock Core running on http://${HOST}:${PORT}`);
});
