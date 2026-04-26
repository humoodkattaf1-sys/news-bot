'use strict';

/**
 * Environment configuration and validation.
 * Called once at server startup; crashes early if critical vars are missing.
 */
function validateEnv() {
  const required = ['ADMIN_TOKEN'];
  const missing = required.filter((k) => !process.env[k]);

  if (missing.length) {
    console.error(`[CONFIG] Missing required environment variables: ${missing.join(', ')}`);
    console.error('[CONFIG] Copy .env.example to .env and fill in the values.');
    process.exit(1);
  }

  if (!process.env.SPREADSHEET_ID || !process.env.GOOGLE_CLIENT_EMAIL || !process.env.GOOGLE_PRIVATE_KEY) {
    console.warn('[CONFIG] Google Sheets credentials not fully configured.');
    console.warn('[CONFIG] Commands that require Sheets access will fail until configured.');
  }
}

function getConfig() {
  return {
    port: parseInt(process.env.PORT || '3000', 10),
    spreadsheetId: process.env.SPREADSHEET_ID || '',
    googleClientEmail: process.env.GOOGLE_CLIENT_EMAIL || '',
    googlePrivateKey: (process.env.GOOGLE_PRIVATE_KEY || '').replace(/\\n/g, '\n'),
    adminToken: process.env.ADMIN_TOKEN || '',
    approvalMode: process.env.APPROVAL_MODE !== 'false',
    timezone: process.env.TIMEZONE || 'Asia/Kuwait',
  };
}

module.exports = { validateEnv, getConfig };
