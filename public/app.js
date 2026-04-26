/* ═══════════════════════════════════════════════════════════
   Hawalli Sheets Command Agent — Frontend JavaScript
   Plain JS, no framework dependencies.
   ═══════════════════════════════════════════════════════════ */

'use strict';

// ── State ────────────────────────────────────────────────────
let currentApprovalId = null;

// ── Startup ──────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
  checkHealth();
  loadApprovals();
  loadLogs();

  // Allow sending with Ctrl+Enter in the textarea
  document.getElementById('commandInput').addEventListener('keydown', (e) => {
    if ((e.ctrlKey || e.metaKey) && e.key === 'Enter') sendCommand();
  });
});

// ── Health check ─────────────────────────────────────────────
async function checkHealth() {
  const dot = document.getElementById('statusDot');
  const txt = document.getElementById('statusText');
  try {
    const res = await fetch('/health');
    const data = await res.json();
    if (data.status === 'ok') {
      dot.className = 'status-dot ok';
      txt.textContent = 'النظام يعمل';
    } else {
      dot.className = 'status-dot err';
      txt.textContent = 'خطأ في النظام';
    }
  } catch {
    dot.className = 'status-dot err';
    txt.textContent = 'تعذر الاتصال';
  }
}

// ── Send command ─────────────────────────────────────────────
async function sendCommand() {
  const text = document.getElementById('commandInput').value.trim();
  const token = document.getElementById('adminToken').value.trim();
  const user = document.getElementById('userInput').value.trim() || 'مشرف';

  if (!text) { showToast('يرجى كتابة أمر أولاً'); return; }
  if (!token) { showToast('يرجى إدخال رمز المشرف أولاً'); return; }

  const btn = document.getElementById('sendBtn');
  btn.disabled = true;
  btn.innerHTML = '<span class="spinner"></span> جاري التنفيذ...';

  try {
    const res = await fetch('/api/command', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-admin-token': token,
      },
      body: JSON.stringify({ text, user }),
    });

    const data = await res.json();
    displayResult(data);

    if (data.status !== 'error') {
      document.getElementById('commandInput').value = '';
    }

    // Refresh side panels
    setTimeout(() => { loadApprovals(); loadLogs(); }, 800);
  } catch (err) {
    displayResult({ status: 'error', message: 'تعذر الاتصال بالخادم: ' + err.message });
  } finally {
    btn.disabled = false;
    btn.innerHTML = '<span>🚀</span> تنفيذ';
  }
}

// ── Display result ───────────────────────────────────────────
function displayResult(data) {
  const card = document.getElementById('resultCard');
  const content = document.getElementById('resultContent');
  const actions = document.getElementById('approvalActions');
  const searchDiv = document.getElementById('searchResults');
  const attendanceDiv = document.getElementById('attendanceResults');

  card.style.display = 'block';
  actions.style.display = 'none';
  searchDiv.style.display = 'none';
  attendanceDiv.style.display = 'none';
  currentApprovalId = null;

  // Status badge
  const statusLabels = {
    executed: { label: 'تم التنفيذ', cls: 'badge-executed' },
    preview: { label: 'بانتظار الاعتماد', cls: 'badge-preview' },
    error: { label: 'خطأ', cls: 'badge-error' },
    needs_clarification: { label: 'يحتاج توضيح', cls: 'badge-clarify' },
  };

  const s = statusLabels[data.status] || { label: data.status, cls: '' };
  const badge = `<span class="result-status-badge ${s.cls}">${s.label}</span>\n`;

  content.textContent = data.message || '';
  content.insertAdjacentHTML('afterbegin', badge);

  // Show approval actions
  if (data.status === 'preview' && data.approvalId) {
    currentApprovalId = data.approvalId;
    actions.style.display = 'flex';
  }

  // Show search results table
  if (data.result?.results && data.result.results.length > 0) {
    searchDiv.style.display = 'block';
    searchDiv.innerHTML = buildEmployeeTable(data.result.results);
  }

  // Show attendance results table
  if (data.result?.records && data.result.records.length > 0) {
    attendanceDiv.style.display = 'block';
    attendanceDiv.innerHTML = buildAttendanceTable(data.result.records);
  }

  // Scroll card into view
  card.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
}

// ── Approve command ──────────────────────────────────────────
async function approveCommand() {
  if (!currentApprovalId) return;
  const token = document.getElementById('adminToken').value.trim();
  const user = document.getElementById('userInput').value.trim() || 'مشرف';

  const btn = document.getElementById('approveBtn');
  btn.disabled = true;
  btn.textContent = 'جاري الاعتماد...';

  try {
    const res = await fetch(`/api/approve/${currentApprovalId}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-admin-token': token },
      body: JSON.stringify({ user }),
    });
    const data = await res.json();
    showToast(data.status === 'ok' ? '✅ تم الاعتماد والتنفيذ' : ('❌ ' + data.message));
    displayResult({ status: data.status === 'ok' ? 'executed' : 'error', message: data.message });
    loadApprovals();
    loadLogs();
  } catch (err) {
    showToast('خطأ: ' + err.message);
  } finally {
    btn.disabled = false;
    btn.innerHTML = '<span>✅</span> اعتماد وتنفيذ';
  }
}

// ── Reject command ───────────────────────────────────────────
async function rejectCommand() {
  if (!currentApprovalId) return;
  const token = document.getElementById('adminToken').value.trim();
  const user = document.getElementById('userInput').value.trim() || 'مشرف';

  try {
    const res = await fetch(`/api/reject/${currentApprovalId}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-admin-token': token },
      body: JSON.stringify({ user, reason: 'رُفض من واجهة النظام' }),
    });
    const data = await res.json();
    showToast(data.status === 'ok' ? '❌ تم الرفض' : data.message);
    document.getElementById('approvalActions').style.display = 'none';
    loadApprovals();
  } catch (err) {
    showToast('خطأ: ' + err.message);
  }
}

// ── Load approvals ───────────────────────────────────────────
async function loadApprovals() {
  const token = document.getElementById('adminToken').value.trim();
  if (!token) return;

  const container = document.getElementById('approvalsContainer');
  const badge = document.getElementById('pendingBadge');

  try {
    const res = await fetch('/api/approvals?status=معلق', {
      headers: { 'x-admin-token': token },
    });
    const data = await res.json();
    const approvals = data.approvals || [];

    badge.textContent = approvals.length;
    badge.className = 'badge' + (approvals.length === 0 ? ' zero' : '');

    if (approvals.length === 0) {
      container.innerHTML = '<p class="empty-msg">لا توجد اعتمادات معلقة</p>';
      return;
    }

    container.innerHTML = approvals.map((a) => `
      <div class="approval-item">
        <div class="approval-command">${escHtml(a.originalText)}</div>
        <div class="approval-meta">
          الإجراء: ${escHtml(a.action)} &nbsp;|&nbsp; بواسطة: ${escHtml(a.user)} &nbsp;|&nbsp; ${escHtml(a.timestamp)}
        </div>
        <div class="approval-btns">
          <button class="btn btn-success btn-sm" onclick="quickApprove('${a.approvalId}')">✅ اعتماد</button>
          <button class="btn btn-danger btn-sm" onclick="quickReject('${a.approvalId}')">❌ رفض</button>
        </div>
      </div>
    `).join('');
  } catch {
    container.innerHTML = '<p class="empty-msg">تعذر تحميل الاعتمادات</p>';
  }
}

async function quickApprove(id) {
  const token = document.getElementById('adminToken').value.trim();
  const user = document.getElementById('userInput').value.trim() || 'مشرف';
  try {
    const res = await fetch(`/api/approve/${id}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-admin-token': token },
      body: JSON.stringify({ user }),
    });
    const data = await res.json();
    showToast(data.status === 'ok' ? '✅ تم الاعتماد والتنفيذ' : data.message);
    loadApprovals();
    loadLogs();
  } catch (err) {
    showToast('خطأ: ' + err.message);
  }
}

async function quickReject(id) {
  const token = document.getElementById('adminToken').value.trim();
  const user = document.getElementById('userInput').value.trim() || 'مشرف';
  try {
    const res = await fetch(`/api/reject/${id}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-admin-token': token },
      body: JSON.stringify({ user, reason: 'رُفض يدوياً' }),
    });
    const data = await res.json();
    showToast(data.status === 'ok' ? '❌ تم الرفض' : data.message);
    loadApprovals();
  } catch (err) {
    showToast('خطأ: ' + err.message);
  }
}

// ── Load today attendance ────────────────────────────────────
async function loadTodayAttendance() {
  const token = document.getElementById('adminToken').value.trim();
  if (!token) { showToast('يرجى إدخال رمز المشرف أولاً'); return; }

  const container = document.getElementById('todayContainer');
  container.innerHTML = '<p class="empty-msg"><span class="spinner"></span></p>';

  try {
    const res = await fetch('/api/today', { headers: { 'x-admin-token': token } });
    const data = await res.json();
    const records = data.records || [];

    const byShift = (s) => records.filter((r) => r.shift === s);
    const morningPresent = byShift('صباح').filter((r) => r.status === 'حاضر').length;
    const afterPresent = byShift('عصر').filter((r) => r.status === 'حاضر').length;
    const nightPresent = byShift('ليل').filter((r) => r.status === 'حاضر').length;

    const summary = `
      <div class="shift-summary">
        <div class="shift-card">
          <div class="shift-label">صباح</div>
          <div class="shift-count">${morningPresent}/${byShift('صباح').length}</div>
        </div>
        <div class="shift-card">
          <div class="shift-label">عصر</div>
          <div class="shift-count">${afterPresent}/${byShift('عصر').length}</div>
        </div>
        <div class="shift-card">
          <div class="shift-label">ليل</div>
          <div class="shift-count">${nightPresent}/${byShift('ليل').length}</div>
        </div>
      </div>
    `;

    if (records.length === 0) {
      container.innerHTML = summary + '<p class="empty-msg">لا توجد سجلات حضور لهذا اليوم</p>';
      return;
    }

    container.innerHTML = summary + buildAttendanceTable(records.slice(0, 20));
  } catch (err) {
    container.innerHTML = '<p class="empty-msg">تعذر تحميل الحضور: ' + escHtml(err.message) + '</p>';
  }
}

// ── Load logs ────────────────────────────────────────────────
async function loadLogs() {
  const token = document.getElementById('adminToken').value.trim();
  if (!token) return;

  const container = document.getElementById('logsContainer');

  try {
    const res = await fetch('/api/logs?limit=20', { headers: { 'x-admin-token': token } });
    const data = await res.json();
    const logs = data.logs || [];

    if (logs.length === 0) {
      container.innerHTML = '<p class="empty-msg">لا توجد سجلات حديثة</p>';
      return;
    }

    container.innerHTML = logs.map((l) => `
      <div class="log-item">
        <div>
          <span class="log-action">${escHtml(l.action)}</span>
          &nbsp;
          <span class="log-status-${escHtml(l.status)}">${statusLabel(l.status)}</span>
        </div>
        <span class="log-text">${escHtml(l.originalText || '')}</span>
        <div class="log-time">${escHtml(l.timestamp)} — ${escHtml(l.user)}</div>
      </div>
    `).join('');
  } catch {
    container.innerHTML = '<p class="empty-msg">تعذر تحميل السجلات</p>';
  }
}

// ── Set quick command ────────────────────────────────────────
function setCommand(text) {
  document.getElementById('commandInput').value = text;
  document.getElementById('commandInput').focus();
}

// ── Table builders ───────────────────────────────────────────
function buildEmployeeTable(rows) {
  if (!rows.length) return '<p class="empty-msg">لا توجد نتائج</p>';
  return `
    <table class="data-table">
      <thead>
        <tr>
          <th>الاسم</th><th>الرتبة</th><th>الإدارة</th><th>المنطقة</th><th>الحالة</th>
        </tr>
      </thead>
      <tbody>
        ${rows.map((r) => `
          <tr>
            <td>${escHtml(r.name || r['الاسم'] || '')}</td>
            <td>${escHtml(r.rank || r['الرتبة'] || '')}</td>
            <td>${escHtml(r.department || r['الإدارة'] || '')}</td>
            <td>${escHtml(r.area || r['المنطقة'] || '')}</td>
            <td class="status-${escHtml(r.status || r['الحالة'] || '')}">${escHtml(r.status || r['الحالة'] || '')}</td>
          </tr>
        `).join('')}
      </tbody>
    </table>
  `;
}

function buildAttendanceTable(rows) {
  if (!rows.length) return '<p class="empty-msg">لا توجد سجلات</p>';
  return `
    <table class="data-table">
      <thead>
        <tr>
          <th>الاسم</th><th>النوبة</th><th>الحالة</th><th>المنطقة</th>
        </tr>
      </thead>
      <tbody>
        ${rows.map((r) => `
          <tr>
            <td>${escHtml(r.name || r['الاسم'] || '')}</td>
            <td>${escHtml(r.shift || r['النوبة'] || '')}</td>
            <td class="status-${escHtml(r.status || r['الحالة'] || '')}">${escHtml(r.status || r['الحالة'] || '')}</td>
            <td>${escHtml(r.area || r['المنطقة'] || '')}</td>
          </tr>
        `).join('')}
      </tbody>
    </table>
  `;
}

// ── Helpers ──────────────────────────────────────────────────
function escHtml(str) {
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

function statusLabel(s) {
  const labels = {
    executed: 'تم التنفيذ',
    error: 'خطأ',
    pending_approval: 'بانتظار اعتماد',
    needs_clarification: 'يحتاج توضيح',
    approved_and_executed: 'معتمد ومنفذ',
    rejected: 'مرفوض',
  };
  return labels[s] || s;
}

let toastTimer;
function showToast(msg) {
  const el = document.getElementById('toast');
  el.textContent = msg;
  el.style.display = 'block';
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => { el.style.display = 'none'; }, 3500);
}
