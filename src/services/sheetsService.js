'use strict';

/**
 * Google Sheets Service — all read/write operations against the spreadsheet.
 *
 * Conventions:
 * - Every sheet is read into memory as an array of objects (row → { header: value }).
 * - Row 1 is always the header row.
 * - All write operations use append or batchUpdate.
 */

const { getSheetsClient, getSpreadsheetId } = require('../config/googleSheets');
const { today, getArabicDay, nowTimestamp } = require('../utils/dateUtils');
const { normalizeArabicText } = require('../utils/arabicNormalizer');

// ── Sheet definitions ───────────────────────────────────────

const SHEET_DEFINITIONS = {
  الموظفين: {
    headers: ['employee_id', 'الاسم', 'الرتبة', 'الإدارة', 'المنطقة', 'الحالة', 'الهاتف', 'ملاحظات'],
    idField: 'employee_id',
    idPrefix: 'EMP',
  },
  الحضور_اليومي: {
    headers: [
      'record_id', 'التاريخ', 'اليوم', 'النوبة', 'المنطقة',
      'employee_id', 'الاسم', 'الحالة', 'وقت_الإدخال', 'بواسطة', 'ملاحظات',
    ],
    idField: 'record_id',
    idPrefix: 'ATT',
  },
  كشف_الحجز: {
    headers: [
      'record_id', 'التاريخ', 'مصدر_النوبة', 'employee_id',
      'الاسم', 'النوبة', 'الحالة', 'ملاحظات', 'وقت_الإدخال',
    ],
    idField: 'record_id',
    idPrefix: 'DET',
  },
  النواقص: {
    headers: [
      'record_id', 'التاريخ', 'النوبة', 'المنطقة',
      'العدد_المطلوب', 'العدد_المتوفر', 'النقص', 'ملاحظات',
    ],
    idField: 'record_id',
    idPrefix: 'SHT',
  },
  التقارير_اليومية: {
    headers: [
      'report_id', 'التاريخ', 'ملخص_الصباح', 'ملخص_العصر', 'ملخص_الليل',
      'إجمالي_الحضور', 'إجمالي_النواقص', 'ملاحظات',
    ],
    idField: 'report_id',
    idPrefix: 'RPT',
  },
  سجل_الأوامر: {
    headers: [
      'log_id', 'التاريخ_والوقت', 'المستخدم', 'الأمر_الأصلي',
      'الإجراء', 'الحالة', 'النتيجة', 'تفاصيل',
    ],
    idField: 'log_id',
    idPrefix: 'LOG',
  },
  الاعتمادات_المعلقة: {
    headers: [
      'approval_id', 'التاريخ_والوقت', 'المستخدم', 'الأمر_الأصلي',
      'الإجراء_المقترح', 'الحالة', 'تفاصيل',
    ],
    idField: 'approval_id',
    idPrefix: 'APR',
  },
};

// ── Low-level helpers ───────────────────────────────────────

/**
 * Fetches all values from a named sheet, returning an array of row objects.
 * Row 0 is headers, rest are data.
 */
async function getSheetRows(sheetName) {
  const sheets = getSheetsClient();
  const spreadsheetId = getSpreadsheetId();

  const res = await sheets.spreadsheets.values.get({
    spreadsheetId,
    range: `${sheetName}`,
  });

  const rows = res.data.values || [];
  if (rows.length === 0) return { headers: [], data: [] };

  const headers = rows[0];
  const data = rows.slice(1).map((row, idx) => {
    const obj = { _rowIndex: idx + 2 }; // 1-based, offset for header
    headers.forEach((h, i) => {
      obj[h] = row[i] !== undefined ? row[i] : '';
    });
    return obj;
  });

  return { headers, data };
}

/**
 * Appends a single row to a sheet. rowData is an object { header: value }.
 */
async function appendRow(sheetName, rowData) {
  const sheets = getSheetsClient();
  const spreadsheetId = getSpreadsheetId();
  const def = SHEET_DEFINITIONS[sheetName];
  if (!def) throw new Error(`تعريف الجدول "${sheetName}" غير موجود`);

  const values = def.headers.map((h) => (rowData[h] !== undefined ? String(rowData[h]) : ''));

  await sheets.spreadsheets.values.append({
    spreadsheetId,
    range: `${sheetName}!A1`,
    valueInputOption: 'USER_ENTERED',
    insertDataOption: 'INSERT_ROWS',
    requestBody: { values: [values] },
  });
}

/**
 * Updates a single row at a specific row index (1-based, including header).
 */
async function updateRowAtIndex(sheetName, rowIndex, rowData) {
  const sheets = getSheetsClient();
  const spreadsheetId = getSpreadsheetId();
  const def = SHEET_DEFINITIONS[sheetName];
  if (!def) throw new Error(`تعريف الجدول "${sheetName}" غير موجود`);

  const values = def.headers.map((h) => (rowData[h] !== undefined ? String(rowData[h]) : ''));

  await sheets.spreadsheets.values.update({
    spreadsheetId,
    range: `${sheetName}!A${rowIndex}`,
    valueInputOption: 'USER_ENTERED',
    requestBody: { values: [values] },
  });
}

/**
 * Finds rows matching a filter function. Returns matched row objects.
 */
async function findRows(sheetName, filterFn) {
  const { data } = await getSheetRows(sheetName);
  return data.filter(filterFn);
}

/**
 * Generates next sequential ID for a sheet by reading existing IDs.
 */
async function generateNextId(sheetName) {
  const def = SHEET_DEFINITIONS[sheetName];
  if (!def) return `${Date.now()}`;
  try {
    const { data } = await getSheetRows(sheetName);
    const ids = data.map((r) => r[def.idField]).filter(Boolean);
    if (ids.length === 0) return `${def.idPrefix}-0001`;
    const nums = ids.map((id) => {
      const m = String(id).match(/(\d+)$/);
      return m ? parseInt(m[1], 10) : 0;
    });
    const max = Math.max(...nums);
    return `${def.idPrefix}-${String(max + 1).padStart(4, '0')}`;
  } catch {
    return `${def.idPrefix}-${Date.now()}`;
  }
}

// ── Sheet existence and setup ───────────────────────────────

async function getExistingSheetTitles() {
  const sheets = getSheetsClient();
  const spreadsheetId = getSpreadsheetId();
  const res = await sheets.spreadsheets.get({ spreadsheetId });
  return (res.data.sheets || []).map((s) => s.properties.title);
}

async function createSheet(title) {
  const sheets = getSheetsClient();
  const spreadsheetId = getSpreadsheetId();
  await sheets.spreadsheets.batchUpdate({
    spreadsheetId,
    requestBody: {
      requests: [{ addSheet: { properties: { title } } }],
    },
  });
}

async function writeHeaders(sheetName) {
  const sheets = getSheetsClient();
  const spreadsheetId = getSpreadsheetId();
  const def = SHEET_DEFINITIONS[sheetName];
  if (!def) return;

  await sheets.spreadsheets.values.update({
    spreadsheetId,
    range: `${sheetName}!A1`,
    valueInputOption: 'RAW',
    requestBody: { values: [def.headers] },
  });
}

/**
 * Creates all required sheets and writes headers if they don't exist.
 * Returns a summary of what was created vs already existed.
 */
async function setupAllSheets() {
  const existing = await getExistingSheetTitles();
  const results = [];

  for (const [sheetName] of Object.entries(SHEET_DEFINITIONS)) {
    if (existing.includes(sheetName)) {
      results.push({ sheet: sheetName, status: 'موجود مسبقاً' });
    } else {
      await createSheet(sheetName);
      await writeHeaders(sheetName);
      results.push({ sheet: sheetName, status: 'تم الإنشاء' });
    }
  }

  return results;
}

// ── Business-logic operations ───────────────────────────────

/**
 * Adds an attendance record to الحضور_اليومي.
 */
async function addAttendance({ date, shift, name, employeeId, area, status, notes, addedBy }) {
  const recordId = await generateNextId('الحضور_اليومي');
  const dayName = getArabicDay(date || today());
  const entryTime = nowTimestamp();

  const row = {
    record_id: recordId,
    التاريخ: date || today(),
    اليوم: dayName,
    النوبة: shift,
    المنطقة: area || '',
    employee_id: employeeId || '',
    الاسم: name,
    الحالة: status || 'حاضر',
    وقت_الإدخال: entryTime,
    بواسطة: addedBy || 'النظام',
    ملاحظات: notes || '',
  };

  await appendRow('الحضور_اليومي', row);
  return { recordId, row };
}

/**
 * Updates an existing attendance record by recordId or name+date+shift.
 */
async function updateAttendance({ recordId, date, shift, name, newStatus, newNotes, newArea }) {
  const { data } = await getSheetRows('الحضور_اليومي');
  const def = SHEET_DEFINITIONS['الحضور_اليومي'];

  let record = null;
  if (recordId) {
    record = data.find((r) => r[def.idField] === recordId);
  }
  if (!record && name && date) {
    const normName = normalizeArabicText(name);
    record = data.find((r) => {
      const nameMatch = normalizeArabicText(r['الاسم']).includes(normName);
      const dateMatch = r['التاريخ'] === date;
      const shiftMatch = !shift || r['النوبة'] === shift;
      return nameMatch && dateMatch && shiftMatch;
    });
  }

  if (!record) throw new Error('لم يتم العثور على السجل المطلوب. تأكد من الاسم والتاريخ والنوبة.');

  if (newStatus) record['الحالة'] = newStatus;
  if (newNotes !== undefined) record['ملاحظات'] = newNotes;
  if (newArea) record['المنطقة'] = newArea;

  await updateRowAtIndex('الحضور_اليومي', record._rowIndex, record);
  return { updated: record };
}

/**
 * Searches employees by partial name match.
 */
async function searchEmployee(query) {
  const norm = normalizeArabicText(query.trim());
  const rows = await findRows('الموظفين', (r) =>
    normalizeArabicText(r['الاسم'] || '').includes(norm)
  );
  return rows;
}

/**
 * Adds a new employee to الموظفين sheet.
 */
async function addEmployee({ name, rank, department, area, phone, notes }) {
  const empId = await generateNextId('الموظفين');
  const row = {
    employee_id: empId,
    الاسم: name,
    الرتبة: rank || '',
    الإدارة: department || '',
    المنطقة: area || '',
    الحالة: 'نشط',
    الهاتف: phone || '',
    ملاحظات: notes || '',
  };
  await appendRow('الموظفين', row);
  return { empId, row };
}

/**
 * Returns all الحضور_اليومي rows for a given date (and optionally shift).
 */
async function getAttendanceByDate(date, shift) {
  return findRows('الحضور_اليومي', (r) => {
    const dateMatch = r['التاريخ'] === date;
    const shiftMatch = !shift || r['النوبة'] === shift;
    return dateMatch && shiftMatch;
  });
}

/**
 * Moves all night-shift records from sourceDate to كشف_الحجز for targetDate.
 * Skips duplicates (same employee_id + date).
 */
async function moveNightShiftToDetention(sourceDate, targetDate, notes) {
  const nightRecords = await getAttendanceByDate(sourceDate, 'ليل');
  if (nightRecords.length === 0) {
    throw new Error(`لا توجد سجلات نوبة ليل بتاريخ ${sourceDate}`);
  }

  // Get existing detention records for targetDate to avoid duplicates
  const existingDetention = await findRows('كشف_الحجز', (r) => r['التاريخ'] === targetDate);
  const existingKeys = new Set(existingDetention.map((r) => `${r['employee_id']}-${r['التاريخ']}`));

  let added = 0;
  let skipped = 0;

  for (const rec of nightRecords) {
    const key = `${rec['employee_id']}-${targetDate}`;
    if (existingKeys.has(key)) {
      skipped++;
      continue;
    }

    const detId = await generateNextId('كشف_الحجز');
    const row = {
      record_id: detId,
      التاريخ: targetDate,
      مصدر_النوبة: 'ليل',
      employee_id: rec['employee_id'] || '',
      الاسم: rec['الاسم'],
      النوبة: 'ليل',
      الحالة: rec['الحالة'],
      ملاحظات: notes || `منقول من نوبة الليل ${sourceDate}`,
      وقت_الإدخال: nowTimestamp(),
    };
    await appendRow('كشف_الحجز', row);
    existingKeys.add(key);
    added++;
  }

  return { total: nightRecords.length, added, skipped };
}

/**
 * Generates an end-of-day report and saves it to التقارير_اليومية.
 */
async function generateDailyReport(date, notes) {
  const allRecords = await getAttendanceByDate(date);

  const countByShift = (shift) => allRecords.filter((r) => r['النوبة'] === shift);
  const presentByShift = (shift) =>
    allRecords.filter((r) => r['النوبة'] === shift && r['الحالة'] === 'حاضر');

  const morning = countByShift('صباح');
  const afternoon = countByShift('عصر');
  const night = countByShift('ليل');

  const summaryLine = (shift, records) => {
    const present = records.filter((r) => r['الحالة'] === 'حاضر').length;
    return `${shift}: ${present} حاضر / ${records.length} إجمالي`;
  };

  const reportId = await generateNextId('التقارير_اليومية');
  const totalPresent = allRecords.filter((r) => r['الحالة'] === 'حاضر').length;

  // Try to get shortage total
  let shortageTotal = 0;
  try {
    const shortages = await findRows('النواقص', (r) => r['التاريخ'] === date);
    shortageTotal = shortages.reduce((sum, r) => sum + parseInt(r['النقص'] || 0, 10), 0);
  } catch {}

  const row = {
    report_id: reportId,
    التاريخ: date,
    ملخص_الصباح: summaryLine('صباح', morning),
    ملخص_العصر: summaryLine('عصر', afternoon),
    ملخص_الليل: summaryLine('ليل', night),
    إجمالي_الحضور: totalPresent,
    إجمالي_النواقص: shortageTotal,
    ملاحظات: notes || '',
  };

  await appendRow('التقارير_اليومية', row);

  return {
    reportId,
    date,
    morning: { total: morning.length, present: presentByShift('صباح').length },
    afternoon: { total: afternoon.length, present: presentByShift('عصر').length },
    night: { total: night.length, present: presentByShift('ليل').length },
    totalPresent,
    shortageTotal,
    summary: `📊 تقرير يوم ${date}\n${summaryLine('صباح', morning)}\n${summaryLine('عصر', afternoon)}\n${summaryLine('ليل', night)}\nإجمالي الحضور: ${totalPresent} | إجمالي النواقص: ${shortageTotal}`,
  };
}

/**
 * Calculates shift shortage by comparing الحضور_اليومي with النواقص sheet.
 */
async function calculateShiftShortage(date, shift) {
  const attendance = await getAttendanceByDate(date, shift);
  const presentCount = attendance.filter((r) => r['الحالة'] === 'حاضر').length;

  // Check if there are required counts in النواقص
  const shortageRows = await findRows('النواقص', (r) => {
    const dateMatch = r['التاريخ'] === date;
    const shiftMatch = !shift || r['النوبة'] === shift;
    return dateMatch && shiftMatch;
  });

  if (shortageRows.length === 0) {
    return {
      date, shift,
      present: presentCount,
      total: attendance.length,
      required: null,
      shortage: null,
      message: `النوبة ${shift || 'الكل'} بتاريخ ${date}: ${presentCount} حاضر من ${attendance.length} إجمالي. لا يوجد عدد مطلوب محدد في جدول النواقص.`,
    };
  }

  const required = shortageRows.reduce((s, r) => s + parseInt(r['العدد_المطلوب'] || 0, 10), 0);
  const shortage = Math.max(0, required - presentCount);

  return {
    date, shift,
    present: presentCount,
    total: attendance.length,
    required,
    shortage,
    message: `النوبة ${shift || 'الكل'} بتاريخ ${date}: حاضر ${presentCount} / مطلوب ${required} / نقص ${shortage}`,
  };
}

/**
 * Adds a note to an attendance record identified by employee name (or recordId).
 */
async function addNoteToRecord({ target, note, date, shift }) {
  const normTarget = normalizeArabicText(target);
  const { data } = await getSheetRows('الحضور_اليومي');

  const record = data.find((r) => {
    const nameMatch = normalizeArabicText(r['الاسم'] || '').includes(normTarget) ||
                      r['record_id'] === target;
    const dateMatch = !date || r['التاريخ'] === date;
    const shiftMatch = !shift || r['النوبة'] === shift;
    return nameMatch && dateMatch && shiftMatch;
  });

  if (!record) throw new Error(`لم يتم العثور على سجل يخص "${target}"`);

  const existing = record['ملاحظات'] || '';
  record['ملاحظات'] = existing ? `${existing} | ${note}` : note;
  await updateRowAtIndex('الحضور_اليومي', record._rowIndex, record);
  return { updated: record };
}

/**
 * Deletes (clears) a row by record_id in any sheet.
 * Actual row deletion requires batchUpdate. We clear the row content instead.
 */
async function deleteRecord(sheetName, recordId) {
  const def = SHEET_DEFINITIONS[sheetName];
  if (!def) throw new Error(`الجدول "${sheetName}" غير معروف`);

  const { data } = await getSheetRows(sheetName);
  const record = data.find(
    (r) => r[def.idField] === String(recordId) || String(r[def.idField]).endsWith(String(recordId))
  );
  if (!record) throw new Error(`لم يتم العثور على سجل برقم "${recordId}" في جدول ${sheetName}`);

  // Clear all cells in the row
  const emptyRow = def.headers.map(() => '');
  emptyRow[0] = `[محذوف-${nowTimestamp()}]`;
  await updateRowAtIndex(sheetName, record._rowIndex, Object.fromEntries(def.headers.map((h, i) => [h, emptyRow[i]])));

  return { deleted: record };
}

/**
 * Appends a command log entry to سجل_الأوامر.
 */
async function appendCommandLog({ user, originalCommand, action, status, result, details }) {
  try {
    const logId = await generateNextId('سجل_الأوامر');
    const row = {
      log_id: logId,
      التاريخ_والوقت: nowTimestamp(),
      المستخدم: user || 'النظام',
      الأمر_الأصلي: originalCommand || '',
      الإجراء: action || '',
      الحالة: status || '',
      النتيجة: typeof result === 'object' ? JSON.stringify(result) : String(result || ''),
      تفاصيل: typeof details === 'object' ? JSON.stringify(details) : String(details || ''),
    };
    await appendRow('سجل_الأوامر', row);
  } catch (e) {
    // Log failures must not crash the main operation
    console.error('[SHEETS] Failed to write command log:', e.message);
  }
}

module.exports = {
  SHEET_DEFINITIONS,
  getSheetRows,
  appendRow,
  updateRowAtIndex,
  findRows,
  setupAllSheets,
  addAttendance,
  updateAttendance,
  searchEmployee,
  addEmployee,
  getAttendanceByDate,
  moveNightShiftToDetention,
  generateDailyReport,
  calculateShiftShortage,
  addNoteToRecord,
  deleteRecord,
  appendCommandLog,
  generateNextId,
};
