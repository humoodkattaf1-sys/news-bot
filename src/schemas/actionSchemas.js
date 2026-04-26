'use strict';

const { z } = require('zod');

// ── Shared field validators ─────────────────────────────────

const ArabicShift = z.enum(['صباح', 'عصر', 'ليل']);
const ArabicStatus = z.enum(['حاضر', 'غائب', 'إجازة', 'طبي', 'مأمورية']);
const ISODate = z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'يجب أن يكون التاريخ بصيغة YYYY-MM-DD');

// ── Action payload schemas ──────────────────────────────────

const AddAttendanceSchema = z.object({
  date: ISODate,
  shift: ArabicShift,
  name: z.string().min(2, 'الاسم مطلوب'),
  employeeId: z.string().optional().default(''),
  area: z.string().optional().default(''),
  status: ArabicStatus.default('حاضر'),
  notes: z.string().optional().default(''),
  addedBy: z.string().optional().default('النظام'),
});

const UpdateAttendanceSchema = z.object({
  recordId: z.string().optional(),
  date: ISODate.optional(),
  shift: ArabicShift.optional(),
  name: z.string().optional(),
  newStatus: ArabicStatus.optional(),
  newNotes: z.string().optional(),
  newArea: z.string().optional(),
});

const SearchEmployeeSchema = z.object({
  query: z.string().min(1, 'كلمة البحث مطلوبة'),
});

const AddEmployeeSchema = z.object({
  name: z.string().min(2, 'الاسم مطلوب'),
  rank: z.string().optional().default(''),
  department: z.string().optional().default(''),
  area: z.string().optional().default(''),
  phone: z.string().optional().default(''),
  notes: z.string().optional().default(''),
});

const UpdateEmployeeSchema = z.object({
  employeeId: z.string().optional(),
  name: z.string().optional(),
  field: z.enum(['الرتبة', 'الإدارة', 'المنطقة', 'الحالة', 'الهاتف', 'ملاحظات']).optional(),
  value: z.string().optional(),
});

const GenerateDailyReportSchema = z.object({
  date: ISODate,
  notes: z.string().optional().default(''),
});

const MoveNightShiftSchema = z.object({
  sourceDate: ISODate,
  targetDate: ISODate,
  notes: z.string().optional().default(''),
});

const CalculateShortageSchema = z.object({
  date: ISODate,
  shift: ArabicShift.optional(),
  area: z.string().optional().default(''),
});

const AddNoteSchema = z.object({
  target: z.string().min(1, 'الهدف مطلوب (اسم الموظف أو رقم السجل)'),
  note: z.string().min(1, 'الملاحظة مطلوبة'),
  date: ISODate.optional(),
  shift: ArabicShift.optional(),
});

const DeleteRecordSchema = z.object({
  sheetName: z.string().min(1),
  recordId: z.union([z.string(), z.number()]),
  reason: z.string().optional().default(''),
});

const ListTodaySchema = z.object({
  date: ISODate,
  shift: ArabicShift.optional(),
  area: z.string().optional().default(''),
});

const ListShiftSchema = z.object({
  date: ISODate,
  shift: ArabicShift,
  area: z.string().optional().default(''),
});

const SetupSheetsSchema = z.object({});

// ── Incoming command schema ─────────────────────────────────

const IncomingCommandSchema = z.object({
  text: z.string().min(1, 'الأمر مطلوب'),
  user: z.string().optional().default('مجهول'),
});

// ── Parsed action schema ────────────────────────────────────

const VALID_ACTIONS = [
  'add_attendance',
  'update_attendance',
  'search_employee',
  'add_employee',
  'update_employee',
  'generate_daily_report',
  'move_night_shift_to_next_day_detention',
  'calculate_shift_shortage',
  'add_note',
  'delete_record',
  'list_today',
  'list_shift',
  'setup_sheets',
  'unknown',
];

const ParsedActionSchema = z.object({
  action: z.enum(VALID_ACTIONS),
  confidence: z.number().min(0).max(1),
  requiresApproval: z.boolean(),
  payload: z.record(z.unknown()),
  originalText: z.string(),
  clarificationNeeded: z.string().optional(),
});

module.exports = {
  AddAttendanceSchema,
  UpdateAttendanceSchema,
  SearchEmployeeSchema,
  AddEmployeeSchema,
  UpdateEmployeeSchema,
  GenerateDailyReportSchema,
  MoveNightShiftSchema,
  CalculateShortageSchema,
  AddNoteSchema,
  DeleteRecordSchema,
  ListTodaySchema,
  ListShiftSchema,
  SetupSheetsSchema,
  IncomingCommandSchema,
  ParsedActionSchema,
  VALID_ACTIONS,
  ArabicShift,
  ArabicStatus,
  ISODate,
};
