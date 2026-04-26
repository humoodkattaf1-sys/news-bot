'use strict';

const { Router } = require('express');
const { searchEmployees, getTodayAttendance, getShiftRecords } = require('../controllers/employeeController');

const router = Router();

// GET /api/employees/search?q=
router.get('/employees/search', searchEmployees);

// GET /api/today
router.get('/today', getTodayAttendance);

// GET /api/shift?date=&shift=
router.get('/shift', getShiftRecords);

module.exports = router;
