'use strict';

const { Router } = require('express');
const { listApprovals, approveCommand, rejectCommand } = require('../controllers/approvalController');

const router = Router();

// GET /api/approvals
router.get('/approvals', listApprovals);

// POST /api/approve/:id
router.post('/approve/:id', approveCommand);

// POST /api/reject/:id
router.post('/reject/:id', rejectCommand);

module.exports = router;
