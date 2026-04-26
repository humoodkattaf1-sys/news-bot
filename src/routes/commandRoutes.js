'use strict';

const { Router } = require('express');
const { handleCommand } = require('../controllers/commandController');

const router = Router();

// POST /api/command
router.post('/command', handleCommand);

module.exports = router;
