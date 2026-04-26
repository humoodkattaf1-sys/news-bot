'use strict';

require('dotenv').config();
const express = require('express');
const path = require('path');

const { validateEnv } = require('./src/config/env');
const commandRoutes = require('./src/routes/commandRoutes');
const approvalRoutes = require('./src/routes/approvalRoutes');
const employeeRoutes = require('./src/routes/employeeRoutes');
const setupRoutes = require('./src/routes/setupRoutes');
const reportRoutes = require('./src/routes/reportRoutes');

// Validate critical environment variables on startup
validateEnv();

const app = express();
const PORT = process.env.PORT || 3000;

// ── Middleware ──────────────────────────────────────────────
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, 'public')));

// Security headers
app.use((req, res, next) => {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'DENY');
  res.setHeader('X-XSS-Protection', '1; mode=block');
  next();
});

// Request logger
app.use((req, res, next) => {
  const ts = new Date().toISOString();
  console.log(`[${ts}] ${req.method} ${req.path}`);
  next();
});

// ── Routes ──────────────────────────────────────────────────
app.use('/api', commandRoutes);
app.use('/api', approvalRoutes);
app.use('/api', employeeRoutes);
app.use('/api', setupRoutes);
app.use('/api', reportRoutes);

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    system: 'Hawalli Sheets Command Agent',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
    approvalMode: process.env.APPROVAL_MODE === 'true',
    timezone: process.env.TIMEZONE || 'Asia/Kuwait',
    sheetsConfigured: !!(process.env.SPREADSHEET_ID && process.env.GOOGLE_CLIENT_EMAIL),
  });
});

// Serve UI for all non-API routes
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Global error handler
app.use((err, req, res, _next) => {
  console.error('[ERROR]', err.message);
  res.status(err.status || 500).json({
    status: 'error',
    message: err.message || 'حدث خطأ غير متوقع في النظام',
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ status: 'error', message: 'المسار غير موجود' });
});

app.listen(PORT, () => {
  console.log('');
  console.log('  ╔══════════════════════════════════════════╗');
  console.log('  ║    Hawalli Sheets Command Agent v1.0     ║');
  console.log('  ╚══════════════════════════════════════════╝');
  console.log(`  🌐 Server running at: http://localhost:${PORT}`);
  console.log(`  🔒 Approval mode: ${process.env.APPROVAL_MODE === 'true' ? 'ENABLED' : 'DISABLED'}`);
  console.log(`  ⏰ Timezone: ${process.env.TIMEZONE || 'Asia/Kuwait'}`);
  console.log('');
});

module.exports = app;
