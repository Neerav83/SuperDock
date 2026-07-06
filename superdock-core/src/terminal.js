const MAX_LINES = 200;

const lines = [
  "> SuperDock Core ready",
  "Waiting for commands...",
];

let live = false;

function append(line) {
  lines.push(line);
  if (lines.length > MAX_LINES) {
    lines.splice(0, lines.length - MAX_LINES);
  }
}

function appendChunk(chunk) {
  const parts = chunk
    .toString()
    .split(/\r?\n/)
    .filter((line) => line.length > 0);

  for (const part of parts) {
    append(part);
  }
}

function setLive(value) {
  live = value;
}

function getOutput() {
  return { live, lines: [...lines] };
}

function clear() {
  lines.length = 0;
  append("> Terminal cleared");
}

module.exports = { append, appendChunk, setLive, getOutput, clear };
