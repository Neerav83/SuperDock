const store = require("./store");

const MAX_ENTRIES = 50;

function addEntry(label, success = true) {
  store.update((data) => {
    data.history.unshift({
      label,
      success,
      timestamp: new Date().toISOString(),
    });
    if (data.history.length > MAX_ENTRIES) {
      data.history.length = MAX_ENTRIES;
    }
  });
}

function formatRelative(isoString) {
  const diffMs = Date.now() - new Date(isoString).getTime();
  const seconds = Math.floor(diffMs / 1000);

  if (seconds < 60) return `${seconds}s ago`;
  const minutes = Math.floor(seconds / 60);
  if (minutes < 60) return `${minutes}m ago`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours}h ago`;
  const days = Math.floor(hours / 24);
  return `${days}d ago`;
}

function getHistory(limit = 10) {
  return store.getData().history.slice(0, limit).map((entry) => ({
    label: entry.label,
    success: entry.success,
    timestamp: entry.timestamp,
    relative: formatRelative(entry.timestamp),
  }));
}

module.exports = { addEntry, getHistory };
