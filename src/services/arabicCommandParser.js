'use strict';

/**
 * Arabic Command Parser — Rule-based NLP for Kuwaiti police/admin commands.
 *
 * Architecture is designed so an AI-based parser (Claude, GPT, etc.) can be
 * plugged in later by replacing the `parse()` export or wrapping it.
 *
 * Each rule set returns { matched: bool, confidence: number, payload: {} }.
 * The highest-confidence match wins.
 */

const {
  extractShiftFromText,
  extractStatusFromText,
  extractNameFromText,
  extractNoteFromText,
  extractRecordIdFromText,
} = require('../utils/arabicNormalizer');

const { extractDateFromText, today, tomorrow } = require('../utils/dateUtils');

// ── Action detection rules ──────────────────────────────────
// Each rule: { pattern, action, weight }
// weight contributes to confidence when matched.

const ACTION_RULES = [
  // Setup
  {
    pattern: /جهز\s*(الأوراق|الشيتات|الجداول|النظام)|انشئ\s*(الأوراق|الشيتات)|ابدأ\s*النظام|setup/i,
    action: 'setup_sheets',
    weight: 0.95,
  },

  // Generate daily report
  {
    pattern: /تقرير\s*يومي|كشف\s*نهاية\s*اليوم|نهاية\s*اليوم|طلع\s*كشف|سو\s*كشف|اعمل\s*تقرير|جهز\s*تقرير/,
    action: 'generate_daily_report',
    weight: 0.9,
  },

  // Move night shift to detention
  {
    pattern: /انقل|حرك|نقل/,
    action: 'move_night_shift_to_next_day_detention',
    weight: 0.5, // low alone; needs shift+detention context
    requires: [/ليل|الليل/, /حجز|الحجز/],
  },

  // Calculate shortage
  {
    pattern: /نواقص|نقص|ناقص|اعرض\s*النواقص|شوفلي\s*نواقص/,
    action: 'calculate_shift_shortage',
    weight: 0.85,
  },

  // Add note
  {
    pattern: /أضف\s*ملاحظة|اضف\s*ملاحظة|حط\s*ملاحظة|عدل\s*ملاحظة|أكتب\s*ملاحظة/,
    action: 'add_note',
    weight: 0.9,
  },

  // Delete record
  {
    pattern: /احذف|حذف|امسح|مسح|إلغاء\s*سجل/,
    action: 'delete_record',
    weight: 0.9,
  },

  // Search employee
  {
    pattern: /دور|ابحث|ابحث\s*عن|فين|وين\s*|اجيب\s*معلومات|ابحث\s*موظف|شوف\s*الموظف/,
    action: 'search_employee',
    weight: 0.85,
  },

  // Add employee
  {
    pattern: /أضف\s*موظف|اضف\s*موظف|سجل\s*موظف\s*جديد|أنشئ\s*موظف/,
    action: 'add_employee',
    weight: 0.95,
  },

  // Update employee
  {
    pattern: /عدل\s*بيانات|غير\s*بيانات|صحح\s*بيانات|تحديث\s*موظف/,
    action: 'update_employee',
    weight: 0.9,
  },

  // Update attendance (update/change existing record)
  {
    pattern: /عدل\s*حالة|غير\s*حالة|صحح\s*حالة|بدل\s*حالة|خله\s*|خليه\s*/,
    action: 'update_attendance',
    weight: 0.85,
  },

  // List today
  {
    pattern: /اعرض\s*اليوم|كشف\s*اليوم|حضور\s*اليوم|من\s*حضر\s*اليوم|شوف\s*اليوم/,
    action: 'list_today',
    weight: 0.85,
  },

  // List shift
  {
    pattern: /اعرض\s*النوبة|كشف\s*النوبة|من\s*في\s*النوبة|قائمة\s*النوبة/,
    action: 'list_shift',
    weight: 0.85,
  },

  // Add attendance — most common, lower weight (depends on name/shift context)
  {
    pattern: /سجل|أضف|اضف|حط|سجله|سجلها|أدخل|ادخل/,
    action: 'add_attendance',
    weight: 0.5,
  },
];

// ── Context boosters: extra signals that raise confidence ───

const CONTEXT_BOOSTERS = {
  add_attendance: [
    { pattern: /نوبة|نوبه|صبح|صباح|عصر|ليل/, boost: 0.25 },
    { pattern: /حاضر|غائب|إجازة|طبي|مأمورية/, boost: 0.15 },
    { pattern: /[؀-ۿ]{2,}\s+[؀-ۿ]{2,}/, boost: 0.1 }, // at least two Arabic words (name)
  ],
  update_attendance: [
    { pattern: /حالة|النوبة|التاريخ|ملاحظة/, boost: 0.15 },
    { pattern: /إلى|الى|ل\s/, boost: 0.1 },
  ],
  search_employee: [
    { pattern: /[؀-ۿ]{2,}\s+[؀-ۿ]{2,}/, boost: 0.2 }, // Name-like phrase
  ],
  move_night_shift_to_next_day_detention: [
    { pattern: /ليل|الليل/, boost: 0.25 },
    { pattern: /حجز|الحجز|كشف الحجز/, boost: 0.25 },
    { pattern: /باجر|غداً|التالي|المقبل/, boost: 0.1 },
  ],
  generate_daily_report: [
    { pattern: /ملخص|إجمالي|مختصر/, boost: 0.15 },
  ],
  calculate_shift_shortage: [
    { pattern: /صبح|صباح|عصر|ليل/, boost: 0.15 },
  ],
  add_note: [
    { pattern: /[:：]/, boost: 0.2 },
    { pattern: /[؀-ۿ]{2,}/, boost: 0.1 },
  ],
  delete_record: [
    { pattern: /رقم\s*\d+|سجل\s*\d+/, boost: 0.3 },
    { pattern: /الخطأ|غلط/, boost: 0.1 },
  ],
};

// ── Approval required actions ───────────────────────────────

const APPROVAL_REQUIRED_ACTIONS = new Set([
  'delete_record',
  'move_night_shift_to_next_day_detention',
  'generate_daily_report',
]);

// ── Payload extractors per action ───────────────────────────

function extractAddAttendancePayload(text) {
  const { date } = extractDateFromText(text);
  const shift = extractShiftFromText(text);
  const status = extractStatusFromText(text) || 'حاضر';
  const name = extractNameFromText(text);
  const notes = extractNoteFromText(text);
  return { date, shift, name, status, area: '', notes };
}

function extractUpdateAttendancePayload(text) {
  const { date } = extractDateFromText(text);
  const shift = extractShiftFromText(text);
  const newStatus = extractStatusFromText(text);
  const name = extractNameFromText(text);
  const recordId = extractRecordIdFromText(text);
  const newNotes = extractNoteFromText(text);
  return {
    recordId: recordId ? String(recordId) : undefined,
    date,
    shift,
    name,
    newStatus,
    newNotes,
  };
}

function extractSearchEmployeePayload(text) {
  const name = extractNameFromText(text);
  return { query: name || text.trim() };
}

function extractAddEmployeePayload(text) {
  const name = extractNameFromText(text);
  return { name, rank: '', department: '', area: '', phone: '', notes: '' };
}

function extractGenerateDailyReportPayload(text) {
  const { date } = extractDateFromText(text);
  const notes = extractNoteFromText(text);
  return { date, notes };
}

function extractMoveNightShiftPayload(text) {
  // Source date defaults to today, target defaults to tomorrow
  const { date: sourceDate } = extractDateFromText(text);
  // Look for "باجر/غدا" for target
  const targetKeywords = /باجر|غداً|غدا|بكرة|التالي/.test(text);
  const targetDate = targetKeywords ? tomorrow() : (() => {
    // Try to find a second date in the text
    const stripped = text.replace(/اليوم/, '');
    const { date } = extractDateFromText(stripped);
    return date;
  })();
  return { sourceDate, targetDate, notes: '' };
}

function extractCalculateShortagePayload(text) {
  const { date } = extractDateFromText(text);
  const shift = extractShiftFromText(text);
  return { date, shift: shift || undefined, area: '' };
}

function extractAddNotePayload(text) {
  const note = extractNoteFromText(text);
  const name = extractNameFromText(text);
  const { date } = extractDateFromText(text);
  const shift = extractShiftFromText(text);
  return { target: name || '', note, date, shift: shift || undefined };
}

function extractDeleteRecordPayload(text) {
  const recordId = extractRecordIdFromText(text);
  return {
    sheetName: /حجز/.test(text) ? 'كشف_الحجز' : 'الحضور_اليومي',
    recordId: recordId ? String(recordId) : '',
    reason: extractNoteFromText(text),
  };
}

function extractListTodayPayload(text) {
  const { date } = extractDateFromText(text);
  const shift = extractShiftFromText(text);
  return { date, shift: shift || undefined, area: '' };
}

function extractListShiftPayload(text) {
  const { date } = extractDateFromText(text);
  const shift = extractShiftFromText(text);
  return { date, shift: shift || 'صباح', area: '' };
}

const PAYLOAD_EXTRACTORS = {
  add_attendance: extractAddAttendancePayload,
  update_attendance: extractUpdateAttendancePayload,
  search_employee: extractSearchEmployeePayload,
  add_employee: extractAddEmployeePayload,
  update_employee: extractSearchEmployeePayload, // reuse search for name extraction
  generate_daily_report: extractGenerateDailyReportPayload,
  move_night_shift_to_next_day_detention: extractMoveNightShiftPayload,
  calculate_shift_shortage: extractCalculateShortagePayload,
  add_note: extractAddNotePayload,
  delete_record: extractDeleteRecordPayload,
  list_today: extractListTodayPayload,
  list_shift: extractListShiftPayload,
  setup_sheets: () => ({}),
  unknown: () => ({}),
};

// ── Main parse function ─────────────────────────────────────

/**
 * Parses an Arabic natural language command into a structured action object.
 *
 * @param {string} text - The raw Arabic command text
 * @returns {ParsedAction}
 */
function parse(text) {
  if (!text || typeof text !== 'string') {
    return buildUnknown(text || '', 'النص فارغ أو غير صالح');
  }

  const normalized = text.trim();

  // Score each action rule
  const scores = [];

  for (const rule of ACTION_RULES) {
    if (!rule.pattern.test(normalized)) continue;

    // Check if "requires" patterns (multi-condition) are all satisfied
    if (rule.requires) {
      const allRequired = rule.requires.every((r) => r.test(normalized));
      if (!allRequired) continue;
    }

    let confidence = rule.weight;

    // Apply context boosters
    const boosters = CONTEXT_BOOSTERS[rule.action] || [];
    for (const { pattern, boost } of boosters) {
      if (pattern.test(normalized)) confidence += boost;
    }

    // Cap at 1.0
    confidence = Math.min(confidence, 1.0);

    scores.push({ action: rule.action, confidence });
  }

  if (scores.length === 0) {
    return buildUnknown(normalized, 'لم أتعرف على الأمر. حاول إعادة الصياغة بشكل أوضح.');
  }

  // Pick the highest confidence action
  scores.sort((a, b) => b.confidence - a.confidence);
  const best = scores[0];

  // Low confidence → ask for clarification
  if (best.confidence < 0.75) {
    return buildUnknown(
      normalized,
      `لم أكن متأكداً من الأمر (الثقة: ${Math.round(best.confidence * 100)}%). هل تقصد: ${describeAction(best.action)}؟`
    );
  }

  // Extract payload using the appropriate extractor
  const extractor = PAYLOAD_EXTRACTORS[best.action] || (() => ({}));
  const payload = extractor(normalized);

  // Validate that we have the critical minimum fields for add_attendance
  if (best.action === 'add_attendance' && !payload.name) {
    return buildUnknown(normalized, 'لم أتمكن من استخراج اسم الموظف من الأمر. يرجى ذكر الاسم الكامل.');
  }

  if (best.action === 'search_employee' && (!payload.query || payload.query.length < 2)) {
    return buildUnknown(normalized, 'يرجى ذكر اسم الموظف أو جزء منه للبحث.');
  }

  return {
    action: best.action,
    confidence: parseFloat(best.confidence.toFixed(2)),
    requiresApproval: APPROVAL_REQUIRED_ACTIONS.has(best.action),
    payload,
    originalText: normalized,
  };
}

// ── Helpers ─────────────────────────────────────────────────

function buildUnknown(text, clarification) {
  return {
    action: 'unknown',
    confidence: 0,
    requiresApproval: false,
    payload: {},
    originalText: text,
    clarificationNeeded: clarification,
  };
}

const ACTION_DESCRIPTIONS = {
  add_attendance: 'تسجيل حضور موظف في نوبة',
  update_attendance: 'تعديل سجل حضور موجود',
  search_employee: 'البحث عن موظف',
  add_employee: 'إضافة موظف جديد',
  update_employee: 'تعديل بيانات موظف',
  generate_daily_report: 'إنشاء تقرير يومي',
  move_night_shift_to_next_day_detention: 'نقل نوبة الليل إلى كشف الحجز لليوم التالي',
  calculate_shift_shortage: 'حساب نواقص النوبة',
  add_note: 'إضافة ملاحظة',
  delete_record: 'حذف سجل',
  list_today: 'عرض حضور اليوم',
  list_shift: 'عرض سجلات نوبة محددة',
  setup_sheets: 'تجهيز جداول Google Sheets',
  unknown: 'أمر غير معروف',
};

function describeAction(action) {
  return ACTION_DESCRIPTIONS[action] || 'أمر غير معروف';
}

/**
 * Returns a human-readable Arabic preview of the parsed action.
 */
function buildPreviewMessage(parsed) {
  const { action, payload, confidence } = parsed;
  const pct = Math.round(confidence * 100);

  const lines = [`📋 **الأمر المُحلَّل:** ${describeAction(action)} (ثقة: ${pct}%)`];

  if (payload.date) lines.push(`📅 التاريخ: ${payload.date}`);
  if (payload.shift) lines.push(`⏱ النوبة: ${payload.shift}`);
  if (payload.name) lines.push(`👤 الاسم: ${payload.name}`);
  if (payload.status) lines.push(`✅ الحالة: ${payload.status}`);
  if (payload.newStatus) lines.push(`✅ الحالة الجديدة: ${payload.newStatus}`);
  if (payload.area) lines.push(`📍 المنطقة: ${payload.area}`);
  if (payload.query) lines.push(`🔍 البحث عن: ${payload.query}`);
  if (payload.note) lines.push(`📝 الملاحظة: ${payload.note}`);
  if (payload.recordId) lines.push(`🔢 رقم السجل: ${payload.recordId}`);
  if (payload.sourceDate) lines.push(`📅 تاريخ المصدر: ${payload.sourceDate}`);
  if (payload.targetDate) lines.push(`📅 تاريخ الهدف: ${payload.targetDate}`);

  return lines.join('\n');
}

// ── AI parser hook (for future integration) ─────────────────
// To add an AI parser, implement this interface and set it via setAIParser().
// The AI parser receives the text and must return the same ParsedAction shape.

let _aiParser = null;

function setAIParser(parserFn) {
  if (typeof parserFn !== 'function') throw new Error('AI parser must be a function');
  _aiParser = parserFn;
}

async function parseWithFallback(text) {
  if (_aiParser) {
    try {
      const result = await _aiParser(text);
      if (result && result.action && result.action !== 'unknown') return result;
    } catch (e) {
      console.warn('[PARSER] AI parser failed, falling back to rule-based:', e.message);
    }
  }
  return parse(text);
}

module.exports = {
  parse,
  parseWithFallback,
  buildPreviewMessage,
  describeAction,
  setAIParser,
};
