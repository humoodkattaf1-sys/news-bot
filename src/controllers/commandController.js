'use strict';

const { processCommand } = require('../services/commandProcessor');
const { IncomingCommandSchema } = require('../schemas/actionSchemas');
const { getConfig } = require('../config/env');

/**
 * POST /api/command
 * Receives an Arabic command and processes it.
 */
async function handleCommand(req, res) {
  const config = getConfig();

  // Token check
  const token = req.headers['x-admin-token'];
  if (!token || token !== config.adminToken) {
    return res.status(401).json({
      status: 'error',
      message: 'غير مصرح. يرجى إرسال x-admin-token صحيح في الهيدر.',
    });
  }

  // Validate input
  const parsed = IncomingCommandSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({
      status: 'error',
      message: 'بيانات غير صالحة',
      errors: parsed.error.errors.map((e) => e.message),
    });
  }

  const { text, user } = parsed.data;

  try {
    const result = await processCommand(text, user);
    return res.json(result);
  } catch (err) {
    console.error('[COMMAND]', err);
    return res.status(500).json({
      status: 'error',
      message: `خطأ في تنفيذ الأمر: ${err.message}`,
    });
  }
}

module.exports = { handleCommand };
