'use strict';

const { google } = require('googleapis');
const { getConfig } = require('./env');

let _sheetsClient = null;

/**
 * Returns an authenticated Google Sheets client (singleton).
 * Throws a clear error if credentials are not configured.
 */
function getSheetsClient() {
  if (_sheetsClient) return _sheetsClient;

  const config = getConfig();

  if (!config.googleClientEmail || !config.googlePrivateKey || !config.spreadsheetId) {
    throw new Error(
      'بيانات Google Sheets غير مكتملة. تأكد من إعداد SPREADSHEET_ID و GOOGLE_CLIENT_EMAIL و GOOGLE_PRIVATE_KEY في ملف .env'
    );
  }

  try {
    const auth = new google.auth.GoogleAuth({
      credentials: {
        client_email: config.googleClientEmail,
        private_key: config.googlePrivateKey,
      },
      scopes: ['https://www.googleapis.com/auth/spreadsheets'],
    });
    _sheetsClient = google.sheets({ version: 'v4', auth });
    return _sheetsClient;
  } catch (err) {
    throw new Error(
      'فشل الاتصال بـ Google Sheets. تأكد أن GOOGLE_PRIVATE_KEY في ملف .env صحيح وكامل.\n' +
      'ملاحظة: يجب أن يكون المفتاح بالشكل: "-----BEGIN RSA PRIVATE KEY-----\\n...\\n-----END RSA PRIVATE KEY-----"\n' +
      `(الخطأ التقني: ${err.message})`
    );
  }
}

function getSpreadsheetId() {
  const config = getConfig();
  if (!config.spreadsheetId) {
    throw new Error('SPREADSHEET_ID غير محدد في ملف .env');
  }
  return config.spreadsheetId;
}

// Reset client (useful for testing)
function resetClient() {
  _sheetsClient = null;
}

module.exports = { getSheetsClient, getSpreadsheetId, resetClient };
