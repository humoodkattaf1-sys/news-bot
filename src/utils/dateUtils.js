'use strict';

const dayjs = require('dayjs');
const utc = require('dayjs/plugin/utc');
const timezone = require('dayjs/plugin/timezone');
const customParseFormat = require('dayjs/plugin/customParseFormat');

dayjs.extend(utc);
dayjs.extend(timezone);
dayjs.extend(customParseFormat);

const TZ = process.env.TIMEZONE || 'Asia/Kuwait';

// Arabic day names
const ARABIC_DAYS = {
  0: 'الأحد',
  1: 'الاثنين',
  2: 'الثلاثاء',
  3: 'الأربعاء',
  4: 'الخميس',
  5: 'الجمعة',
  6: 'السبت',
};

/**
 * Returns today's date as YYYY-MM-DD in Kuwait timezone.
 */
function today() {
  return dayjs().tz(TZ).format('YYYY-MM-DD');
}

/**
 * Returns tomorrow's date as YYYY-MM-DD in Kuwait timezone.
 */
function tomorrow() {
  return dayjs().tz(TZ).add(1, 'day').format('YYYY-MM-DD');
}

/**
 * Returns yesterday's date as YYYY-MM-DD in Kuwait timezone.
 */
function yesterday() {
  return dayjs().tz(TZ).subtract(1, 'day').format('YYYY-MM-DD');
}

/**
 * Returns current timestamp as ISO string in Kuwait timezone.
 */
function nowTimestamp() {
  return dayjs().tz(TZ).format('YYYY-MM-DD HH:mm:ss');
}

/**
 * Returns Arabic day name for a given YYYY-MM-DD date.
 */
function getArabicDay(dateStr) {
  const d = dayjs(dateStr, 'YYYY-MM-DD');
  return ARABIC_DAYS[d.day()] || '';
}

/**
 * Parses an Arabic date reference (اليوم، باجر، أمس) or a formatted date
 * into a normalized YYYY-MM-DD string.
 * Returns null if not recognizable.
 */
function parseArabicDate(text) {
  if (!text) return null;
  const t = text.trim();

  // Relative date words
  if (/اليوم/.test(t)) return today();
  if (/باجر|غداً|غدا|بكرة|بكره/.test(t)) return tomorrow();
  if (/أمس|امس|البارحة|بالامس/.test(t)) return yesterday();

  // Numeric formats: 26/4/2026 or 26-04-2026 or 2026-04-26
  const ddmmyyyy = t.match(/(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})/);
  if (ddmmyyyy) {
    const [, d, m, y] = ddmmyyyy;
    const parsed = dayjs(`${y}-${m.padStart(2, '0')}-${d.padStart(2, '0')}`, 'YYYY-MM-DD');
    if (parsed.isValid()) return parsed.format('YYYY-MM-DD');
  }

  const yyyymmdd = t.match(/(\d{4})[\/\-](\d{1,2})[\/\-](\d{1,2})/);
  if (yyyymmdd) {
    const [, y, m, d] = yyyymmdd;
    const parsed = dayjs(`${y}-${m.padStart(2, '0')}-${d.padStart(2, '0')}`, 'YYYY-MM-DD');
    if (parsed.isValid()) return parsed.format('YYYY-MM-DD');
  }

  return null;
}

/**
 * Extracts the first date-like string from an Arabic text.
 * Returns { date, word } where word is the matched substring (or null).
 */
function extractDateFromText(text) {
  // Try relative words first
  const relativeMatch = text.match(/اليوم|باجر|غداً|غدا|بكرة|بكره|أمس|امس|البارحة|بالامس/);
  if (relativeMatch) {
    return { date: parseArabicDate(relativeMatch[0]), word: relativeMatch[0] };
  }

  // Try numeric patterns
  const numericMatch = text.match(/\d{1,2}[\/\-]\d{1,2}[\/\-]\d{4}|\d{4}[\/\-]\d{1,2}[\/\-]\d{1,2}/);
  if (numericMatch) {
    return { date: parseArabicDate(numericMatch[0]), word: numericMatch[0] };
  }

  return { date: today(), word: null }; // Default to today
}

/**
 * Formats a YYYY-MM-DD string to Arabic display format: dd/mm/yyyy
 */
function formatDisplayDate(dateStr) {
  const d = dayjs(dateStr, 'YYYY-MM-DD');
  if (!d.isValid()) return dateStr;
  return d.format('DD/MM/YYYY');
}

module.exports = {
  today,
  tomorrow,
  yesterday,
  nowTimestamp,
  getArabicDay,
  parseArabicDate,
  extractDateFromText,
  formatDisplayDate,
};
