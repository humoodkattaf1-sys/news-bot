'use strict';

/**
 * Command Processor — orchestrates the full lifecycle of an Arabic command:
 * parse → validate → approve/execute → log → respond.
 */

const { parseWithFallback, buildPreviewMessage } = require('./arabicCommandParser');
const approvalService = require('./approvalService');
const logService = require('./logService');
const sheetsService = require('./sheetsService');
const { getConfig } = require('../config/env');

const {
  AddAttendanceSchema,
  UpdateAttendanceSchema,
  SearchEmployeeSchema,
  AddEmployeeSchema,
  GenerateDailyReportSchema,
  MoveNightShiftSchema,
  CalculateShortageSchema,
  AddNoteSchema,
  DeleteRecordSchema,
  ListTodaySchema,
  ListShiftSchema,
} = require('../schemas/actionSchemas');

// ── Action executor map ─────────────────────────────────────

const EXECUTORS = {
  add_attendance: async (payload) => {
    const data = AddAttendanceSchema.parse(payload);
    return sheetsService.addAttendance(data);
  },

  update_attendance: async (payload) => {
    const data = UpdateAttendanceSchema.parse(payload);
    return sheetsService.updateAttendance(data);
  },

  search_employee: async (payload) => {
    const data = SearchEmployeeSchema.parse(payload);
    const results = await sheetsService.searchEmployee(data.query);
    return { results, count: results.length };
  },

  add_employee: async (payload) => {
    const data = AddEmployeeSchema.parse(payload);
    return sheetsService.addEmployee(data);
  },

  update_employee: async (payload) => {
    // Reuse updateAttendance pattern on الموظفين — simplified
    const { name, field, value } = payload;
    if (!name) throw new Error('اسم الموظف مطلوب لتعديل بياناته');
    const rows = await sheetsService.searchEmployee(name);
    if (rows.length === 0) throw new Error(`لم يتم العثور على موظف باسم "${name}"`);
    const emp = rows[0];
    if (field && value) emp[field] = value;
    await sheetsService.updateRowAtIndex('الموظفين', emp._rowIndex, emp);
    return { updated: emp };
  },

  generate_daily_report: async (payload) => {
    const data = GenerateDailyReportSchema.parse(payload);
    return sheetsService.generateDailyReport(data.date, data.notes);
  },

  move_night_shift_to_next_day_detention: async (payload) => {
    const data = MoveNightShiftSchema.parse(payload);
    return sheetsService.moveNightShiftToDetention(data.sourceDate, data.targetDate, data.notes);
  },

  calculate_shift_shortage: async (payload) => {
    const data = CalculateShortageSchema.parse(payload);
    return sheetsService.calculateShiftShortage(data.date, data.shift);
  },

  add_note: async (payload) => {
    const data = AddNoteSchema.parse(payload);
    return sheetsService.addNoteToRecord(data);
  },

  delete_record: async (payload) => {
    const data = DeleteRecordSchema.parse(payload);
    return sheetsService.deleteRecord(data.sheetName, data.recordId);
  },

  list_today: async (payload) => {
    const data = ListTodaySchema.parse(payload);
    const records = await sheetsService.getAttendanceByDate(data.date, data.shift);
    return {
      date: data.date,
      shift: data.shift || 'الكل',
      count: records.length,
      records: records.map((r) => ({
        id: r['record_id'],
        name: r['الاسم'],
        shift: r['النوبة'],
        status: r['الحالة'],
        area: r['المنطقة'],
        notes: r['ملاحظات'],
      })),
    };
  },

  list_shift: async (payload) => {
    const data = ListShiftSchema.parse(payload);
    const records = await sheetsService.getAttendanceByDate(data.date, data.shift);
    return {
      date: data.date,
      shift: data.shift,
      count: records.length,
      records: records.map((r) => ({
        id: r['record_id'],
        name: r['الاسم'],
        status: r['الحالة'],
        area: r['المنطقة'],
        notes: r['ملاحظات'],
      })),
    };
  },

  setup_sheets: async () => {
    return sheetsService.setupAllSheets();
  },

  unknown: async () => {
    throw new Error('الأمر غير معروف');
  },
};

// ── Main process function ───────────────────────────────────

/**
 * Processes an Arabic command end-to-end.
 *
 * @param {string} text - The raw Arabic command
 * @param {string} user - The username sending the command
 * @returns {ProcessResult}
 */
async function processCommand(text, user = 'مجهول') {
  const config = getConfig();

  // 1. Parse the command
  const parsed = await parseWithFallback(text);

  // 2. Needs clarification?
  if (parsed.action === 'unknown' || parsed.confidence < 0.75) {
    await logService.log({
      user,
      originalText: text,
      action: 'unknown',
      status: 'needs_clarification',
      result: parsed.clarificationNeeded,
    });

    return {
      status: 'needs_clarification',
      message: parsed.clarificationNeeded || 'لم أفهم الأمر. يرجى إعادة الصياغة.',
      parsed,
    };
  }

  // 3. Requires approval?
  const needsApproval = parsed.requiresApproval && config.approvalMode;

  if (needsApproval) {
    const approval = approvalService.createApproval({ user, originalText: text, parsed });

    await logService.log({
      user,
      originalText: text,
      action: parsed.action,
      status: 'pending_approval',
      result: `approval_id: ${approval.approvalId}`,
    });

    return {
      status: 'preview',
      message: `⏳ هذا الأمر يتطلب اعتماداً قبل التنفيذ.\n\n${buildPreviewMessage(parsed)}\n\nرقم الطلب: ${approval.approvalId}`,
      parsed,
      approvalId: approval.approvalId,
    };
  }

  // 4. Execute immediately
  return executeAction(parsed, text, user);
}

/**
 * Executes an already-approved action (called from the approve endpoint).
 */
async function executeApprovedAction(approval, user) {
  const parsed = {
    action: approval.action,
    payload: approval.payload,
    confidence: approval.confidence,
    requiresApproval: true,
    originalText: approval.originalText,
  };
  return executeAction(parsed, approval.originalText, user || approval.user);
}

// ── Internal execution ──────────────────────────────────────

async function executeAction(parsed, originalText, user) {
  const executor = EXECUTORS[parsed.action];

  if (!executor) {
    return {
      status: 'error',
      message: `لا يوجد منفذ للأمر: ${parsed.action}`,
      parsed,
    };
  }

  try {
    const result = await executor(parsed.payload);

    await logService.log({
      user,
      originalText,
      action: parsed.action,
      status: 'executed',
      result,
    });

    return {
      status: 'executed',
      message: buildSuccessMessage(parsed.action, result),
      parsed,
      result,
    };
  } catch (err) {
    await logService.log({
      user,
      originalText,
      action: parsed.action,
      status: 'error',
      result: err.message,
      details: err.stack,
    });

    return {
      status: 'error',
      message: `❌ حدث خطأ: ${err.message}`,
      parsed,
    };
  }
}

// ── Success message builder ─────────────────────────────────

function buildSuccessMessage(action, result) {
  switch (action) {
    case 'add_attendance':
      return `✅ تم تسجيل الحضور بنجاح — رقم السجل: ${result.recordId}`;

    case 'update_attendance':
      return `✅ تم تعديل سجل الحضور بنجاح`;

    case 'search_employee':
      if (result.count === 0) return `🔍 لم يتم العثور على موظف يطابق البحث`;
      return `🔍 تم العثور على ${result.count} نتيجة`;

    case 'add_employee':
      return `✅ تم إضافة الموظف بنجاح — رقم الموظف: ${result.empId}`;

    case 'update_employee':
      return `✅ تم تعديل بيانات الموظف بنجاح`;

    case 'generate_daily_report':
      return result.summary || `✅ تم إنشاء التقرير اليومي بنجاح`;

    case 'move_night_shift_to_next_day_detention':
      return `✅ تم نقل ${result.added} سجل إلى كشف الحجز (${result.skipped} مكرر تم تجاهله)`;

    case 'calculate_shift_shortage':
      return result.message || `✅ تم حساب النواقص`;

    case 'add_note':
      return `✅ تم إضافة الملاحظة بنجاح`;

    case 'delete_record':
      return `✅ تم حذف السجل بنجاح`;

    case 'list_today':
      return `📋 ${result.date} — ${result.shift}: ${result.count} سجل`;

    case 'list_shift':
      return `📋 نوبة ${result.shift} بتاريخ ${result.date}: ${result.count} سجل`;

    case 'setup_sheets':
      return `✅ تم تجهيز الجداول:\n${result.map((r) => `${r.sheet}: ${r.status}`).join('\n')}`;

    default:
      return `✅ تم تنفيذ الأمر بنجاح`;
  }
}

module.exports = { processCommand, executeApprovedAction };
