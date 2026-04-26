'use strict';

const { Router } = require('express');
const { getCommandLogs } = require('../controllers/reportController');

const router = Router();

// GET /api/logs
router.get('/logs', getCommandLogs);

module.exports = router;
