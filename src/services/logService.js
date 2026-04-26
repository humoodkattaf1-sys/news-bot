'use strict';

/**
 * Log Service — writes command logs to local JSON file.
 * Also attempts to sync to Google Sheets سجل_الأوامر when possible.
 */

const fs = require('fs');
const path = require('path');
const { generateUUID } = require('../utils/idGenerator');
const { nowTimestamp } = require('../utils/dateUtils');

const LOGS_FILE = path.join(__dirname, '../../data/commandLogs.json');
const MAX_LOCAL_LOGS = 500; // Keep last 500 entries in local file

// ── File helpers ────────────────────────────────────────────

function readLogs() {
  try {
    if (!fs.existsSync(LOGS_FILE)) return [];
    const raw = fs.readFileSync(LOGS_FILE, 'utf8');
    return JSON.parse(raw);
  } catch {
    return [];
  }
}

function writeLogs(logs) {
  const dir = path.dirname(LOGS_FILE);
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  // Trim to MAX_LOCAL_LOGS
  const trimmed = logs.slice(-MAX_LOCAL_LOGS);
  fs.writeFileSync(LOGS_FILE, JSON.stringify(trimmed, null, 2), 'utf8');
}

// ── Public API ──────────────────────────────────────────────

/**
 * Writes a command log entry locally and optionally syncs to Google Sheets.
 */
async function log({ user, originalText, action, status, result, details, syncToSheets = true }) {
  const entry = {
    logId: generateUUID(),
    timestamp: nowTimestamp(),
    user: user || 'النظام',
    originalText: originalText || '',
    action: action || 'unknown',
    status: status || 'unknown',
    result: typeof result === 'object' ? JSON.stringify(result) : String(result || ''),
    details: typeof details === 'object' ? JSON.stringify(details) : String(details || ''),
  };

  // Write locally
  const logs = readLogs();
  logs.push(entry);
  writeLogs(logs);

  // Optionally sync to Google Sheets (fire-and-forget)
  if (syncToSheets) {
    try {
      const sheetsService = require('./sheetsService');
      await sheetsService.appendCommandLog({
        user: entry.user,
        originalCommand: entry.originalText,
        action: entry.action,
        status: entry.status,
        result: entry.result,
        details: entry.details,
      });
    } catch {
      // Sheets sync failure is non-fatal
    }
  }

  return entry;
}

/**
 * Returns recent log entries, newest first.
 */
function getRecentLogs(limit = 50) {
  const logs = readLogs();
  return logs.slice(-limit).reverse();
}

/**
 * Returns logs filtered by action type.
 */
function getLogsByAction(action) {
  return readLogs().filter((l) => l.action === action).reverse();
}

module.exports = { log, getRecentLogs, getLogsByAction };
