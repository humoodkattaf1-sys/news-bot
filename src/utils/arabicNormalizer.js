'use strict';

/**
 * Normalizes Arabic shift names to canonical form.
 */
function normalizeShift(text) {
  if (!text) return null;
  const t = text.trim();
  if (/صباح|صبح|الصبح|الصباح|صبح|الصب/.test(t)) return 'صباح';
  if (/عصر|العصر|عصري/.test(t)) return 'عصر';
  if (/ليل|الليل|ليلة|مسائي|مساء|المسائي/.test(t)) return 'ليل';
  return null;
}

/**
 * Extracts shift keyword from a full text string.
 */
function extractShiftFromText(text) {
  if (!text) return null;
  if (/نوبة\s*الصباح|نوبة\s*صباح|صبح|الصبح|الصباح/.test(text)) return 'صباح';
  if (/نوبة\s*العصر|نوبة\s*عصر|العصر/.test(text)) return 'عصر';
  if (/نوبة\s*الليل|نوبة\s*ليل|الليل|مسائي/.test(text)) return 'ليل';
  return null;
}

/**
 * Normalizes Arabic attendance status to canonical form.
 */
function normalizeStatus(text) {
  if (!text) return null;
  const t = text.trim();
  if (/حاضر|موجود|وصل|حضر|جاي|وصلت|حضرت/.test(t)) return 'حاضر';
  if (/غائب|مو موجود|ما وصل|غاب|مو جاي|ما حضر/.test(t)) return 'غائب';
  if (/إجازة|اجازة|مجازة|اجازه|إجازه/.test(t)) return 'إجازة';
  if (/طبي|مريض|إجازة طبية|اجازة طبية|مرخص/.test(t)) return 'طبي';
  if (/مأمورية|ماموري|بعثة|مبعوث/.test(t)) return 'مأمورية';
  return null;
}

/**
 * Extracts status keyword from a full text string.
 */
function extractStatusFromText(text) {
  if (!text) return null;
  const statusPatterns = [
    { pattern: /حاضر|موجود|وصل|حضر|جاي/, value: 'حاضر' },
    { pattern: /غائب|مو موجود|ما وصل|غاب|مو جاي/, value: 'غائب' },
    { pattern: /إجازة طبية|اجازة طبية|طبي|مريض|مرخص/, value: 'طبي' },
    { pattern: /إجازة|اجازة|مجازة/, value: 'إجازة' },
    { pattern: /مأمورية|ماموري|بعثة|مبعوث/, value: 'مأمورية' },
  ];
  for (const { pattern, value } of statusPatterns) {
    if (pattern.test(text)) return value;
  }
  return null;
}

/**
 * Removes common Arabic stop words and command keywords from text,
 * returning what's likely a name or important value.
 */
function removeCommandKeywords(text) {
  const stopWords = [
    // Action verbs
    'سجل', 'أضف', 'اضف', 'حط', 'عدل', 'غير', 'بدل', 'صحح', 'دور', 'ابحث',
    'ابحث عن', 'فين', 'وين', 'شوف', 'شوفلي', 'طلع', 'انقل', 'حرك', 'احذف',
    'حذف', 'امسح', 'مسح', 'اعرض', 'عرض', 'جهز', 'أضف ملاحظة', 'عدل ملاحظة',
    'حط ملاحظة', 'خله', 'خليه', 'كشف', 'سو', 'اعمل', 'اجيب',
    // Prepositions and connectors (no single letters — they strip partial Arabic words)
    'في', 'على', 'إلى', 'الى', 'من', 'عن', 'مع', 'بتاريخ',
    'لـ', 'بـ', 'ثم', 'بعد', 'قبل', 'لليوم', 'لباجر',
    // Date keywords (handled separately)
    'اليوم', 'باجر', 'غداً', 'غدا', 'بكرة', 'بكره', 'أمس', 'امس',
    // Shift keywords
    'نوبة', 'نوبه', 'الصباح', 'الصبح', 'العصر', 'الليل', 'صباح', 'عصر', 'ليل',
    'صبح', 'مسائي',
    // Status keywords
    'حاضر', 'غائب', 'إجازة', 'اجازة', 'طبي', 'مأمورية', 'ماموري',
    // Common nouns in commands
    'حالة', 'حاله', 'الموظف', 'ملاحظة', 'ملاحظه', 'سجل', 'رقم',
    // Report keywords
    'تقرير', 'اليومي', 'نهاية', 'نواقص', 'نقص', 'الحجز',
    // Common filler
    'كل', 'جميع', 'الكل', 'الموجودين', 'الموجودون',
  ];

  let result = text;
  // Sort by length desc so longer phrases are removed first
  stopWords.sort((a, b) => b.length - a.length);
  for (const word of stopWords) {
    result = result.replace(new RegExp(word, 'g'), ' ');
  }

  // Remove numeric date patterns
  result = result.replace(/\d{1,2}[\/\-]\d{1,2}[\/\-]\d{4}/g, ' ');
  result = result.replace(/\d{4}[\/\-]\d{1,2}[\/\-]\d{1,2}/g, ' ');
  // Remove numbers
  result = result.replace(/\d+/g, ' ');
  // Collapse spaces
  result = result.replace(/\s+/g, ' ').trim();

  return result;
}

/**
 * Extracts a probable Arabic name from command text after removing known keywords.
 * Expects at least 2 Arabic letters in a word to count as a name part.
 */
function extractNameFromText(text) {
  const cleaned = removeCommandKeywords(text);
  // Keep only Arabic words (at least 2 chars)
  const words = cleaned
    .split(/\s+/)
    .filter((w) => /^[؀-ۿ]{2,}$/.test(w));
  return words.join(' ') || null;
}

/**
 * Normalizes Arabic text: removes tashkeel (diacritics), normalizes alef variants.
 */
function normalizeArabicText(text) {
  if (!text) return '';
  return text
    .replace(/[ً-ٟ]/g, '') // Remove tashkeel
    .replace(/[أإآ]/g, 'ا')           // Normalize alef
    .replace(/ة/g, 'ه')              // Normalize ta marbuta
    .replace(/ى/g, 'ي')              // Normalize alef maqsura
    .trim();
}

/**
 * Extracts a note/annotation that appears after note-indicating words.
 * E.g. "أضف ملاحظة على محمد: تم التواصل" → "تم التواصل"
 */
function extractNoteFromText(text) {
  // Look for text after colon
  const colonMatch = text.match(/[:：]\s*(.+)$/);
  if (colonMatch) return colonMatch[1].trim();
  // Look for text after note keywords
  const noteMatch = text.match(/(?:ملاحظة|ملاحظه)\s+(?:\S+\s+)?[:：]?\s*(.+)$/);
  if (noteMatch) return noteMatch[1].trim();
  return '';
}

/**
 * Extracts a record ID number from text (e.g. "رقم 15" → 15).
 */
function extractRecordIdFromText(text) {
  const match = text.match(/رقم\s*(\d+)|#(\d+)|id[:\s]+(\d+)/i);
  if (match) return parseInt(match[1] || match[2] || match[3], 10);
  // Just a standalone number
  const numMatch = text.match(/\b(\d+)\b/);
  return numMatch ? parseInt(numMatch[1], 10) : null;
}

module.exports = {
  normalizeShift,
  extractShiftFromText,
  normalizeStatus,
  extractStatusFromText,
  removeCommandKeywords,
  extractNameFromText,
  normalizeArabicText,
  extractNoteFromText,
  extractRecordIdFromText,
};
