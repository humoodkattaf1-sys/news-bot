'use strict';

const sheetsService = require('../services/sheetsService');
const { getConfig } = require('../config/env');
const { today } = require('../utils/dateUtils');

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
 * GET /api/employees/search?q=
 * Search employees by partial name match.
 */
async function searchEmployees(req, res) {
  if (!requireToken(req, res)) return;

  const { q } = req.query;
  if (!q || q.trim().length < 1) {
    return res.status(400).json({ status: 'error', message: 'يرجى إدخال كلمة بحث' });
  }

  try {
    const results = await sheetsService.searchEmployee(q.trim());
    res.json({
      status: 'ok',
      count: results.length,
      results: results.map((r) => ({
        id: r['employee_id'],
        name: r['الاسم'],
        rank: r['الرتبة'],
        department: r['الإدارة'],
        area: r['المنطقة'],
        status: r['الحالة'],
        phone: r['الهاتف'],
        notes: r['ملاحظات'],
      })),
    });
  } catch (err) {
    res.status(500).json({ status: 'error', message: err.message });
  }
}

/**
 * GET /api/today
 * Returns today's attendance records.
 */
async function getTodayAttendance(req, res) {
  if (!requireToken(req, res)) return;

  const date = req.query.date || today();
  const shift = req.query.shift || undefined;

  try {
    const records = await sheetsService.getAttendanceByDate(date, shift);
    res.json({
      status: 'ok',
      date,
      shift: shift || 'الكل',
      count: records.length,
      records: records.map((r) => ({
        id: r['record_id'],
        date: r['التاريخ'],
        day: r['اليوم'],
        shift: r['النوبة'],
        name: r['الاسم'],
        status: r['الحالة'],
        area: r['المنطقة'],
        entryTime: r['وقت_الإدخال'],
        notes: r['ملاحظات'],
      })),
    });
  } catch (err) {
    res.status(500).json({ status: 'error', message: err.message });
  }
}

/**
 * GET /api/shift?date=&shift=
 * Returns records for a specific shift.
 */
async function getShiftRecords(req, res) {
  if (!requireToken(req, res)) return;

  const { date, shift } = req.query;
  if (!date || !shift) {
    return res.status(400).json({ status: 'error', message: 'التاريخ والنوبة مطلوبان' });
  }

  try {
    const records = await sheetsService.getAttendanceByDate(date, shift);
    res.json({
      status: 'ok',
      date,
      shift,
      count: records.length,
      records: records.map((r) => ({
        id: r['record_id'],
        name: r['الاسم'],
        status: r['الحالة'],
        area: r['المنطقة'],
        notes: r['ملاحظات'],
      })),
    });
  } catch (err) {
    res.status(500).json({ status: 'error', message: err.message });
  }
}

module.exports = { searchEmployees, getTodayAttendance, getShiftRecords };
