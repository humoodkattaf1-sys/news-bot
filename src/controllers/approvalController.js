'use strict';

const approvalService = require('../services/approvalService');
const { executeApprovedAction } = require('../services/commandProcessor');
const logService = require('../services/logService');
const { getConfig } = require('../config/env');

function requireToken(req, res) {
  const config = getConfig();
  const token = req.headers['x-admin-token'];
  if (!token || token !== config.adminToken) {
    res.status(401).json({ status: 'error', message: 'غير مصرح. يرجى إرسال x-admin-token صحيح.' });
    return false;
  }
  return true;
}

/**
 * GET /api/approvals
 * Returns all pending approvals.
 */
async function listApprovals(req, res) {
  if (!requireToken(req, res)) return;
  const status = req.query.status || 'معلق';
  const approvals = approvalService.listApprovals(status === 'all' ? undefined : status);
  res.json({ status: 'ok', count: approvals.length, approvals });
}

/**
 * POST /api/approve/:id
 * Approves a pending command and executes it.
 */
async function approveCommand(req, res) {
  if (!requireToken(req, res)) return;

  const { id } = req.params;
  const user = req.body?.user || 'مشرف';

  try {
    // Mark as approved in storage
    const approval = approvalService.approveEntry(id);

    // Execute the action
    const result = await executeApprovedAction(approval, user);

    await logService.log({
      user,
      originalText: approval.originalText,
      action: approval.action,
      status: 'approved_and_executed',
      result: result.message,
    });

    res.json({
      status: 'ok',
      message: `✅ تم اعتماد وتنفيذ الأمر: ${result.message}`,
      execution: result,
    });
  } catch (err) {
    console.error('[APPROVE]', err);
    res.status(400).json({ status: 'error', message: err.message });
  }
}

/**
 * POST /api/reject/:id
 * Rejects a pending command.
 */
async function rejectCommand(req, res) {
  if (!requireToken(req, res)) return;

  const { id } = req.params;
  const reason = req.body?.reason || '';
  const user = req.body?.user || 'مشرف';

  try {
    const approval = approvalService.rejectEntry(id, reason);

    await logService.log({
      user,
      originalText: approval.originalText,
      action: approval.action,
      status: 'rejected',
      result: reason || 'تم الرفض',
    });

    res.json({
      status: 'ok',
      message: `❌ تم رفض الأمر`,
      approval,
    });
  } catch (err) {
    res.status(400).json({ status: 'error', message: err.message });
  }
}

module.exports = { listApprovals, approveCommand, rejectCommand };
