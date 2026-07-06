const store = require("./store");

const MAX_LINES = 200;

let broadcaster = null;

function setBroadcaster(fn) {
  broadcaster = fn;
}

function notify() {
  if (!broadcaster) return;
  broadcaster(getOutput());
}

function append(line) {
  store.update((data) => {
    data.terminal.lines.push(line);
    if (data.terminal.lines.length > MAX_LINES) {
      data.terminal.lines.splice(0, data.terminal.lines.length - MAX_LINES);
    }
  });
  notify();
}

function appendChunk(chunk) {
  const parts = chunk
    .toString()
    .split(/\r?\n/)
    .filter((line) => line.length > 0);

  if (parts.length === 0) return;

  store.update((data) => {
    for (const part of parts) {
      data.terminal.lines.push(part);
    }
    if (data.terminal.lines.length > MAX_LINES) {
      data.terminal.lines.splice(0, data.terminal.lines.length - MAX_LINES);
    }
  });
  notify();
}

function setLive(value) {
  store.update((data) => {
    data.terminal.live = value;
  });
  notify();
}

function getOutput() {
  const terminal = store.getData().terminal;
  return { live: terminal.live, lines: [...terminal.lines] };
}

function clear() {
  store.update((data) => {
    data.terminal.lines = ["> Terminal cleared"];
    data.terminal.live = false;
  });
  notify();
}

module.exports = {
  append,
  appendChunk,
  setLive,
  getOutput,
  clear,
  setBroadcaster,
};
