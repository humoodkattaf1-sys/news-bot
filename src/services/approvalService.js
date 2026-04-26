'use strict';

/**
 * Approval Service — manages pending approval records using local JSON storage.
 * Falls back gracefully if the data directory doesn't exist.
 */

const fs = require('fs');
const path = require('path');
const { generateUUID } = require('../utils/idGenerator');
const { nowTimestamp } = require('../utils/dateUtils');

const APPROVALS_FILE = path.join(__dirname, '../../data/pendingApprovals.json');

// ── File helpers ────────────────────────────────────────────

function readApprovals() {
  try {
    if (!fs.existsSync(APPROVALS_FILE)) return [];
    const raw = fs.readFileSync(APPROVALS_FILE, 'utf8');
    return JSON.parse(raw);
  } catch {
    return [];
  }
}

function writeApprovals(approvals) {
  const dir = path.dirname(APPROVALS_FILE);
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(APPROVALS_FILE, JSON.stringify(approvals, null, 2), 'utf8');
}

// ── Public API ──────────────────────────────────────────────

/**
 * Creates a new pending approval entry and returns it.
 */
function createApproval({ user, originalText, parsed }) {
  const approvals = readApprovals();

  const entry = {
    approvalId: generateUUID(),
    timestamp: nowTimestamp(),
    user: user || 'مجهول',
    originalText,
    action: parsed.action,
    payload: parsed.payload,
    confidence: parsed.confidence,
    status: 'معلق',
    details: JSON.stringify(parsed.payload),
  };

  approvals.push(entry);
  writeApprovals(approvals);
  return entry;
}

/**
 * Returns all approvals with optional status filter.
 */
function listApprovals(statusFilter) {
  const approvals = readApprovals();
  if (statusFilter) return approvals.filter((a) => a.status === statusFilter);
  return approvals;
}

/**
 * Returns a single approval by ID or null.
 */
function getApproval(approvalId) {
  return readApprovals().find((a) => a.approvalId === approvalId) || null;
}

/**
 * Marks an approval as approved and returns it.
 */
function approveEntry(approvalId) {
  const approvals = readApprovals();
  const entry = approvals.find((a) => a.approvalId === approvalId);
  if (!entry) throw new Error(`لم يتم العثور على الاعتماد رقم: ${approvalId}`);
  if (entry.status !== 'معلق') throw new Error(`هذا الاعتماد ليس في حالة معلق (الحالة الحالية: ${entry.status})`);

  entry.status = 'معتمد';
  entry.approvedAt = nowTimestamp();
  writeApprovals(approvals);
  return entry;
}

/**
 * Marks an approval as rejected.
 */
function rejectEntry(approvalId, reason) {
  const approvals = readApprovals();
  const entry = approvals.find((a) => a.approvalId === approvalId);
  if (!entry) throw new Error(`لم يتم العثور على الاعتماد رقم: ${approvalId}`);
  if (entry.status !== 'معلق') throw new Error(`هذا الاعتماد ليس في حالة معلق`);

  entry.status = 'مرفوض';
  entry.rejectedAt = nowTimestamp();
  entry.rejectionReason = reason || '';
  writeApprovals(approvals);
  return entry;
}

/**
 * Returns count of pending approvals.
 */
function pendingCount() {
  return readApprovals().filter((a) => a.status === 'معلق').length;
}

module.exports = {
  createApproval,
  listApprovals,
  getApproval,
  approveEntry,
  rejectEntry,
  pendingCount,
};
