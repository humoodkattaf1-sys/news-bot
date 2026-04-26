'use strict';

const logService = require('../services/logService');
const { getConfig } = require('../config/env');

function requireToken(req, res) {
  const config = getConfig();
  const token = req.headers['x-admin-token'];
  if (!token || token !== config.adminToken) {
    res.status(401).json({ status: 'error', message: 'غير مصرح.' });
    return false;
  }
  return true;
}

/**
 * GET /api/logs
 * Returns recent command logs.
 */
async function getCommandLogs(req, res) {
  if (!requireToken(req, res)) return;
  const limit = parseInt(req.query.limit || '50', 10);
  const logs = logService.getRecentLogs(limit);
  res.json({ status: 'ok', count: logs.length, logs });
}

module.exports = { getCommandLogs };
