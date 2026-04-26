'use strict';

const { Router } = require('express');
const { getConfig } = require('../config/env');
const sheetsService = require('../services/sheetsService');

const router = Router();

/**
 * POST /api/setup
 * Creates required Google Sheet tabs and headers.
 * Requires admin token.
 */
router.post('/setup', async (req, res) => {
  const config = getConfig();
  const token = req.headers['x-admin-token'];
  if (!token || token !== config.adminToken) {
    return res.status(401).json({ status: 'error', message: 'غير مصرح. يرجى إرسال x-admin-token صحيح.' });
  }

  try {
    const results = await sheetsService.setupAllSheets();
    res.json({
      status: 'ok',
      message: 'تم تجهيز جداول Google Sheets',
      results,
    });
  } catch (err) {
    res.status(500).json({ status: 'error', message: err.message });
  }
});

module.exports = router;
