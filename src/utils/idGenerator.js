'use strict';

const { v4: uuidv4 } = require('uuid');
const { nowTimestamp } = require('./dateUtils');

/**
 * Generates a short unique record ID (timestamp-based + random suffix).
 * Format: REC-20260426-a3f9
 */
function generateRecordId(prefix = 'REC') {
  const ts = nowTimestamp().replace(/\D/g, '').slice(0, 12);
  const rand = Math.random().toString(36).substring(2, 6).toUpperCase();
  return `${prefix}-${ts}-${rand}`;
}

/**
 * Generates a UUID for approvals and logs.
 */
function generateUUID() {
  return uuidv4();
}

/**
 * Generates a sequential ID from an existing list of IDs.
 * Finds the max numeric suffix and increments by 1.
 */
function nextSequentialId(existingIds, prefix = 'REC') {
  if (!existingIds || existingIds.length === 0) return `${prefix}-0001`;
  const nums = existingIds
    .map((id) => {
      const match = String(id).match(/(\d+)$/);
      return match ? parseInt(match[1], 10) : 0;
    })
    .filter((n) => !isNaN(n));
  const max = nums.length > 0 ? Math.max(...nums) : 0;
  return `${prefix}-${String(max + 1).padStart(4, '0')}`;
}

module.exports = { generateRecordId, generateUUID, nextSequentialId };
